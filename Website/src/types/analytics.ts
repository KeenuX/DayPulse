export interface ProductivityScoreBreakdown {
  totalScore: number; // 0 to 100
  completionPoints: number; // max 40
  priorityPoints: number; // max 30
  punctualityPoints: number; // max 15
  consistencyPoints: number; // max 15
  summaryExplanation: string;
}

export interface StreakCalculationResult {
  currentStreak: number;
  longestStreak: number;
  totalSuccessfulDays: number;
  isTodaySuccessful: boolean;
}

export interface DayFocusMetric {
  date: string;
  dayName: string;
  focusMinutes: number;
  completedTasksCount: number;
}

export interface CategoryBreakdownItem {
  categoryId: string | null;
  categoryName: string;
  colorHex: string;
  taskCount: number;
  percentage: number;
}
