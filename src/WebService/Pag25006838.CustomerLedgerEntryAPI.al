page 25006838 "Customer Ledger Entry API"
{
    Caption = 'Customer Ledger Entry API';
    PageType = API;
    SourceTable = "Cust. Ledger Entry";
    DelayedInsert = true;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'customerLedgerEntries';
    EntitySetName = 'customerLedgerEntries';
    Editable = false;  // API en lecture seule

    layout
    {
        area(Content)
        {
            group("Customer Ledger Entry")
            {
                field("EntryNo"; "Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field("CustomerNo"; "Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field("DocumentType"; "Document Type")
                {
                    Caption = 'Document Type';
                }
                field("DocumentNo"; "Document No.")
                {
                    Caption = 'Document No.';
                }
                field("PostingDate"; "Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field("DueDate"; "Due Date")
                {
                    Caption = 'Due Date';
                }
                field("Amount"; Amount)
                {
                    Caption = 'Amount';
                }
                field("RemainingAmount"; "Remaining Amount")
                {
                    Caption = 'Remaining Amount';
                }
                field("CurrencyCode"; "Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(Open; Open)
                {
                    Caption = 'Open';
                }
                field("CustomerName"; "Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field("CustomerPostingGroup"; "Customer Posting Group")
                {
                    Caption = 'Customer Posting Group';
                }

            }
        }
    }
}
