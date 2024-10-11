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
            field("Activ. Def. Bin Purch.Order"; "Activ. Def. Bin Purch.Order")
            {
                ApplicationArea = all;
                Caption = 'Activer Emp Par Déf Cmd Achat';
                trigger OnValidate()
                begin
                    if xRec."Activ. Def. Bin Purch.Order" = false then begin
                        if ("Default Location Purch.Order" = '') OR ("Default Bin Purch.Order" = '') then begin
                            Error('Vous devez spécifier magasin et contenu par défaut pour commande achat !');
                        end
                    end
                end;
            }
            field("Default Location Purch.Order"; "Default Location Purch.Order")
            {
                ApplicationArea = all;
                Caption = 'Magasin par défaut Cmd Achat';
                Editable = NOT "Activ. Def. Bin Purch.Order";
                trigger OnValidate()
                begin
                    if rec."Default Location Purch.Order" = '' then begin
                        "Default Bin Purch.Order" := '';
                        rec.Modify();
                    end
                end;
            }
            field("Default Bin Purch.Order"; "Default Bin Purch.Order")
            {
                ApplicationArea = all;
                Caption = 'Emplacement par défaut Cmd Achat';
                Editable = NOT "Activ. Def. Bin Purch.Order";
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