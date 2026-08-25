enum RepeatRule {
  none('none', 'No Repeat'),
  daily('daily', 'Daily'),
  weekdays('weekdays', 'Weekdays (Mon-Fri)'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  custom('custom', 'Custom');

  final String value;
  final String label;

  const RepeatRule(this.value, this.label);

  static RepeatRule fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'daily':
        return RepeatRule.daily;
      case 'weekdays':
        return RepeatRule.weekdays;
      case 'weekly':
        return RepeatRule.weekly;
      case 'monthly':
        return RepeatRule.monthly;
      case 'custom':
        return RepeatRule.custom;
      case 'none':
      default:
        return RepeatRule.none;
    }
  }

  bool get isRecurring => this != RepeatRule.none;
}

enum RecurrenceEndType {
  never('never', 'Never'),
  afterOccurrences('after_occurrences', 'After occurrences'),
  untilDate('until_date', 'On date');

  final String value;
  final String label;

  const RecurrenceEndType(this.value, this.label);

  static RecurrenceEndType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'after_occurrences':
      case 'afteroccurrences':
        return RecurrenceEndType.afterOccurrences;
      case 'until_date':
      case 'untildate':
        return RecurrenceEndType.untilDate;
      case 'never':
      default:
        return RecurrenceEndType.never;
    }
  }
}