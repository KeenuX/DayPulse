import React, { useState, useEffect } from 'react';
import { ThemeProvider } from './core/theme/ThemeContext';
import { initializeSeedData } from './core/db/seedData';
import { Sidebar } from './features/navigation/Sidebar';
import { Navbar } from './features/navigation/Navbar';
import { BottomNav } from './features/navigation/BottomNav';
import { CommandPalette } from './features/navigation/CommandPalette';

import { TodayPage } from './features/today/TodayPage';
import { TasksPage } from './features/tasks/TasksPage';
import { CalendarPage } from './features/calendar/CalendarPage';
import { ProgressPage } from './features/progress/ProgressPage';
import { TomorrowPlannerPage } from './features/planner/TomorrowPlannerPage';
import { CategoriesPage } from './features/categories/CategoriesPage';
import { SettingsPage } from './features/settings/SettingsPage';

import { CreateEditTaskModal } from './features/tasks/CreateEditTaskModal';
import { TaskDetailModal } from './features/tasks/TaskDetailModal';
import { RescheduleModal } from './features/tasks/RescheduleModal';
import { CategoryEditorModal } from './features/categories/CategoryEditorModal';
import { DeleteCategoryModal } from './features/categories/DeleteCategoryModal';
import { DailySummaryModal } from './features/planner/DailySummaryModal';
import { AppDateUtils } from './core/utilities/dateUtils';

export function AppContent() {
  const [currentTab, setCurrentTab] = useState<string>('today');

  // Modal States
  const [isCreateTaskOpen, setIsCreateTaskOpen] = useState(false);
  const [editingTaskId, setEditingTaskId] = useState<string | null>(null);
  const [taskDetailId, setTaskDetailId] = useState<string | null>(null);
  const [rescheduleTaskId, setRescheduleTaskId] = useState<string | null>(null);
  const [initialTaskDate, setInitialTaskDate] = useState<string | undefined>(undefined);

  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [editingCategoryId, setEditingCategoryId] = useState<string | null>(null);
  const [deletingCategoryId, setDeletingCategoryId] = useState<string | null>(null);

  const [isDailySummaryOpen, setIsDailySummaryOpen] = useState(false);
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false);
  const [selectedCategoryFilter, setSelectedCategoryFilter] = useState<string | null>(null);

  // Initialize Seed Data on startup
  useEffect(() => {
    initializeSeedData();
  }, []);

  // Global Keyboard Shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ctrl+K / Cmd+K -> Command Palette
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        setIsCommandPaletteOpen(prev => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Task Action Handlers
  const handleOpenCreateTask = (presetDate?: string) => {
    setEditingTaskId(null);
    setInitialTaskDate(presetDate || AppDateUtils.toIsoDate(new Date()));
    setIsCreateTaskOpen(true);
  };

  const handleEditTask = (taskId: string) => {
    setEditingTaskId(taskId);
    setIsCreateTaskOpen(true);
  };

  const handleSelectTask = (taskId: string) => {
    setTaskDetailId(taskId);
  };

  const handleRescheduleTask = (taskId: string) => {
    setRescheduleTaskId(taskId);
  };

  // Category Action Handlers
  const handleOpenCreateCategory = () => {
    setEditingCategoryId(null);
    setIsCategoryModalOpen(true);
  };

  const handleEditCategory = (catId: string) => {
    setEditingCategoryId(catId);
    setIsCategoryModalOpen(true);
  };

  const handleDeleteCategory = (catId: string) => {
    setDeletingCategoryId(catId);
  };

  const handleSelectCategoryFromNav = (catId: string | null) => {
    setSelectedCategoryFilter(catId);
    setCurrentTab('tasks');
  };

  return (
    <div className="min-h-screen bg-[#F4F7FC] dark:bg-[#0B0F19] text-slate-800 dark:text-slate-100 flex transition-colors duration-200">
      {/* Desktop / Tablet Sidebar */}
      <Sidebar
        currentTab={currentTab}
        onSelectTab={tab => {
          if (tab !== 'tasks') setSelectedCategoryFilter(null);
          setCurrentTab(tab);
        }}
        onOpenCreateTask={() => handleOpenCreateTask()}
        onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
        onSelectCategory={catId => handleSelectCategoryFromNav(catId)}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 min-h-screen">
        {/* Top Navbar */}
        <Navbar
          onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
          onOpenDailySummary={() => setIsDailySummaryOpen(true)}
        />

        {/* Dynamic Main Page Content */}
        <main className="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto">
          {currentTab === 'today' && (
            <TodayPage
              onSelectTask={handleSelectTask}
              onEditTask={handleEditTask}
              onRescheduleTask={handleRescheduleTask}
              onOpenCreateTask={() => handleOpenCreateTask()}
              onOpenDailySummary={() => setIsDailySummaryOpen(true)}
            />
          )}

          {currentTab === 'tasks' && (
            <TasksPage
              onSelectTask={handleSelectTask}
              onEditTask={handleEditTask}
              onRescheduleTask={handleRescheduleTask}
              onOpenCreateTask={() => handleOpenCreateTask()}
              initialCategoryFilter={selectedCategoryFilter}
            />
          )}

          {currentTab === 'calendar' && (
            <CalendarPage
              onSelectTask={handleSelectTask}
              onEditTask={handleEditTask}
              onRescheduleTask={handleRescheduleTask}
              onOpenCreateTaskForDate={dateStr => handleOpenCreateTask(dateStr)}
            />
          )}

          {currentTab === 'progress' && <ProgressPage />}

          {currentTab === 'planner' && (
            <TomorrowPlannerPage
              onSelectTask={handleSelectTask}
              onEditTask={handleEditTask}
              onRescheduleTask={handleRescheduleTask}
              onOpenCreateTaskForDate={dateStr => handleOpenCreateTask(dateStr)}
            />
          )}

          {currentTab === 'categories' && (
            <CategoriesPage
              onOpenCreateCategory={handleOpenCreateCategory}
              onOpenEditCategory={handleEditCategory}
              onOpenDeleteCategory={handleDeleteCategory}
              onSelectCategoryFilter={catId => handleSelectCategoryFromNav(catId)}
            />
          )}

          {currentTab === 'settings' && <SettingsPage />}
        </main>
      </div>

      {/* Mobile Bottom Navigation */}
      <BottomNav
        currentTab={currentTab}
        onSelectTab={setCurrentTab}
        onOpenCreateTask={() => handleOpenCreateTask()}
      />

      {/* Global Modals & Dialogs */}
      <CreateEditTaskModal
        isOpen={isCreateTaskOpen}
        onClose={() => setIsCreateTaskOpen(false)}
        editTaskId={editingTaskId}
        initialDate={initialTaskDate}
        onOpenCreateCategory={handleOpenCreateCategory}
      />

      <TaskDetailModal
        isOpen={!!taskDetailId}
        onClose={() => setTaskDetailId(null)}
        taskId={taskDetailId}
        onEdit={handleEditTask}
        onReschedule={handleRescheduleTask}
      />

      <RescheduleModal
        isOpen={!!rescheduleTaskId}
        onClose={() => setRescheduleTaskId(null)}
        taskId={rescheduleTaskId}
      />

      <CategoryEditorModal
        isOpen={isCategoryModalOpen}
        onClose={() => setIsCategoryModalOpen(false)}
        editCategoryId={editingCategoryId}
      />

      <DeleteCategoryModal
        isOpen={!!deletingCategoryId}
        onClose={() => setDeletingCategoryId(null)}
        categoryId={deletingCategoryId}
      />

      <DailySummaryModal
        isOpen={isDailySummaryOpen}
        onClose={() => setIsDailySummaryOpen(false)}
        onNavigateToPlanner={() => setCurrentTab('planner')}
      />

      <CommandPalette
        isOpen={isCommandPaletteOpen}
        onClose={() => setIsCommandPaletteOpen(false)}
        onNavigate={tab => setCurrentTab(tab)}
        onOpenCreateTask={() => handleOpenCreateTask()}
        onOpenCreateCategory={handleOpenCreateCategory}
        onOpenDailySummary={() => setIsDailySummaryOpen(true)}
        onSelectTask={handleSelectTask}
      />
    </div>
  );
}

export default function App() {
  return (
    <ThemeProvider>
      <AppContent />
    </ThemeProvider>
  );
}
