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
        addafter(DocAttach)
        {
            action("Modify Invoice")
            {
                ApplicationArea = All;
                Caption = 'Modifier Facture';
                Image = Edit;

                trigger OnAction()
                var
                    SalesInvoiceLine: Record "Sales Invoice Line";
                    ModifySalesLineDescription: Page "Modify Sales Line Description";
                begin
                    SalesInvoiceLine.SetRange("Document No.", Rec."Document No.");
                    SalesInvoiceLine.SetRange("Line No.", Rec."Line No.");
                    ModifySalesLineDescription.SetTableView(SalesInvoiceLine);
                    ModifySalesLineDescription.RunModal();
                end;
            }
        }

    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Initial Unit Price", "Initial Discount", "Price modified", "Discount modified")
    end;
}