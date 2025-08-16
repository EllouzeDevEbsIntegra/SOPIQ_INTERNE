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
                field("Item Created"; "Item Created")
                {
                    ApplicationArea = All;
                }
            }
        }

    }
    actions
    {
        area(processing)
        {
            action("Créer dans Items")
            {
                ApplicationArea = All;
                Caption = 'Créer dans Items';
                Image = Add;
                Enabled = not (creatd);
                trigger OnAction()
                var

                begin
                    Message('A compléter cette partie !');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Item Created");
        if "Item Created" then
            creatd := true
        else
            creatd := false;
    end;

    var
        creatd: Boolean;

}
