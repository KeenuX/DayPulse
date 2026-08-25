import { db } from './database';
import { Category } from '../../types/category';
import { Task } from '../../types/task';
import { AppDateUtils } from '../utilities/dateUtils';
import { addDays, subDays } from 'date-fns';

export async function initializeSeedData() {
  const categoryCount = await db.categories.count();
  if (categoryCount > 0) return; // Already seeded

  const now = new Date();
  const nowIso = now.toISOString();
  const todayStr = AppDateUtils.toIsoDate(now);
  const tomorrowStr = AppDateUtils.toIsoDate(addDays(now, 1));
  const yesterdayStr = AppDateUtils.toIsoDate(subDays(now, 1));
  const twoDaysAgoStr = AppDateUtils.toIsoDate(subDays(now, 2));

  // 1. Seed Categories
  const categories: Category[] = [
    { id: 'cat_work', name: 'Work', iconName: 'Briefcase', colorHex: '#4F46E5', createdAt: nowIso },
    { id: 'cat_code', name: 'Coding', iconName: 'Code2', colorHex: '#06B6D4', createdAt: nowIso },
    { id: 'cat_health', name: 'Health & Fitness', iconName: 'HeartPulse', colorHex: '#10B981', createdAt: nowIso },
    { id: 'cat_study', name: 'Study & Reading', iconName: 'BookOpen', colorHex: '#8B5CF6', createdAt: nowIso },
    { id: 'cat_personal', name: 'Personal', iconName: 'Home', colorHex: '#F59E0B', createdAt: nowIso },
    { id: 'cat_finance', name: 'Finance', iconName: 'DollarSign', colorHex: '#EC4899', createdAt: nowIso },
  ];

  await db.categories.bulkAdd(categories);

  // 2. Seed Initial Tasks
  const tasks: Task[] = [
    {
      id: 'task_welcome',
      title: 'Welcome to DayPulse Web 🌟',
      description: 'Your complete daily planner and habit tracking dashboard, ported straight to the web.',
      categoryId: 'cat_personal',
      date: todayStr,
      startTime: '09:00',
      durationMinutes: 15,
      priority: 'high',
      completed: true,
      completedAt: nowIso,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
      notes: 'Enjoy the fast local storage, 53-week heatmap, dark mode, and keyboard shortcuts!',
    },
    {
      id: 'task_project_review',
      title: 'Review DayPulse Web Dashboard & Analytics',
      description: 'Check out the 53-week GitHub-style heatmap, focus metrics, and category donut chart.',
      categoryId: 'cat_code',
      date: todayStr,
      startTime: '10:30',
      durationMinutes: 45,
      priority: 'high',
      completed: false,
      reminderEnabled: true,
      reminderOffset: 10,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    // Subtasks for task_project_review
    {
      id: 'subtask_1',
      parentId: 'task_project_review',
      title: 'Explore the 7-Column Month Calendar Matrix',
      date: todayStr,
      priority: 'medium',
      completed: true,
      completedAt: nowIso,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'subtask_2',
      parentId: 'task_project_review',
      title: 'Test Quick-Add Natural Language parser (e.g. "Meeting tomorrow at 3pm !high for 30m")',
      date: todayStr,
      priority: 'high',
      completed: false,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'subtask_3',
      parentId: 'task_project_review',
      title: 'Switch between Dark and Light Themes',
      date: todayStr,
      priority: 'low',
      completed: false,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'task_daily_workout',
      title: 'Daily Workout & Hydration Routine',
      description: '30 minutes cardio and stretching.',
      categoryId: 'cat_health',
      date: subDays(now, 7).toISOString().split('T')[0],
      startTime: '07:30',
      durationMinutes: 30,
      priority: 'medium',
      completed: false,
      reminderEnabled: true,
      repeatRule: 'daily',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'task_reading',
      title: 'Read 20 pages of Deep Work',
      description: 'Quiet evening reading.',
      categoryId: 'cat_study',
      date: todayStr,
      startTime: '21:00',
      durationMinutes: 30,
      priority: 'low',
      completed: false,
      reminderEnabled: false,
      repeatRule: 'weekdays',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'task_plan_tomorrow',
      title: 'Plan Tomorrow with Evening Review',
      description: 'Review pending tasks and set top 3 priorities.',
      categoryId: 'cat_personal',
      date: tomorrowStr,
      startTime: '20:00',
      durationMinutes: 15,
      priority: 'medium',
      completed: false,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    // Past historical completions for instant heatmap & streak delight
    {
      id: 'hist_task_1',
      title: 'Setup repository & architecture',
      categoryId: 'cat_code',
      date: yesterdayStr,
      priority: 'high',
      completed: true,
      completedAt: yesterdayStr,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'hist_task_2',
      title: 'Evening Run & Stretch',
      categoryId: 'cat_health',
      date: yesterdayStr,
      priority: 'medium',
      completed: true,
      completedAt: yesterdayStr,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'hist_task_3',
      title: 'Finish module roadmap',
      categoryId: 'cat_work',
      date: twoDaysAgoStr,
      priority: 'high',
      completed: true,
      completedAt: twoDaysAgoStr,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
    {
      id: 'hist_task_4',
      title: 'Budget & expense review',
      categoryId: 'cat_finance',
      date: twoDaysAgoStr,
      priority: 'medium',
      completed: true,
      completedAt: twoDaysAgoStr,
      reminderEnabled: false,
      repeatRule: 'none',
      repeatEndType: 'never',
      repeatInterval: 1,
      createdAt: nowIso,
      updatedAt: nowIso,
    },
  ];

  await db.tasks.bulkAdd(tasks);

  // 3. Seed Preferences
  await db.preferences.put({
    id: 'user_preferences',
    themeMode: 'dark',
    soundEnabled: true,
    notificationsEnabled: false,
    streakThreshold: 70,
    hasCompletedOnboarding: true,
    userName: 'DayPulse User',
  });
}
