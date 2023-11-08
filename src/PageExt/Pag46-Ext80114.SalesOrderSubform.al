pageextension 80114 "Sales Order Subform" extends "Sales Order Subform" //46
{
    layout

    {

        addafter("Unit Price") // Ajout du champ prix initial dans ligne vente
        {
            field("Stk Mg Principal"; "Stk Mg Principal")
            {
                ApplicationArea = All;
                Editable = false;
                StyleExpr = FieldStyleQty;
                DecimalPlaces = 0 : 2;

            }
            field("Prix Initial";
            rec."Initial Unit Price")
            {
                ApplicationArea = All;
            }

            field("Received Quantity"; "Received Quantity")
            {
                ApplicationArea = All;
                DecimalPlaces = 0 : 2;
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
        FieldStyleQty := SetStyleQte("Stk Mg Principal");
        CalcFields("Received Quantity");
    end;

}