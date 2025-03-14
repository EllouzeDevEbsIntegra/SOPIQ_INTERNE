pageextension 80142 "Item Bin Contents" extends "Item Bin Contents" //7379
{
    layout
    {
        addafter("Quantity (Base)")
        {
            field("Count Content"; "Count Content")
            {
                ApplicationArea = All;
                Caption = 'Nombre emplacement';
            }
            field("Invoice No."; "Invoice No.")
            {
                ApplicationArea = all;
                Caption = 'N° Facture Achat';
                trigger OnValidate()
                var
                    PurchInvLine: Record "Purch. Inv. Line";
                    PurchInvHeader: Record "Purch. Inv. Header";
                begin
                    PurchInvLine.Reset();
                    PurchInvLine.SetRange("Document No.", "Invoice No.");
                    PurchInvLine.SetRange("No.", "Item No.");
                    if PurchInvLine.FindFirst() then begin
                        PurchInvHeader.Reset();
                        PurchInvHeader.SetRange("No.", PurchInvLine."Document No.");
                        if PurchInvHeader.FindFirst() then begin
                            "Vendor Inv. No." := PurchInvHeader."Vendor Invoice No.";
                            "Purch. Line Date" := PurchInvHeader."Document Date";
                            "Purch. Line Price" := PurchInvLine."Direct Unit Cost";
                            "Last Modification Date" := Today;
                            rec.Modify();
                        end;

                    end;
                end;

            }
            field("Vendor Inv. No."; "Vendor Inv. No.")
            {
                ApplicationArea = all;
                Caption = 'N° Facture Frs';
                Editable = false;
            }
            field("Purch. Line Date"; "Purch. Line Date")
            {
                ApplicationArea = all;
                Caption = 'Date Achat';
                Editable = false;
            }

            field("Purch. Line Price"; "Purch. Line Price")
            {
                ApplicationArea = all;
                Caption = 'Prix Achat';
                Editable = false;
            }

            field(Status; Status)
            {
                ApplicationArea = all;
                Caption = 'Status Réclamation';
                trigger OnValidate()
                begin
                    "Last Modification Date" := Today;
                    rec.Modify();
                end;
            }

            field(Observation; Observation)
            {
                ApplicationArea = all;
                Caption = 'Observation';
            }
            field("Last Modification Date"; "Last Modification Date")
            {
                ApplicationArea = all;
                Caption = 'Date Dernier Modification';
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}