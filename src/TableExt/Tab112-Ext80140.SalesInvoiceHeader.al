tableextension 80140 "Sales Invoice Header" extends "Sales Invoice Header"//112
{
    fields
    {
        // Add changes to table fields here
        field(80140; "Moy Jour Paiement"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Moyen Jour Paiement';
            DecimalPlaces = 0 : 2;
        }
    }

    var
        myInt: Integer;
}