pageextension 80116 "Vehicle SO Proc. Activities" extends "Vehicle SO Proc. Activities" //25006539
{
    layout
    {

        addbefore(B2B)
        {
            cuegroup(ADMIN)
            {
                Caption = 'Notification Admin';
                field("Unit price modified 2"; rec."Sales Line PU Modif")
                {
                    Caption = 'Prix vente modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }

                field("Today Sum Sales"; rec."Today Sum Sales")
                {
                    Caption = 'Vente du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;

                }
            }

        }




    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin
        if "date jour" <> Today then begin
            "date jour" := Today;
            Modify();
        end
    end;

    var
        myInt: Integer;
}