/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2D6A4F',
          50: '#F0F7F4',
          100: '#D1EBDF',
          200: '#A3D7BE',
          300: '#74C69D',
          400: '#52B788',
          500: '#2D6A4F',
          600: '#245840',
          700: '#1B4631',
          800: '#122E20',
          900: '#091710',
        },
        secondary: '#74C69D',
        accent: '#F4A261',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
