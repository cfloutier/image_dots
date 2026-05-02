class DataDots extends GenericData
{
  DataDots() {
    super("Dots");
  }

  float surfaceWidth  = 800;
  float surfaceHeight = 600;
  float minDist       = 12;   // distance minimale entre points (contrôle la densité)
  int   maxCandidates = 30;   // paramètre k de Bridson
  int   seed          = 42;
  boolean draw        = true;
}


class DotsGUI extends GUIPanel
{
  DataDots dots;

  Slider surfaceWidth;
  Slider surfaceHeight;
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

    surfaceWidth  = addSlider("surfaceWidth",  "Surface Width",  100, 2000);
    nextLine();
    surfaceHeight = addSlider("surfaceHeight", "Surface Height", 100, 2000);
    nextLine();
    minDist       = addSlider("minDist",       "Min Distance",   2, 80);
    nextLine();
    maxCandidates = addSlider("maxCandidates", "Max Candidates", 1, 60);
    nextLine();
    seedLabel     = inlineLabel("Seed: " + dots.seed, 160);
    newSeedButton = addButton("New Seed");
  }

  void setGUIValues()
  {
    surfaceWidth.setValue(dots.surfaceWidth);
    surfaceHeight.setValue(dots.surfaceHeight);
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
