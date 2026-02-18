
page 25006882 "Detailed Cust Ledg Entry API"
{
    PageType = API;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'custLedgerEntry';
    EntitySetName = 'custLedgerEntries';
    Caption = 'Customer Ledger Entry API';
    SourceTable = "Detailed Cust. Ledg. Entry";
    ODataKeyFields = "Entry No.";
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(custLedgerEntryNo; Rec."Cust. Ledger Entry No.")
                {
                    Caption = 'Cust. Ledger Entry No.';
                }
                field(entryType; Rec."Entry Type")
                {
                    Caption = 'Entry Type';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(documentType; Rec."Document Type")
                {
                    Caption = 'Document Type';
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Amount';
                }
                field(amountLCY; Rec."Amount (LCY)")
                {
                    Caption = 'Amount (LCY)';
                }
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(entryDueDate; dueDate)
                {
                    Caption = 'Entry Due Date';
                    ApplicationArea = All;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(userId; Rec."User ID")
                {
                    Caption = 'User ID';
                }
            }
        }
    }

    var
        recPayLine: Record "Payment Line";
        dueDate: Text;

    trigger OnAfterGetRecord()
    begin
        dueDate := '';
        recPayLine.Reset();
        recPayLine.SetRange("No.", "Document No.");
        recPayLine.SetRange("Entry No. Credit", "Applied Cust. Ledger Entry No.");
        if recPayLine.FindFirst() then
            if recPayLine."Due Date" <> 0D then
                dueDate := Format(recPayLine."Due Date", 0, 9);
    end;

}