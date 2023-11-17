tableextension 80341 "Payment Header" extends "Payment Header"//10865

{
    fields
    {
        // Add changes to table fields here
        field(80378; AbreviationPaimentType; Code[10])
        {
            caption = 'Abréviation Type Paiement';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnAfterInsert()
    VAR
        PaimentClass: Record "Payment Class";
    begin
        PaimentClass.Reset();
        PaimentClass.SetRange(Code, "Payment Class");
        if PaimentClass.FindFirst() then rec.AbreviationPaimentType := PaimentClass.AbreviationPaimentType;
    end;

}