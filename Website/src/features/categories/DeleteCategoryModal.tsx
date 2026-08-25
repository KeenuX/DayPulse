import React from 'react';
import { AlertTriangle, X, Trash2 } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { CategoryIcon } from './CategoryIcon';

interface DeleteCategoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  categoryId: string | null;
}

export const DeleteCategoryModal: React.FC<DeleteCategoryModalProps> = ({
  isOpen,
  onClose,
  categoryId,
}) => {
  const { categories, tasks, deleteCategory } = useDayPulseData();

  if (!isOpen || !categoryId) return null;

  const category = categories.find(c => c.id === categoryId);
  if (!category) return null;

  const affectedTasksCount = tasks.filter(t => t.categoryId === categoryId).length;

  const handleDelete = async () => {
    await deleteCategory(category.id);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in" onClick={onClose}>
      <div
        className="w-full max-w-md bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-3xl shadow-2xl overflow-hidden animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        <div className="p-6 space-y-4">
          <div className="w-12 h-12 rounded-2xl bg-rose-500/10 border border-rose-500/20 text-rose-500 flex items-center justify-center">
            <AlertTriangle className="w-6 h-6" />
          </div>

          <div>
            <h3 className="text-lg font-bold text-slate-800 dark:text-white">Delete Category?</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 leading-relaxed">
              Are you sure you want to delete <strong className="text-slate-800 dark:text-slate-200">{category.name}</strong>?
            </p>
          </div>

          <div className="p-3.5 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border text-xs text-slate-600 dark:text-slate-300 space-y-1">
            <div className="font-semibold text-slate-700 dark:text-slate-200 flex items-center gap-1.5">
              <CategoryIcon iconName={category.iconName} className="w-4 h-4" style={{ color: category.colorHex }} />
              <span>{category.name}</span>
            </div>
            <p className="text-[11px] text-slate-400">
              {affectedTasksCount} task(s) currently linked to this category will be automatically reassigned to <strong>General</strong> (uncategorized). No tasks will be deleted.
            </p>
          </div>

          <div className="flex items-center justify-end gap-3 pt-2">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle"
            >
              Cancel
            </button>
            <button
              onClick={handleDelete}
              className="flex items-center gap-1.5 px-5 py-2 rounded-xl bg-rose-500 hover:bg-rose-600 text-white text-xs font-bold shadow-md shadow-rose-500/20 active:scale-95 transition-all"
            >
              <Trash2 className="w-4 h-4" />
              <span>Delete Category</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
