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

            field("Reservation Obligatoire"; "Reservation Obligatoire")
            {
                ApplicationArea = All;
                Caption = 'Reservation article Obligatoire';
                ToolTip = 'En activant cette option, l''option reserver sur la fiche article prend automatiquement la valeur Toujours.';
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