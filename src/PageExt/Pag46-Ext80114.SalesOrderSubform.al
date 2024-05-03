pageextension 80114 "Sales Order Subform" extends "Sales Order Subform" //46
{
    layout

    {

        addbefore("No.")
        {
            field("No2"; "No.")
            {
                ApplicationArea = Basic, Suite;
                ShowMandatory = NOT IsCommentLine;
                ToolTip = 'Specifies the number of a general ledger account, item, resource, additional cost, or fixed asset, depending on the contents of the Type field.';

                trigger OnValidate()
                begin
                    Validate("No.");
                end;
            }
        }
        addafter("Unit Price") // Ajout du champ prix initial dans ligne vente
        {
            field("Available Qty"; "Available Qty")
            {
                ApplicationArea = All;
                Caption = 'Stock Disponible';
                Editable = false;
                StyleExpr = FieldStyleQty;
                DecimalPlaces = 0 : 2;

            }
            field("Prix Initial"; rec."Initial Unit Price")
            {
                ApplicationArea = All;
            }

            field("Amount Including VAT"; "Amount Including VAT")
            {
                ApplicationArea = all;
                Caption = 'Mnt TTC';
            }

            field("Received Quantity"; "Received Quantity")
            {
                ApplicationArea = All;
                DecimalPlaces = 0 : 2;
                Editable = false;
            }

            field(lastSalesDocType; lastSalesDocType)
            {
                ApplicationArea = all;
                Editable = false;
            }
            field(lastSalesPrice; lastSalesPrice)
            {
                ApplicationArea = all;
                Editable = false;
            }

            field(lastSalesDate; lastSalesDate)
            {
                ApplicationArea = all;
                Editable = false;
            }

            field(lastSalesDiscount; lastSalesDiscount)
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(ItemTransaction)
        {
            action("Sales Price Update")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mettre à jours prix de vente';
                Image = UpdateUnitCost;
                trigger OnAction()
                var
                    messageValidate: Label 'Voulez vous vraiment mettre à jour le prix de vente défini sur cette commande dans fiche article !';

                begin
                    recItem2.reset();

                    if Confirm(messageValidate) then begin
                        recItem2.SetRange("No.", "No.");
                        if recitem2.FindSet() then begin
                            recItem2."Unit Price" := rec."Unit Price";
                            recItem2.Validate("Unit Price");
                            recItem2.Modify();
                        end;

                    end;
                end;

            }
        }
        addafter(ApplyDiscount)
        {
            action("Reserve All")
            {
                Caption = 'Réserver Tous';
                Image = ItemReservation;
                trigger OnAction()
                var
                    messageValidate: Label 'Voulez vous vraiment réserver tous les articles de cette commande !';
                    SalesLine: Record "Sales Line";
                begin

                    if Confirm(messageValidate) then begin
                        SalesLine.Reset();
                        SalesLine.SetRange("Document No.", rec."Document No.");
                        if SalesLine.FindSet() then begin
                            repeat
                                SalesLine.Reserve := Reserve::Always;
                                SalesLine.Modify();
                                // SalesLine.Validate("Reserved Quantity", "Outstanding Quantity");
                                SalesLine.AutoReserve();
                            until SalesLine.Next() = 0;
                        end

                    end;
                    CurrPage.Update();
                end;

            }
        }
    }

    var
        Text006: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        recItem, recItem2 : Record "Item";
        GLSetupRead: Boolean;
        recInventorySetup: Record "Inventory Setup";
        FieldStyleQty: Text[50];

    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    trigger OnAfterGetRecord()
    begin
        FieldStyleQty := SetStyleQte("Available Qty");
        CalcFields("Received Quantity");
    end;

}