// import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

ImageDotsData data;
DataGUI dataGui;
DotsGenerator generator;
DotsRenderer renderer;
DotsSort sorter;
ShapesGroup shapes_group;
boolean _sort_dirty   = false;
boolean _shapes_dirty = false;
PGraphics current_graphics;
ControlP5 cp5;
ColorChooserPopup colorPopup;

void setup()
{
  size(1200, 800);
  pixelDensity(1);
  surface.setResizable(true);

  data = new ImageDotsData();
  dataGui = new DataGUI(data);
  generator = new DotsGenerator();
  renderer = new DotsRenderer();
  sorter = new DotsSort();
  shapes_group = new ShapesGroup();

  setupControls();
  file_ui.export_shapes = shapes_group;

  data.LoadSettings("./Settings/default.json");
  dataGui.setGUIValues();
}

void setupControls()
{
  init_xlib();
  dataGui.Init();
}

void draw()
{
  if (shapes_group.totalCount() > 0)
    file_ui.updateExportScale(shapes_group.getBoundingBox(data.page.clipping, data.page.clip_width, data.page.clip_height));

  start_draw();

  data.image.buildTransformedImage();
  if (data.image.draw)
    data.image.draw(data.image.imageAlpha);

  boolean image_changed = data.image.changed;
  boolean dots_changed  = data.dots.changed;
  boolean sort_changed  = data.sort.changed;
  boolean shape_changed = data.shape.changed;

  // toujours réinitialiser (couvre aussi style et page)
  data.reset_all_changes();

  float iw = (data.image.transformed_image != null) ? data.image.transformed_image.width  : width;
  float ih = (data.image.transformed_image != null) ? data.image.transformed_image.height : height;

  // Phase 1 : générer les positions — redémarre si image ou dots ont changé
  if (image_changed || dots_changed)
  {
    generator.start(data.dots, data.image, iw, ih);
    sorter.isComplete = false; // invalider le tri
    _sort_dirty = true;
  }

  if (sort_changed)
    _sort_dirty = true;

  if (shape_changed)
    _shapes_dirty = true;

  if (!generator.isComplete)
  {
    generator.maxIterationsPerResume = data.debug.slow_mode ? data.debug.steps_per_frame : Integer.MAX_VALUE;
    if (!data.debug.paused)
      generator.resume();
  }

  // Phase 2 : trier — déclenché une seule fois dès que la génération est terminée
  if (generator.isComplete && _sort_dirty)
  {
    sorter.start(generator.points, data.sort.hex_size);
    _sort_dirty = false;
    _shapes_dirty = true;
  }

  // Reconstruction du ShapesGroup dès que le tri est prêt et les données ont changé
  if (sorter.isComplete && _shapes_dirty)
  {
    renderer.buildShapesGroup(sorter.sorted, data.shape, shapes_group);
    file_ui.updateExportScale(shapes_group.getBoundingBox(data.page.clipping, data.page.clip_width, data.page.clip_height));
    _shapes_dirty = false;
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
    renderer.draw(sorter.sorted, data.shape, true, data.page.clipping, data.page.clip_width, data.page.clip_height);
  }
  else
  {
    // Afficher le dernier stade disponible
    if (!generator.isComplete)
    {
      // Phase 1 en cours : points accumulés en live
      if (dataGui.dots_ui.draw)
        generator.draw(data.page.clipping, data.page.clip_width, data.page.clip_height);
      if (dataGui.shape_ui.draw)
        renderer.draw(generator.points, data.shape, false, data.page.clipping, data.page.clip_width, data.page.clip_height);
      if (data.debug.show_active)
        generator.drawActive(data.debug.active_color, data.page.clipping, data.page.clip_width, data.page.clip_height);
    }
    else
    {
      // Phase 1 terminée (+ phase 2 terminée dans le même frame) : résultat final
      if (dataGui.dots_ui.draw)
        generator.draw(data.page.clipping, data.page.clip_width, data.page.clip_height);

      if (dataGui.sort_ui.draw_path)
        sorter.drawPath();

      if (dataGui.sort_ui.draw_hex_transitions)
        sorter.drawHexTransitions();

      if (dataGui.shape_ui.draw)
        renderer.draw(sorter.sorted, data.shape, false, data.page.clipping, data.page.clip_width, data.page.clip_height);
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

  color bg = data.style.backgroundColor;
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
