pageextension 80190 "Posted Sales Invoice Subform" extends "Posted Sales Invoice Subform"//133
{
    layout
    {
        // Add changes to page layout here
        addafter("Unit Price")
        {
            field("Prix Initial"; "Initial Unit Price")
            {

            }

            field("Remise Initial"; "Initial Discount")
            {

            }
            field("Ctrl Facture"; "Ctrl Invoice Modified")
            {

            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Initial Unit Price", "Initial Discount", "Price modified", "Discount modified")
    end;
}