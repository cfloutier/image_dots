

static class StringUtils
{
  // Formate un entier avec des espaces comme séparateurs de milliers (ex: 1 234 567)
  public static String formatInt(int n)
  {
    String s = str(abs(n));
    String result = "";
    int len = s.length();
    for (int i = 0; i < len; i++)
    {
      if (i > 0 && (len - i) % 3 == 0)
        result += " "; // séparateur de milliers
      result += s.charAt(i);
    }
    return (n < 0 ? "-" : "") + result;
  }

  public static boolean isEmpty(String str)
  {
    if (str == null)
      return true;

    if (str == "")

      return true;


    return false;
  }
}

