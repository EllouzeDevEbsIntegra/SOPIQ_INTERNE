pageextension 80342 "Sales Return Order Subform" extends "Sales Return Order Subform"//6631
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(ApplyDiscount)
        {
            action(ApplyLocation)
            {
                Caption = 'Appliquer Emplacement';
                Image = Home;
                trigger OnAction()
                var
                    salesLine, salesLine2 : Record "Sales Line";
                begin
                    CurrPage.SetSelectionFilter(SalesLine);
                    SalesLine.FindFirst();
                    salesLine2.Reset();
                    salesLine2.SetRange("Document Type", SalesLine."Document Type");
                    salesLine2.SetRange("Document No.", SalesLine."Document No.");
                    salesLine2.SetRange(Type, salesLine2.Type::Item);
                    if salesLine2.FindSet() then
                        repeat
                            salesLine2.Validate("Location Code", salesLine."Location Code");
                            salesLine2.Validate("Bin Code", SalesLine."Bin Code");
                            salesLine2.Modify(true);
                        until salesLine2.Next() = 0;

                end;
            }
        }
    }

    var
        myInt: Integer;
}