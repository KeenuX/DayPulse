class DurationFormatter {
  static String formatMinutes(int? minutes, {bool showZero = false}) {
    if (minutes == null || minutes <= 0) {
      return showZero ? '0m' : '';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  static String formatHoursAndMinutes(Duration duration, {bool showZero = false}) {
    final minutes = duration.inMinutes;
    return formatMinutes(minutes, showZero: showZero);
  }
}