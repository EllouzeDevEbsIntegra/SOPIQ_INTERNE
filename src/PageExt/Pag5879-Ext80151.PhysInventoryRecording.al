pageextension 80151 "Phys. Inventory Recording" extends "Phys. Inventory Recording" //5879
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        // addafter(Print)
        // {
        //     action("Print Inv")
        //     {
        //         ApplicationArea = Warehouse;
        //         Caption = 'Imprimer Etat Inventaire';
        //         Ellipsis = true;
        //         Image = Print;
        //         Promoted = true;
        //         PromotedCategory = Process;
        //         ToolTip = 'Print the recording document. The printed document has an empty column in which to write the counted quantities.';

        //         trigger OnAction()
        //         begin
        //             DocPrint.PrintInvtRecording(Rec, true);
        //         end;
        //     }
        // }
    }

    var
        DocPrint: Codeunit "Document-Print";
}