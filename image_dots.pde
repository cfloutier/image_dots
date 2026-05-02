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

  if (data.any_change())
  {
    generator.generate(data.dots);
    dots_filter.buildPoints(generator.points, data.image);
    data.reset_all_changes();
  }

  if (data.dots.draw)
    generator.draw();

  if (data.filter.draw)
    dots_filter.draw();

  end_draw();
}
