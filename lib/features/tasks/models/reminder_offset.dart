enum ReminderOffset {
  none(null, 'None'),
  atTime(0, 'At task time'),
  fiveMinutes(5, '5 minutes before'),
  tenMinutes(10, '10 minutes before'),
  thirtyMinutes(30, '30 minutes before'),
  oneHour(60, '1 hour before');

  final int? minutesBefore;
  final String label;

  const ReminderOffset(this.minutesBefore, this.label);

  static ReminderOffset fromString(String? value) {
    if (value == null) return ReminderOffset.none;
    switch (value.toLowerCase()) {
      case '0':
      case 'attime':
        return ReminderOffset.atTime;
      case '5':
      case 'fiveminutes':
        return ReminderOffset.fiveMinutes;
      case '10':
      case 'tenminutes':
        return ReminderOffset.tenMinutes;
      case '30':
      case 'thirtyminutes':
        return ReminderOffset.thirtyMinutes;
      case '60':
      case 'onehour':
        return ReminderOffset.oneHour;
      default:
        return ReminderOffset.tenMinutes;
    }
  }

  static ReminderOffset fromMinutes(int? minutes) {
    if (minutes == null) return ReminderOffset.none;
    switch (minutes) {
      case 0:
        return ReminderOffset.atTime;
      case 5:
        return ReminderOffset.fiveMinutes;
      case 10:
        return ReminderOffset.tenMinutes;
      case 30:
        return ReminderOffset.thirtyMinutes;
      case 60:
        return ReminderOffset.oneHour;
      default:
        return ReminderOffset.tenMinutes;
    }
  }
}