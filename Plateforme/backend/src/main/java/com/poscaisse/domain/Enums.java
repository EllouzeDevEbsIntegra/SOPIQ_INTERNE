package com.poscaisse.domain;

public final class Enums {
    private Enums() {}
    public enum OrderStatus { HELD, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED }
    public enum ServiceMode { DINE_IN, TAKEAWAY, DELIVERY }
    /** Nature du compte qui porte une dette : celui d'un client ou celui d'un livreur. */
    public enum AccountParty { CUSTOMER, COURIER }
    public enum SessionStatus { OPEN, CLOSED }
    public enum ProductType { SIMPLE, MENU }
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
