pageextension 80426 "Document Status List" extends "Document Status List" //25006435
{
    layout
    {
        // Add changes to page layout here
        addafter(NextStatusonWorkFinished)
        {
            field(SendMsg; SendMsg)
            {
                ApplicationArea = all;
                Caption = 'Envoyer Message';
            }

            field(Message; Message)
            {
                ApplicationArea = all;
                Caption = 'Message à envoyer';
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