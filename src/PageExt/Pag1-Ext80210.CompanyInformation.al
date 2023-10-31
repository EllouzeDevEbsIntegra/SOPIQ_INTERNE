pageextension 80210 "Company Information" extends "Company Information" // 1
{
    layout
    {
        // Add changes to page layout here
        addafter(Picture)
        {
            field(Company; Company)
            {
                ApplicationArea = Basic;
                Caption = 'Société';

            }
            field("Base Company"; "Base Company")
            {
                ApplicationArea = Basic;
                Caption = 'Société de base';
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