import controlP5.*;

class ImageDotsData extends DataGlobal
{
  DataImage image = new DataImage();
  Style style = new Style();
  DataDots dots = new DataDots();
  DataShape shape = new DataShape();
  DataSort sort = new DataSort();
  DataDebug debug = new DataDebug();

  ImageDotsData()
  {
    addChapter(image);
    addChapter(style);
    addChapter(dots);
    addChapter(shape);
    addChapter(sort);
    addChapter(debug);
  }

  void reset()
  {
    image.CopyFrom(new DataImage());
    style.CopyFrom(new Style());
    dots.CopyFrom(new DataDots());
    shape.CopyFrom(new DataShape());
    sort.CopyFrom(new DataSort());
    debug.CopyFrom(new DataDebug());
  }
}
