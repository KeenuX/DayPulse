import Dexie, { Table } from 'dexie';
import { Task } from '../../types/task';
import { TaskOccurrence } from '../../types/recurrence';
import { Category } from '../../types/category';
import { UserPreferences } from '../../types/preferences';

export class DayPulseDatabase extends Dexie {
  tasks!: Table<Task, string>;
  task_occurrences!: Table<TaskOccurrence, string>;
  categories!: Table<Category, string>;
  preferences!: Table<UserPreferences & { id: string }, string>;

  constructor() {
    super('DayPulseDB');
    this.version(1).stores({
      tasks: 'id, parentId, categoryId, date, priority, completed, repeatRule, createdAt, isStarred',
      task_occurrences: 'id, taskId, date, [taskId+date], completed',
      categories: 'id, name, createdAt',
      preferences: 'id',
    });
  }
}

export const db = new DayPulseDatabase();
