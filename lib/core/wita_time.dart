/// Utility class for timezone handling, ensuring everything is synchronized to
/// WITA (Waktu Indonesia Tengah / UTC+8 / Asia/Makassar).
class WitaTime {
  WitaTime._();

  static const Duration offset = Duration(hours: 8);

  /// Current DateTime in WITA (UTC+8).
  /// Returns a DateTime object whose year, month, day, hour, minute, second
  /// represent the exact wall-clock time in WITA regardless of device OS timezone.
  static DateTime now() {
    final utc = DateTime.now().toUtc();
    final w = utc.add(offset);
    return DateTime(
      w.year,
      w.month,
      w.day,
      w.hour,
      w.minute,
      w.second,
      w.millisecond,
      w.microsecond,
    );
  }

  /// Today's date in WITA at 00:00:00.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Parse any database timestamp (timestamptz from Supabase/PostgreSQL)
  /// or date string into a WITA DateTime representation.
  static DateTime? parse(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) {
      final utc = input.isUtc ? input : input.toUtc();
      final w = utc.add(offset);
      return DateTime(
        w.year,
        w.month,
        w.day,
        w.hour,
        w.minute,
        w.second,
        w.millisecond,
        w.microsecond,
      );
    }

    final str = input.toString().trim();
    if (str.isEmpty) return null;

    // Date-only format (YYYY-MM-DD)
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
      final parts = str.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }

    try {
      final dt = DateTime.parse(str);
      // Supabase timestamptz strings ending in +00:00 or Z
      if (dt.isUtc || str.endsWith('Z') || str.contains('+') || str.endsWith('00:00')) {
        final w = dt.toUtc().add(offset);
        return DateTime(
          w.year,
          w.month,
          w.day,
          w.hour,
          w.minute,
          w.second,
          w.millisecond,
          w.microsecond,
        );
      } else {
        return dt;
      }
    } catch (_) {
      return null;
    }
  }

  /// Convert a WITA DateTime representation back to UTC ISO8601 string for PostgreSQL storage.
  static String? toUtcIso(DateTime? dt) {
    if (dt == null) return null;
    final utc = dt.subtract(offset);
    return utc.toUtc().toIso8601String();
  }

  /// Format a DateTime as YYYY-MM-DD for database date columns.
  static String toDateStr(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '--';
  }
}
