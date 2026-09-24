package com.poscaisse.service;

import com.poscaisse.domain.Product;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.ProductRepo;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Les codes-barres d'un article : les nettoyer, et refuser qu'un code serve deux fois.
 *
 * POURQUOI CETTE CLASSE EXISTE. La meme regle s'applique a trois endroits - la fiche
 * article, l'import de carte, et le jour ou un ecran de stock en posera. Ecrite trois
 * fois, elle aurait diverge au premier correctif : c'est exactement ce qui est arrive aux
 * gestes PostgreSQL de la plateforme, ecrits deux fois avant d'etre reunis.
 *
 * LE DOUBLON EST LA SEULE VRAIE FAUTE. Un code porte par deux articles rend le scan
 * ambigu : la douchette en choisit un, toujours le meme, et l'autre devient invendable
 * sans que rien ne le signale. Le refus est donc net, et il NOMME l'article fautif - un
 * message qui dit seulement << code deja utilise >> oblige a chercher dans quinze mille
 * lignes.
 */
public final class CodesBarres {
    private CodesBarres() {}

    /** Le separateur stocke. Un code n'a que des chiffres : rien a echapper. Voir V19. */
    public static final String SEPARATEUR = " ";

    /**
     * Nettoyer une liste recue : on retire les vides, les espaces, et les doublons INTERNES.
     *
     * Les doublons internes ne sont pas une erreur de l'utilisateur mais une banalite des
     * exports - le meme EAN revient sur deux lignes du fichier source. Les refuser ferait
     * echouer un import de quatre cents articles pour une redite sans consequence.
     */
    public static List<String> nettoyer(List<String> codes) {
        Set<String> vus = new LinkedHashSet<>();
        if (codes != null)
            for (String c : codes) {
                if (c == null) continue;
                String propre = c.trim().replace(SEPARATEUR, "");
                if (!propre.isEmpty()) vus.add(propre);
            }
        return new ArrayList<>(vus);
    }

    /** La forme stockee en base : les codes separes par une espace, ou {@code null} si aucun. */
    public static String joindre(List<String> codes) {
        List<String> propres = nettoyer(codes);
        return propres.isEmpty() ? null : String.join(SEPARATEUR, propres);
    }

    /** La forme rendue a l'ecran et a la caisse. Jamais {@code null} : une liste vide se parcourt. */
    public static List<String> separer(String stocke) {
        if (stocke == null || stocke.isBlank()) return List.of();
        return List.of(stocke.trim().split("\\s+"));
    }

    /**
     * Poser le code principal et les secondaires sur un article, en refusant les collisions.
     *
     * Le principal est retire des secondaires s'il s'y trouve : un export le repete souvent,
     * et le garder aux deux endroits ferait croire a un doublon a la verification suivante.
     */
    public static void poser(Product p, String principal, List<String> secondaires, ProductRepo repo) {
        String cb = principal == null || principal.isBlank() ? null : principal.trim();
        List<String> autres = new ArrayList<>(nettoyer(secondaires));
        if (cb != null) autres.remove(cb);

        List<String> tous = new ArrayList<>();
        if (cb != null) tous.add(cb);
        tous.addAll(autres);

        if (!tous.isEmpty()) {
            String requete = String.join(SEPARATEUR, tous);
            for (Product autre : repo.portantUnDeCesCodes(requete, p.getId())) {
                Set<String> siens = new LinkedHashSet<>(separer(autre.getBarcodesSecondaires()));
                if (autre.getBarcode() != null) siens.add(autre.getBarcode());
                for (String c : tous)
                    if (siens.contains(c))
                        throw new BusinessException("Le code-barres « " + c + " » est déjà celui de « "
                                + autre.getName() + " ».");
            }
        }
        p.setBarcode(cb);
        p.setBarcodesSecondaires(autres.isEmpty() ? null : String.join(SEPARATEUR, autres));
    }

    /**
     * La meme pose, mais qui ECARTE les codes en conflit au lieu de tout refuser.
     *
     * C'est la regle de l'IMPORT, et elle differe de celle de la fiche article a dessein :
     * une carte de quatre cents lignes ne doit pas s'arreter sur un code recopie deux fois
     * dans le fichier source - ce qui est la banalite meme des exports d'un autre logiciel.
     * L'article entre sans ce code-la, et l'avertissement dit lequel et pourquoi, pour que
     * quelqu'un puisse trancher apres coup.
     *
     * @return les avertissements a joindre au resultat de l'import
     */
    public static List<String> poserTolerant(Product p, String principal, List<String> secondaires,
                                             ProductRepo repo, boolean estNouveau) {
        List<String> avertissements = new ArrayList<>();
        String cb = principal == null || principal.isBlank() ? null : principal.trim();
        List<String> autres = new ArrayList<>(nettoyer(secondaires));
        if (cb != null) autres.remove(cb);

        List<String> tous = new ArrayList<>();
        if (cb != null) tous.add(cb);
        tous.addAll(autres);

        if (!tous.isEmpty()) {
            for (Product autre : repo.portantUnDeCesCodes(String.join(SEPARATEUR, tous), estNouveau ? null : p.getId())) {
                Set<String> siens = new LinkedHashSet<>(separer(autre.getBarcodesSecondaires()));
                if (autre.getBarcode() != null) siens.add(autre.getBarcode());
                for (String c : new ArrayList<>(tous)) {
                    if (!siens.contains(c)) continue;
                    avertissements.add("Code-barres déjà utilisé par « " + autre.getName() + " » : " + c
                            + " — « " + p.getName() + " » est importé sans ce code.");
                    tous.remove(c);
                    autres.remove(c);
                    if (c.equals(cb)) cb = null;
                }
            }
        }
        p.setBarcode(cb);
        p.setBarcodesSecondaires(autres.isEmpty() ? null : String.join(SEPARATEUR, autres));
        return avertissements;
    }
}
