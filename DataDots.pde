class DataDots extends GenericData
{
  DataDots() {
    super("Dots");
  }

  // Direction B : density = densite de base (zones sombres)
  // valeur haute = plus de points. r_min interne = 1 / density
  float density       = 0.5;
  float contrast      = 10;   // ratio r_max / r_min
  float gamma         = 1.0;  // courbe de densite : > 1 = moins de pts en demi-teintes
  // seuils : les pixels hors [min_value, max_value] sont ramenes aux extremes
  float min_value     = 0;    // pixels en dessous : traites comme noir (dense)
  float max_value     = 255;  // pixels au dessus  : traites comme blanc (vide)
  boolean invert      = false; // inverser : zones claires = denses

  int   seed          = 42;
}


class DotsGUI extends GUIPanel
{
  DataDots dots;
  boolean draw = false;

  Toggle draw_toggle;
  Toggle invert_toggle;
  Slider density;
  Slider contrast;
  Slider gamma;
  Slider min_value;
  Slider max_value;
  Textlabel seedLabel;
  Button newSeedButton;

  DotsGUI(DataDots dots)
  {
    super("Dots", dots);
    this.dots = dots;
  }

  void setupControls()
  {
    super.Init();

    draw_toggle   = addToggle("draw_dots", "Draw");
    invert_toggle = addToggle("invert",    "Invert");
    nextLine();
    density       = addSlider("density",  "Density",      0.1, 2.0);
    nextLine();
    contrast      = addSlider("contrast",  "Contrast",     1.0, 30);
    nextLine();
    gamma         = addSlider("gamma",     "Gamma",        0.3, 4.0);
    nextLine();
    min_value     = addSlider("min_value", "Min Value",    0, 255);
    nextLine();
    max_value     = addSlider("max_value", "Max Value",    0, 255);
    nextLine();
    seedLabel     = inlineLabel("Seed: " + dots.seed, 160);
    newSeedButton = addButton("New Seed");
  }

  void setGUIValues()
  {
    draw_toggle.setValue(draw);
    invert_toggle.setValue(dots.invert);
    density.setValue(dots.density);
    contrast.setValue(dots.contrast);
    gamma.setValue(dots.gamma);
    min_value.setValue(dots.min_value);
    max_value.setValue(dots.max_value);
    seedLabel.setText("Seed: " + dots.seed);
  }

  void update_ui()
  {
    seedLabel.setText("Seed: " + dots.seed);
  }

  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController())
    {
      Controller c = theEvent.getController();
      if (c == draw_toggle)
      {
        draw = draw_toggle.getValue() > 0.5;
        return;
      }
      if (c == newSeedButton)
      {
        dots.seed = (int)random(100000);
        dots.changed = true;
        data.changed = true;
        update_ui();
        return;
      }
    }
    super.controlEvent(theEvent);
  }
}
