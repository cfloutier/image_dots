class DataDots extends GenericData
{
  DataDots() {
    super("Dots");
  }

  // Direction B : deux rayons encadrant la densité
  // r_min → zones sombres (points rapprochés)
  // r_max → zones claires (points espacés)
  float r_min         = 2;
  float r_max         = 20;

  int   maxCandidates = 30;
  int   seed          = 42;
}


class DotsGUI extends GUIPanel
{
  DataDots dots;
  boolean draw = false;

  Toggle draw_toggle;
  Slider r_min;
  Slider r_max;
  Slider maxCandidates;
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
    nextLine();
    r_min         = addSlider("r_min",         "r min (dark)",   0.1, 5);
    nextLine();
    r_max         = addSlider("r_max",         "r max (light)",  0.1, 15);
    nextLine();
    maxCandidates = addSlider("maxCandidates", "Max Candidates", 1, 60);
    nextLine();
    seedLabel     = inlineLabel("Seed: " + dots.seed, 160);
    newSeedButton = addButton("New Seed");
  }

  void setGUIValues()
  {
    draw_toggle.setValue(draw);
    r_min.setValue(dots.r_min);
    r_max.setValue(dots.r_max);
    maxCandidates.setValue(dots.maxCandidates);
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
