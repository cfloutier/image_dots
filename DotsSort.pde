// ============================================================
// DotsSort — Tri spatial par grille hexagonale en spirale
//
// Algorithme :
//   1. Assigner chaque point à une cellule hexagonale (coordonnées axiales)
//   2. Parcourir les cellules en spirale depuis la cellule centrale
//   3. Dans chaque cellule : nearest-neighbour local
//      (point de départ = dernier point du résultat → transition douce)
//
// Coordonnées : hexagones "pointy-top", origine = centre du canvas
// Complexité  : O(n + k·m²), k = nb cellules, m = points/cellule
// ============================================================

class DotsSort
{
  ArrayList<PVector> sorted = new ArrayList<PVector>();
  ArrayList<Integer> cell_starts  = new ArrayList<Integer>(); // index du 1er point de chaque cellule
  ArrayList<PVector> cell_centers = new ArrayList<PVector>(); // centre pixel de chaque cellule visitée
  boolean isComplete = true;
  int totalCalcMillis = 0;
  private float _hex_size = 100;

  // Directions axiales (pointy-top) pour le parcours en anneau
  final int[][] DIRS = {{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}};

  void start(ArrayList<PVector> points, float hex_size)
  {
    sorted.clear();
    cell_starts.clear();
    cell_centers.clear();
    _hex_size = hex_size;
    isComplete = false;
    long t0 = System.currentTimeMillis();

    // 1. Affecter chaque point à une cellule hexagonale
    HashMap<Long, ArrayList<PVector>> cells = new HashMap<Long, ArrayList<PVector>>();
    int max_ring = 0;

    for (PVector p : points)
    {
      int[] qr = pixelToHex(p.x, p.y, hex_size);
      long key = cellKey(qr[0], qr[1]);
      if (!cells.containsKey(key))
        cells.put(key, new ArrayList<PVector>());
      cells.get(key).add(p);
      int ring = hexRing(qr[0], qr[1]);
      if (ring > max_ring) max_ring = ring;
    }

    // 2. Parcourir les cellules en spirale (anneau 0, 1, 2, ...)
    visitCell(cells, 0, 0);
    for (int ring = 1; ring <= max_ring; ring++)
    {
      // Départ : (0, -ring), puis 6 côtés de `ring` pas chacun
      int q = 0, r = -ring;
      for (int side = 0; side < 6; side++)
      {
        for (int step = 0; step < ring; step++)
        {
          visitCell(cells, q, r);
          q += DIRS[side][0];
          r += DIRS[side][1];
        }
      }
    }

    totalCalcMillis = (int)(System.currentTimeMillis() - t0);
    isComplete = true;
  }

  // Parcourt une cellule en nearest-neighbour depuis le dernier point du résultat
  private void visitCell(HashMap<Long, ArrayList<PVector>> cells, int q, int r)
  {
    ArrayList<PVector> cell = cells.get(cellKey(q, r));
    if (cell == null || cell.isEmpty()) return;

    ArrayList<PVector> rem = new ArrayList<PVector>(cell);
    PVector last = sorted.isEmpty() ? rem.get(0) : sorted.get(sorted.size() - 1);

    cell_starts.add(sorted.size()); // enregistrer le début de cette cellule
    cell_centers.add(hexCenter(q, r, _hex_size)); // centre pixel

    while (!rem.isEmpty())
    {
      int best = 0;
      float best_d2 = Float.MAX_VALUE;
      for (int i = 0; i < rem.size(); i++)
      {
        PVector p = rem.get(i);
        float dx = p.x - last.x, dy = p.y - last.y;
        float d2 = dx*dx + dy*dy;
        if (d2 < best_d2) { best_d2 = d2; best = i; }
      }
      last = rem.get(best);
      sorted.add(last);
      // Suppression O(1) par swap-with-last
      rem.set(best, rem.get(rem.size() - 1));
      rem.remove(rem.size() - 1);
    }
  }

  // Centre pixel d'une cellule hexagonale (pointy-top)
  private PVector hexCenter(int q, int r, float size)
  {
    float x = size * (sqrt(3) * q + sqrt(3) / 2.0 * r);
    float y = size * (3.0 / 2.0 * r);
    return new PVector(x, y);
  }

  // Dessine un hexagone pointy-top centré en (cx, cy) de rayon size
  private void drawHexagon(float cx, float cy, float size)
  {
    current_graphics.beginShape();
    for (int i = 0; i < 6; i++)
    {
      float angle = radians(30 + 60 * i);
      current_graphics.vertex(cx + size * cos(angle), cy + size * sin(angle));
    }
    current_graphics.endShape(CLOSE);
  }

  // Coordonnées pixel → cellule hexagonale (axial, pointy-top, origine centrée)
  private int[] pixelToHex(float x, float y, float size)
  {
    float qf = (sqrt(3) / 3.0 * x - 1.0/3.0 * y) / size;
    float rf = (2.0/3.0 * y) / size;
    return hexRound(qf, rf);
  }

  // Arrondi fractional axial → entier (via cube coordinates)
  private int[] hexRound(float qf, float rf)
  {
    float sf = -qf - rf;
    int q = round(qf), r = round(rf), s = round(sf);
    float dq = abs(q - qf), dr = abs(r - rf), ds = abs(s - sf);
    if (dq > dr && dq > ds)
      q = -r - s;
    else if (dr > ds)
      r = -q - s;
    return new int[]{q, r};
  }

  // Distance hexagonale depuis l'origine (= numéro d'anneau)
  private int hexRing(int q, int r)
  {
    return (abs(q) + abs(q + r) + abs(r)) / 2;
  }

  // Clé longue unique pour (q, r), plage ±32767
  private long cellKey(int q, int r)
  {
    return ((long)(q + 32768) << 16) | (long)(r + 32768);
  }

  // Dégradé arc-en-ciel (t : 0 → 1)
  private color rainbow(float t)
  {
    float h = t * 6.0;
    int   i = (int) h;
    float f = h - i;
    float q = 1.0 - f;
    switch (i % 6)
    {
      case 0: return color(255,      f * 255, 0);
      case 1: return color(q * 255,  255,     0);
      case 2: return color(0,        255,     f * 255);
      case 3: return color(0,        q * 255, 255);
      case 4: return color(f * 255,  0,       255);
      default: return color(255,     0,       q * 255);
    }
  }

  // Dessin du chemin avec dégradé arc-en-ciel
  void drawPath()
  {
    int n = sorted.size();
    if (n < 2) return;
    current_graphics.noFill();
    for (int i = 0; i < n - 1; i++)
    {
      float t = (float) i / (n - 1);
      current_graphics.stroke(rainbow(t));
      PVector a = sorted.get(i);
      PVector b = sorted.get(i + 1);
      current_graphics.line(a.x, a.y, b.x, b.y);
    }
  }

  // Dessin des hexagones + lignes centre-à-centre dans l'ordre de la spirale
  void drawHexTransitions()
  {
    if (cell_centers.isEmpty()) return;
    current_graphics.noFill();
    int nc = cell_centers.size();

    // Hexagones (dégradé arc-en-ciel par anneau)
    for (int i = 0; i < nc; i++)
    {
      float t = (float) i / max(nc - 1, 1);
      current_graphics.stroke(rainbow(t));
      PVector c = cell_centers.get(i);
      drawHexagon(c.x, c.y, _hex_size);
    }

    // Lignes centre → centre
    current_graphics.stroke(255, 255, 0);
    for (int i = 0; i < nc - 1; i++)
    {
      PVector a = cell_centers.get(i);
      PVector b = cell_centers.get(i + 1);
      current_graphics.line(a.x, a.y, b.x, b.y);
    }
  }

  int progress() { return isComplete ? 100 : 0; }
}
