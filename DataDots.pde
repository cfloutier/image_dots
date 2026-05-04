class DataDots extends GenericData
{
  DataDots() {
    super("Dots");
  }

  float minDist       = 12;
  int   maxCandidates = 30;
  int   seed          = 42;
}


class DotsGUI extends GUIPanel
{
  DataDots dots;
  boolean draw = false;

  Toggle draw_toggle;
  Slider minDist;
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
    minDist       = addSlider("minDist",       "Min Distance",   0.1, 10);
    nextLine();
    maxCandidates = addSlider("maxCandidates", "Max Candidates", 1, 60);
    nextLine();
    seedLabel     = inlineLabel("Seed: " + dots.seed, 160);
    newSeedButton = addButton("New Seed");
  }

  void setGUIValues()
  {
    draw_toggle.setValue(draw);
    minDist.setValue(dots.minDist);
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
