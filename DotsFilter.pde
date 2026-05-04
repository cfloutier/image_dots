// Filtre les points blue noise selon la valeur pixel de l'image
// Pipeline : valeur brute → restriction [min,max] → normalisation → gamma → probabilité

class DotsFilter
{
  ArrayList<PVector> points = new ArrayList<PVector>();
  DataFilter data_filter;

  DotsFilter(DataFilter filter)
  {
    this.data_filter = filter;
  }

  void buildPoints(ArrayList<PVector> source_points, DataImage image, int seed)
  {
    points.clear();

    float range = data_filter.max_value - data_filter.min_value;
    if (range <= 0) return;

    randomSeed(seed);

    for (PVector p : source_points)
    {
      float value = image.getPixelValue(p);

      // hors image
      if (value == -1) continue;

      // clamp dans la plage d'intérêt
      value = constrain(value, data_filter.min_value, data_filter.max_value);

      // normalisation dans [0, 1]
      float normalized = (value - data_filter.min_value) / range;

      // gamma
      normalized = pow(normalized, data_filter.gamma);

      // probabilité : zones sombres = prob haute, zones claires = prob basse
      float prob = data_filter.black ? (1.0 - normalized) : normalized;

      // threshold comme densité globale [0..255] → [0..1]
      prob *= data_filter.threshold / 255.0;

      if (random(1.0) < prob)
        points.add(p);
    }

    println("DotsFilter: " + points.size() + " / " + source_points.size() + " points kept");
  }

  void draw()
  {
    for (PVector p : points) {
      current_graphics.point(p.x, p.y);
    }
  }

  void drawWithShape(DataShape shape)
  {
    drawWithShape(shape, false);
  }

  void drawWithShape(DataShape shape, boolean verbose)
  {
    int total = points.size();
    int log_step = max(1, total / 20); // tous les 5%

    if (verbose)
      println("Export: dessin de " + StringUtils.formatInt(total) + " points...");

    if (shape.mode == DataShape.MODE_POINT)
    {
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
      // polygone centré sur chaque point
      current_graphics.noFill();
      float r = shape.size / 2.0;
      int   n = shape.sides;

      for (int i = 0; i < total; i++)
      {
        if (verbose && i % log_step == 0)
          println("  " + (i * 100 / total) + "%  (" + StringUtils.formatInt(i) + " / " + StringUtils.formatInt(total) + ")");
        PVector p = points.get(i);
        current_graphics.beginShape();
        for (int j = 0; j <= n; j++)
        {
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
