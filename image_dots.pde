import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

ImageDotsData data;
DataGUI dataGui;
PGraphics current_graphics;
ControlP5 cp5;

void setup()
{
  size(1200, 800);
  surface.setResizable(true);

  data = new ImageDotsData();
  dataGui = new DataGUI(data);

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

  pushMatrix();
  scale(data.page.global_scale, data.page.global_scale);

  // TODO: draw dots

  popMatrix();
  end_draw();
}
