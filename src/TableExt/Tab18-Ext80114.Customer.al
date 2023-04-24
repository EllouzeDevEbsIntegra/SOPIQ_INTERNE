tableextension 80114 "Customer" extends "Customer" //18
{
    fields
    {
        // Add changes to table fields here
        field(80114; "Opened Invoice"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" WHERE("Document Type" = filter('Facture| Avoir'), "Customer No." = FIELD("No."), STOuvert = filter('Oui')));
            Caption = 'Opened Invoice';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80115; "Shipped Not Invoiced BL"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Shipped Not Invoiced (LCY)" WHERE("Document Type" = CONST(Order),
                                                                               "Bill-to Customer No." = FIELD("No."),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Currency Code" = FIELD("Currency Filter"), "Shipped Not Invoiced (LCY)" = FILTER(> 0),
                                                                               "Expédition type" = filter('Expédition')));
            Caption = 'Livré non facturé BL';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80116; "Nb Opened Invoice"; Integer)
        {
            AutoFormatType = 1;
            CalcFormula = count("Detailed Cust. Ledg. Entry" WHERE("Document Type" = filter('Facture'), "Customer No." = FIELD("No."), STOuvert = filter('Oui')));
            Caption = 'Nb Opened Invoice';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80117; "Nb Facture NP"; Integer)
        {
            Caption = 'Nombre de facture non payée autorisée';
            InitValue = 2;
        }

        field(80118; "Return Receipts Not Invoiced"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Sales Line"."Return Rcd. Not Invd. (LCY)" WHERE("Document Type" = CONST("Return Order"),
                                                                               "Bill-to Customer No." = FIELD("No."),
                                                                               "Shortcut Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Shortcut Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                               "Currency Code" = FIELD("Currency Filter"), "Return Rcd. Not Invd. (LCY)" = FILTER(> 0)));
            Caption = 'Réception retour non facturé';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80119; "Is Special Vendor"; Boolean)
        {
            AutoFormatType = 1;
            InitValue = false;
            trigger OnValidate()
            var
                recSalesPrice: Record "Sales price";
            Begin
                if NOT ("Is Special Vendor") THEN BEGIN
                    if Confirm('Voulez vous supprimer tous les prix spéciaux de ce client ?') then begin
                        recSalesPrice.Reset();
                        recSalesPrice.SetRange("Sales Type", recSalesPrice."Sales Type"::Customer);
                        recSalesPrice.SetRange("Sales Code", "No.");
                        if recSalesPrice.FindSet() then begin
                            repeat
                                recSalesPrice.Delete();
                            until recSalesPrice.Next = 0;
                        end;
                    end

                END


            End;
        }

    }

    var
        myInt: Integer;
}