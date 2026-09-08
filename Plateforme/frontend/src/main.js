import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/styles.css'
import { activerSaisieTactile, bloquerMenuContextuel } from './utils/touch-inputs'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')

// Le poste n'a ni clavier ni souris : un champ numerique se corrige au doigt, et
// l'appui long sert a la caisse, pas au navigateur.
activerSaisieTactile()
bloquerMenuContextuel()
