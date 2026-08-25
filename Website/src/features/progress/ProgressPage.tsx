import React from 'react';
import { StreakHeroCard } from './StreakHeroCard';
import { ProductivityScoreCard } from './ProductivityScoreCard';
import { AnnualHeatmapCard } from './AnnualHeatmapCard';
import { DailyCompletedCard } from './DailyCompletedCard';
import { CategoryDonutCard } from './CategoryDonutCard';
import { FocusMetricsCard } from './FocusMetricsCard';
import { BarChart3 } from 'lucide-react';

export const ProgressPage: React.FC = () => {
  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 md:pb-12 animate-fade-in">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">
          Me & Analytics
        </h2>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
          Your personal productivity pulse, 53-week contribution matrix, and focus metrics
        </p>
      </div>

      {/* Streak Hero Card */}
      <StreakHeroCard />

      {/* Productivity Score Breakdown */}
      <ProductivityScoreCard />

      {/* 53-Week Annual Heatmap */}
      <AnnualHeatmapCard />

      {/* Daily & Category Visualizations */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <DailyCompletedCard />
        <CategoryDonutCard />
      </div>

      {/* Weekly Focus Time Metrics */}
      <FocusMetricsCard />
    </div>
  );
};
