tableextension 80132 "Item Discount Group" extends "Item Discount Group"//341
{
    fields
    {
        field(80132; "Code Groupe"; Code[50])
        {
            Caption = 'Code Groupe';

            TableRelation = "Item Category".Code where(Indentation = filter(1));
        }

        field(80133; "Code Fabricant"; Code[50])
        {
            Caption = 'Code Fabricant';

            TableRelation = "Manufacturer".Code;
        }

    }

    var
        myInt: Integer;
}