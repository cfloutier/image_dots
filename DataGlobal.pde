import controlP5.*;

class ImageDotsData extends DataGlobal
{
  DataImage image = new DataImage();
  Style style = new Style();
  DataDots dots = new DataDots();
  DataShape shape = new DataShape();

  ImageDotsData()
  {
    addChapter(image);
    addChapter(style);
    addChapter(dots);
    addChapter(shape);
  }

  void reset()
  {
    image.CopyFrom(new DataImage());
    style.CopyFrom(new Style());
    dots.CopyFrom(new DataDots());
    shape.CopyFrom(new DataShape());
  }
}
