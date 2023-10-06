pageextension 80300 "Activities comptable" extends "Activities comptable" //70016
{
    layout

    {

        addafter(Control36)
        {
            cuegroup("Client")
            {
                Caption = 'Clients';
                field("Cheque En Coffre"; "Cheque En Coffre")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque En Coffre';
                    DecimalPlaces = 0 : 0;
                }

                field("Cheque Impaye"; "Cheque Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque Impayé';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite En Coff."; "Traite En Coff.")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite En Coffre';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite En Escompte"; "Traite En Escompte")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Escompte';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite Impaye"; "Traite Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Impayee';
                    DecimalPlaces = 0 : 0;
                }
            }
        }
        // Add changes to page layout here
        // modify(Clients)
        // {
        //     Visible = false;
        // }
        modify("Intelligent Cloud")
        {
            Visible = false;
        }
        modify(Control36)
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