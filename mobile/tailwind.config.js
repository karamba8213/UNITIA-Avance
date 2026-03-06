/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2D6A4F',
          50: '#F0F7F4',
          100: '#D1EBDF',
          400: '#52B788',
          500: '#2D6A4F',
          600: '#245840',
        },
        accent: '#F4A261',
        secondary: '#74C69D',
      },
    },
  },
  plugins: [],
}
