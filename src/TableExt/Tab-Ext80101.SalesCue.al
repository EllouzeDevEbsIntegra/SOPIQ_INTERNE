tableextension 80101 "Sales Cue" extends "Sales Cue"

{
    fields
    {


        field(50100; "Month Sum Purchase"; Decimal)
        {
            Caption = 'Total achat du mois';

            FieldClass = FlowField;
            CalcFormula = sum("Purch. Inv. Line"."Amount" WHERE("Posting Date" = field("Date Filter Month"), "Buy-from Vendor No." = field("Default Vendor")));
            // CalcFormula = sum("Sales Shipment Line"."Line Amount" where("Shipment Date" = field("date jour")));

        }

        field(50101; "Today Sum Sales"; Decimal)
        {
            Caption = 'Total des ventes du jour';

            FieldClass = FlowField;
            CalcFormula = sum("Sales Line"."Line Amount" where("Shipment Date" = field("date jour"), "Document Type" = filter(order)));
            // CalcFormula = sum("Sales Shipment Line"."Line Amount" where("Shipment Date" = field("date jour")));

        }

        field(50102; "Today Sum Return"; Decimal)
        {
            Caption = 'Total des retours du jour';

            FieldClass = FlowField;
            CalcFormula = sum("Sales Line"."Line Amount" where("Shipment Date" = field("date jour"), "Document Type" = filter("Return Order")));
            // CalcFormula = sum("Sales Shipment Line"."Line Amount" where("Shipment Date" = field("date jour")));

        }

        field(50103; "Sales Line PU Modif"; Integer)
        {
            Caption = 'Ligne vente avec prix unitaire modifié';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Price modified" = filter(true), "Ctrl Modified Price" = filter(false), "Document Type" = filter(Order)));

        }

        field(50111; "Sales Line Disc. Modif"; Integer)
        {
            Caption = 'Ligne vente avec remise modifié';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Discount modified" = filter(true), "Ctrl Modified Discount" = filter(false), "Document Type" = filter(Order)));

        }

        // field(50120; "Sales Invoice Price. Modif"; Integer)
        // {
        //     Caption = 'Ligne Facture vente avec prix modifié';

        //     FieldClass = FlowField;
        //     CalcFormula = count("Sales Invoice Line" where("Price modified" = filter(true), "Ctrl Invoice Modified" = filter(false)));

        // }

        // field(50121; "Sales Invoice Disc. Modif"; Integer)
        // {
        //     Caption = 'Ligne Facture vente avec remise modifié';

        //     FieldClass = FlowField;
        //     CalcFormula = count("Sales Invoice Line" where("Discount modified" = filter(true), "Ctrl Invoice Modified" = filter(false)));

        // }



        field(50104; "date jour"; Date)
        {

        }

        field(50200; "Date Filter Month"; Date)
        {
            Caption = 'Date Filter Month';
            Editable = false;
            FieldClass = FlowFilter;
        }

        field(50201; "Default Vendor"; Code[20])
        {

        }

        field(50115; "First Day Of Year"; Date)
        {
            Caption = 'Date Debut Année';
            FieldClass = FlowFilter;
        }

        field(50105; "Item Bin"; Integer)
        {
            Caption = 'Article avec plusieurs emplacement';
            FieldClass = FlowField;
            CalcFormula = count("Bin Content" where("Count Content" = filter(> 1), "Quantity (Base)" = filter(> 0), "Location Code" = filter('<>''LITIGE'''), "Bin Code" = filter('<>''RECEPTION''')));
        }

        field(50110; "Neg Ajust Year"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Item Ledger Entry" where("Entry Type" = filter('''Négatif (ajust.)'''), "Posting Date" = field("First Day Of Year")));
        }


        field(70013; "Purchase Special Order Echu"; Integer)
        {
            Caption = 'Ligne commande achat spécial échue';

            FieldClass = FlowField;
            CalcFormula = count("Purchase Line" where("Special Order" = filter(true), "Document Type" = filter(Order), "Quantity Received" = filter(0), "Planned Receipt Date" = field("Date Filter")));
        }

        field(70014; "Purchase Special Order"; Integer)
        {
            Caption = 'Ligne commande achat spécial en attente';

            FieldClass = FlowField;
            CalcFormula = count("Purchase Line" where("Special Order" = filter(true), "Document Type" = filter(Order), "Quantity Received" = filter(0)));
        }

        field(70015; "Reci. Purch. Special Order"; Integer)
        {
            Caption = 'Ligne commande achat spécial réceptionnée';

            FieldClass = FlowField;
            CalcFormula = count("Purchase Line" where("Special Order" = filter(true), "Document Type" = filter(Order), "Quantity Received" = filter(<> 0)));
        }

        field(70016; "Sal. Spec. Order Not Ship."; Integer)
        {
            Caption = 'Ligne commande vente spécial non expédiée';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Special Order" = filter(true), "Document Type" = filter(Order), "Completely Shipped" = filter(false), "Received Quantity" = filter(0), "Special Order Purchase No." = filter(<> '')));
        }

        field(70017; "Sal. Spec. Order ready Ship."; Integer)
        {
            Caption = 'Ligne commande vente spécial prêt pour expédition';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Special Order" = filter(true), "Document Type" = filter(Order), "Completely Shipped" = filter(false), "Received Quantity" = filter(<> 0), "Special Order Purchase No." = filter(<> '')));
        }

        field(70018; "Spec. Order Not Purch. Order"; Integer)
        {
            Caption = 'Ligne commande vente spécial non commandée';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Special Order" = filter(true), "Document Type" = filter(Order), "Completely Shipped" = filter(false), "Special Order Purchase No." = filter('')));
        }

        field(70019; "Sales Order Not Ship."; Integer)
        {
            Caption = 'Ligne commande vente non expédiée';

            FieldClass = FlowField;
            CalcFormula = count("Sales Line" where("Special Order" = filter(false), "Document Type" = filter(Order), "Completely Shipped" = filter(false)));
        }

        field(70020; "Sales Ship. Not Invoiced"; Integer)
        {
            Caption = 'Ligne Bon de livraison vente non facturée';

            FieldClass = FlowField;
            CalcFormula = count("Sales Shipment Line" where("Quantity Invoiced" = filter(0), "Type" = filter('Article'), "BS" = filter(false)));
        }

        field(70021; "Sales Return Not Invoiced"; Integer)
        {
            Caption = 'Ligne Bon de retour vente non facturée';

            FieldClass = FlowField;
            CalcFormula = count("Return Receipt Line" where("Quantity Invoiced" = filter(0), "Type" = filter('Article')));
        }

        field(70022; "unpaid invoice"; Integer)
        {
            Caption = 'Facture non réglée';

            FieldClass = FlowField;
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter('Facture'), "open" = filter(true)));
        }


        field(80210; "Cheque En Coffre"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_CHEQUE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(21000)
                                                                 ));
            Caption = 'Chèque en coffre';
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 0;
        }

        field(80211; "Cheque Impaye"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_CHEQUE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(32000)
                                                                 ));
            Caption = 'Chèque Impayé';
            Editable = false;
            FieldClass = FlowField;

        }

        field(80212; "Traite En Coff."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(30000)
                                                                 ));
            Caption = 'Traite en coffre';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80213; "Traite En Escompte"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                 "Copied To No." = FILTER('')
                                                                , "Status No." = FILTER(50030)
                                                                 , "Due Date" = filter('>a')));
            Caption = 'Traite en escompte';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80214; "Traite Impaye"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(40050 | 50070)
                                                                 ));
            Caption = 'Traite Impayée';
            Editable = false;
            FieldClass = FlowField;
        }
    }

}