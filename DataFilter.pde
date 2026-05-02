class DataFilter extends GenericData
{
  DataFilter() {
    super("Filter");
  }

  boolean draw      = true;
  boolean black     = true;   // true = garder les zones sombres

  float threshold   = 128;
  float min_value   = 0;
  float max_value   = 255;
  float gamma       = 1.0;
}


class FilterGUI extends GUIPanel
{
  DataFilter filter;

  Toggle draw;
  Toggle black;
  Slider threshold;
  Slider min_value;
  Slider max_value;
  Slider gamma;

  FilterGUI(DataFilter filter)
  {
    super("Filter", filter);
    this.filter = filter;
  }

  void setupControls()
  {
    super.Init();

    draw      = addToggle("draw",      "Draw");
    black     = addToggle("black",     "Dark zones");
    nextLine();
    threshold = addSlider("threshold", "Threshold", 0, 255);
    nextLine();
    min_value = addSlider("min_value", "Min Value", 0, 255);
    nextLine();
    max_value = addSlider("max_value", "Max Value", 0, 255);
    nextLine();
    gamma     = addSlider("gamma",     "Gamma",     0.1, 4.0);
  }

  void setGUIValues()
  {
    draw.setValue(filter.draw);
    black.setValue(filter.black);
    threshold.setValue(filter.threshold);
    min_value.setValue(filter.min_value);
    max_value.setValue(filter.max_value);
    gamma.setValue(filter.gamma);
  }

  void update_ui() {}
}
