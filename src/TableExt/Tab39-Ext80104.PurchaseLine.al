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