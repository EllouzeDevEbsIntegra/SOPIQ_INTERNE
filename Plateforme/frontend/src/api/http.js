import axios from 'axios'

export const http = axios.create({ baseURL: '/api', timeout: 20000 })

let onUnauthorized = null
export function setUnauthorizedHandler(fn) { onUnauthorized = fn }
export function setToken(token) {
  if (token) http.defaults.headers.common.Authorization = `Bearer ${token}`
  else delete http.defaults.headers.common.Authorization
}

/** Turns any axios error into a human message (never "HTTP 500" when the API explained itself). */
export function errorMessage(e) {
  if (!e) return 'Erreur inconnue.'
  if (e.response) {
    const d = e.response.data
    if (d && d.message) return d.message
    if (e.response.status === 401) return 'Session expirée, veuillez vous reconnecter.'
    if (e.response.status === 403) return "Vous n'avez pas la permission d'effectuer cette action."
    if (e.response.status === 404) return 'Ressource introuvable.'
    return 'Le serveur a renvoyé une erreur (' + e.response.status + ').'
  }
  if (e.code === 'ECONNABORTED') return 'Le serveur ne répond pas (délai dépassé).'
  return 'Impossible de joindre le serveur. Vérifiez la connexion réseau.'
}

http.interceptors.response.use(r => r, e => {
  if (e.response && e.response.status === 401 && onUnauthorized) onUnauthorized()
  e.humanMessage = errorMessage(e)
  return Promise.reject(e)
})
