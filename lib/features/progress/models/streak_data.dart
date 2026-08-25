class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalSuccessfulDays;
  final bool isTodaySuccessful;
  final int streakThresholdPercentage;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSuccessfulDays,
    required this.isTodaySuccessful,
    required this.streakThresholdPercentage,
  });

  static const StreakData empty = StreakData(
    currentStreak: 0,
    longestStreak: 0,
    totalSuccessfulDays: 0,
    isTodaySuccessful: false,
    streakThresholdPercentage: 70,
  );
}