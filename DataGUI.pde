import controlP5.*;

class DataGUI extends MainPanel
{
  ImageDotsData data;
  FileGUI file_ui;
  ImageGUI images_ui;
  StyleGUI style_ui;
  DotsGUI dots_ui;
  ShapeGUI shape_ui;
  SortGUI sort_ui;

  public DataGUI(ImageDotsData data)
  {
    this.data = data;
    file_ui = new FileGUI(data);
    images_ui = new ImageGUI(data.image);
    style_ui = new StyleGUI(data.style);
    dots_ui = new DotsGUI(data.dots);
    shape_ui = new ShapeGUI(data.shape);
    sort_ui = new SortGUI(data.sort);
  }

  void Init()
  {
    addTab(file_ui);
    addTab(images_ui);
    addTab(style_ui);
    addTab(dots_ui);
    addTab(sort_ui);
    addTab(shape_ui);

    super.Init();

    cp5.getTab("Dots").bringToFront();
  }
}
