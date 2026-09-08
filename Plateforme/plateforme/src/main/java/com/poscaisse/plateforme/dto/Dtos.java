package com.poscaisse.plateforme.dto;

import com.poscaisse.plateforme.domain.Enums;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

/** Ce qui entre et ce qui sort. Les entites, elles, ne franchissent jamais l'API. */
public class Dtos {

    // ------------------------------------------------------------------ entree
    public record ClientRequest(@NotBlank String raisonSociale, String enseigne, String contactNom,
                                String contactTel, String contactEmail, String ville, String adresse,
                                String matriculeFiscal, Enums.StatutClient statut, String notes) {}

    public record AbonnementRequest(@NotNull Enums.Module module, Enums.Formule formule, Integer nbCaisses,
                                    BigDecimal prixMensuel, LocalDate debutLe, LocalDate finLe) {}

    public record FactureRequest(LocalDate periodeDebut, LocalDate periodeFin, BigDecimal montant,
                                 LocalDate emiseLe, LocalDate echeanceLe, String libelle) {}

    public record ReglementRequest(@NotNull BigDecimal montant, LocalDate recuLe, Enums.MoyenReglement moyen,
                                   String reference, String note) {}

    public record ConnexionRequest(@NotBlank String username, @NotBlank String password) {}

    public record UtilisateurRequest(@NotBlank String username, @NotBlank String fullName, String email,
                                     String password, @NotNull Enums.Role role, Boolean active) {}

    public record MotifRequest(String motif) {}

    /** Ce qu'une caisse envoie pour demander le droit d'ouvrir. */
    public record VerificationRequest(@NotBlank String cle, String empreinte, String libelle) {}

    // ------------------------------------------------------------------ sortie
    public record ClientDto(Long id, String code, String raisonSociale, String enseigne, String contactNom,
                            String contactTel, String contactEmail, String ville, String adresse,
                            String matriculeFiscal, Enums.StatutClient statut, String notes,
                            OffsetDateTime createdAt, List<AbonnementDto> abonnements,
                            BigDecimal soldeDu) {}

    public record AbonnementDto(Long id, Long clientId, String clientCode, String clientNom, Enums.Module module,
                                Enums.Formule formule, int nbCaisses, BigDecimal prixMensuel, LocalDate debutLe,
                                LocalDate finLe, Enums.StatutAbonnement statut, String baseNom, String urlClient,
                                String version, OffsetDateTime provisionneLe, List<LicenceDto> licences) {}

    public record LicenceDto(Long id, String cle, int postesMax, LocalDate expireLe, boolean revoquee,
                             OffsetDateTime derniereVerif, int postesUtilises, List<ActivationDto> activations) {}

    public record ActivationDto(Long id, String empreinte, String libelle,
                                OffsetDateTime premiereLe, OffsetDateTime derniereLe) {}

    public record FactureDto(Long id, Long clientId, String clientCode, String clientNom, Long abonnementId,
                             String numero, LocalDate periodeDebut, LocalDate periodeFin, BigDecimal montant,
                             BigDecimal regle, BigDecimal reste, LocalDate emiseLe, LocalDate echeanceLe,
                             Enums.StatutFacture statut, boolean enRetard, String libelle,
                             List<ReglementDto> reglements) {}

    public record ReglementDto(Long id, BigDecimal montant, LocalDate recuLe, Enums.MoyenReglement moyen,
                               String reference, String note, OffsetDateTime createdAt) {}

    public record UtilisateurDto(Long id, String username, String fullName, String email, Enums.Role role,
                                 boolean active, OffsetDateTime lastLoginAt) {}

    public record ConnexionReponse(String token, UtilisateurDto utilisateur, long expireDansMinutes) {}

    public record JournalDto(Long id, String username, String action, String cibleType, Long cibleId,
                             String details, OffsetDateTime createdAt) {}

    /**
     * La reponse a une caisse qui demande a ouvrir.
     *
     * Trois issues, et une seule est un refus sec : autorise, LECTURE SEULE - l'abonnement
     * est suspendu mais les donnees sont la et consultables -, ou refuse. Le message est
     * ecrit pour etre lu par un caissier a 19 h, pas par un developpeur.
     */
    public record VerificationLicence(boolean autorise, boolean lectureSeule, String message,
                                      String client, Enums.Module module, Integer caisses, LocalDate expireLe) {
        public static VerificationLicence ok(String client, Enums.Module module, int caisses, LocalDate expire) {
            return new VerificationLicence(true, false, "Licence valide.", client, module, caisses, expire);
        }
        public static VerificationLicence lectureSeule(String message) {
            return new VerificationLicence(false, true, message, null, null, null, null);
        }
        public static VerificationLicence refus(String message) {
            return new VerificationLicence(false, false, message, null, null, null, null);
        }
    }

    /** Le tableau de bord : ce qu'on regarde le matin, en un appel. */
    public record TableauDeBord(long clients, long clientsActifs, long clientsSuspendus,
                                long abonnements, long caisses, BigDecimal recurrentMensuel,
                                long facturesEnRetard, BigDecimal montantEnRetard,
                                List<FactureDto> retards, List<AbonnementDto> derniersAbonnements) {}
}
