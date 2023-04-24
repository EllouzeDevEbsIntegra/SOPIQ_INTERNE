tableextension 80117 "Bin Content" extends "Bin Content" //7302
{
    fields
    {
        field(50113; "Count Content"; Integer)
        {
            Caption = 'Nombre d''emplacement';

            FieldClass = FlowField;
            CalcFormula = count("Bin Content" where("Location Code" = filter('<> ''LITIGE'''), "Bin Code" = filter('<>''RECEPTION'''), "Quantity" = filter(> 0), "Item No." = field("Item No.")));
        }
    }

    var
        myInt: Integer;
}