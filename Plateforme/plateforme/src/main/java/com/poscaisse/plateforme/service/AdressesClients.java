package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.Abonnement;
import com.poscaisse.plateforme.domain.Client;
import com.poscaisse.plateforme.repository.AbonnementRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.Set;
import java.util.TreeSet;

/**
 * Donner a un client une adresse et un port : les deux choses qu'il n'avait pas.
 *
 * CE QUE CETTE CLASSE DECIDE. Le nom que le commercant tapera tous les matins -
 * << numberone.pos.ebs-integra.com >> - et le port local sur lequel sa caisse ecoutera.
 * Rien d'autre : elle ne cree aucun fichier et ne touche a aucun service. C'est le script
 * poscaisse-ouvrir, sur le serveur, qui pose ensuite ce qu'il faut.
 *
 * POURQUOI LE SOUS-DOMAINE VIENT DE L'ENSEIGNE ET NON DU CODE CLIENT. Le code
 * << CLI0001 >> est notre langage, pas le sien : une adresse qu'on lit au telephone doit
 * pouvoir s'epeler et se retenir. On part donc de l'enseigne, reduite a des minuscules et
 * des tirets, et on ne retombe sur le code que si l'enseigne ne donne rien d'utilisable -
 * une raison sociale entierement en arabe, par exemple.
 *
 * CE NOM FINIT DANS UN NOM DE FICHIER, UNE UNITE SYSTEMD ET UNE DIRECTIVE NGINX. Il n'a
 * donc le droit de contenir que des minuscules, des chiffres et des tirets, et la base le
 * verifie une seconde fois par une contrainte : ce qui est fabrique ici ne doit jamais
 * pouvoir devenir un chemin, une option, ni un second nom de serveur.
 */
@Service @RequiredArgsConstructor
public class AdressesClients {

    private final AbonnementRepo abonnements;

    @Value("${plateforme.domaine:pos.ebs-integra.com}") private String domaine;
    @Value("${plateforme.provisionnement.port-min:8101}") private int portMin;
    @Value("${plateforme.provisionnement.port-max:8120}") private int portMax;

    /**
     * Les noms qu'on ne donne a personne.
     *
     * << pos >> est le domaine lui-meme et sert le back-office ; << demo >> et tout ce qui
     * commence par << demo- >> appartiennent aux six demonstrations (V3), et un client qui
     * s'appellerait << demo-resto >> volerait l'adresse de l'une d'elles. Les autres sont
     * les noms d'infrastructure qu'on regretterait d'avoir donnes le jour ou l'on en a
     * besoin.
     */
    private static final Set<String> RESERVES = Set.of(
            "pos", "www", "api", "admin", "back-office", "backoffice", "demo",
            "mail", "smtp", "imap", "ftp", "ns", "ns1", "ns2", "test", "staging");

    /**
     * LES FORMES JURIDIQUES NE FONT PAS UNE ADRESSE.
     *
     * Une raison sociale finit presque toujours par sa forme - << Number One SARL >> - et
     * cette forme n'identifie personne : on la retire de la fin du nom. Surtout, elle ne
     * doit JAMAIS rester seule. Une enseigne ecrite entierement en arabe ne laisse aucune
     * lettre latine ; la raison sociale << مقهى النور SARL >> en laissait quatre, et le
     * client se voyait attribuer l'adresse << sarl.pos.ebs-integra.com >>. Le deuxieme
     * client dans ce cas aurait eu << sarl-2 >>. Trouve par un test, pas en production.
     */
    private static final Set<String> FORMES = Set.of(
            "sarl", "suarl", "sa", "sas", "sasu", "eurl", "snc", "spa", "sci",
            "ste", "societe", "llc", "ltd", "inc");

    public String domaine() { return domaine; }

    public String adresse(String sousDomaine) { return "https://" + sousDomaine + "." + domaine; }

    /**
     * Le sous-domaine du client, libre et stable.
     *
     * Stable : une fois attribue il ne bouge plus - c'est ecrit sur le comptoir du client,
     * dans son navigateur et dans nos vhosts. Le renommer est une operation a part, pas un
     * effet de bord d'un provisionnement relance.
     */
    public String sousDomaineLibre(Client c) {
        String base = tronquer(slug(c.getEnseigne()));
        if (!utilisable(base)) base = tronquer(slug(c.getRaisonSociale()));
        if (!utilisable(base)) base = tronquer(slug(c.getCode()));
        if (!utilisable(base)) throw new ErreurMetier(
                "Impossible de fabriquer une adresse à partir de « " + c.getRaisonSociale()
                + " » : donnez au client une enseigne en lettres latines, ou un code.");

        Set<String> pris = prisEnCompte();
        if (!pris.contains(base) && !RESERVES.contains(base)) return base;
        // Le suffixe plutot qu'un refus : deux commerces peuvent legitimement porter la
        // meme enseigne, et le commercial ne doit pas etre bloque a la vente.
        for (int i = 2; i <= 99; i++) {
            String essai = tronquer(base) + "-" + i;
            if (!pris.contains(essai) && !RESERVES.contains(essai)) return essai;
        }
        throw new ErreurMetier("Cent adresses commencent déjà par « " + base + " » : choisissez une autre enseigne.");
    }

    /**
     * Le premier port libre de la plage.
     *
     * Le premier LIBRE, et non le suivant du dernier attribue : un client resilie rend son
     * port, et rien ne justifie de laisser un trou dans une plage qui n'en compte que
     * vingt.
     */
    public int portLibre() {
        Set<Integer> pris = new TreeSet<>();
        for (Abonnement a : abonnements.findAll()) if (a.getPort() != null) pris.add(a.getPort());
        for (int p = portMin; p <= portMax; p++) if (!pris.contains(p)) return p;
        throw new ErreurMetier("Plus aucun port libre entre " + portMin + " et " + portMax
                + " : " + (portMax - portMin + 1) + " caisses sont déjà ouvertes sur ce serveur. "
                + "Élargissez « plateforme.provisionnement.port-max » ou ouvrez un second serveur.");
    }

    // ------------------------------------------------------------------ mecanique

    private Set<String> prisEnCompte() {
        Set<String> pris = new TreeSet<>();
        for (Abonnement a : abonnements.findAll())
            if (a.getSousDomaine() != null) pris.add(a.getSousDomaine());
        return pris;
    }

    /**
     * << CAFÉ DES DÉLICES >> devient << cafe-des-delices >>.
     *
     * Les accents sont DECOMPOSES puis leurs marques retirees, plutot que remplaces lettre
     * a lettre : une table de correspondance oublie toujours un caractere, et celui qu'elle
     * oublie disparait du nom au lieu d'y laisser sa lettre de base.
     */
    private static String slug(String texte) {
        if (texte == null) return "";
        String sansAccents = Normalizer.normalize(texte, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        String s = sansAccents.toLowerCase()
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-+|-+$", "");
        return sansForme(s);
    }

    /** << number-one-sarl >> devient << number-one >>, mais << sarl >> seul reste << sarl >>. */
    private static String sansForme(String s) {
        int tiret = s.lastIndexOf('-');
        if (tiret <= 0) return s;
        return FORMES.contains(s.substring(tiret + 1)) ? s.substring(0, tiret) : s;
    }

    /** 40 caracteres : il reste de la place pour un suffixe sous la limite de 63 d'une etiquette DNS. */
    private static String tronquer(String s) {
        String t = s.length() > 40 ? s.substring(0, 40) : s;
        return t.replaceAll("-+$", "");
    }

    /**
     * Ce qu'un nom doit valoir pour qu'on s'en serve.
     *
     * Deux caracteres au moins, la forme d'une etiquette DNS, pas uniquement des chiffres,
     * pas une forme juridique toute seule - elle n'identifie personne - et pas le prefixe
     * des demonstrations. Un nom qui echoue ici ne provoque pas d'erreur : on passe
     * simplement a la source suivante, la raison sociale puis le code client.
     */
    private static boolean utilisable(String s) {
        return s != null && s.length() >= 2 && s.matches("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$")
                && !s.matches("^[0-9]+$") && !s.startsWith("demo-") && !FORMES.contains(s);
    }
}
