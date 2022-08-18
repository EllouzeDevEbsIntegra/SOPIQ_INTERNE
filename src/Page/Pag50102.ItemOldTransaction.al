page 50102 "Item Old Transaction"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Item Old Transaction";
    Caption = 'Mouvement articles 2020-2021';
    Editable = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    DataCaptionExpression = GetCaption;
    DataCaptionFields = "Item N°";


    layout
    {
        area(Content)
        {
            grid(Quantité)
            {

                field(ActualQty; Itemstk.Inventory)
                {
                    Caption = 'Quantité actuel';
                    Editable = false;
                }
                field(PurshQty20; ItemStk.PurshQty20)
                {

                    Caption = 'Achat 2020';
                    Editable = false;

                    ApplicationArea = All;
                }

                field(PurshQty21; ItemStk.PurshQty21)
                {

                    Caption = 'Achat 2021';
                    Editable = false;

                    ApplicationArea = All;
                }
                field(SalesQty20; ItemStk.SalesQty20)
                {

                    Caption = 'Vente 2020';
                    Editable = false;

                    ApplicationArea = All;
                }
                field(SalesQty21; ItemStk.SalesQty21)
                {

                    Caption = 'Vente 2021';
                    Editable = false;

                    ApplicationArea = All;
                }

            }
            repeater(GroupName)
            {
                field("Document N°"; "Document N°")
                {
                    Caption = 'N° Document';
                    Editable = false;
                }

                field("Document Type"; "Document Type")
                {
                    Caption = 'Type';
                    Editable = false;
                }

                field("Is Output"; "Is Output")
                {
                    Caption = 'Sortie';
                    Editable = false;
                    Visible = false;
                }

                field("Is Input"; "Is Input")
                {
                    Caption = 'Entré';
                    Editable = false;
                    Visible = false;
                }

                field("Tier N°"; "Tier N°")
                {
                    Caption = 'N° Tier';
                    Editable = false;
                }

                field("Tier Name"; "Tier Name")
                {
                    Caption = 'Nom Tier';
                    Editable = false;
                }

                field("Document date"; "Document date")
                {
                    Caption = 'Date';
                    Editable = false;
                }

                field("Year"; "Year")
                {
                    Caption = 'Année';
                    Editable = false;
                }

                field("Item N°"; "Item N°")
                {
                    Caption = 'Réf Article';
                    Editable = false;
                }

                field("Item Description"; "Item Description")
                {
                    Caption = 'Désignation article';
                    Editable = false;
                }

                field("Sales Qty"; "Sales Qty")
                {
                    Caption = 'Qté sortie';
                    Editable = false;
                }

                field("Purshase Qty"; "Purshase Qty")
                {
                    Caption = 'Qté entrée';
                    Editable = false;
                }

                field("Unit Price HT"; "Unit Price HT")
                {
                    Caption = 'PU H.T';
                    Editable = false;
                }

                field("Discount Percent"; "Discount Percent")
                {
                    Caption = 'Remise (%)';
                    Editable = false;
                }

                field("Amount HT"; "Amount HT")
                {
                    Caption = 'Net H.T';
                    Editable = false;
                }

                field("VAT Tax Amount"; "VAT Tax Amount")
                {
                    Caption = 'Montant TVA';
                    Editable = false;
                }

                field("Total Line HT"; "Total Line HT")
                {
                    Caption = 'Total NET H.T';
                    Editable = false;
                }

                field("Total Line TTC"; "Total Line TTC")
                {
                    Caption = 'Total NET TTC';
                    Editable = false;
                }
            }
        }
        area(Factboxes)
        {

        }
    }


    trigger OnAfterGetRecord()

    begin

        if ItemStk.get("Item N°") Then
            ItemStk.CalcFields(Inventory, PurshQty20, PurshQty21, SalesQty20, SalesQty21);

    end;

    var
        ItemStk: Record Item;
        recItem: Record "Item old transaction";



    local procedure GetCaption(): Text
    var

        ItemLocal: Record "Item";
        SourceTableName: Text;
        SourceFilter: Text;
    begin

        case true of
            GetFilter("Item N°") <> '':
                begin
                    SourceTableName := 'Article';
                    SourceFilter := GetFilter("Item N°");
                end;

        end;
        exit(StrSubstNo('%1 %2', SourceTableName, SourceFilter));

    end;

}