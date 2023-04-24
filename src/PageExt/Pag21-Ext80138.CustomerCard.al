pageextension 80138 "Customer Card" extends "Customer Card"//21
{
    layout
    {
        // Add changes to page layout here

        addafter("Encours sur encaissement en coffre")
        {
            field("Nb Facture NP"; "Nb Facture NP")
            {
                ApplicationArea = All;
                Caption = 'Nombre de facture non payée autorisée';
            }
        }
        addafter("Customer Disc. Group")
        {
            field("Is Special Vendor"; "Is Special Vendor")
            {
                ApplicationArea = All;
                Caption = 'Client Spécial';
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