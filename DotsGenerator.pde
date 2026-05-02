// Générateur de points en blue noise (Poisson Disk Sampling, Bridson 2007)
// Les points sont générés dans un rectangle centré sur l'origine
// (l'origine correspond au centre écran via start_draw)

class DotsGenerator
{
  ArrayList<PVector> points = new ArrayList<PVector>();

  void generate(DataDots data)
  {
    points.clear();

    float r    = data.minDist;
    float cell = r / sqrt(2);

    float w  = data.surfaceWidth;
    float h  = data.surfaceHeight;
    float ox = w / 2;   // offset pour passer en coordonnées positives
    float oy = h / 2;

    int cols = ceil(w / cell);
    int rows = ceil(h / cell);

    // grille de fond : stocke l'index du point ou -1 si vide
    int[] grid = new int[cols * rows];
    java.util.Arrays.fill(grid, -1);

    ArrayList<PVector> active = new ArrayList<PVector>();

    // premier point aléatoire dans la surface
    PVector first = new PVector(random(-w/2, w/2), random(-h/2, h/2));
    _addPoint(first, grid, cols, cell, ox, oy);
    active.add(first);

    while (active.size() > 0)
    {
      int idx = (int)random(active.size());
      PVector p = active.get(idx);

      boolean found = false;

      for (int n = 0; n < data.maxCandidates; n++)
      {
        float angle = random(TWO_PI);
        float d     = random(r, 2 * r);
        PVector candidate = new PVector(p.x + cos(angle) * d,
                                        p.y + sin(angle) * d);

        // hors surface
        if (candidate.x < -w/2 || candidate.x > w/2 ||
            candidate.y < -h/2 || candidate.y > h/2) continue;

        // vérification dans la grille (voisins à ±2 cellules)
        int cgx = (int)((candidate.x + ox) / cell);
        int cgy = (int)((candidate.y + oy) / cell);

        boolean ok = true;
        for (int dy = -2; dy <= 2 && ok; dy++) {
          for (int dx = -2; dx <= 2 && ok; dx++) {
            int nx = cgx + dx;
            int ny = cgy + dy;
            if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) continue;
            int pidx = grid[nx + ny * cols];
            if (pidx == -1) continue;
            PVector neighbor = points.get(pidx);
            if (dist(candidate.x, candidate.y, neighbor.x, neighbor.y) < r) {
              ok = false;
            }
          }
        }

        if (ok) {
          _addPoint(candidate, grid, cols, cell, ox, oy);
          active.add(candidate);
          found = true;
          break;
        }
      }

      if (!found)
        active.remove(idx);
    }

    println("DotsGenerator: " + points.size() + " points generated");
  }

  void draw()
  {
    for (PVector p : points) {
      current_graphics.point(p.x, p.y);
    }
  }

  // --- privé ---

  private void _addPoint(PVector p, int[] grid, int cols, float cell, float ox, float oy)
  {
    points.add(p);
    int gx = (int)((p.x + ox) / cell);
    int gy = (int)((p.y + oy) / cell);
    grid[gx + gy * cols] = points.size() - 1;
  }
}
