pageextension 80650 "Purchase Invoice" extends "Purchase Invoice"//51
{
    layout
    {
        // Add changes to page layout here
        modify("Vendor Invoice No.")
        {
            ApplicationArea = All;
            trigger OnBeforeValidate()
            var
                PurchaseHeader: Record "Purchase Header";
                PurchInvHeader: Record "Purch. Inv. Header";
            begin
                PurchaseHeader.Reset();
                PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
                PurchaseHeader.SetRange("Vendor Invoice No.", Rec."Vendor Invoice No.");
                PurchaseHeader.SetRange("Buy-from Vendor No.", Rec."Buy-from Vendor No.");
                // Check if the vendor invoice number already exists in purchase invoices
                if PurchaseHeader.FindFirst() then begin
                    Error('Le numéro de facture fournisseur %1 est déjà utilisé dans la liste des factures en attente sous le N° %2.', Rec."Vendor Invoice No.", PurchaseHeader."No.");
                end else begin
                    PurchInvHeader.Reset();
                    PurchInvHeader.SetRange("Vendor Invoice No.", Rec."Vendor Invoice No.");
                    PurchInvHeader.SetRange("Buy-from Vendor No.", Rec."Buy-from Vendor No.");
                    // Check if the vendor invoice number already exists in posted invoices
                    if PurchInvHeader.FindFirst() then begin
                        Error('Le numéro de facture fournisseur %1 est déjà utilisé dans les factures enregistrées sous le N° %2.', Rec."Vendor Invoice No.", PurchInvHeader."No.");
                    end;

                end;
            end;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}