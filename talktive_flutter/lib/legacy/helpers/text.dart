String formatText(String? text) {
  if (text == null || text.isEmpty) return '';

  // Replace consecutive whitespace characters (space, tabs, newlines) with a single space
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
