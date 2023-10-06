tableextension 80170 "Sales & Receivables Setup" extends "Sales & Receivables Setup"//311
{
    fields
    {
        // Add changes to table fields here
        field(80170; "UndoShipment"; Boolean)
        {
            InitValue = false;
        }
    }

    var
        myInt: Integer;
}