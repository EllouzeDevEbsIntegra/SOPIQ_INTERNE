page 25006996 "TecDoc Criteria Part"
{
    PageType = ListPart;
    SourceTable = "TecDoc Criteria Buffer";
    Editable = false;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Nom; Nom)
                {
                    Caption = 'Nom';
                }
                field(Valeur; Valeur)
                {
                    Caption = 'Valeur';
                }
            }
        }
    }
}
