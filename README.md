Live on-> https://daypulse.antideploy.com/

# 🌟 DayPulse — Modern Daily Planner & Habit Tracker

[![Live Web App](https://img.shields.io/badge/Live%20Web%20App-daypulse.antideploy.com-6366F1?style=for-the-badge&logo=googlechrome&logoColor=white)](https://daypulse.antideploy.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![React](https://img.shields.io/badge/React-19.x-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Vite](https://img.shields.io/badge/Vite-6.x-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![State Management](https://img.shields.io/badge/Riverpod-2.x-8A2BE2?style=for-the-badge)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/SQLite%20%7C%20IndexedDB-Offline--First-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://pub.dev/packages/sqflite)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

**DayPulse** is a feature-rich, privacy-focused personal productivity suite available for **Mobile (Flutter)** and **Web (React 19 + TypeScript + Vite)**. It combines task management, zero-bloat recurring task synthesis, 53-week annual contribution heatmap analytics, high-priority notifications, and custom category workflows into a unified, seamless experience.

🌐 **Live Web App**: [https://daypulse.antideploy.com](https://daypulse.antideploy.com) · [Website Documentation](Website/README.md)

---

## 📸 Visual Showcase & Web Screenshots

### 1. Today Command Center (OLED Dark & Crisp Light Theme)
> Real-time progress pulse ring, Natural Language quick-add bar, and time-block slotting (*Morning, Afternoon, Evening*).

| Dark Theme (OLED) | Light Theme |
| :---: | :---: |
| ![Today Dashboard Dark](Website/screenshots/01_today_dashboard.png) | ![Today Dashboard Light](Website/screenshots/06_light_theme.png) |

---

### 2. "Me" Productivity Hub & 53-Week Annual Contribution Heatmap
> 53-week Sunday-aligned activity matrix, Category Donut chart, Weekly Focus time analytics, and compact expandable upcoming tasks.

<div align="center">
  <img src="Website/screenshots/04_me_analytics.png" alt="Me Screen & Annual Heatmap Analytics" width="92%" />
</div>

---

### 3. 7-Column Calendar Matrix & Task Management
> Seamless navigation between Month, Week, and Day views with category indicators and quick filtering.

| 7-Column Calendar Month Matrix | Filtered Task Hub |
| :---: | :---: |
| ![Calendar Month Grid](Website/screenshots/02_calendar_view.png) | ![Task Management](Website/screenshots/03_tasks_page.png) |

---

### 4. Evening Review (Plan Tomorrow) & Mobile PWA Responsive View
> Wrap up daily accomplishments, clear backlogs, and set top 3 priorities for tomorrow on desktop and mobile.

| Evening Review & Tomorrow Planner | Mobile PWA Responsive View |
| :---: | :---: |
| ![Plan Tomorrow Planner](Website/screenshots/05_planner_page.png) | <img src="Website/screenshots/07_mobile_responsive.png" alt="Mobile Responsive Experience" width="340px" /> |

---

## ✨ Key Features

- **⚡ Natural Language Task Parser**: Type naturally like `"Meeting tomorrow at 3pm !high for 30m"` to automatically extract date, time, priority, and duration.
- **🔒 100% Local & Privacy-First**: All data is stored locally in client-side storage (**SQLite** on Mobile, **IndexedDB / Dexie.js** on Web). No tracking, zero telemetry.
- **📊 53-Week GitHub-Style Heatmap**: Visualize streaks and annual consistency with Sunday-aligned activity cells and interactive tooltips.
- **🔁 Zero-Bloat Recurring Engine**: Dynamic on-the-fly recurrence calculation (`Daily`, `Weekdays`, `Weekends`, `Weekly`, `Monthly`, `Custom`) without polluting database rows.
- **📅 7-Column Calendar Matrix**: Interactive month grid, week timeline, and day schedule views with category color dots.
- **🎯 Hierarchical Subtasks**: Direct subtask creation, progress tracking, and bidirectional completion synchronization.
- **🔔 High-Priority Alarms & Reminders**: Exact alarms and notifications with configurable offsets (`5m`, `10m`, `30m`, `1h`) and 14-day recurring lookahead.
- **🌙 Fluid OLED Dark & Light Themes**: Hand-crafted themes with glassmorphism effects and modern typography.
- **📥 One-Click Backup & Restore**: Instant JSON backup export and import for hassle-free data portability.

---

## 🏗️ Architecture & Technology Stack

### 📱 1. Mobile App (Flutter & Dart)

```
lib/
├── core/
│   ├── database/        # SQLite migration v3, table definitions, DAO
│   ├── notifications/   # High-priority alert channels & exact alarms
│   ├── preferences/     # User preferences & theme persistence
│   ├── routing/         # GoRouter navigation shell & route declarations
│   ├── theme/           # Dark/Light theme design tokens & palettes
│   └── utilities/       # Date calculations, natural language parsers
└── features/
    ├── calendar/        # Month grid, week & day timeline widgets, filter state
    ├── categories/      # Category models, repositories, and editor sheets
    ├── onboarding/      # Welcome flow and permission triggers
    ├── planner/         # Tomorrow planner & evening review workflows
    ├── progress/        # 53-week heatmap, focus table, category donut charts
    ├── settings/        # App configuration, backup & restore
    ├── tasks/           # Task models, recurrence engine, cards & sheets
    └── today/           # Time-slot sections, quick add, daily overview
```

| Component | Technology |
| :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev) (Dart 3.x) |
| **State Management** | [Flutter Riverpod 2.x](https://riverpod.dev) |
| **Local Database** | [Sqflite](https://pub.dev/packages/sqflite) (SQLite v3) + [SharedPreferences](https://pub.dev/packages/shared_preferences) |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) |
| **Charts** | [fl_chart](https://pub.dev/packages/fl_chart) |
| **Notifications** | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) + [timezone](https://pub.dev/packages/timezone) |

---

### 🌐 2. Web App (React 19, TypeScript & Vite)

```
Website/
├── src/
│   ├── core/
│   │   ├── db/            # Dexie.js IndexedDB schema, seed data, live hooks
│   │   ├── notifications/ # Web Notification API service
│   │   ├── sound/         # Sound effect audio synthesizers
│   │   ├── theme/         # ThemeContext provider & dark mode tokens
│   │   └── utilities/     # NLP parser, date formatting, score calculators
│   ├── features/
│   │   ├── calendar/      # MonthGridView, WeekTimelineView, DayTimelineView
│   │   ├── categories/    # CategoriesPage, CategoryEditorModal, Icons
│   │   ├── navigation/    # Sidebar, BottomNav, CommandPalette (Ctrl+K)
│   │   ├── planner/       # TomorrowPlannerPage, DailySummaryModal
│   │   ├── progress/      # AnnualHeatmapCard, Next7DaysTasksCard, Donut
│   │   ├── tasks/         # TasksPage, TaskCard, SubtasksList, TaskModal
│   │   └── today/         # TodayPage, TodayHeaderCard, QuickAddBar
│   └── types/             # TypeScript definitions (Task, Category, Recurrence)
└── public/
    ├── sitemap.xml        # Search Engine XML Sitemap
    ├── robots.txt         # Crawler indexing rules
    └── manifest.json      # PWA application manifest
```

| Component | Technology |
| :--- | :--- |
| **Framework** | [React 19](https://react.dev) + [TypeScript 5](https://www.typescriptlang.org) |
| **Build Tool** | [Vite 6](https://vitejs.dev) |
| **Styling** | [Tailwind CSS 3.4](https://tailwindcss.com) + Custom CSS Design System |
| **Client Database** | [Dexie.js 4](https://dexie.org) (IndexedDB) with `useLiveQuery` reactive hooks |
| **Icons & UI** | [Lucide React](https://lucide.dev) + [Framer Motion](https://www.framer.com/motion/) |
| **Delight** | [Canvas Confetti](https://www.npmjs.com/package/canvas-confetti) |
| **E2E Testing** | [Playwright](https://playwright.dev) |
| **Hosting & CI/CD** | [Antideploy](https://antideploy.com) + GitHub Actions |

---

## 🚀 Getting Started

### 📱 1. Running Mobile App (Flutter)

#### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.22.0` or higher
- Android Studio / Xcode
- Java 17+

```bash
# Clone the repository
git clone https://github.com/KeenuX/DayPulse.git
cd DayPulse

# Install dependencies
flutter pub get

# Run unit test suite
flutter test

# Launch mobile application
flutter run

# Build release APK
flutter build apk --split-per-abi --release
```

---

### 🌐 2. Running Web App (React + Vite)

#### Prerequisites
- Node.js 18+ or 20+
- npm / pnpm

```bash
# Navigate to Website directory
cd Website

# Install dependencies
npm install

# Run local development server
npm run dev
# -> http://localhost:5173

# Build production bundle
npm run build
```

---

## 🚢 Web Deployment

The web app is deployed directly to **Antideploy** and can also be hosted on Docker, Vercel, or Netlify:

```bash
# Antideploy Deployment
cd Website
tar -czf project.tar.gz --exclude=.git --exclude=node_modules --exclude=project.tar.gz .
curl -sS -X POST "https://antideploy.com/api/v1/deploy" \
  -H "Authorization: Bearer <YOUR_API_KEY>" \
  -F "archive=@project.tar.gz"
```

---

## 🧪 Automated Testing

### Mobile Unit Tests (Flutter)
```bash
flutter test
# Output: 23/23 tests passed!
```

### Web End-to-End Tests (Playwright)
```bash
npx playwright test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
