/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js}'],
  theme: {
    extend: {
      colors: {
        woot: {
          25: '#f4faff',
          50: '#e8f4ff',
          100: '#c5e2ff',
          200: '#9eceff',
          300: '#77baff',
          400: '#59abff',
          500: '#3b9eff',
          600: '#0090ff',
          700: '#2870bd',
          800: '#1a5a9e',
          900: '#0e3f73',
        },
        slate: {
          25: '#f9f9fb',
        },
      },
    },
  },
  plugins: [],
}
