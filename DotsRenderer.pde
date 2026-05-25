// Rendu final des points selon DataShape.
// Recoit une liste de PVector et dessine chaque point
// en mode "point" ou "polygone regulier" selon les parametres.

class DotsRenderer
{
  void draw(ArrayList<PVector> points, DataShape shape)
  {
    draw(points, shape, false);
  }

  void draw(ArrayList<PVector> points, DataShape shape, boolean verbose)
  {
    int total    = points.size();
    int log_step = max(1, total / 10); // log tous les 10%

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
      // Polygone regulier centre sur chaque point.
      // -PI/2 : premier sommet vers le haut (12h).
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
      println("Export dots: done. Saving in progress... Please wait");
  }

  // Build a ShapesGroup from the given points for direct SVG export.
  // MODE_POINT  → Dot entries (zero-length line in SVG, same stroke-width as polylines)
  // MODE_POLYGON → Polyline entries (closed regular polygon)
  void buildShapesGroup(ArrayList<PVector> points, DataShape shape, ShapesGroup group)
  {
    group.clear();
    float r = shape.size / 2.0;
    int   n = shape.sides;

    if (shape.mode == DataShape.MODE_POINT)
    {
      for (PVector p : points)
        group.addDot(p);
    }
    else
    {
      for (PVector p : points)
      {
        Polyline pl = new Polyline();
        for (int j = 0; j <= n; j++)
        {
          float angle = TWO_PI * j / n - PI / 2;
          pl.addPoint(new PVector(p.x + cos(angle) * r, p.y + sin(angle) * r));
        }
        group.addPolyline(pl);
      }
    }
  }
}
