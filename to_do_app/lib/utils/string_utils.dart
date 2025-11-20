class StringUtils {
  static List<String> listFromString(String s) {
    // Remove the square brackets
    s = s.substring(1, s.length - 1); // "apple, banana, orange"

    // Split by comma and trim spaces
    List<String> list = s.split(',').map((e) => e.trim()).toList();

    return list;
  }
}
