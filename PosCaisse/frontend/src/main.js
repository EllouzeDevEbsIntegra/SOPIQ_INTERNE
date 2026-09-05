import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/styles.css'
import { activerSaisieTactile } from './utils/touch-inputs'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')

// Le poste n'a ni clavier ni souris : un champ numerique se corrige au doigt.
activerSaisieTactile()
