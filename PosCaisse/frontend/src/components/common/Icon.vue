<script setup>
/**
 * Jeu d'icônes vectorielles (contour 24×24, trait 1.75).
 * Un logiciel commercial n'affiche pas d'emoji dans son propre chrome :
 * les icônes s'alignent sur la typographie et héritent de la couleur du texte.
 */
const P = {
  menu: 'M4 7h16M4 12h16M4 17h16',
  close: 'M6 6l12 12M18 6L6 18',
  search: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4.3-4.3',
  cart: 'M3 4h2l2.4 11.2a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.6L21 8H6M10 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM18 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2z',
  plus: 'M12 5v14M5 12h14',
  minus: 'M5 12h14',
  trash: 'M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13M10 11v6M14 11v6',
  pause: 'M9 5v14M15 5v14',
  play: 'M7 4l12 8-12 8z',
  clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3.5 2',
  user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z',
  users: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8',
  printer: 'M6 9V3h12v6M6 18H4a1 1 0 0 1-1-1v-6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v6a1 1 0 0 1-1 1h-2M6 14h12v7H6z',
  receipt: 'M6 3h12a1 1 0 0 1 1 1v17l-3-2-2 2-2-2-2 2-2-2-3 2V4a1 1 0 0 1 1-1zM9 8h6M9 12h6',
  cash: 'M2 6h20v12H2zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6 9v.01M18 15v.01',
  card: 'M2 6h20v12H2zM2 10h20M6 15h4',
  coins: 'M9 14a6 6 0 1 0 0-12 6 6 0 0 0 0 12zM15.5 8.1A6 6 0 1 1 9 20.9',
  percent: 'M19 5L5 19M7.5 10a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5zM16.5 19a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
  tag: 'M20 12.5L12.5 20a2 2 0 0 1-2.8 0L3 13.2V4a1 1 0 0 1 1-1h9.2l6.8 6.7a2 2 0 0 1 0 2.8zM7.5 8v.01',
  star: 'M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.7l5.9-.8z',
  grid: 'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z',
  layers: 'M12 3l9 5-9 5-9-5 9-5zM3 13l9 5 9-5M3 17l9 5 9-5',
  copy: 'M9 9h10a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V10a1 1 0 0 1 1-1zM5 15H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v1',
  box: 'M21 8.5v7a2 2 0 0 1-1 1.7l-7 4a2 2 0 0 1-2 0l-7-4a2 2 0 0 1-1-1.7v-7a2 2 0 0 1 1-1.7l7-4a2 2 0 0 1 2 0l7 4a2 2 0 0 1 1 1.7zM3.5 7.5L12 12.3l8.5-4.8M12 21v-8.7',
  list: 'M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01',
  book: 'M4 4.5A2.5 2.5 0 0 1 6.5 2H20v18H6.5A2.5 2.5 0 0 0 4 22zM4 19.5A2.5 2.5 0 0 1 6.5 17H20',
  chart: 'M4 20V10M10 20V4M16 20v-7M22 20H2',
  trend: 'M3 17l6-6 4 4 8-8M15 7h6v6',
  settings: 'M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-2.9 1.2v.2a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-3-1.2l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0-1.2-2.9H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.4 7l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 2.9-1.2V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 2.9 1.2l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0 1.2 2.9h.2a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.6 1z',
  sliders: 'M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6',
  shield: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10zM9 12l2 2 4-4',
  lock: 'M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4',
  store: 'M3 9l1.5-5h15L21 9M4 9h16v11H4zM9 20v-6h6v6M3 9a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0',
  moon: 'M21 13A9 9 0 1 1 11 3a7 7 0 0 0 10 10z',
  calendar: 'M4 6h16v15H4zM4 10h16M8 3v4M16 3v4',
  refresh: 'M21 12a9 9 0 1 1-3-6.7M21 4v5h-5',
  download: 'M12 3v12M7.5 10.5L12 15l4.5-4.5M4 20h16',
  edit: 'M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4z',
  note: 'M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8zM14 3v5h5M9 13h6M9 17h4',
  eye: 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  logout: 'M15 17l5-5-5-5M20 12H9M12 3H5a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h7',
  check: 'M4 12.5l5 5L20 6.5',
  warning: 'M12 3l9.5 17H2.5zM12 9v5M12 17.5v.01',
  info: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5M12 7.5v.01',
  chevronRight: 'M9 5l7 7-7 7',
  chevronLeft: 'M15 5l-7 7 7 7',
  chevronDown: 'M5 9l7 7 7-7',
  arrowLeft: 'M20 12H4M10 6l-6 6 6 6',
  arrowRight: 'M4 12h16M14 6l6 6-6 6',
  arrowUp: 'M12 20V4M6 10l6-6 6 6',
  arrowDown: 'M12 4v16M6 14l6 6 6-6',
  utensils: 'M6 3v8a2 2 0 0 0 4 0V3M8 11v10M17 3c-1.5 1.5-2 3.5-2 6v3h4V3z',
  bag: 'M6 7h12l1 14H5zM9 10V6a3 3 0 0 1 6 0v4',
  truck: 'M3 6h11v10H3zM14 9h4l3 3v4h-7zM7.5 19a1.8 1.8 0 1 0 0-3.6 1.8 1.8 0 0 0 0 3.6zM17.5 19a1.8 1.8 0 1 0 0-3.6 1.8 1.8 0 0 0 0 3.6z',
  drawer: 'M3 5h18v14H3zM3 12h18M8 8.5h8M9.5 15.5h5'
}
defineProps({
  name: { type: String, required: true },
  size: { type: [Number, String], default: 20 },
  stroke: { type: [Number, String], default: 1.75 }
})
</script>
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" :stroke-width="stroke"
       stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">
    <path :d="P[name] || P.info" />
  </svg>
</template>
