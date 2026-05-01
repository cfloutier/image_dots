import controlP5.*;

class ImageDotsData extends DataGlobal
{
  DataImage image = new DataImage();
  Style style = new Style();

  ImageDotsData()
  {
    addChapter(image);
    addChapter(style);
  }

  void reset()
  {
    image.CopyFrom(new DataImage());
    style.CopyFrom(new Style());
  }
}
