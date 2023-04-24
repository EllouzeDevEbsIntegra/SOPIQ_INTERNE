pageextension 80160 "Service Order Subform EDMS" extends "Service Order Subform EDMS"//25006184
{
    layout
    {
        // Add changes to page layout here
        addafter(UnitPrice)
        {
            field("Prix Vente Public"; "Prix Vente Public")
            {
                ApplicationArea = All;
                Caption = 'Prix Vente Public';
                Editable = false;
                style = Unfavorable;
            }

            field("Last Price First Vendor"; "Last Price First Vendor")
            {
                ApplicationArea = All;
                Caption = 'Dernier Prix Frs Principal';
                Editable = false;
            }

            field("Last Price Date"; "Last Price Date")
            {
                ApplicationArea = All;
                Caption = 'Date Prix Frs Principal';
                Editable = false;
            }

            field("Last Document Type"; "Last Document Type")
            {
                ApplicationArea = All;
                Caption = 'Type Doc Prix Frs Principal';
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