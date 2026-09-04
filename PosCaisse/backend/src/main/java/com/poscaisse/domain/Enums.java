package com.poscaisse.domain;

public final class Enums {
    private Enums() {}
    public enum OrderStatus { HELD, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED }
    public enum ServiceMode { DINE_IN, TAKEAWAY, DELIVERY }
    /** Nature du compte qui porte une dette : celui d'un client ou celui d'un livreur. */
    public enum AccountParty { CUSTOMER, COURIER }
    public enum SessionStatus { OPEN, CLOSED }
    public enum ProductType { SIMPLE, MENU }
    /** CREDIT : porte le ticket au compte du client au lieu d'encaisser. */
    public enum PaymentKind { CASH, CARD, CHECK, MEAL_VOUCHER, CREDIT, OTHER }
    public enum MovementType { IN, OUT }
    public enum DestinationKind { CUSTOMER, PREP }
    public enum PrintJobStatus { PENDING, PRINTED, FAILED }
    public enum JournalEvent { SESSION_OPEN, SALE, PAYMENT, CANCELLATION, REFUND, CASH_IN, CASH_OUT, SESSION_CLOSE, DAILY_CLOSE }
}
