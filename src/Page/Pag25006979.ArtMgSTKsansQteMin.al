page 25006979 "Art. Mg STK sans Qte Min"
{
    Caption = 'Articles en Mg Stockage sans Qté min';
    PageType = List;
    SourceTable = Item;
    SourceTableView = sorting("No.") where("Mg STK Sans Qte Min" = const(true));
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    CardPageId = "Item Card";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    Caption = 'Réf.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Désignation';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("MainQty"; Rec."MainQty")
                {
                    Caption = 'Stock Mg Principal';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Default Bin"; Rec."Default Bin")
                {
                    Caption = 'Emplacement par défaut';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("StorageQty"; Rec."StorageQty")
                {
                    Caption = 'Stock Mg STOCK';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Qte Min Mg Principal"; Rec."Qte Min Mg Principal")
                {
                    Caption = 'Qté Min Mg Principal';
                    ApplicationArea = All;
                    ToolTip = 'Saisir ici la quantité minimum : l''article quitte cette liste au prochain recalcul.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Actualiser)
            {
                Caption = 'Actualiser';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Recalcule les alertes magasin de stockage.';

                trigger OnAction()
                begin
                    KPIManagement.UpdateAlertesMgStk();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.setMgPrincipalFilter(Rec);
        Rec.CalcFields(Rec."MainQty", Rec."StorageQty", Rec."Default Bin");
    end;

    var
        KPIManagement: Codeunit "KPI Management";
}
