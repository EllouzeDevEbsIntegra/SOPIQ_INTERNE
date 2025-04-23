page 25006999 "TecDoc Articles List"
{
    PageType = List;
    SourceTable = "TecDoc Article Buffer";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    CardPageId = "Article Tecdoc Details";
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Référence; Référence) { }
                field(Fabricant; Fabricant) { }
                field(Description; Description) { }
                field(Famille; Famille) { }
            }
        }
    }
}
