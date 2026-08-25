import { RepeatRule, RecurrenceEndType } from './recurrence';

export type TaskPriority = 'high' | 'medium' | 'low';

export interface Task {
  id: string;
  parentId?: string | null;
  title: string;
  description?: string;
  categoryId?: string | null;
  date: string; // YYYY-MM-DD
  startTime?: string | null; // HH:mm
  endTime?: string | null; // HH:mm
  durationMinutes?: number | null;
  priority: TaskPriority;
  completed: boolean;
  completedAt?: string | null;
  reminderEnabled: boolean;
  reminderOffset?: number; // Minutes before start: 0, 5, 10, 30, 60
  reminderTime?: string | null;
  repeatRule: RepeatRule;
  repeatEndType: RecurrenceEndType;
  repeatEndDate?: string | null; // YYYY-MM-DD
  repeatEndCount?: number | null;
  repeatInterval: number; // default 1
  repeatDaysOfWeek?: number[] | null; // 1=Mon, ..., 7=Sun
  createdAt: string;
  updatedAt: string;
  notes?: string | null;
  isStarred?: boolean;
}

export type TaskFilterStatus = 'all' | 'today' | 'upcoming' | 'completed' | 'overdue';
export type TaskSortOption = 'date' | 'priority' | 'title' | 'created';
