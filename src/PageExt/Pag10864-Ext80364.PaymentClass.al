pageextension 80364 "Payment Class" extends "Payment Class" //10864
{
    layout
    {
        // Add changes to page layout here
        addafter(Code)
        {
            field(AbreviationPaimentType; AbreviationPaimentType)
            {
                caption = 'Abréviation Type Paiement';
                ApplicationArea = all;
                ToolTip = 'Ajouter l''abréviation à ajouter au début du commentaire du ligne paiement. Exemple pour l''encaissement espèce ENC ESP, chèque ENC CHQ etc...';
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