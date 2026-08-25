import { useLiveQuery } from 'dexie-react-hooks';
import confetti from 'canvas-confetti';
import { db } from './database';
import { Task } from '../../types/task';
import { Category } from '../../types/category';
import { TaskOccurrence } from '../../types/recurrence';
import { UserPreferences } from '../../types/preferences';
import { soundEffects } from '../sound/soundEffects';
import { AppDateUtils } from '../utilities/dateUtils';

export function useDayPulseData() {
  const tasks = useLiveQuery(() => db.tasks.toArray(), []) || [];
  const categories = useLiveQuery(() => db.categories.toArray(), []) || [];
  const occurrences = useLiveQuery(() => db.task_occurrences.toArray(), []) || [];
  const preferences = useLiveQuery(() => db.preferences.get('user_preferences'), []) || {
    themeMode: 'dark',
    soundEnabled: true,
    notificationsEnabled: false,
    streakThreshold: 70,
    hasCompletedOnboarding: true,
  };

  // Helper map for categories
  const categoryMap = new Map<string, Category>();
  categories.forEach(c => categoryMap.set(c.id, c));

  // Add Task (with optional subtasks)
  const addTask = async (
    taskData: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>,
    subtaskTitles: string[] = []
  ): Promise<string> => {
    const nowIso = new Date().toISOString();
    const taskId = `task_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const newTask: Task = {
      ...taskData,
      id: taskId,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    await db.transaction('rw', db.tasks, async () => {
      await db.tasks.add(newTask);

      if (subtaskTitles.length > 0) {
        const subtasks: Task[] = subtaskTitles
          .filter(t => t.trim().length > 0)
          .map((title, i) => ({
            id: `subtask_${Date.now()}_${i}_${Math.random().toString(36).substring(2, 6)}`,
            parentId: taskId,
            title: title.trim(),
            date: taskData.date,
            priority: taskData.priority,
            completed: false,
            reminderEnabled: false,
            repeatRule: 'none',
            repeatEndType: 'never',
            repeatInterval: 1,
            createdAt: nowIso,
            updatedAt: nowIso,
          }));

        if (subtasks.length > 0) {
          await db.tasks.bulkAdd(subtasks);
        }
      }
    });

    return taskId;
  };

  // Update Task
  const updateTask = async (taskId: string, updates: Partial<Task>) => {
    const nowIso = new Date().toISOString();
    await db.tasks.update(taskId, {
      ...updates,
      updatedAt: nowIso,
    });
  };

  // Delete Task
  const deleteTask = async (taskId: string) => {
    await db.transaction('rw', db.tasks, db.task_occurrences, async () => {
      await db.tasks.delete(taskId);
      // Delete child subtasks
      const childSubtasks = await db.tasks.where('parentId').equals(taskId).toArray();
      for (const st of childSubtasks) {
        await db.tasks.delete(st.id);
      }
      // Delete occurrences
      await db.task_occurrences.where('taskId').equals(taskId).delete();
    });
  };

  // Toggle Task / Occurrence completion
  const toggleTaskCompletion = async (task: Task, targetDate?: string) => {
    const now = new Date();
    const nowIso = now.toISOString();
    const effectiveDate = targetDate || task.date;

    if (task.repeatRule !== 'none') {
      // Recurring task: toggle occurrence
      const occKey = `${task.id}_${effectiveDate}`;
      const existingOcc = await db.task_occurrences.get(occKey);
      const newCompleted = existingOcc ? !existingOcc.completed : true;

      await db.task_occurrences.put({
        id: occKey,
        taskId: task.id,
        date: effectiveDate,
        completed: newCompleted,
        completedAt: newCompleted ? nowIso : null,
        isSkipped: false,
        createdAt: existingOcc?.createdAt || nowIso,
        updatedAt: nowIso,
      });

      if (newCompleted) {
        if (preferences.soundEnabled) soundEffects.playTaskComplete();
      }
    } else {
      // Non-recurring task
      const newCompleted = !task.completed;
      await db.tasks.update(task.id, {
        completed: newCompleted,
        completedAt: newCompleted ? nowIso : null,
        updatedAt: nowIso,
      });

      // If this is a subtask, sync parent task completion
      if (task.parentId) {
        const siblingSubtasks = await db.tasks.where('parentId').equals(task.parentId).toArray();
        const allSiblingsDone = siblingSubtasks.every(st => (st.id === task.id ? newCompleted : st.completed));
        await db.tasks.update(task.parentId, {
          completed: allSiblingsDone,
          completedAt: allSiblingsDone ? nowIso : null,
          updatedAt: nowIso,
        });
      } else {
        // If this is a parent task, check/uncheck all subtasks
        const childSubtasks = await db.tasks.where('parentId').equals(task.id).toArray();
        if (childSubtasks.length > 0) {
          for (const st of childSubtasks) {
            await db.tasks.update(st.id, {
              completed: newCompleted,
              completedAt: newCompleted ? nowIso : null,
              updatedAt: nowIso,
            });
          }
        }
      }

      if (newCompleted) {
        if (preferences.soundEnabled) soundEffects.playTaskComplete();

        // Confetti for completing top-level tasks
        if (!task.parentId) {
          try {
            confetti({
              particleCount: 40,
              spread: 60,
              origin: { y: 0.8 },
              colors: ['#4F75FF', '#6366F1', '#10B981', '#F59E0B', '#38BDF8'],
            });
          } catch {
            // Ignore if canvas confetti fails
          }
        }
      }
    }
  };

  // Reschedule Task
  const rescheduleTask = async (taskId: string, newDate: string, newTime?: string | null) => {
    await db.tasks.update(taskId, {
      date: newDate,
      ...(newTime !== undefined ? { startTime: newTime } : {}),
      updatedAt: new Date().toISOString(),
    });
  };

  // Toggle Star
  const toggleStarTask = async (taskId: string) => {
    const task = await db.tasks.get(taskId);
    if (task) {
      await db.tasks.update(taskId, {
        isStarred: !task.isStarred,
        updatedAt: new Date().toISOString(),
      });
    }
  };

  // Add Category
  const addCategory = async (catData: Omit<Category, 'id' | 'createdAt'>) => {
    const catId = `cat_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const newCategory: Category = {
      ...catData,
      id: catId,
      createdAt: new Date().toISOString(),
    };
    await db.categories.add(newCategory);
    return catId;
  };

  // Update Category
  const updateCategory = async (catId: string, updates: Partial<Category>) => {
    await db.categories.update(catId, updates);
  };

  // Delete Category & reassign tasks to null (General)
  const deleteCategory = async (catId: string) => {
    await db.transaction('rw', db.categories, db.tasks, async () => {
      await db.categories.delete(catId);
      const affectedTasks = await db.tasks.where('categoryId').equals(catId).toArray();
      for (const t of affectedTasks) {
        await db.tasks.update(t.id, { categoryId: null });
      }
    });
  };

  // Update preferences
  const updatePreferences = async (updates: Partial<UserPreferences>) => {
    await db.preferences.put({
      ...preferences,
      ...updates,
      id: 'user_preferences',
    });
  };

  // Reset all database data
  const resetAllData = async () => {
    await db.transaction('rw', db.tasks, db.task_occurrences, db.categories, db.preferences, async () => {
      await db.tasks.clear();
      await db.task_occurrences.clear();
      await db.categories.clear();
      await db.preferences.clear();
    });
  };

  // Export full JSON backup
  const exportBackupJson = async (): Promise<string> => {
    const allTasks = await db.tasks.toArray();
    const allCategories = await db.categories.toArray();
    const allOccurrences = await db.task_occurrences.toArray();
    const allPrefs = await db.preferences.get('user_preferences');

    const backupData = {
      version: 1,
      appName: 'DayPulse',
      exportedAt: new Date().toISOString(),
      tasks: allTasks,
      categories: allCategories,
      task_occurrences: allOccurrences,
      preferences: allPrefs,
    };

    return JSON.stringify(backupData, null, 2);
  };

  // Import JSON backup
  const importBackupJson = async (jsonContent: string): Promise<{ success: boolean; message: string }> => {
    try {
      const data = JSON.parse(jsonContent);
      if (!data || !Array.isArray(data.tasks)) {
        return { success: false, message: 'Invalid backup file format.' };
      }

      await db.transaction('rw', db.tasks, db.task_occurrences, db.categories, db.preferences, async () => {
        if (data.tasks) {
          await db.tasks.clear();
          await db.tasks.bulkAdd(data.tasks);
        }
        if (data.categories) {
          await db.categories.clear();
          await db.categories.bulkAdd(data.categories);
        }
        if (data.task_occurrences) {
          await db.task_occurrences.clear();
          await db.task_occurrences.bulkAdd(data.task_occurrences);
        }
        if (data.preferences) {
          await db.preferences.put({ ...data.preferences, id: 'user_preferences' });
        }
      });

      return { success: true, message: `Successfully restored ${data.tasks.length} tasks and ${data.categories?.length || 0} categories.` };
    } catch (err: unknown) {
      return { success: false, message: `Import failed: ${(err as Error).message}` };
    }
  };

  // Helper to dynamically synthesize tasks (non-recurring + recurring occurrences) for any date
  const getTasksForDate = (targetDate: Date | string): Task[] => {
    const d = typeof targetDate === 'string' ? AppDateUtils.parseIsoDate(targetDate) : targetDate;
    const dStr = AppDateUtils.toIsoDate(d);

    const nonRec = tasks.filter(t => !t.parentId && t.repeatRule === 'none' && t.date === dStr);

    const occMap = new Map<string, TaskOccurrence>();
    occurrences.forEach(o => {
      if (o.date === dStr) occMap.set(o.taskId, o);
    });

    const rec = tasks
      .filter(t => !t.parentId && t.repeatRule !== 'none' && AppDateUtils.isOccurringOnDate(t, d))
      .filter(t => {
        const occ = occMap.get(t.id);
        return !(occ && occ.isSkipped);
      })
      .map(t => {
        const occ = occMap.get(t.id);
        return {
          ...t,
          date: dStr,
          completed: occ ? occ.completed : false,
          completedAt: occ?.completedAt,
        };
      });

    const result = [...nonRec, ...rec];
    result.sort((a, b) => {
      const aTime = a.startTime || '99:99';
      const bTime = b.startTime || '99:99';
      const timeComp = aTime.localeCompare(bTime);
      if (timeComp !== 0) return timeComp;
      const priWeights: Record<string, number> = { high: 3, medium: 2, low: 1 };
      return (priWeights[b.priority] || 1) - (priWeights[a.priority] || 1);
    });
    return result;
  };

  return {
    tasks,
    categories,
    categoryMap,
    occurrences,
    preferences,
    getTasksForDate,
    addTask,
    updateTask,
    deleteTask,
    toggleTaskCompletion,
    rescheduleTask,
    toggleStarTask,
    addCategory,
    updateCategory,
    deleteCategory,
    updatePreferences,
    resetAllData,
    exportBackupJson,
    importBackupJson,
  };
}
