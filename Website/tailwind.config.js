/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          200: '#C7D2FE',
          300: '#A5B4FC',
          400: '#818CF8',
          500: '#4F75FF', // DayPulse primary soft blue
          600: '#4361EE',
          700: '#3858D6',
          800: '#2B42B0',
          900: '#1E2C80',
          DEFAULT: '#4F75FF',
        },
        surface: {
          light: '#FFFFFF',
          'light-subtle': '#F4F7FC',
          'light-variant': '#F0F4F9',
          'light-border': '#E2E8F0',
          dark: '#131A29',
          'dark-bg': '#0B0F19',
          'dark-subtle': '#1A2338',
          'dark-variant': '#1E293B',
          'dark-border': '#2D3748',
        },
        priority: {
          high: '#EF4444',
          medium: '#F59E0B',
          low: '#10B981',
        },
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 4px 20px -2px rgba(79, 117, 255, 0.12)',
        'soft-lg': '0 10px 30px -4px rgba(79, 117, 255, 0.18)',
        'dark-soft': '0 4px 20px -2px rgba(0, 0, 0, 0.4)',
        'dark-soft-lg': '0 10px 30px -4px rgba(0, 0, 0, 0.6)',
      },
      animation: {
        'pulse-subtle': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'fade-in': 'fadeIn 0.2s ease-out forwards',
        'slide-up': 'slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(12px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [],
}
