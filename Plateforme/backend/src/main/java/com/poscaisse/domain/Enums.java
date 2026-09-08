package com.poscaisse.domain;

public final class Enums {
    private Enums() {}
    public enum OrderStatus { HELD, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED }
    public enum ServiceMode { DINE_IN, TAKEAWAY, DELIVERY }
    /** Nature du compte qui porte une dette : celui d'un client ou celui d'un livreur. */
    public enum AccountParty { CUSTOMER, COURIER }
    public enum SessionStatus { OPEN, CLOSED }
    public enum ProductType { SIMPLE, MENU }

    /**
     * Ce que l'on compte quand on vend cet article.
     *
     * PIECE se compte : deux cafes, trois bouteilles. KG et LITRE se mesurent, et le prix
     * de la fiche est celui de l'unite entiere - 58 dinars le kilo de baklawa, dont on
     * vend 300 grammes. La caisse demande alors un poids au lieu d'ajouter << 1 >>.
     */
    public enum Unite {
        PIECE("pièce", "", false),
        KG("kilogramme", "kg", true),
        LITRE("litre", "L", true);

        private final String libelle;
        private final String symbole;
        private final boolean mesuree;

        Unite(String libelle, String symbole, boolean mesuree) {
            this.libelle = libelle; this.symbole = symbole; this.mesuree = mesuree;
        }

        public String libelle() { return libelle; }
        /** << kg >>, << L >>, ou rien pour ce qui se compte. */
        public String symbole() { return symbole; }
        /** Vrai si l'article se pese ou se mesure : l'ecran doit demander une quantite. */
        public boolean mesuree() { return mesuree; }
    }
    /** Ou la valeur d'une variante se place dans le nom : « 1/2 Sandwich » ou « Pizza Large ». */
    public enum NamePosition { PREFIX, SUFFIX }
    /** CREDIT : porte le ticket au compte du client au lieu d'encaisser. */
    public enum PaymentKind { CASH, CARD, CHECK, MEAL_VOUCHER, CREDIT, OTHER }
    public enum MovementType { IN, OUT }
    public enum DestinationKind { CUSTOMER, PREP }
    public enum PrintJobStatus { PENDING, PRINTED, FAILED }
    public enum JournalEvent { SESSION_OPEN, SALE, PAYMENT, CANCELLATION, REFUND, CASH_IN, CASH_OUT, SESSION_CLOSE, DAILY_CLOSE,
                               /** Pates recues et pates perdues : le journal porte les deux, avec le nom du caissier. */
                               STOCK_IN, STOCK_OUT }

    /** Ce qui fait bouger un compteur de pate. */
    /**
     * INVENTAIRE : le comptage physique. Il ne dit pas ce qui est parti, il POSE le
     * chiffre vrai - c'est le seul mouvement dont la quantite se deduit de l'ecart.
     */
    public enum StockMovement { ENTREE, VENTE, CASSE, ANNULATION, REMISE_A_ZERO, INVENTAIRE }
}
