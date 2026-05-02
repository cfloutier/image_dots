import controlP5.*;

class ImageDotsData extends DataGlobal
{
  DataImage image = new DataImage();
  Style style = new Style();
  DataDots dots = new DataDots();

  ImageDotsData()
  {
    addChapter(image);
    addChapter(style);
    addChapter(dots);
  }

  void reset()
  {
    image.CopyFrom(new DataImage());
    style.CopyFrom(new Style());
    dots.CopyFrom(new DataDots());
  }
}
