/**
 * Vite résout « ../utils/money » sans extension ; Node exige la sienne.
 * Ce crochet ajoute « .js » quand la résolution échoue, pour que les modules du
 * dossier src/ se chargent tels quels sous Node, sans étape de compilation.
 */
export async function resolve(specifier, context, next) {
  try { return await next(specifier, context) }
  catch (e) {
    if (/^[./]/.test(specifier) && !/\.[a-z]+$/i.test(specifier)) return next(specifier + '.js', context)
    throw e
  }
}
