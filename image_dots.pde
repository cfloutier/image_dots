import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

ImageDotsData data;
DataGUI dataGui;
DotsGenerator generator;
DotsFilter dots_filter;
PGraphics current_graphics;
ControlP5 cp5;

void setup()
{
  size(1200, 800);
  surface.setResizable(true);

  data = new ImageDotsData();
  dataGui = new DataGUI(data);
  generator = new DotsGenerator();
  dots_filter = new DotsFilter(data.filter);

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
  data.image.draw();

  boolean image_changed  = data.image.changed;
  boolean dots_changed   = data.dots.changed;
  boolean filter_changed = data.filter.changed;

  // toujours réinitialiser (couvre aussi style et page)
  data.reset_all_changes();

  float iw = (data.image.blurred_image != null) ? data.image.blurred_image.width  : width;
  float ih = (data.image.blurred_image != null) ? data.image.blurred_image.height : height;

  // redémarrer le générateur si image ou dots ont changé
  if (image_changed || dots_changed)
    generator.start(data.dots, iw, ih);

  // continuer la génération si pas encore terminée
  if (!generator.isComplete)
  {
    boolean just_done = generator.resume();
    if (just_done)
      dots_filter.buildPoints(generator.points, data.image, data.dots.seed);
  }
  else if (filter_changed)
  {
    dots_filter.buildPoints(generator.points, data.image, data.dots.seed);
  }

  long t_draw_start = System.currentTimeMillis();

  if (_record)
  {
    // export : toujours Shape uniquement, avec progression console
    dots_filter.drawWithShape(data.shape, true);
  }
  else
  {
    if (dataGui.dots_ui.draw)
      generator.draw();

    if (dataGui.filter_ui.draw || dataGui.shape_ui.draw)
    {
      if (dataGui.shape_ui.draw)
        dots_filter.drawWithShape(data.shape, false);
      else
        dots_filter.draw();
    }
  }

  end_draw();

  int lastDrawMillis = (int)(System.currentTimeMillis() - t_draw_start);
  drawHUD(lastDrawMillis);
}

void drawHUD(int drawMillis)
{
  int bar_x = 20;
  int bar_y = height - 30;
  int bar_w = 300;
  int bar_h = 16;

  color bg = data.style.backgroundColor.col;
  color fg = color(255 - red(bg), 255 - green(bg), 255 - blue(bg));

  // barre de progression (visible uniquement pendant la génération)
  if (!generator.isComplete)
  {
    noStroke();
    fill(red(bg)*0.6, green(bg)*0.6, blue(bg)*0.6);
    rect(bar_x, bar_y, bar_w, bar_h);
    fill(0, 200, 100);
    rect(bar_x, bar_y, bar_w * generator.progressRatio, bar_h);
  }

  // timer + nb points toujours affichés
  fill(fg);
  textSize(12);
  int n_generated = generator.points != null ? generator.points.size() : 0;
  int n_filtered  = dots_filter.points  != null ? dots_filter.points.size()  : 0;
  String pts_text = StringUtils.formatInt(n_generated) + " pts  →  " + StringUtils.formatInt(n_filtered) + " pts";
  String timer_text = "draw: " + drawMillis + " ms";
  if (!generator.isComplete)
    timer_text = "calc: " + generator.lastResumeMillis + " ms   " + timer_text;
  text(pts_text + "      " + timer_text, bar_x, bar_y - 5);
}
