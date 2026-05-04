class DataShape extends GenericData
{
  DataShape() {
    super("Shape");
  }

  static final int MODE_POINT   = 0;
  static final int MODE_POLYGON = 1;

  int   mode  = MODE_POINT;
  int   sides = 6;
  float size  = 3.0;
}


class ShapeGUI extends GUIPanel
{
  DataShape shape;
  boolean draw = true;

  Toggle     draw_toggle;
  myRadioButton mode_radio;
  Slider     sides;
  Slider     size;

  ShapeGUI(DataShape shape)
  {
    super("Shape", shape);
    this.shape = shape;
  }

  void setupControls()
  {
    super.Init();

    draw_toggle = addToggle("draw_shape", "Draw");
    nextLine();

    ArrayList<String> modes = new ArrayList<String>();
    modes.add("Point");
    modes.add("Polygon");
    mode_radio = addRadio("mode", modes);
    nextLine();

    sides = addSlider("sides", "Sides", 3, 12);
    nextLine();
    size  = addSlider("size",  "Size",  0.1, 5);
  }

  void setGUIValues()
  {
    draw_toggle.setValue(draw);
    mode_radio.setValue(shape.mode);
    sides.setValue(shape.sides);
    size.setValue(shape.size);
  }

  void update_ui()
  {
    if (sides == null || size == null) return;
    boolean is_polygon = shape.mode == DataShape.MODE_POLYGON;
    if (is_polygon) { sides.show(); size.show(); }
    else            { sides.hide(); size.hide(); }
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
    }
    super.controlEvent(theEvent);
    update_ui();
  }
}
