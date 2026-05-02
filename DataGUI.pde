import controlP5.*;

class DataGUI extends MainPanel
{
  ImageDotsData data;
  FileGUI file_ui;
  ImageGUI images_ui;
  StyleGUI style_ui;
  DotsGUI dots_ui;

  public DataGUI(ImageDotsData data)
  {
    this.data = data;
    file_ui = new FileGUI(data);
    images_ui = new ImageGUI(data.image);
    style_ui = new StyleGUI(data.style);
    dots_ui = new DotsGUI(data.dots);
  }

  void Init()
  {
    addTab(file_ui);
    addTab(images_ui);
    addTab(style_ui);
    addTab(dots_ui);

    super.Init();

    cp5.getTab("Dots").bringToFront();
  }
}
