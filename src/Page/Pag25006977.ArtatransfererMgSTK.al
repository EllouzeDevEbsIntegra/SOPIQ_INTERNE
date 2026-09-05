page 25006977 "Art. a transferer Mg STK"
{
    Caption = 'Articles à transférer depuis Mg Stockage';
    PageType = List;
    SourceTable = Item;
    SourceTableView = sorting("No.") where("Sous Min Mg Principal" = const(true));
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
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
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Désignation';
                    ApplicationArea = All;
                }
                field("MainQty"; Rec."MainQty")
                {
                    Caption = 'Stock Mg Principal';
                    ApplicationArea = All;
                }
                field("Default Bin"; Rec."Default Bin")
                {
                    Caption = 'Emplacement par défaut';
                    ApplicationArea = All;
                }
                field("StorageQty"; Rec."StorageQty")
                {
                    Caption = 'Stock Mg STOCK';
                    ApplicationArea = All;
                }
                field("Qte Min Mg Principal"; Rec."Qte Min Mg Principal")
                {
                    Caption = 'Qté Min Mg Principal';
                    ApplicationArea = All;
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
                ToolTip = 'Recalcule la liste des articles à transférer depuis les magasins de stockage.';

                trigger OnAction()
                begin
                    KPIManagement.UpdateAlertesMgStk();
                    CurrPage.Update(false);
                end;
            }

            action(Imprimer)
            {
                Caption = 'Imprimer la liste';
                ApplicationArea = All;
                Image = Print;
                ToolTip = 'Imprime l''état des articles affichés dans cette liste, filtres compris.';

                trigger OnAction()
                var
                    lItem: Record Item;
                begin
                    lItem.Reset();
                    lItem.CopyFilters(Rec);
                    lItem.SetRange("Sous Min Mg Principal", true);
                    Report.RunModal(Report::"Etat Art. Transf. Mg STK", true, false, lItem);
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
