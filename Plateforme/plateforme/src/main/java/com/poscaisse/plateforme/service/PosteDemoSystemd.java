package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.Demo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

/**
 * Le lanceur reel : un script enveloppe, appele par sudo.
 *
 * POURQUOI UN SCRIPT PLUTOT QUE systemctl DIRECTEMENT. Le back-office tourne sous un compte
 * sans privilege et doit pourtant demarrer un service systeme : il lui faut donc une regle
 * sudo. Ecrite sur systemctl, cette regle contiendrait un joker - << systemctl start
 * poscaisse@* >> - et ce joker accepte n'importe quel argument : le nom d'une unite qui
 * n'est pas une demonstration, ou une unite fabriquee pour l'occasion. Le jour ou une
 * faille laisse choisir cet argument, elle donne le droit de demarrer ce qu'on veut en
 * root.
 *
 * Le script enveloppe supprime le joker. Il valide le metier recu contre une liste fixe de
 * six noms et refuse tout le reste, et la regle sudo n'autorise donc QU'UNE commande, sans
 * argument libre : /usr/local/sbin/poscaisse-demo. Ce qui est passe ici n'est de toute
 * facon jamais une saisie - c'est le nom d'une valeur d'enumeration - mais la garantie ne
 * doit pas dependre de cette phrase-la.
 *
 * LE DELAI N'EST PAS UNE PRECAUTION DE STYLE. systemctl start attend que l'unite soit
 * partie ; si le processus de caisse bloque au demarrage - une base injoignable, un port
 * deja pris - l'attente ne rend jamais la main, et c'est le thread de la requete HTTP du
 * back-office qui reste pris avec elle. Passe trente secondes on tue et on le dit.
 */
@Service
@ConditionalOnProperty(name = "plateforme.demo.lanceur", havingValue = "systemd", matchIfMissing = true)
public class PosteDemoSystemd implements PosteDemo {
    private static final Logger log = LoggerFactory.getLogger(PosteDemoSystemd.class);

    private static final String ENVELOPPE = "/usr/local/sbin/poscaisse-demo";
    private static final int DELAI_SECONDES = 30;

    @Override
    public void demarrer(Demo d) { exiger("start", d); }

    @Override
    public void arreter(Demo d) { exiger("stop", d); }

    @Override
    public boolean tourne(Demo d) { return code("status", d) == 0; }

    // ------------------------------------------------------------------ mecanique

    /** Le geste doit reussir : un code de sortie non nul est une erreur qu'on remonte. */
    private void exiger(String geste, Demo d) {
        int code = code(geste, d);
        if (code != 0)
            throw new ErreurMetier("La démo « " + metier(d) + " » n'a pas répondu à « " + geste
                    + " » (code " + code + "). Regardez le journal du serveur : "
                    + "journalctl -u poscaisse-demo@" + metier(d) + ".");
        log.info("Démo « {} » : {} effectué.", metier(d), geste);
    }

    private int code(String geste, Demo d) {
        ProcessBuilder pb = new ProcessBuilder("sudo", ENVELOPPE, geste, metier(d));
        // La sortie du script part dans le journal du serveur : personne ne lit un flux
        // qu'on n'a pas vide, et un tampon plein arrete le processus au milieu de son travail.
        pb.redirectErrorStream(true);
        pb.redirectOutput(ProcessBuilder.Redirect.DISCARD);
        Process p = null;
        try {
            p = pb.start();
            if (!p.waitFor(DELAI_SECONDES, TimeUnit.SECONDS)) {
                p.destroyForcibly();
                throw new ErreurMetier("La démo « " + metier(d) + " » ne répond pas après "
                        + DELAI_SECONDES + " secondes. Elle a peut-être un port occupé ou une base "
                        + "injoignable ; vérifiez le serveur avant de réessayer.");
            }
            return p.exitValue();
        } catch (IOException e) {
            throw new ErreurMetier("Le lanceur des démos est introuvable ou refusé (" + ENVELOPPE
                    + ") : " + e.getMessage() + ". Installez le script et sa règle sudo sur ce serveur.");
        } catch (InterruptedException e) {
            // Le serveur s'arrete pendant qu'on attend : on ne masque pas l'interruption,
            // et on ne laisse pas un processus derriere nous.
            Thread.currentThread().interrupt();
            if (p != null) p.destroyForcibly();
            throw new ErreurMetier("Opération sur la démo « " + metier(d) + " » interrompue.");
        }
    }

    /** << cafe >>, tel que le script et l'unite systemd le nomment. */
    private static String metier(Demo d) { return d.getModule().name().toLowerCase(); }
}
