class DataDots extends GenericData
{
  DataDots() {
    super("Dots");
  }

  float surfaceWidth  = 800;
  float surfaceHeight = 600;
  float minDist       = 12;   // distance minimale entre points (contrôle la densité)
  int   maxCandidates = 30;   // paramètre k de Bridson
  boolean draw        = true;
}


class DotsGUI extends GUIPanel
{
  DataDots dots;

  Slider surfaceWidth;
  Slider surfaceHeight;
  Slider minDist;
  Slider maxCandidates;

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
  }

  void setGUIValues()
  {
    surfaceWidth.setValue(dots.surfaceWidth);
    surfaceHeight.setValue(dots.surfaceHeight);
    minDist.setValue(dots.minDist);
    maxCandidates.setValue(dots.maxCandidates);
  }

  void update_ui() {}
}
