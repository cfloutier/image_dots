import controlP5.*;

class ImageDotsData extends DataGlobal
{
  DataImage image = new DataImage();
  Style style = new Style();
  DataDots dots = new DataDots();
  DataFilter filter = new DataFilter();
  DataShape shape = new DataShape();

  ImageDotsData()
  {
    addChapter(image);
    addChapter(style);
    addChapter(dots);
    addChapter(filter);
    addChapter(shape);
  }

  void reset()
  {
    image.CopyFrom(new DataImage());
    style.CopyFrom(new Style());
    dots.CopyFrom(new DataDots());
    filter.CopyFrom(new DataFilter());
    shape.CopyFrom(new DataShape());
  }
}
