const TZ = 'Africa/Tunis'
export function fmtDateTime(v) { if (!v) return ''; return new Date(v).toLocaleString('fr-FR', { timeZone: TZ, day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }) }
export function fmtDate(v) { if (!v) return ''; return new Date(v).toLocaleDateString('fr-FR', { timeZone: TZ, day: '2-digit', month: '2-digit', year: 'numeric' }) }
export function fmtTime(v) { if (!v) return ''; return new Date(v).toLocaleTimeString('fr-FR', { timeZone: TZ, hour: '2-digit', minute: '2-digit' }) }
export function isoDate(d = new Date()) { const p = new Intl.DateTimeFormat('en-CA', { timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit' }).format(d); return p }
export function addDays(iso, n) { const d = new Date(iso + 'T12:00:00'); d.setDate(d.getDate() + n); return d.toISOString().slice(0, 10) }
export function startOfDayIso(iso) { return new Date(iso + 'T00:00:00+01:00').toISOString() }
export function endOfDayIso(iso) { return new Date(addDays(iso, 1) + 'T00:00:00+01:00').toISOString() }
export function firstOfMonth(iso) { return iso.slice(0, 8) + '01' }
export function startOfWeek(iso) { const d = new Date(iso + 'T12:00:00'); const day = (d.getDay() + 6) % 7; d.setDate(d.getDate() - day); return d.toISOString().slice(0, 10) }
