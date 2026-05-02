// Filtre les points blue noise selon la valeur pixel de l'image
// Pipeline : valeur brute → restriction [min,max] → normalisation → gamma → seuil

class DotsFilter
{
  ArrayList<PVector> points = new ArrayList<PVector>();
  DataFilter data_filter;

  DotsFilter(DataFilter filter)
  {
    this.data_filter = filter;
  }

  void buildPoints(ArrayList<PVector> source_points, DataImage image)
  {
    points.clear();

    float range = data_filter.max_value - data_filter.min_value;
    if (range <= 0) return;

    for (PVector p : source_points)
    {
      float value = image.getPixelValue(p);

      // hors image
      if (value == -1) continue;

      // hors plage d'intérêt
      if (value < data_filter.min_value || value > data_filter.max_value) continue;

      // normalisation dans [0, 1]
      float normalized = (value - data_filter.min_value) / range;

      // gamma
      normalized = pow(normalized, data_filter.gamma);

      // retour en [0, 255]
      float remapped = normalized * 255;

      // seuil
      if (data_filter.black)
      {
        if (remapped < data_filter.threshold)
          points.add(p);
      } else
      {
        if (remapped > data_filter.threshold)
          points.add(p);
      }
    }

    println("DotsFilter: " + points.size() + " / " + source_points.size() + " points kept");
  }

  void draw()
  {
    for (PVector p : points) {
      current_graphics.point(p.x, p.y);
    }
  }
}
