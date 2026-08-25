export type RepeatRule = 'none' | 'daily' | 'weekdays' | 'weekly' | 'monthly' | 'custom';

export type RecurrenceEndType = 'never' | 'untilDate' | 'afterOccurrences';

export interface TaskOccurrence {
  id: string;
  taskId: string;
  date: string; // YYYY-MM-DD
  completed: boolean;
  completedAt?: string | null;
  isSkipped: boolean;
  createdAt: string;
  updatedAt: string;
}
