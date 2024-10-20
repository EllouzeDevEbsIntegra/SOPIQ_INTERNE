tableextension 80114 "Customer" extends "Customer" //18
{
    fields
    {
        field(80109; "Cust. Doc. Trans. Filter"; Boolean)
        {

        }
        field(80110; "No. of Pstd. BS"; Integer)
        {
            CalcFormula = Count("Sales Shipment Header" WHERE("Sell-to Customer No." = FIELD("No."), BS = filter(true)));
            Caption = 'No. of Pstd. BS';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80112; "Is Divers"; Boolean)
        {
            AutoFormatType = 1;
            Caption = 'Client Divers';
        }

        field(80113; "Dep Enc Princ."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Dépassement Encour Principal';
        }

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


        field(90000; "Total Encours Financier"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Encours Financier';
            Editable = false;
        }


        field(80120; "Cheque En Coffre"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_CHEQUE'),
                                                                 "Account No." = field("No."),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(21000)
                                                                 ));
            Caption = 'Chèque en coffre';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80900; "Cheque Impaye"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_CHEQUE'),
                                                                 "Account No." = field("No."),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(32000)
                                                                 ));
            Caption = 'Chèque Impayé';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80121; "Traite En Coff."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account No." = field("No."),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(30000)
                                                                 ));
            Caption = 'Traite en coffre';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80122; "Traite En Escompte"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account No." = field("No."),
                                                                 "Account Type" = FILTER(Customer),
                                                                 "Copied To No." = FILTER('')
                                                                , "Status No." = FILTER(50030)
                                                                 , "Due Date" = filter('>a')));
            Caption = 'Traite en escompte';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80901; "Traite Impaye"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account No." = field("No."),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(40050 | 50070)
                                                                 ));
            Caption = 'Traite Impayée';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80902; "Moyen Jour Paiement"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Moyen Jour Paiement';
        }
        field(80903; "Moyen Amount / Facture"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Moyen TTC / Facture';
        }



    }

    var
        myInt: Integer;

    procedure CalcMoyenParClient()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        MoyenJourPaiement, MoyenAmountParFacture, nbInvoice, totalInvoice : Decimal;
        recCustomer: Record Customer;
    begin
        // Calcul Moyen de jour Paiement pour chaque client
        if recCustomer.FindSet() then begin
            repeat
                MoyenJourPaiement := 0;
                totalInvoice := 0;
                MoyenAmountParFacture := 0;
                SalesInvoiceHeader.Reset();
                SalesInvoiceHeader.SetRange("Bill-to Customer No.", recCustomer."No.");
                SalesInvoiceHeader.CalcFields("Remaining Amount");
                SalesInvoiceHeader.SetRange("Remaining Amount", 0);
                nbInvoice := SalesInvoiceHeader.Count;

                if SalesInvoiceHeader.FindSet() then begin
                    repeat
                        MoyenJourPaiement := MoyenJourPaiement + SalesInvoiceHeader.MoyJourPaiement(SalesInvoiceHeader);
                        SalesInvoiceHeader.CalcFields("Amount Including VAT");
                        totalInvoice := totalInvoice + SalesInvoiceHeader."Amount Including VAT";
                    until SalesInvoiceHeader.Next() = 0;
                    MoyenJourPaiement := MoyenJourPaiement / nbInvoice;
                    MoyenAmountParFacture := totalInvoice / nbInvoice;
                end;
                recCustomer."Moyen Jour Paiement" := MoyenJourPaiement;
                recCustomer."Moyen Amount / Facture" := MoyenAmountParFacture;
                recCustomer.Modify();
            until recCustomer.Next() = 0;

        end


    end;
}