package com.poscaisse.config;

/**
 * Page affichée lorsqu'aucun build du frontend n'est présent (frontend/dist n'est pas versionné).
 * Évite un « 404 Ressource introuvable » incompréhensible au premier démarrage.
 */
public final class FrontendPlaceholder {
    private FrontendPlaceholder() {}

    public static String html() {
        return """
            <!doctype html><html lang="fr"><head><meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>PosCaisse — interface non compilée</title>
            <style>body{font-family:'Segoe UI',system-ui,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;align-items:center;
            justify-content:center;min-height:100vh;margin:0;padding:24px}.c{max-width:660px;background:#1e293b;border-radius:16px;padding:32px;
            box-shadow:0 20px 50px rgba(0,0,0,.4)}h1{margin:0 0 12px;font-size:26px}p{color:#94a3b8;line-height:1.6}
            code{display:block;background:#0f172a;color:#fdba74;padding:12px 16px;border-radius:8px;margin:10px 0;font-family:Consolas,monospace;
            white-space:pre;overflow-x:auto}b{color:#fff}.ok{color:#4ade80;font-weight:600}</style></head><body><div class="c">
            <h1>🧾 PosCaisse</h1>
            <p class="ok">✓ Le backend fonctionne : API et base de données opérationnelles.</p>
            <p>L'<b>interface n'a pas encore été compilée</b> : le dossier <b>frontend/dist</b> est absent
            (les fichiers de build ne sont pas versionnés dans Git).</p>
            <p><b>Option 1 — mode développement</b> (rechargement automatique), dans une autre fenêtre :</p>
            <code>cd frontend
            npm install
            npm run dev</code>
            <p>puis ouvrez <b>http://localhost:5173</b></p>
            <p><b>Option 2 — un seul port</b> : compilez l'interface, redémarrez le backend, puis rechargez cette page :</p>
            <code>cd frontend
            npm install
            npm run build</code>
            <p>Le script <b>START_POS.bat</b> choisit automatiquement l'option adaptée.</p>
            </div></body></html>""";
    }
}
