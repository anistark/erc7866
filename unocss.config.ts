import { defineConfig, presetUno, presetIcons, presetWebFonts } from 'unocss'

export default defineConfig({
  presets: [
    presetUno(),
    presetIcons({
      scale: 1.2,
      warn: true,
      extraProperties: {
        display: 'inline-block',
        'vertical-align': 'middle',
      },
    }),
    presetWebFonts({
      fonts: {
        sans: 'Inter:400,500,600,700',
        mono: 'Fira Code:400,500',
      },
    }),
  ],
  theme: {
    colors: {
      primary: '#6366f1',
      light: '#e0e7ff',
      dark: '#312e81',
    },
  },
})
