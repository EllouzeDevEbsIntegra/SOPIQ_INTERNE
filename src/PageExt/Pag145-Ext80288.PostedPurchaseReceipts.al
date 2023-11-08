pageextension 80288 "Posted Purchase Receipts" extends "Posted Purchase Receipts"//145
{
    Editable = true;
    layout
    {
        // Add changes to page layout here
        addafter("Buy-from Vendor Name")
        {
            field("Order No."; "Order No.")
            {
                ApplicationArea = All;
                Editable = false;
                Caption = 'N° Commande';

            }

            field("Vendor Shipment No."; "Vendor Shipment No.")
            {
                ApplicationArea = All;
                Editable = true;
                Caption = 'N° BL/FA Frs';
                trigger OnValidate()
                var
                    recPurchRecptHeader: Record "Purch. Rcpt. Header";

                begin
                    if (xRec."Vendor Shipment No." <> rec."Vendor Shipment No.") then begin
                        recPurchRecptHeader.Reset();
                        recPurchRecptHeader.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                        recPurchRecptHeader.setfilter("Vendor Shipment No.", "Vendor Shipment No.");
                        if recPurchRecptHeader.FindFirst() then begin
                            Error('N° BL Frs existe déja dans réception achat N° %1', recPurchRecptHeader."No.");
                        end
                        else begin
                            rec.Validate("Vendor Shipment No.");
                            rec.Modify();
                        end;
                    end;


                end;

            }
        }

        Modify("No.")
        {
            editable = false;
        }
        Modify("Buy-from Vendor No.")
        {
            editable = false;
        }
        Modify("Order Address Code")
        {
            editable = false;
        }
        Modify("Buy-from Vendor Name")
        {
            editable = false;
        }
        Modify("Buy-from Post Code")
        {
            editable = false;
        }
        Modify("Buy-from Country/Region Code")
        {
            editable = false;
        }
        Modify("Buy-from Contact")
        {
            editable = false;
        }
        Modify("Pay-to Vendor No.")
        {
            editable = false;
        }
        Modify("Pay-to Name")
        {
            editable = false;
        }
        Modify("Pay-to Post Code")
        {
            editable = false;
        }
        Modify("Pay-to Country/Region Code")
        {
            editable = false;
        }
        Modify("Pay-to Contact")
        {
            editable = false;
        }
        Modify("Ship-to Code")
        {
            editable = false;
        }
        Modify("Ship-to Name")
        {
            editable = false;
        }
        Modify("Ship-to Post Code")
        {
            editable = false;
        }
        Modify("Ship-to Country/Region Code")
        {
            editable = false;
        }
        Modify("Ship-to Contact")
        {
            editable = false;
        }
        Modify("Posting Date")
        {
            editable = false;
        }
        Modify("Purchaser Code")
        {
            editable = false;
        }
        Modify("Shortcut Dimension 1 Code")
        {
            editable = false;
        }
        Modify("Shortcut Dimension 2 Code")
        {
            editable = false;
        }
        Modify("Location Code")
        {
            editable = false;
        }
        Modify("No. Printed")
        {
            editable = false;
        }
        Modify("Document Date")
        {
            editable = false;
        }
        Modify("Shipment Method Code")
        {
            editable = false;
        }

        Modify("Document Profile")
        {
            editable = false;
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("Co&mments")
        {
            action(ModifyDocumentNo)
            {
                Caption = 'Modifier N° BL Frs';
                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;
}