/**
 * Vite résout « ../utils/money » sans extension, et « ../api » par son index ;
 * Node exige l'une et l'autre en toutes lettres. Ce crochet essaie donc les deux,
 * dans cet ordre, pour que les modules du dossier src/ se chargent tels quels sous
 * Node, sans étape de compilation — et pour que le harnais résolve ce que Vite
 * résout, faute de quoi un import parfaitement valide fait échouer les tests.
 */
export async function resolve(specifier, context, next) {
  try { return await next(specifier, context) }
  catch (e) {
    if (!/^[./]/.test(specifier) || /\.[a-z]+$/i.test(specifier)) throw e
    try { return await next(specifier + '.js', context) }
    catch (e2) { return next(specifier + '/index.js', context) }
  }
}
