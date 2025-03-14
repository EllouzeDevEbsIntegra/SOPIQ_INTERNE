pageextension 80138 "Customer Card" extends "Customer Card"//21
{
    layout
    {
        // Add changes to page layout here
        modify("Traite en coffre")
        {
            Visible = false;
        }

        modify("Chèques en coffre")
        {
            Visible = false;
        }

        addafter("Encours sur encaissement en coffre")
        {
            field("Nb Facture NP"; "Nb Facture NP")
            {
                ApplicationArea = All;
                Caption = 'Nombre de facture non payée autorisée';
            }

            group("Encours Chèques")
            {
                field("Cheque En Coffre"; "Cheque En Coffre")
                {
                    ApplicationArea = All;
                    Caption = 'Chèque En Coffre';
                }

                field("Cheque Impaye"; "Cheque Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Chèque Impayé';
                }
            }
            group("Encours Traites")
            {
                field("Traite En Coff."; "Traite En Coff.")
                {
                    ApplicationArea = All;
                    Caption = 'Traite En Coffre';
                }

                field("Traite En Escompte"; "Traite En Escompte")
                {
                    ApplicationArea = All;
                    Caption = 'Traite Escomptée';
                }

                field("Traite Impaye"; "Traite Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Traite Impayée';
                }
            }

        }
        addafter("Customer Disc. Group")
        {
            field("Is Special Vendor"; "Is Special Vendor")
            {
                ApplicationArea = All;
                Caption = 'Client Spécial';
            }

            field("Is Divers"; "Is Divers")
            {
                ApplicationArea = all;
                Caption = 'Client Divers';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnOpenPage()
    begin
        CalcFields("Traite En Escompte", "Cheque En Coffre", "Cheque Impaye", "Traite En Coff.", "Traite Impaye");
    end;
}