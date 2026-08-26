<div align="center">

# ⚡ DayPulse Web — Daily Planner & Habit Tracker

**A modern, lightning-fast, privacy-first daily planner, habit tracker, and productivity dashboard.**

[![Live Web App](https://img.shields.io/badge/Live%20App-daypulse.antideploy.com-6366F1?style=for-the-badge&logo=googlechrome&logoColor=white)](https://daypulse.antideploy.com)
[![React](https://img.shields.io/badge/React-19.x-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Vite](https://img.shields.io/badge/Vite-6.x-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](../LICENSE)

<br/>

👉 **[Launch Live Web App](https://daypulse.antideploy.com)** 👈

</div>

---

## 📸 Screenshots & Visual Walkthrough

### 1. Today Command Center (Dark & Light Theme)
> Dynamic progress pulse ring, NLP quick-add bar, and time-block morning / afternoon / evening task slots.

| Dark Theme (OLED) | Light Theme |
| :---: | :---: |
| ![Today Dashboard Dark](screenshots/01_today_dashboard.png) | ![Today Dashboard Light](screenshots/06_light_theme.png) |

---

### 2. Me Screen, 53-Week Annual Heatmap & Analytics
> Complete productivity hub featuring a 53-week Sunday-aligned activity matrix, Category Donut chart, Weekly Focus time bars, and compact expandable upcoming tasks.

<div align="center">
  <img src="screenshots/04_me_analytics.png" alt="Me Screen & Annual Heatmap Analytics" width="90%" />
</div>

---

### 3. Interactive 7-Column Calendar Matrix & Task Management
> Switch seamlessly between Month, Week, and Day views with visual category color dots and real-time scheduling.

| 7-Column Calendar Matrix | Filtered Task Hub |
| :---: | :---: |
| ![Calendar Month Grid](screenshots/02_calendar_view.png) | ![Task Management](screenshots/03_tasks_page.png) |

---

### 4. Plan Tomorrow & Mobile Responsive Experience
> Evening review workflow to wrap up today's accomplishments and set top priorities for tomorrow. Fully responsive across desktop, tablet, and mobile.

| Evening Review & Tomorrow Planner | Mobile PWA View |
| :---: | :---: |
| ![Plan Tomorrow Planner](screenshots/05_planner_page.png) | <img src="screenshots/07_mobile_responsive.png" alt="Mobile Responsive Experience" width="360px" /> |

---

## ✨ Key Features

- **⚡ Natural Language Task Parser**: Type naturally like `"Review roadmap tomorrow at 3pm !high for 45m"` to automatically extract date, time, priority, and duration.
- **🔒 100% Local & Privacy-First**: All your data is stored locally in your browser using **IndexedDB (Dexie.js)**. No servers, no tracking, zero telemetry.
- **📊 53-Week GitHub-Style Heatmap**: Visualize your productivity streak and consistency across all 365 days with hoverable completion tooltips.
- **🔄 Smart Recurrence Engine**: Support for Daily, Weekday, Weekend, Weekly, and Monthly recurring habits with independent daily occurrence tracking.
- **🎯 Time-Block Slotting**: Automatically groups your schedule into Morning, Afternoon, Evening, and Anytime sections.
- **🌙 Fluid Dark / Light Modes**: Hand-crafted dark theme with glassmorphism effects and clean typography.
- **📥 Backup & Restore**: Instant one-click JSON export and import for seamless cross-device migration.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | [React 19](https://react.dev) + [TypeScript](https://www.typescriptlang.org) |
| **Build Tool** | [Vite 6](https://vitejs.dev) |
| **Styling** | [Tailwind CSS 3.4](https://tailwindcss.com) + Custom CSS Variables |
| **Local Database** | [Dexie.js](https://dexie.org) (IndexedDB Wrapper) with Live Query React Hooks |
| **Icons** | [Lucide React](https://lucide.dev) |
| **Delight & Confetti** | [Canvas Confetti](https://www.npmjs.com/package/canvas-confetti) |
| **Hosting** | [Antideploy](https://antideploy.com) |

---

## 🚀 Getting Started Locally

### Prerequisites
- Node.js 18+ or 20+
- npm or pnpm

### Installation

```bash
# 1. Navigate to the Website directory
cd Website

# 2. Install dependencies
npm install

# 3. Start the local development server
npm run dev
```

The app will start at `http://localhost:5173`.

### Production Build

```bash
npm run build
```

This compiles the static single-page application into `dist/` ready for zero-config static hosting.

---

## 🚢 Deployment

The website is configured for instant deployment to **Antideploy**, **Docker / Nginx**, **Vercel**, or **Netlify**:

```bash
# Antideploy Deployment
tar -czf project.tar.gz --exclude=.git --exclude=node_modules --exclude=project.tar.gz .
curl -sS -X POST "https://antideploy.com/api/v1/deploy" \
  -H "Authorization: Bearer <YOUR_API_KEY>" \
  -F "archive=@project.tar.gz"
```

---

<div align="center">
  <sub>Built with ❤️ for focused productivity. Part of the <a href="../README.md">DayPulse Ecosystem</a>.</sub>
</div>
