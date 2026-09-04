import { receiptHtml } from '../utils/receipt'

/**
 * Browser printing of text tickets. Each job is rendered N times (copies) in a hidden iframe sized for the paper width.
 * Architecture note: PrintJob rows stay in the DB with status PENDING → an ESC/POS print agent can consume them later.
 */
export function printJobs(jobs, template) {
  return new Promise(resolve => {
    const paper = template?.paperWidth || 80
    const widthMm = paper <= 58 ? 58 : 80
    const fontPx = template?.fontSize || 12
    const margin = template?.marginMm ?? 3
    // Le logo passe en noir et blanc : une imprimante thermique n'a qu'une encre, et
    // une image en couleurs y ressort en aplats gris illisibles.
    const logo = template?.showLogo && template?.logoData ? `<img src="${template.logoData}" class="logo">` : ''
    let body = ''
    for (const j of jobs) for (let i = 0; i < Math.max(1, j.copies); i++) body += `<div class="t">${receiptHtml(j.content, logo)}</div>`
    const html = `<!doctype html><html><head><meta charset="utf-8"><title>Ticket</title><style>
      @page { size: ${widthMm}mm auto; margin: ${margin}mm; }
      body { margin: 0; font-family: 'Consolas','Courier New',monospace; font-size: ${fontPx}px; line-height: 1.2; width: ${widthMm - 2 * margin}mm; }
      pre { margin: 0; white-space: pre; font: inherit; }
      pre.big { font-size: 2em; font-weight: 800; line-height: 1.06; }
      .head { display: flex; align-items: center; gap: 3mm; margin-bottom: 1.5mm; }
      .head .logo { flex: none; width: 34%; max-height: 18mm; object-fit: contain; filter: grayscale(1) contrast(1.4); }
      .head-txt { flex: 1; min-width: 0; }
      .head .name { font-size: 1.5em; font-weight: 800; line-height: 1.12; text-align: center; }
      .head .when { margin-top: .5mm; text-align: center; }
      .head .split { display: flex; justify-content: space-between; gap: 2mm; text-align: left; }
      .t { page-break-after: always; break-after: page; padding-bottom: 8mm; }
    </style></head><body>${body}</body></html>`
    const iframe = document.createElement('iframe')
    iframe.style.cssText = 'position:fixed;right:0;bottom:0;width:0;height:0;border:0;visibility:hidden'
    document.body.appendChild(iframe)
    const doc = iframe.contentWindow.document
    doc.open(); doc.write(html); doc.close()
    const done = () => { setTimeout(() => { iframe.remove(); resolve() }, 500) }
    iframe.contentWindow.onafterprint = done
    setTimeout(() => { try { iframe.contentWindow.focus(); iframe.contentWindow.print() } catch { /* ignore */ } setTimeout(done, 1500) }, 250)
  })
}
