tableextension 80112 "Transfer Header" extends "Transfer Header"//5740
{
    fields
    {
        modify("Transit Folder No.")
        {
            trigger OnAfterValidate()
            var
                recTransitFolder: Record "Transit Folder";
            begin

                recTransitFolder.SetRange("No.", "Transit Folder No.");
                if recTransitFolder.FindSet() then begin
                    if not (recTransitFolder."Item Price Updated") then Error('Mise à jour de prix article non effectuée pour le dossier d''import N° %1', recTransitFolder."No.");
                end

            end;
        }
        // Add changes to table fields here
    }

    var
        myInt: Integer;
}