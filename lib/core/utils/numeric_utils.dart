double parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim()) ?? defaultValue;
  }
  return defaultValue;
}

int parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.trim()) ??
        (double.tryParse(value.trim())?.toInt() ?? defaultValue);
  }
  return defaultValue;
}

class NumericUtils {
  static double parse(dynamic value, [double defaultValue = 0.0]) => parseDouble(value, defaultValue);
  static int parseIntVal(dynamic value, [int defaultValue = 0]) => parseInt(value, defaultValue);

  static String formatCurrency(dynamic amount) {
    final val = parseDouble(amount);
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }
}

