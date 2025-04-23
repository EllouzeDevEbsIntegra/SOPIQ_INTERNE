page 25006997 "TecDoc OEM Part"
{
    PageType = ListPart;
    SourceTable = "TecDoc OEM Buffer";
    Editable = false;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(OEMNumber; OEMNumber)
                {
                    Caption = 'OEM Number';
                }
                field(Marque; Marque)
                {
                    Caption = 'Marque';
                }
            }
        }
    }
}
