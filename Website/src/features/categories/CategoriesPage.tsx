import React from 'react';
import { Plus, Edit, Trash2, Folder, Tag, Layers } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { CategoryIcon } from './CategoryIcon';

interface CategoriesPageProps {
  onOpenCreateCategory: () => void;
  onOpenEditCategory: (categoryId: string) => void;
  onOpenDeleteCategory: (categoryId: string) => void;
  onSelectCategoryFilter: (categoryId: string | null) => void;
}

export const CategoriesPage: React.FC<CategoriesPageProps> = ({
  onOpenCreateCategory,
  onOpenEditCategory,
  onOpenDeleteCategory,
  onSelectCategoryFilter,
}) => {
  const { categories, tasks } = useDayPulseData();

  // Count tasks per category
  const generalTasksCount = tasks.filter(t => !t.parentId && !t.categoryId).length;

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">Categories</h2>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Organize tasks and habits with custom color palettes and icons
          </p>
        </div>

        <button
          onClick={onOpenCreateCategory}
          className="flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold shadow-md shadow-brand-500/20 active:scale-95 transition-all"
        >
          <Plus className="w-4 h-4 stroke-[2.5]" />
          <span>New Category</span>
        </button>
      </div>

      {/* Grid of Categories */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
        {/* General Category Card (Default) */}
        <div className="p-5 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border shadow-sm flex flex-col justify-between space-y-4">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-2xl bg-slate-500/10 text-slate-500 flex items-center justify-center">
                <Folder className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-800 dark:text-white">General</h3>
                <span className="text-[11px] text-slate-400">Default Category</span>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between pt-2 border-t border-slate-100 dark:border-surface-dark-border/60 text-xs">
            <span className="font-bold text-slate-700 dark:text-slate-200">
              {generalTasksCount} task{generalTasksCount === 1 ? '' : 's'}
            </span>
            <button
              onClick={() => onSelectCategoryFilter('general')}
              className="text-brand-500 hover:text-brand-600 font-semibold text-[11px]"
            >
              View Tasks →
            </button>
          </div>
        </div>

        {/* Custom Categories */}
        {categories.map(cat => {
          const taskCount = tasks.filter(t => !t.parentId && t.categoryId === cat.id).length;
          return (
            <div
              key={cat.id}
              className="group p-5 rounded-3xl bg-surface-light dark:bg-surface-dark border border-slate-200/80 dark:border-surface-dark-border hover:border-slate-300 dark:hover:border-slate-700 shadow-sm flex flex-col justify-between space-y-4 transition-all"
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className="w-11 h-11 rounded-2xl flex items-center justify-center shadow-sm"
                    style={{ backgroundColor: `${cat.colorHex}22`, color: cat.colorHex }}
                  >
                    <CategoryIcon iconName={cat.iconName} className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-800 dark:text-white">{cat.name}</h3>
                    <div className="flex items-center gap-1.5 mt-0.5">
                      <div className="w-2 h-2 rounded-full" style={{ backgroundColor: cat.colorHex }} />
                      <span className="text-[10px] text-slate-400 uppercase font-mono">{cat.colorHex}</span>
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={() => onOpenEditCategory(cat.id)}
                    className="p-1.5 rounded-lg text-slate-400 hover:text-brand-500 hover:bg-slate-100 dark:hover:bg-surface-dark-variant"
                    title="Edit Category"
                  >
                    <Edit className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => onOpenDeleteCategory(cat.id)}
                    className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/20"
                    title="Delete Category"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between pt-2 border-t border-slate-100 dark:border-surface-dark-border/60 text-xs">
                <span className="font-bold text-slate-700 dark:text-slate-200">
                  {taskCount} task{taskCount === 1 ? '' : 's'}
                </span>
                <button
                  onClick={() => onSelectCategoryFilter(cat.id)}
                  className="text-brand-500 hover:text-brand-600 font-semibold text-[11px]"
                >
                  View Tasks →
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
