// Générateur de points en blue noise (Poisson Disk Sampling, Bridson 2007)
// Les points sont générés dans un rectangle centré sur l'origine
// (l'origine correspond au centre écran via start_draw)
// Support génération progressive : start() puis resume() à chaque frame

class DotsGenerator
{
  ArrayList<PVector> points = new ArrayList<PVector>();
  boolean isComplete = true;
  int     lastResumeMillis = 0;
  float   progressRatio   = 0;  // 0..1, basé sur points générés vs estimation

  private int _estimatedMax = 1;

  // état interne persistant entre frames
  private ArrayList<PVector> _active;
  private int[]   _grid;
  private int     _cols;
  private float   _cell;
  private float   _ox, _oy;
  private float   _w, _h;
  private float   _r;
  private int     _maxCandidates;

  static final int MAX_MILLIS = 500;

  void start(DataDots data, float w, float h)
  {
    points.clear();
    isComplete       = false;
    lastResumeMillis = 0;
    progressRatio    = 0;
    // estimation : ~0.7 points par cellule de grille
    _estimatedMax    = max(1, (int)(0.7 * ceil(w / (data.minDist / sqrt(2))) * ceil(h / (data.minDist / sqrt(2)))));
    println("DotsGenerator estimated max points: " + _estimatedMax);

    println("DotsGenerator.start() minDist=" + data.minDist + " maxCandidates=" + data.maxCandidates + " seed=" + data.seed);

    randomSeed(data.seed);

    _r             = data.minDist;
    _maxCandidates = data.maxCandidates;
    _cell          = _r / sqrt(2);
    _w             = w;
    _h             = h;
    _ox            = w / 2;
    _oy            = h / 2;

    _cols = ceil(w / _cell);
    int rows = ceil(h / _cell);

    _grid = new int[_cols * rows];
    java.util.Arrays.fill(_grid, -1);

    _active = new ArrayList<PVector>();

    PVector first = new PVector(random(-w/2, w/2), random(-h/2, h/2));
    _addPoint(first);
    _active.add(first);
  }

  // retourne true si la génération est terminée
  boolean resume()
  {
    if (isComplete) return true;

    long t0       = System.currentTimeMillis();
    long deadline = t0 + MAX_MILLIS;

    while (_active.size() > 0)
    {
      if (System.currentTimeMillis() >= deadline)
      {
        lastResumeMillis = (int)(System.currentTimeMillis() - t0);
        progressRatio = min(1.0, (float)points.size() / _estimatedMax);
        return false;
      }

      int idx = (int)random(_active.size());
      PVector p = _active.get(idx);

      boolean found = false;

      for (int n = 0; n < _maxCandidates; n++)
      {
        float angle = random(TWO_PI);
        float d     = random(_r, 2 * _r);
        PVector candidate = new PVector(p.x + cos(angle) * d,
                                        p.y + sin(angle) * d);

        if (candidate.x < -_w/2 || candidate.x > _w/2 ||
            candidate.y < -_h/2 || candidate.y > _h/2) continue;

        int cgx = (int)((candidate.x + _ox) / _cell);
        int cgy = (int)((candidate.y + _oy) / _cell);

        boolean ok = true;
        for (int dy = -2; dy <= 2 && ok; dy++) {
          for (int dx = -2; dx <= 2 && ok; dx++) {
            int nx = cgx + dx;
            int ny = cgy + dy;
            if (nx < 0 || nx >= _cols || ny < 0 || ny >= (_grid.length / _cols)) continue;
            int pidx = _grid[nx + ny * _cols];
            if (pidx == -1) continue;
            PVector neighbor = points.get(pidx);
            if (dist(candidate.x, candidate.y, neighbor.x, neighbor.y) < _r) {
              ok = false;
            }
          }
        }

        if (ok) {
          _addPoint(candidate);
          _active.add(candidate);
          found = true;
          break;
        }
      }

      if (!found)
        _active.remove(idx);
    }

    isComplete       = true;
    lastResumeMillis = (int)(System.currentTimeMillis() - t0);
    progressRatio    = 1.0;
    println("DotsGenerator: " + points.size() + " points generated");
    return true;
  }

  void draw()
  {
    for (PVector p : points) {
      current_graphics.point(p.x, p.y);
    }
  }

  // --- privé ---

  private void _addPoint(PVector p)
  {
    points.add(p);
    int gx = (int)((p.x + _ox) / _cell);
    int gy = (int)((p.y + _oy) / _cell);
    _grid[gx + gy * _cols] = points.size() - 1;
  }
}
