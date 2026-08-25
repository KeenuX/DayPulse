import { db } from './database';
import { Category } from '../../types/category';

export async function initializeSeedData() {
  const categoryCount = await db.categories.count();
  if (categoryCount > 0) return; // Already seeded

  const nowIso = new Date().toISOString();

  // 1. Seed Starter Categories
  const categories: Category[] = [
    { id: 'cat_work', name: 'Work', iconName: 'Briefcase', colorHex: '#4F46E5', createdAt: nowIso },
    { id: 'cat_code', name: 'Coding', iconName: 'Code2', colorHex: '#06B6D4', createdAt: nowIso },
    { id: 'cat_health', name: 'Health & Fitness', iconName: 'HeartPulse', colorHex: '#10B981', createdAt: nowIso },
    { id: 'cat_study', name: 'Study & Reading', iconName: 'BookOpen', colorHex: '#8B5CF6', createdAt: nowIso },
    { id: 'cat_personal', name: 'Personal', iconName: 'Home', colorHex: '#F59E0B', createdAt: nowIso },
    { id: 'cat_finance', name: 'Finance', iconName: 'DollarSign', colorHex: '#EC4899', createdAt: nowIso },
  ];

  await db.categories.bulkAdd(categories);

  // 2. Preferences (Default setup without fake pre-entered tasks)
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
