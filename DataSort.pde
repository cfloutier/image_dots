class DataSort extends GenericData
{
  DataSort() { super("Sort"); }

  float hex_size = 10.0;
}


class SortGUI extends GUIPanel
{
  DataSort sort;
  boolean draw_path = false;
  boolean draw_hex_transitions = false;

  Toggle draw_path_toggle;
  Toggle draw_hex_transitions_toggle;
  Slider hex_size;

  SortGUI(DataSort sort)
  {
    super("Sort", sort);
    this.sort = sort;
  }

  void setupControls()
  {
    super.Init();

    draw_path_toggle = addToggle("sort_draw_path", "Draw path");
    nextLine();
    draw_hex_transitions_toggle = addToggle("sort_draw_hex_transitions", "Draw hex transitions");
    nextLine();
    hex_size = addSlider("hex_size", "Hex Size", 5, 100);
  }

  void setGUIValues()
  {
    draw_path_toggle.setValue(draw_path ? 1 : 0);
    draw_hex_transitions_toggle.setValue(draw_hex_transitions ? 1 : 0);
    hex_size.setValue(sort.hex_size);
  }

  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController())
    {
      Controller c = theEvent.getController();

      if (c == draw_path_toggle)
      {
        draw_path = draw_path_toggle.getValue() > 0.5;
        return;
      }

      if (c == draw_hex_transitions_toggle)
      {
        draw_hex_transitions = draw_hex_transitions_toggle.getValue() > 0.5;
        return;
      }
    }
    super.controlEvent(theEvent);
  }
}
