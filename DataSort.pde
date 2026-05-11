class DataSort extends GenericData
{
  DataSort() { super("Sort"); }

  boolean enabled = false;
}


class SortGUI extends GUIPanel
{
  DataSort sort;
  boolean draw_path = false;

  Toggle enabled_toggle;
  Toggle draw_path_toggle;

  SortGUI(DataSort sort)
  {
    super("Sort", sort);
    this.sort = sort;
  }

  void setupControls()
  {
    super.Init();

    enabled_toggle   = addToggle("sort_enabled",   "Sort (nearest neighbour)");
    nextLine();
    draw_path_toggle = addToggle("sort_draw_path", "Draw path");
  }

  void setGUIValues()
  {
    enabled_toggle.setValue(sort.enabled ? 1 : 0);
    draw_path_toggle.setValue(draw_path ? 1 : 0);
  }

  public void controlEvent(ControlEvent theEvent)
  {
    if (theEvent.isController())
    {
      Controller c = theEvent.getController();

      if (c == enabled_toggle)
      {
        sort.enabled = enabled_toggle.getValue() > 0.5;
        sort.changed = true;
        data.changed = true;
        return;
      }

      if (c == draw_path_toggle)
      {
        draw_path = draw_path_toggle.getValue() > 0.5;
        return;
      }
    }
    super.controlEvent(theEvent);
  }
}
