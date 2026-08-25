import React, { useState, useEffect } from 'react';
import { X, Palette, Check } from 'lucide-react';
import { useDayPulseData } from '../../core/db/useDayPulseData';
import { CATEGORY_PALETTE, CATEGORY_ICONS } from '../../types/category';
import { CategoryIcon } from './CategoryIcon';

interface CategoryEditorModalProps {
  isOpen: boolean;
  onClose: () => void;
  editCategoryId?: string | null;
}

export const CategoryEditorModal: React.FC<CategoryEditorModalProps> = ({
  isOpen,
  onClose,
  editCategoryId,
}) => {
  const { categories, addCategory, updateCategory } = useDayPulseData();

  const [name, setName] = useState('');
  const [selectedColor, setSelectedColor] = useState(CATEGORY_PALETTE[0]);
  const [selectedIcon, setSelectedIcon] = useState(CATEGORY_ICONS[0].name);

  useEffect(() => {
    if (editCategoryId) {
      const cat = categories.find(c => c.id === editCategoryId);
      if (cat) {
        setName(cat.name);
        setSelectedColor(cat.colorHex);
        setSelectedIcon(cat.iconName);
      }
    } else {
      setName('');
      setSelectedColor(CATEGORY_PALETTE[0]);
      setSelectedIcon(CATEGORY_ICONS[0].name);
    }
  }, [editCategoryId, isOpen, categories]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    if (editCategoryId) {
      await updateCategory(editCategoryId, {
        name: name.trim(),
        colorHex: selectedColor,
        iconName: selectedIcon,
      });
    } else {
      await addCategory({
        name: name.trim(),
        colorHex: selectedColor,
        iconName: selectedIcon,
      });
    }

    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in" onClick={onClose}>
      <div
        className="w-full max-w-lg bg-white dark:bg-surface-dark border border-slate-200 dark:border-surface-dark-border rounded-3xl shadow-2xl overflow-hidden animate-slide-up"
        onClick={e => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-slate-100 dark:border-surface-dark-border flex items-center justify-between">
          <h3 className="font-bold text-slate-800 dark:text-white text-base">
            {editCategoryId ? 'Edit Category' : 'Create Category'}
          </h3>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Preview Badge */}
          <div className="flex flex-col items-center justify-center p-4 rounded-2xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-100 dark:border-surface-dark-border gap-2">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Live Preview</span>
            <div
              className="flex items-center gap-2 px-4 py-2 rounded-2xl text-sm font-bold text-white shadow-md transition-all"
              style={{ backgroundColor: selectedColor }}
            >
              <CategoryIcon iconName={selectedIcon} className="w-4 h-4" />
              <span>{name.trim() || 'Category Name'}</span>
            </div>
          </div>

          {/* Name input */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1.5">
              Category Name
            </label>
            <input
              type="text"
              placeholder="e.g. Health, Deep Work, Finance..."
              value={name}
              onChange={e => setName(e.target.value)}
              required
              autoFocus
              className="w-full px-4 py-2.5 rounded-xl bg-slate-50 dark:bg-surface-dark-subtle border border-slate-200 dark:border-surface-dark-border text-slate-900 dark:text-white text-sm outline-none"
            />
          </div>

          {/* Color Swatches Grid */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
              Color Palette (12 Curated Swatches)
            </label>
            <div className="grid grid-cols-6 gap-2">
              {CATEGORY_PALETTE.map(color => {
                const isSelected = selectedColor.toLowerCase() === color.toLowerCase();
                return (
                  <button
                    key={color}
                    type="button"
                    onClick={() => setSelectedColor(color)}
                    className="w-10 h-10 rounded-2xl flex items-center justify-center transition-transform hover:scale-105 active:scale-95 shadow-sm"
                    style={{ backgroundColor: color }}
                  >
                    {isSelected && <Check className="w-5 h-5 text-white stroke-[3]" />}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Icon Grid */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
              Icon (16 Curated Options)
            </label>
            <div className="grid grid-cols-4 sm:grid-cols-8 gap-2">
              {CATEGORY_ICONS.map(item => {
                const isSelected = selectedIcon === item.name;
                return (
                  <button
                    key={item.name}
                    type="button"
                    onClick={() => setSelectedIcon(item.name)}
                    className={`h-11 rounded-2xl flex items-center justify-center transition-all ${
                      isSelected
                        ? 'bg-brand-500 text-white shadow-md shadow-brand-500/25 scale-105'
                        : 'bg-slate-100 dark:bg-surface-dark-subtle text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-surface-dark-variant'
                    }`}
                    title={item.label}
                  >
                    <CategoryIcon iconName={item.name} className="w-5 h-5" />
                  </button>
                );
              })}
            </div>
          </div>

          {/* Submit */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100 dark:border-surface-dark-border">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-surface-dark-subtle"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-brand-500 to-indigo-600 hover:from-brand-600 hover:to-indigo-700 text-white text-xs font-bold shadow-md shadow-brand-500/25 active:scale-95 transition-all"
            >
              {editCategoryId ? 'Update Category' : 'Save Category'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
