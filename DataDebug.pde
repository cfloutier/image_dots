import controlP5.*;

// Onglet Debug : outils de diagnostic pour observer la propagation de
// DotsGenerator sans changer le resultat final (le meme nuage de points est
// genere, seule la vitesse a laquelle on le regarde naitre change).
class DataDebug extends GenericData
{
  DataDebug()
  {
    super("Debug");
  }

  boolean paused          = false; // suspend la propagation (resume() n'est plus appele)
  boolean slow_mode       = false; // limite resume() a "steps_per_frame" tentatives par frame
  int     steps_per_frame = 10;    // nb de tentatives de propagation par frame quand slow_mode est actif
  boolean show_active     = false; // dessine les points actifs pendant la generation
  ColorRef active_color   = new ColorRef(color(255, 0, 0), "active_color");

  void LoadJson(JSONObject src)
  {
    super.LoadJson(src);
    if (src == null) return;
    active_color.LoadJson(src);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = super.SaveJson();
    active_color.SaveJson(dest);
    return dest;
  }
}

class DebugGUI extends GUIPanel
{
  DataDebug debug;

  Toggle paused;
  Toggle slow_mode;
  Slider steps_per_frame;
  Toggle show_active;
  ColorGroup active_color;
  Button newSeedButton;
  Button clearButton;

  DebugGUI(DataDebug debug)
  {
    super("Debug", debug);
    this.debug = debug;
  }

  void setupControls()
  {
    super.Init();

    paused = addToggle("paused", "Pause", debug);
    nextLine();
    slow_mode = addToggle("slow_mode", "Slow Mode", debug);
    nextLine();
    steps_per_frame = addIntSlider("steps_per_frame", "Steps / Frame", debug, 1, 2000);
    nextLine();
    show_active = addToggle("show_active", "Show Active", debug);
    nextLine();
    active_color = addColorGroup("Active Color", debug.active_color);
    newSeedButton = addButton("New Seed");
    clearButton = addButton("Clear");
  }

  void setGUIValues()
  {
    paused.setValue(debug.paused);
    slow_mode.setValue(debug.slow_mode);
    steps_per_frame.setValue(debug.steps_per_frame);
    show_active.setValue(debug.show_active);
    active_color.colorRef = debug.active_color;
  }

  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController())
    {
      Controller c = theEvent.getController();
      if (c == newSeedButton)
      {
        data.dots.seed = (int)random(100000);
        data.dots.changed = true;
        data.changed = true;
        return;
      }
      if (c == clearButton)
      {
        generator.clear();
        _sort_dirty = true;
        return;
      }
    }
    super.controlEvent(theEvent);
  }
}
