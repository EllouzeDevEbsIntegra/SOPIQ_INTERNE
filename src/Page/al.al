page 25006999 "TecDoc Articles"
{
    PageType = Card;
    SourceTable = "TecDoc Article Buffer";
    Caption = 'Article TecDoc';
    Editable = false;

    layout
    {
        area(content)
        {
            group(Générale)
            {
                Caption = 'Générale';
                field(Référence; Rec.Référence)
                {
                    ApplicationArea = All;
                }
                field(Fabricant; Rec.Fabricant)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(Famille; Rec.Famille)
                {
                    ApplicationArea = All;
                    Caption = 'Famille';
                }
            }
        }
    }
}
