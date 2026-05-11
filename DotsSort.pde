// ============================================================
// DotsSort — Tri des points par l'algorithme du plus proche voisin
//            (heuristique TSP nearest-neighbour)
//
// Exécution incrémentale : MAX_MILLIS ms maximum par frame pour
// ne pas bloquer le rendu pendant le calcul.
//
// Complexité : O(n²) — acceptable jusqu'à ~100 000 points.
// ============================================================

class DotsSort
{
  ArrayList<PVector> sorted = new ArrayList<PVector>();
  boolean isComplete = true;
  int     totalCalcMillis = 0;

  private ArrayList<PVector> _remaining;
  private long _startMillis;

  static final int MAX_MILLIS = 100;

  void start(ArrayList<PVector> points)
  {
    sorted.clear();
    isComplete      = false;
    totalCalcMillis = 0;
    _startMillis    = System.currentTimeMillis();
    _remaining      = new ArrayList<PVector>(points); // copie superficielle
  }

  void resume()
  {
    long t0 = System.currentTimeMillis();

    while (!_remaining.isEmpty() && System.currentTimeMillis() - t0 < MAX_MILLIS)
    {
      PVector last = sorted.isEmpty()
        ? _remaining.get(0)
        : sorted.get(sorted.size() - 1);

      int   best_idx  = 0;
      float best_dist = Float.MAX_VALUE;

      for (int i = 0; i < _remaining.size(); i++)
      {
        PVector p  = _remaining.get(i);
        float   dx = p.x - last.x;
        float   dy = p.y - last.y;
        float   d  = dx*dx + dy*dy; // pas besoin de sqrt pour comparer
        if (d < best_dist)
        {
          best_dist = d;
          best_idx  = i;
        }
      }

      // Suppression O(1) : swap avec le dernier élément
      int last_idx = _remaining.size() - 1;
      PVector best = _remaining.get(best_idx);
      _remaining.set(best_idx, _remaining.get(last_idx));
      _remaining.remove(last_idx);
      sorted.add(best);
    }

    if (_remaining.isEmpty())
    {
      isComplete      = true;
      totalCalcMillis = (int)(System.currentTimeMillis() - _startMillis);
    }
  }

  // Dessine le chemin de tracé avec un dégradé rouge → bleu
  void drawPath()
  {
    int n = sorted.size();
    if (n < 2) return;
    current_graphics.noFill();
    for (int i = 0; i < n - 1; i++)
    {
      float t = (float) i / (n - 1);
      current_graphics.stroke(lerpColor(color(255, 0, 0), color(0, 0, 255), t));
      PVector a = sorted.get(i);
      PVector b = sorted.get(i + 1);
      current_graphics.line(a.x, a.y, b.x, b.y);
    }
  }

  int progress()
  {
    if (isComplete) return 100;
    if (sorted.isEmpty() && (_remaining == null || _remaining.isEmpty())) return 0;
    int total = sorted.size() + (_remaining != null ? _remaining.size() : 0);
    if (total == 0) return 0;
    return sorted.size() * 100 / total;
  }
}
