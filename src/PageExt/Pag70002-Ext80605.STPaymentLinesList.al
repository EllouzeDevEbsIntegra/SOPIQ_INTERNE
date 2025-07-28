pageextension 80605 "STPayment Lines List" extends "STPayment Lines List" //70002
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(Modify)
        {
            action("Mentionner Aval")
            {
                ApplicationArea = All;
                Caption = 'Mentionner Aval';
                Image = SuggestSalesPrice;
                trigger OnAction()
                var
                    myInt: Integer;
                begin
                    if Confirm('Voulez-vous vraiment mentionner "AVAL" sur les traites sélectionnées ?', true) then begin
                        rec."Drawee Reference" := 'AVAL';
                        rec.Modify();
                    end;

                end;
            }
        }
    }

    var
        myInt: Integer;
}