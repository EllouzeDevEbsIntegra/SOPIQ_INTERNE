"""Teste la vraie frontière de validation, sans écrire dans /etc ni lancer de service.

La partie du script avant son premier contrôle d'installation est exécutée telle quelle.
Seul `id` est simulé : ces essais restent sans privilège, y compris sur Linux.
"""
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import unittest

RACINE = Path(__file__).resolve().parents[1]
BASH = os.environ.get("BASH_AUDIT") or shutil.which("bash")
if os.name == "nt":
    BASH = os.environ.get("BASH_AUDIT", r"C:\Program Files\Git\bin\bash.exe")


class ValidationOuvertureTest(unittest.TestCase):
    def lancer(self, **valeurs):
        donnees = dict(sous_domaine="boutique", port="8101", base="pos_cli0001_shop",
                       profil="SHOP", enseigne="Épicerie du Centre", demonstration="true")
        donnees.update(valeurs)
        script = (RACINE / "sbin/poscaisse-ouvrir").read_text(encoding="utf-8")
        frontiere = script.index('[ -f "$MODELE" ]')
        args = []
        for nom, valeur in donnees.items():
            args.extend(["--" + nom.replace("_", "-"), valeur])
        validation = ('id() { printf "0\\n"; }\nset -- ' + shlex.join(args) + '\n'
                      + script[:frontiere] + '\nprintf "VALIDATION_ACCEPTEE\\n"\n')
        return subprocess.run([BASH, "-s"], input=validation, text=True, encoding="utf-8",
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              env={**os.environ, "DOMAINE": "audit.example.test"}, timeout=10)

    def refuse(self, **valeurs):
        resultat = self.lancer(**valeurs)
        self.assertNotEqual(resultat.returncode, 0,
                            f"Entrée dangereuse acceptée : {valeurs!r}\n{resultat.stdout}")
        self.assertNotIn("VALIDATION_ACCEPTEE", resultat.stdout)

    def test_nom_commercial_valide(self):
        r = self.lancer()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("VALIDATION_ACCEPTEE", r.stdout)

    def test_traversee_simple_refusee(self):
        self.refuse(sous_domaine="../../autre")

    def test_sous_domaine_multiligne_refuse(self):
        self.refuse(sous_domaine="boutique\n../../autre")

    def test_base_multiligne_refusee(self):
        self.refuse(base="pos_client\nPOSCAISSE_JWT_SECRET=impose")

    def test_metier_expression_reguliere_refuse(self):
        self.refuse(profil=".*")

    def test_metier_multiligne_refuse(self):
        self.refuse(profil="SHOP\nPOSCAISSE_DB_NAME=autre")

    def test_enseigne_ne_peut_injecter_environnement(self):
        self.refuse(enseigne="Épicerie\nPOSCAISSE_DB_NAME=autre")

    def test_enseigne_ne_peut_continuer_la_ligne(self):
        self.refuse(enseigne="Épicerie\\")

    def test_prefixe_demo_reserve(self):
        self.refuse(sous_domaine="demo-shop")

    def test_ports_hors_bornes_refuses(self):
        for port in ["80", "65536", "8101;id", "8101\n8102"]:
            with self.subTest(port=port):
                self.refuse(port=port)


class SecretsProcessusTest(unittest.TestCase):
    def test_le_secret_postgres_ne_passe_pas_dans_les_arguments_psql(self):
        script = (RACINE / "preparer-demos.sh").read_text(encoding="utf-8")
        lignes = script.splitlines()
        dangereuses = [ligne for ligne in lignes
                       if "psql" in ligne and "-c" in ligne and ("$mdp" in ligne or "PASSWORD" in ligne)]
        self.assertEqual(dangereuses, [],
                         "Le mot de passe serait visible dans la ligne de commande du processus psql")


class EntetesNginxTest(unittest.TestCase):
    def test_les_deux_applications_posent_les_quatre_entetes_de_securite(self):
        requis = ["Strict-Transport-Security", "X-Frame-Options", "X-Content-Type-Options",
                  "Content-Security-Policy"]
        for nom in ["pos-caisse.conf.modele", "pos-plateforme.conf"]:
            with self.subTest(nom=nom):
                texte = (RACINE / "nginx" / nom).read_text(encoding="utf-8")
                for entete in requis:
                    self.assertIn("add_header " + entete, texte)


if __name__ == "__main__":
    unittest.main(verbosity=2)
