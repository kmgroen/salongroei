/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: "class",
  theme: {
      extend: {
          colors: {
              "primary": "#ff8370",
              "background-light": "#FFF8F0",
              "background-dark": "#23120f",
              "expert-navy": "#1E3A5F",
              "soft-sage": "#B4C7B0",
              "sunshine-yellow": "#FFD93D",
              "friendly-coral": "#ff8370",
          },
          fontFamily: {
              "display": ["Noto Serif", "serif"],
              "sans": ["Noto Sans", "sans-serif"]
          },
          borderRadius: {"DEFAULT": "0.5rem", "lg": "1rem", "xl": "1.5rem", "full": "9999px"},
      },
  },
  plugins: [],
}