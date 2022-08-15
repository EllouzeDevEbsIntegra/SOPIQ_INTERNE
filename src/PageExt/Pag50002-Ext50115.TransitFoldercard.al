pageextension 50115 "Transit Folder card" extends "Transit Folder card" //50002
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

    }

    var
        myInt: Integer;
}