/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#0E0703',
        'bg-deep': '#08040A',
        surface: '#1A0F0A',
        'surface-2': '#251812',
        'surface-3': '#2F1F17',
        primary: '#E8854A',
        'primary-soft': '#F5A574',
        'primary-deep': '#C26835',
        cream: '#F5E6D3',
        success: '#6EE7A7',
        danger: '#F87171',
        warning: '#FBBF24',
      },
      fontFamily: {
        sans: ['"Noto Sans Lao"', 'sans-serif'],
        display: ['"Noto Serif Lao"', 'serif'],
        body: ['"Noto Sans Lao"', 'sans-serif'],
        mono: ['Manrope', 'monospace'],
      },
    },
  },
  plugins: [],
}
