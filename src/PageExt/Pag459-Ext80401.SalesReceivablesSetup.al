pageextension 80401 "Sales & Receivables Setup" extends "Sales & Receivables Setup" //459
{
    layout
    {
        // Add changes to page layout here
        addafter("Enable Stock Avail. Selection")
        {
            field(UndoShipment; UndoShipment)
            {
                ApplicationArea = All;
                Caption = 'Autoriser annuler expédition';
            }

            field(VendorCodeRequired; VendorCodeRequired)
            {
                ApplicationArea = all;
                Caption = 'Code vendeur Obligatoire';
            }


        }

        addafter("Price Analy. % Average Disc.")
        {
            field(Tolerance; Tolerance)
            {
                Caption = 'Tolérance de comparaison';
                ApplicationArea = all;
                DecimalPlaces = 0 : 2;
            }

            field(margeStandard; margeStandard)
            {
                Caption = 'Marge Standard';
                ApplicationArea = all;
                DecimalPlaces = 0 : 2;
            }

            field(margeSpecifique; margeSpecifique)
            {
                Caption = 'Marge Spécifique';
                ApplicationArea = all;
                DecimalPlaces = 0 : 2;
            }
        }
        modify("Price Analy. % Average Disc.")
        {
            Visible = false;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}