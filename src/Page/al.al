page 25006999 "TecDoc Articles"
{
    PageType = List;
    SourceTable = "TecDoc Article Buffer";
    Caption = 'Articles TecDoc';
    Editable = false;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Référence; Référence)
                {
                    ApplicationArea = All;
                }
                field(Fabricant; Fabricant)
                {
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(Famille; Famille)
                {
                    ApplicationArea = All;
                    Caption = 'Famille';
                }
            }
        }
    }
}
