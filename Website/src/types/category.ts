export interface Category {
  id: string;
  name: string;
  iconName: string;
  colorHex: string;
  createdAt: string;
}

export const CATEGORY_PALETTE: string[] = [
  '#4F46E5', // Indigo
  '#10B981', // Emerald
  '#06B6D4', // Cyan
  '#F59E0B', // Amber
  '#EC4899', // Pink
  '#8B5CF6', // Purple
  '#EF4444', // Rose
  '#3B82F6', // Blue
  '#14B8A6', // Teal
  '#64748B', // Slate
  '#D97706', // Ochre
  '#6366F1', // Soft Brand Violet
];

export const CATEGORY_ICONS: { name: string; label: string }[] = [
  { name: 'BookOpen', label: 'Reading / Study' },
  { name: 'Code2', label: 'Coding / Dev' },
  { name: 'Briefcase', label: 'Work / Job' },
  { name: 'Dumbbell', label: 'Fitness / Gym' },
  { name: 'Home', label: 'Home / Chores' },
  { name: 'Rocket', label: 'Project / Startup' },
  { name: 'Pin', label: 'Focus / Priority' },
  { name: 'Music', label: 'Music / Audio' },
  { name: 'Palette', label: 'Design / Art' },
  { name: 'Coffee', label: 'Break / Social' },
  { name: 'Gamepad2', label: 'Gaming' },
  { name: 'ShoppingBag', label: 'Shopping' },
  { name: 'HeartPulse', label: 'Health' },
  { name: 'DollarSign', label: 'Finance' },
  { name: 'Globe', label: 'Travel / Life' },
  { name: 'Folder', label: 'General' },
];
