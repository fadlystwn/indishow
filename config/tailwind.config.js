const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        skenara: {
          background: '#1C1C1E',     // Charcoal Black
          primary: '#9B59B6',        // Electric Crimson
          secondary: '#A8A8A8',      // Ash Gray
          highlightGreen: '#2EFF84', // Neon Green (CTA)
          highlightYellow: '#F3FF6B',// Acid Yellow (CTA alternative)
          text: '#FFFFFF',           // White
        },
      },
    },
  },
  plugins: [
    // require('@tailwindcss/forms'),
    // require('@tailwindcss/typography'),
    // require('@tailwindcss/container-queries'),
  ]
}
