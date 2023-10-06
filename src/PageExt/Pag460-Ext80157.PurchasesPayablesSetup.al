pageextension 80157 "Purchases & Payables Setup" extends "Purchases & Payables Setup" //460
{
    layout
    {
        // Add changes to page layout here
        addafter("Nbr Days Item recently created")
        {
            field("Default Vendor"; "Default Vendor")
            {
                ApplicationArea = All;
                Caption = 'Fournisseur Par Défaut';
            }

            field("MF obligatoire"; "MF obligatoire")
            {
                ApplicationArea = All;
                Caption = 'MF Fournisseur Obligatoire';
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