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

  boolean image_changed = data.image.changed;
  boolean dots_changed  = data.dots.changed;
  boolean sort_changed  = data.sort.changed;

  // toujours réinitialiser (couvre aussi style et page)
  data.reset_all_changes();

  float iw = (data.image.blurred_image != null) ? data.image.blurred_image.width  : width;
  float ih = (data.image.blurred_image != null) ? data.image.blurred_image.height : height;

  // Phase 1 : générer les positions — redémarre si image ou dots ont changé
  if (image_changed || dots_changed)
  {
    generator.start(data.dots, data.image, iw, ih);
    sorter.isComplete = false; // invalider le tri
    _sort_dirty = true;
  }

  if (sort_changed)
    _sort_dirty = true;

  if (!generator.isComplete)
    generator.resume();

  // Phase 2 : trier — déclenché une seule fois dès que la génération est terminée
  if (generator.isComplete && _sort_dirty)
  {
    sorter.start(generator.points, data.sort.hex_size);
    _sort_dirty = false;
  }

  // Phase 3 : rendu — les shapes sont dessinées à partir du résultat du tri

  long t_draw_start = System.currentTimeMillis();

  if (_record)
  {
    // Export refusé si le pipeline n'est pas complet
    if (!generator.isComplete || !sorter.isComplete)
    {
      println("Export annulé : calcul en cours.");
      end_draw();
      return;
    }
    renderer.draw(sorter.sorted, data.shape, true);
  }
  else
  {
    // Afficher le dernier stade disponible
    if (!generator.isComplete)
    {
      // Phase 1 en cours : points accumulés en live
      if (dataGui.dots_ui.draw)
        generator.draw();
      if (dataGui.shape_ui.draw)
        renderer.draw(generator.points, data.shape, false);
    }
    else
    {
      // Phase 1 terminée (+ phase 2 terminée dans le même frame) : résultat final
      if (dataGui.dots_ui.draw)
        generator.draw();

      if (dataGui.sort_ui.draw_path)
        sorter.drawPath();

      if (dataGui.sort_ui.draw_hex_transitions)
        sorter.drawHexTransitions();

      if (dataGui.shape_ui.draw)
        renderer.draw(sorter.sorted, data.shape, false);
    }
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
  if (!generator.isComplete || _sort_dirty)
    sort_text = "   sort: waiting...";
  else if (!sorter.isComplete)
    sort_text = "   sort: running...";
  else
    sort_text = "   sort: done (" + StringUtils.formatDuration(sorter.totalCalcMillis) + ")";

  String save_text = "";
  if (file_ui.last_save_duration >= 0)
    save_text = "   saved in " + StringUtils.formatDuration(file_ui.last_save_duration);

  text(pts_text + "      " + timer_text + sort_text + save_text, bar_x, bar_y);
}
