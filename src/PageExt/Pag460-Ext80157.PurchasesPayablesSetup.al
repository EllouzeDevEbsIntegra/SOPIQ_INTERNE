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

            field(UpdateProfitOblogatoire; UpdateProfitOblogatoire)
            {
                ApplicationArea = All;
                Caption = 'Mise à jour marge CA obligatoire';
            }
            field(PurchaserCodeRequired; PurchaserCodeRequired)
            {
                ApplicationArea = all;
                Caption = 'Code acheteur obligatoire';
            }

            field(controlePurshOrder; controlePurshOrder)
            {
                ApplicationArea = all;
                Caption = 'Contrôle Commande Achat';
            }
            field("Current Year"; "Current Year")
            {
                ApplicationArea = All;
                Caption = 'Année courante';
                Editable = false;
            }
            field("Last Year"; "Last Year")
            {
                ApplicationArea = All;
                Caption = 'Année précédente';
                Editable = false;
            }
            field("Last Year-1"; "Last Year-1")
            {
                ApplicationArea = All;
                Caption = 'Année avant précédente';
                Editable = false;
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