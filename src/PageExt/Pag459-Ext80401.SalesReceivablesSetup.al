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

        addafter("Posted BC")
        {
            field("Reçu Caisse Serie"; "Reçu Caisse Serie")
            {
                Caption = 'N° Reçu de caisse';
                ApplicationArea = all;
            }

            field("Retour BS"; "Retour BS")
            {
                Caption = 'Retour BS';
                ApplicationArea = all;
            }


            field("Retour BS Enregistré"; "Retour BS Enregistré")
            {
                Caption = 'Retour BS Enregistré';
                ApplicationArea = all;
            }


        }
        modify("Price Analy. % Average Disc.")
        {
            Visible = false;
        }
        addafter("Prix de vente 1 % remise")
        {
            field("Same Price Order/BS"; "Same Price Order/BS")
            {
                ApplicationArea = all;
                Caption = 'Garder prix initial';
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