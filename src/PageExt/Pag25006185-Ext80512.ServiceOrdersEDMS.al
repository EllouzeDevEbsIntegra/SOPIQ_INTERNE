pageextension 80512 "Service Orders EDMS" extends "Service Orders EDMS" //25006185
{
    layout
    {
        // Add changes to page layout here
        addafter(DocumentStatus)
        {
            field(Masquer; Masquer)
            {
                ApplicationArea = All;
                Caption = 'Masquer';
            }
            field("Initiator Code"; "Initiator Code")
            {
                ApplicationArea = all;
                Caption = 'Code Initiateur';
                Editable = true;
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