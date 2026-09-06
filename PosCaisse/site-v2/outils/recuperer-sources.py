from pathlib import Path
import json, urllib.request, concurrent.futures, hashlib
base = Path(r'D:/SOPIQ_INTERNE_POS/PosCaisse/site-v2')
source = Path(r'D:/SOPIQ_INTERNE_POS/PosCaisse/site')
before = {str(p.relative_to(source)): hashlib.sha256(p.read_bytes()).hexdigest() for p in source.rglob('*') if p.is_file()}
(base/'outils'/'source-originale.sha256.json').write_text(json.dumps(before, indent=2), encoding='utf-8')
menu = json.loads((base/'carte.json').read_text(encoding='utf-8'))
root = 'https://raw.githubusercontent.com/EllouzeDevEbsIntegra/SOPIQ_INTERNE/claude/poscaisse-full-app-omsdd4/'
assets = [(a['photo'], root+'PosCaisse/site/'+a['photo']) for c in menu['categories'] for a in c['articles']]
assets += [('img/logo-number-one.png', root+'img/logo-number-one.png'), ('fonts/BarlowCondensed-Bold.ttf', 'https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-Bold.ttf'), ('fonts/BarlowCondensed-OFL.txt', 'https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/OFL.txt'), ('fonts/DMSans.ttf', 'https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans/DMSans%5Bopsz,wght%5D.ttf'), ('fonts/DMSans-OFL.txt', 'https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans/OFL.txt')]
def download(asset):
    name, url = asset
    try:
        data = urllib.request.urlopen(url, timeout=25).read()
        (base/name).write_bytes(data)
        return name, len(data)
    except Exception as exc:
        return name, str(exc)
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
    results = list(pool.map(download, assets))
print(json.dumps({'downloads':len(results), 'failures':[r for r in results if not isinstance(r[1], int)], 'bytes':sum(r[1] for r in results if isinstance(r[1],int))}, indent=2))
