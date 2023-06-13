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
    }

}