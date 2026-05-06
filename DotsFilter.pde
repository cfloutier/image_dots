// ============================================================
// DotsFilter — Filtrage probabiliste des points blue noise par l'image
//
// PRINCIPE GÉNÉRAL :
//   Le générateur (DotsGenerator) produit une grille de points régulièrement
//   espacés, sans tenir compte de l'image. Le rôle du DotsFilter est de
//   décider, pour chaque point, s'il sera conservé ou supprimé, en fonction
//   de la luminosité du pixel correspondant dans l'image source.
//
//   L'idée : une zone sombre de l'image → forte densité de points conservés
//            une zone claire                → peu ou pas de points
//   (ou l'inverse si le mode "black" est désactivé)
//
// PIPELINE PAR POINT :
//   valeur brute [0..255]
//     → clamp dans [min_value, max_value]     (ignorer les extrêmes)
//     → normalisation dans [0, 1]             (min_value → 0, max_value → 1)
//     → correction gamma : pow(x, gamma)      (courbe de contraste)
//     → inversion si mode black               (1 - x)
//     → multiplication par threshold/255      (densité globale)
//     → tirage aléatoire : si random < prob   → point conservé
//
// REPRODUCTIBILITÉ :
//   On fixe randomSeed(seed) avec le même seed que le générateur,
//   pour que le même paramétrage donne toujours le même résultat.
// ============================================================

class DotsFilter
{
  // Liste des points conservés après filtrage (sous-ensemble des points du générateur)
  ArrayList<PVector> points = new ArrayList<PVector>();

  // Référence aux paramètres de filtrage (seuil, gamma, min/max, mode noir/blanc)
  DataFilter data_filter;

  DotsFilter(DataFilter filter)
  {
    this.data_filter = filter;
  }

  // -------------------------------------------------------
  // buildPoints() : construit la liste filtrée à partir des points bruts
  // Appelé après chaque fin de génération, ou quand les paramètres filter changent.
  // -------------------------------------------------------
  void buildPoints(ArrayList<PVector> source_points, DataImage image, DataDots dots)
  {
    // Repart d'une liste vide à chaque recalcul
    points.clear();

    // Plage utile de valeurs pixel — si nulle (min = max), rien à faire
    float range = data_filter.max_value - data_filter.min_value;
    if (range <= 0) return;

    // Fixe la graine aléatoire pour que le filtrage soit reproductible
    randomSeed(dots.seed);

    // SHUFFLE optionnel : mélange aléatoire pour éviter le biais d'ordre
    // (sans shuffle, les points du début de liste ont moins de voisins et
    // sont donc systématiquement favorisés par rapport aux suivants)
    ArrayList<PVector> ordered = new ArrayList<PVector>(source_points);
    if (dots.shuffle)
      java.util.Collections.shuffle(ordered, new java.util.Random(dots.seed));

    // GRILLE SPATIALE des points déjà acceptés
    // Même principe que dans DotsGenerator : cellule de taille influence_radius,
    // chaque cellule stocke la liste des points acceptés qu'elle contient.
    float cell    = data_filter.influence_radius;
    float img_w   = (image.blurred_image != null) ? image.blurred_image.width  : width;
    float img_h   = (image.blurred_image != null) ? image.blurred_image.height : height;
    float ox      = img_w / 2;
    float oy      = img_h / 2;
    int   g_cols  = ceil(img_w / cell) + 1;
    int   g_rows  = ceil(img_h / cell) + 1;

    // Chaque cellule contient une liste d'index vers points[]
    ArrayList<Integer>[] grid = new ArrayList[g_cols * g_rows];
    for (int i = 0; i < grid.length; i++)
      grid[i] = new ArrayList<Integer>();

    for (PVector p : ordered)
    {
      // Valeur de luminosité du pixel sous le point p [0..255]
      float value = image.getPixelValue(p);
      if (value == -1) continue;

      // ÉTAPE 1 — CLAMP
      value = constrain(value, data_filter.min_value, data_filter.max_value);

      // ÉTAPE 2 — NORMALISATION [0, 1]
      float normalized = (value - data_filter.min_value) / range;

      // ÉTAPE 3 — GAMMA
      normalized = pow(normalized, data_filter.gamma);

      // ÉTAPE 4 — MODE noir/blanc
      float prob = data_filter.black ? (1.0 - normalized) : normalized;

      // ÉTAPE 5 — DENSITÉ GLOBALE
      prob *= data_filter.threshold / 255.0;

      // ÉTAPE 6 — CORRECTION SPATIALE (Direction A)
      // Compte les points déjà acceptés dans le rayon influence_radius
      int cgx = (int)((p.x + ox) / cell);
      int cgy = (int)((p.y + oy) / cell);

      int neighbor_count = 0;
      float r2 = data_filter.influence_radius * data_filter.influence_radius;

      // Inspecte les cellules voisines (voisinage 3x3 suffit car cell = influence_radius)
      for (int dy = -1; dy <= 1 && neighbor_count < data_filter.max_neighbors; dy++)
      {
        for (int dx = -1; dx <= 1 && neighbor_count < data_filter.max_neighbors; dx++)
        {
          int nx = cgx + dx;
          int ny = cgy + dy;
          if (nx < 0 || nx >= g_cols || ny < 0 || ny >= g_rows) continue;
          for (int idx : grid[nx + ny * g_cols])
          {
            PVector q = points.get(idx);
            float ddx = p.x - q.x;
            float ddy = p.y - q.y;
            if (ddx*ddx + ddy*ddy < r2)
            {
              neighbor_count++;
              if (neighbor_count >= data_filter.max_neighbors) break;
            }
          }
        }
      }

      // CORRECTION SPATIALE ADAPTATIVE
      // Problème de la formule plate : en zone sombre (prob élevé), dès que
      // max_neighbors voisins sont acceptés, prob → 0, ce qui efface la densité
      // souhaitée par l'image.
      //
      // Solution : le nombre de voisins TOLÉRÉS est proportionnel à prob_image.
      //   zone noire  (prob=0.85) → expected=2.55 voisins tolérés avant réduction
      //   zone grise  (prob=0.50) → expected=1.50
      //   zone claire (prob=0.10) → expected=0.30 → même 1 voisin cause une réduction
      //
      // On ne réduit que l'EXCÈS par rapport à cette cible locale :
      //   excess = max(0, neighbor_count - expected)
      //   prob  *= max(0, 1 - excess / max_neighbors)
      float expected = data_filter.max_neighbors * prob; // cible locale
      float excess   = max(0, neighbor_count - expected);
      prob *= max(0, 1.0 - excess / data_filter.max_neighbors);

      // TIRAGE
      if (random(1.0) < prob)
      {
        // Enregistre le point et le place dans la grille spatiale
        int new_idx = points.size();
        points.add(p);
        int gx = constrain((int)((p.x + ox) / cell), 0, g_cols - 1);
        int gy = constrain((int)((p.y + oy) / cell), 0, g_rows - 1);
        grid[gx + gy * g_cols].add(new_idx);
      }
    }

    println("DotsFilter: " + points.size() + " / " + source_points.size() + " points kept");
  }

  // -------------------------------------------------------
  // draw() : affichage debug — tous les points filtrés comme simples pixels
  // -------------------------------------------------------
  void draw()
  {
    for (PVector p : points) {
      current_graphics.point(p.x, p.y);
    }
  }

  // -------------------------------------------------------
  // drawWithShape() : affichage final — point ou polygone selon DataShape
  // -------------------------------------------------------

  // Surcharge sans verbosité (rendu normal à l'écran)
  void drawWithShape(DataShape shape)
  {
    drawWithShape(shape, false);
  }

  // verbose=true : affiche la progression dans la console (utilisé lors de l'export)
  void drawWithShape(DataShape shape, boolean verbose)
  {
    int total = points.size();

    // Fréquence de log : tous les 5% (total/20 points)
    int log_step = max(1, total / 20);

    if (verbose)
      println("Export: dessin de " + StringUtils.formatInt(total) + " points...");

    if (shape.mode == DataShape.MODE_POINT)
    {
      // MODE POINT : chaque point est un simple pixel — le plus léger pour l'export
      for (int i = 0; i < total; i++)
      {
        if (verbose && i % log_step == 0)
          println("  " + (i * 100 / total) + "%  (" + StringUtils.formatInt(i) + " / " + StringUtils.formatInt(total) + ")");
        PVector p = points.get(i);
        current_graphics.point(p.x, p.y);
      }
    }
    else
    {
      // MODE POLYGONE : dessine un polygone régulier centré sur chaque point.
      // Un cercle est approximé par un polygone à n côtés (n = shape.sides).
      // Plus n est grand, plus la forme est ronde ; n=3 donne des triangles, etc.
      current_graphics.noFill(); // contour seulement (trait de plume)

      // r = rayon du polygone inscrit (= moitié de la taille choisie)
      float r = shape.size / 2.0;
      int   n = shape.sides;

      for (int i = 0; i < total; i++)
      {
        if (verbose && i % log_step == 0)
          println("  " + (i * 100 / total) + "%  (" + StringUtils.formatInt(i) + " / " + StringUtils.formatInt(total) + ")");

        PVector p = points.get(i);

        current_graphics.beginShape();
        for (int j = 0; j <= n; j++) // j <= n pour fermer le polygone (dernier = premier)
        {
          // Répartit n sommets uniformément sur le cercle de rayon r.
          // -PI/2 : fait pointer le premier sommet vers le haut (12h).
          float angle = TWO_PI * j / n - PI / 2;
          current_graphics.vertex(p.x + cos(angle) * r,
                                  p.y + sin(angle) * r);
        }
        current_graphics.endShape();
      }
    }

    if (verbose)
      println("Export: done.");
  }
}
