tableextension 80104 "Purchase Line" extends "Purchase Line" //39
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                if recItem.Get("No.") then Marge := recItem."Profit %";
            end;
        }

        modify(Preferential)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                recItem.Reset();
                recItem.SetRange("No.", "No.");
                if recItem.FindFirst() then begin
                    recItem."Last. Preferential" := Preferential;
                    recItem.Modify();
                end;
            end;
        }


        field(80105; "Marge"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Marge à définir';
            Editable = true;
        }



    }

    var
        myInt: Integer;


}