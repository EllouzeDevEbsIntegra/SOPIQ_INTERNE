tableextension 80378 "Payment Class" extends "Payment Class" //10860
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
}