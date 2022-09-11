pageextension 80131 "Purchase Quote" extends "Purchase Quote" //49
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify(MakeOrder)
        {
            trigger OnBeforeAction()
            var
                recpurshLine: Record "Purchase Line";
            begin

                recpurshLine.Reset();

                recpurshLine.SetRange("Document No.", "No.");
                recpurshLine.SetFilter("asking price", '> 0');
                recpurshLine.SetRange("negotiated price", 0);
                if recpurshLine.FindFirst() then begin
                    //Message('Succés : %1 - %2 - %3', recpurshLine."Document No.", recpurshLine."asking price", recpurshLine."negotiated price");
                    Error('Vérifier les prix négociés dans la demande de prix %1', "No.");
                end;



            end;
        }
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}