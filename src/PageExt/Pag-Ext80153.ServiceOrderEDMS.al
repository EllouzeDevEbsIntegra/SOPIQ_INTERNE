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
    }

    var
        myInt: Integer;
}