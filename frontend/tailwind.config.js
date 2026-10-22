/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#F27F0D',
          light: '#F5A04D',
          bg: '#FFF3E8',
          dark: '#D96A00',
        },
        surface: '#FFFFFF',
        background: '#F8F6F5',
        border: '#E6E0DB',
        muted: '#8A7560',
        brand: '#2D6A4F',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Manrope', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
