pageextension 80115 "Transit Folder card" extends "Transit Folder card" //50002
{
    layout
    {

        addafter("Produit équivalent Comparateur")
        {

            part("Kit Comparateur"; "Kit Comparateur")
            {

                Caption = 'Composant / Kit';
                Provider = "Purchase Recep. Lines";
                SubPageLink = "Parent Item No." = FIELD("No.");
                UpdatePropagation = Both;

            }

        }

    }

    actions
    {
        addafter(Cloturer)
        {
            action("Tarification") // MAJ des quelques champs sur la fiche article dans toute la table article
            {
                ApplicationArea = All;
                Caption = 'Tarification';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Purch. Recept. Lines";
                RunPageLink = "Transit Folder No." = FIELD("No.");
                RunPageView = SORTING("Document No.", "Line No.")
                              WHERE(Type = FILTER(Item | "Fixed Asset"));

                Visible = true;
                Enabled = true;
            }
        }

    }

    var
        myInt: Integer;
}