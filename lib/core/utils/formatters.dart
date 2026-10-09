class Formatters {
  Formatters._();

  // 1234.5 -> "1.2k", 2500000 -> "2.50M", 12.34 -> "12.3"
  static String compact(num value) {
    final abs = value.abs();
    if (abs >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
    if (abs >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
    if (abs >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}k';
    return value is int ? '$value' : value.toStringAsFixed(1);
  }

  // "09/10 14:05"
  static String dateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
