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
        sans: ['"Inter"', ...defaultTheme.fontFamily.sans],
        display: ['"Bebas Neue"', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        music: {
          background: '#0F0F0F',       // Deep black background
          surface: '#1A1A1A',         // Card surfaces
          primary: '#FF4D4D',         // Vibrant red for primary actions
          secondary: '#4D4DFF',       // Electric blue for secondary elements
          accent: '#FFD700',          // Gold for highlights
          text: '#FFFFFF',            // White text
          'text-secondary': '#A0A0A0',// Gray for secondary text
          genre: {                    // Genre-specific colors
            rock: '#FF4D4D',
            pop: '#4D4DFF',
            classical: '#FFD700',
            hiphop: '#9B59B6',
            electronic: '#00FF88',
            indie: '#FF8800',
            world: '#00D2FF',
            latin: '#FF00AA',
            film: '#AAAAAA'
          }
        },
      },
      animation: {
        'pulse-slow': 'pulse 3s ease infinite',
      },
      boxShadow: {
        'genre': '0 4px 14px 0 rgba(0, 0, 0, 0.3)',
        'genre-hover': '0 6px 20px 0 rgba(0, 0, 0, 0.4)',
        'button': '0 2px 10px 0 rgba(255, 77, 77, 0.4)',
      },
      borderRadius: {
        'genre': '12px',
        'button': '20px',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ]
}