import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

ImageDotsData data;
DataGUI dataGui;
DotsGenerator generator;
DotsRenderer renderer;
DotsSort sorter;
boolean _sort_dirty = false;
PGraphics current_graphics;
ControlP5 cp5;

void setup()
{
  size(1200, 800);
  surface.setResizable(true);

  data = new ImageDotsData();
  dataGui = new DataGUI(data);
  generator = new DotsGenerator();
  renderer = new DotsRenderer();
  sorter = new DotsSort();

  setupControls();

  data.LoadSettings("./Settings/default.json");
  dataGui.setGUIValues();
}

void setupControls()
{
  cp5 = new ControlP5(this);
  cp5.getTab("default").setLabel("Hide GUI");
  dataGui.Init();
}

void draw()
{
  start_draw();

  data.image.buildBlurredImage();
  data.image.draw(dataGui.images_ui.imageAlpha);

  boolean image_changed  = data.image.changed;
  boolean dots_changed   = data.dots.changed;
  boolean sort_changed   = data.sort.changed;

  // toujours réinitialiser (couvre aussi style et page)
  data.reset_all_changes();

  float iw = (data.image.blurred_image != null) ? data.image.blurred_image.width  : width;
  float ih = (data.image.blurred_image != null) ? data.image.blurred_image.height : height;

  // redémarrer le générateur si image ou dots ont changé
  if (image_changed || dots_changed)
  {
    generator.start(data.dots, data.image, iw, ih);
    _sort_dirty = true;
  }

  // marquer le tri à refaire si l'option vient d'être activée
  if (sort_changed && data.sort.enabled)
    _sort_dirty = true;

  // continuer la génération si pas encore terminée
  if (!generator.isComplete)
    generator.resume();

  // démarrer / continuer le tri une fois la génération terminée
  if (generator.isComplete && data.sort.enabled)
  {
    if (_sort_dirty)
    {
      sorter.start(generator.points);
      _sort_dirty = false;
    }
    if (!sorter.isComplete)
      sorter.resume();
  }

  long t_draw_start = System.currentTimeMillis();

  if (_record)
  {
    // export : Shape uniquement, avec progression console
    ArrayList<PVector> pts_export = (data.sort.enabled && sorter.isComplete) ? sorter.sorted : generator.points;
    renderer.draw(pts_export, data.shape, true);
  }
  else
  {
    if (dataGui.dots_ui.draw)
      generator.draw();

    ArrayList<PVector> pts = (data.sort.enabled && sorter.isComplete) ? sorter.sorted : generator.points;

    if (dataGui.sort_ui.draw_path && data.sort.enabled)
      sorter.drawPath();

    if (dataGui.shape_ui.draw)
      renderer.draw(pts, data.shape, false);
  }

  end_draw();

  int lastDrawMillis = (int)(System.currentTimeMillis() - t_draw_start);
  drawHUD(lastDrawMillis);
}

void drawHUD(int drawMillis)
{
  int bar_x = 20;
  int bar_y = height - 10;

  color bg = data.style.backgroundColor.col;
  color fg = color(255 - red(bg), 255 - green(bg), 255 - blue(bg));

  fill(fg);
  textSize(12);
  int n_generated = generator.points != null ? generator.points.size() : 0;
  String pts_text = StringUtils.formatInt(n_generated) + " pts";
  String timer_text;
  if (!generator.isComplete)
    timer_text = "calc: " + StringUtils.formatDuration(generator.totalCalcMillis) + "   draw: " + StringUtils.formatDuration(drawMillis);
  else
    timer_text = "total calc: " + StringUtils.formatDuration(generator.totalCalcMillis) + "   draw: " + StringUtils.formatDuration(drawMillis);

  String sort_text = "";
  if (data.sort.enabled)
  {
    if (!generator.isComplete || _sort_dirty)
      sort_text = "   sort: waiting...";
    else if (!sorter.isComplete)
      sort_text = "   sort: " + sorter.progress() + "%";
    else
      sort_text = "   sort: done (" + StringUtils.formatDuration(sorter.totalCalcMillis) + ")";
  }

  text(pts_text + "      " + timer_text + sort_text, bar_x, bar_y);
}
