// ============================================================
// DotsGenerator — Poisson Disk Sampling à densité variable (Direction B)
//
// DIFFÉRENCE AVEC LA VERSION UNIFORME :
//   Au lieu d'une distance minimale fixe r, on calcule un r_local pour
//   chaque candidat à partir de la valeur du pixel sous sa position :
//
//     r_local = r_min + (r_max - r_min) × pow(pixel/255, gamma)
//
//   gamma = 1  → reponse lineaire (defaut)
//   gamma < 1  → demi-teintes plus denses (proches du sombre)
//   gamma > 1  → demi-teintes plus espacees (proches du clair)
//
//   r_max = r_min × contrast
//
// GRILLE SPATIALE :
//   On utilise r_min/√2 comme taille de cellule (le plus petit r possible).
//   Cela garantit qu'une cellule contient au plus 1 point.
//   Le voisinage à inspecter est plus large que dans la version uniforme :
//   on regarde jusqu'à ceil(r_max / cell) cellules dans chaque direction.
//
// ANNEAU DE GÉNÉRATION :
//   Les candidats sont tirés dans l'anneau [r_min, 2×r_max] autour du
//   point actif, puis validés avec leur r_local propre.
// ============================================================

class DotsGenerator
{
  ArrayList<PVector> points = new ArrayList<PVector>();
  boolean isComplete = true;
  int     lastResumeMillis = 0;
  float   progressRatio    = 0;

  private int _estimatedMax = 1;
  private ArrayList<PVector> _active;
  private int[]   _grid;
  private int     _cols;
  private float   _cell;       // = r_min / sqrt(2)
  private float   _ox, _oy;
  private float   _w, _h;
  private float   _r_min;
  private float   _r_max;
  private float   _gamma;
  private float   _min_value;  // seuil bas : pixels en dessous = noir
  private float   _max_value;  // seuil haut : pixels au dessus  = blanc
  private int     _lookRadius; // nb de cellules a inspecter = ceil(r_max / cell)

  static final int CANDIDATES = 7; // valeur empirique : bon rapport qualite/perf

  // Reference a l'image pour lire les pixels pendant la generation
  private DataImage _image;

  static final int MAX_MILLIS = 500;

  void start(DataDots data, DataImage image, float w, float h)
  {
    points.clear();
    isComplete       = false;
    lastResumeMillis = 0;
    progressRatio    = 0;

    _image         = image;
    _r_min         = data.r_min;
    _r_max         = max(data.r_min * data.contrast, data.r_min);
    _gamma         = data.gamma;
    _min_value     = data.min_value;
    _max_value     = max(data.max_value, data.min_value + 1);

    _cell = _r_min / sqrt(2);
    _w    = w;
    _h    = h;
    _ox   = w / 2;
    _oy   = h / 2;

    _lookRadius = ceil(_r_max / _cell) + 1;
    _cols       = ceil(w / _cell);
    int rows    = ceil(h / _cell);

    _grid = new int[_cols * rows];
    java.util.Arrays.fill(_grid, -1);

    _active       = new ArrayList<PVector>();
    _estimatedMax = max(1, (int)(0.7 * ceil(w / _cell) * ceil(h / _cell)));

    randomSeed(data.seed);

    println("DotsGenerator.start() r_min=" + _r_min + " r_max=" + _r_max +
            " contrast=" + data.contrast + " gamma=" + _gamma +
            " lookRadius=" + _lookRadius +
            " seed=" + data.seed);

    PVector first = new PVector(random(-w/2, w/2), random(-h/2, h/2));
    _addPoint(first);
    _active.add(first);
  }

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
        progressRatio    = min(1.0, (float)points.size() / _estimatedMax);
        return false;
      }

      int idx   = (int)random(_active.size());
      PVector p = _active.get(idx);
      boolean found = false;

      for (int n = 0; n < CANDIDATES; n++)
      {
        float angle = random(TWO_PI);
        float d     = random(_r_min, 2 * _r_max);

        PVector candidate = new PVector(p.x + cos(angle) * d,
                                        p.y + sin(angle) * d);

        if (candidate.x < -_w/2 || candidate.x > _w/2 ||
            candidate.y < -_h/2 || candidate.y > _h/2) continue;

        float r_local = _getRLocal(candidate);
        if (r_local < 0) continue; // hors image

        int cgx = (int)((candidate.x + _ox) / _cell);
        int cgy = (int)((candidate.y + _oy) / _cell);

        boolean ok = true;
        float   r2 = r_local * r_local;

        for (int dy = -_lookRadius; dy <= _lookRadius && ok; dy++) {
          for (int dx = -_lookRadius; dx <= _lookRadius && ok; dx++) {
            int nx = cgx + dx;
            int ny = cgy + dy;
            if (nx < 0 || nx >= _cols || ny < 0 || ny >= (_grid.length / _cols)) continue;
            int pidx = _grid[nx + ny * _cols];
            if (pidx == -1) continue;
            PVector neighbor = points.get(pidx);
            float ddx = candidate.x - neighbor.x;
            float ddy = candidate.y - neighbor.y;
            if (ddx*ddx + ddy*ddy < r2) ok = false;
          }
        }

        if (ok) {
          _addPoint(candidate);
          _active.add(candidate);
          found = true;
          break;
        }
      }

      if (!found) _active.remove(idx);
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

  // Mapping densite-lineaire :
  //   density = (1 - t)^gamma   (1 = zone noire dense, 0 = zone blanche vide)
  //   r_local = r_min / sqrt(density), capé à r_max
  //
  // Contrairement au mapping lineaire en r, celui-ci est perceptuellement
  // uniforme : un meme ecart de luminosite donne un meme ecart de densite
  // apparente. Les zones blanches (density -> 0) tendent naturellement vers
  // r_max -> aucun point place, sans coupure brutale.
  //
  // gamma > 1 : accentue le contraste (moins de pts dans les demi-teintes)
  // gamma < 1 : aplanie le contraste (plus de pts dans les demi-teintes)
  //
  // Retourne -1 si le pixel est hors image.
  private float _getRLocal(PVector p)
  {
    float pixel = _image.getPixelValue(p);
    if (pixel == -1 || _image.blurred_image == null)
      return -1;
    // applique les seuils et normalise dans [0, 1]
    float t_clamped = constrain(pixel, _min_value, _max_value);
    float t_norm    = (t_clamped - _min_value) / (_max_value - _min_value);
    float density = pow(1.0 - t_norm, _gamma);
    // cap inferieur de densite = 1/contrast^2 <-> r_local = r_max
    float min_density = 1.0 / ((_r_max / _r_min) * (_r_max / _r_min));
    return _r_min / sqrt(max(density, min_density));
  }

  private void _addPoint(PVector p)
  {
    points.add(p);
    int gx = constrain((int)((p.x + _ox) / _cell), 0, _cols - 1);
    int gy = constrain((int)((p.y + _oy) / _cell), 0, (_grid.length / _cols) - 1);
    _grid[gx + gy * _cols] = points.size() - 1;
  }
}
