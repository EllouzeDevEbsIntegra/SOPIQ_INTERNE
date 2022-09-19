pageextension 80133 "Detailed Cust. Ledg. Ent 573" extends "Detailed Cust. Ledg. Entries"//573
{
    layout
    {
        addafter("Initial Entry Due Date")
        {
            field("Entry Due Date"; dueDate)
            {
                ApplicationArea = All;
            }
        }

    }

    actions
    {
        // Add changes to page actions here
    }

    var
        recPayLine: Record "Payment Line";
        dueDate: Date;

    trigger OnAfterGetRecord()

    begin

        recPayLine.Reset();
        recPayLine.SetRange("No.", "Document No.");
        recPayLine.SetRange("Entry No. Credit", "Applied Cust. Ledger Entry No.");
        if recPayLine.FindFirst() then
            // Message('date echeance = %1 - %2 -%3 - %4', recPayLine."Due Date", recPayLine."No.", "Document No.", "Applied Cust. Ledger Entry No.");
        dueDate := recPayLine."Due Date";
    end;
}