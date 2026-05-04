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
  void buildPoints(ArrayList<PVector> source_points, DataImage image, int seed)
  {
    // Repart d'une liste vide à chaque recalcul
    points.clear();

    // Plage utile de valeurs pixel — si nulle (min = max), rien à faire
    float range = data_filter.max_value - data_filter.min_value;
    if (range <= 0) return;

    // Fixe la graine aléatoire pour que le filtrage soit reproductible
    // (même seed que le générateur → résultat stable pour un paramétrage donné)
    randomSeed(seed);

    for (PVector p : source_points)
    {
      // Récupère la valeur de luminosité du pixel sous le point p [0..255]
      // Retourne -1 si le point est en dehors des limites de l'image
      float value = image.getPixelValue(p);

      // Point hors image : on l'ignore systématiquement
      if (value == -1) continue;

      // ÉTAPE 1 — CLAMP : ignore les pixels trop clairs ou trop sombres.
      // Permet de ne travailler que sur une plage de tonalités choisie.
      // Ex: min_value=50, max_value=200 → les noirs purs et blancs purs sont ignorés.
      value = constrain(value, data_filter.min_value, data_filter.max_value);

      // ÉTAPE 2 — NORMALISATION : ramène la valeur dans [0, 1].
      // 0 = la valeur la plus sombre de la plage, 1 = la plus claire.
      float normalized = (value - data_filter.min_value) / range;

      // ÉTAPE 3 — CORRECTION GAMMA : applique une courbe de puissance.
      // gamma < 1 : compresse les hautes valeurs → plus de points dans les zones claires
      // gamma > 1 : compresse les basses valeurs → plus de points dans les zones sombres
      // gamma = 1 : aucune correction, relation linéaire
      normalized = pow(normalized, data_filter.gamma);

      // ÉTAPE 4 — MODE : détermine si les zones sombres ou claires génèrent des points.
      // black=true  → prob haute pour normalized proche de 0 (zones sombres)
      // black=false → prob haute pour normalized proche de 1 (zones claires)
      float prob = data_filter.black ? (1.0 - normalized) : normalized;

      // ÉTAPE 5 — DENSITÉ GLOBALE : threshold [0..255] agit comme un multiplicateur.
      // threshold=255 → prob inchangée (densité maximale)
      // threshold=128 → moitié des points conservés en moyenne
      // threshold=0   → aucun point conservé
      prob *= data_filter.threshold / 255.0;

      // TIRAGE ALÉATOIRE : conserve le point avec la probabilité calculée.
      // random(1.0) retourne une valeur dans [0, 1[ de façon uniforme.
      // En moyenne, une proportion "prob" des points sera conservée.
      if (random(1.0) < prob)
        points.add(p);
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
