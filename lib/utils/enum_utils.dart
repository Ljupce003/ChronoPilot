T? enumFromString<T extends Enum>(List<T> values, String? source) {
  if (source == null) return null;

  try {
    return values.firstWhere((value) => value.name == source);
  } catch (_) {
    try {
      return values.firstWhere(
        (value) => value.name.toLowerCase() == source.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

