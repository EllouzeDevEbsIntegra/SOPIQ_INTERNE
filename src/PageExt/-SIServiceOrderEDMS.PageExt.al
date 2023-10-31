pageextension 80153 "Service Order EDMS" extends "Service Order EDMS"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify("Imprimer Picking list")
        {
            Visible = true;
        }
        // Add changes to page actions here
        modify(InsertServicePackage)
        {
            Visible = false;
            Promoted = false;
        }
        addafter(InsertServicePackage)
        {
            action(SI_InsertServicePackage)
            {
                ApplicationArea = Basic;
                Caption = 'Inserer Service Package';
                Image = CopyFromTask;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SI_InsertServPackage
                end;
            }
        }
    }

    var
        myInt: Integer;
}