/// Utilidades para normalizar nombres usados como `username` en Firestore.
String normalizeUsername(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
}
