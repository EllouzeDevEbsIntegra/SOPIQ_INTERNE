page 50119 PurchaseItemCompare
{
    PageType = List;
    SourceTable = "Purchase Price";
    Caption = 'Comparateur de prix d''achat fournisseurs';
    //SourceTableView = where("Ending Date" = FILTER(''''));


    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(frs; frs)
                {
                    ApplicationArea = all;
                    caption = 'Frs';
                }
                field("No."; "No.")
                {
                    ApplicationArea = all;
                }

                field(Description; Description)
                {
                    ApplicationArea = all;
                }

                field(Famille; Famille)
                {
                    ApplicationArea = all;
                }

                field("Sous Famille"; "Sous Famille")
                {
                    ApplicationArea = all;
                }

                field("Item PU Devise"; "Last Curr. Price.")
                {
                    ApplicationArea = all;
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = all;
                }

                field("Purch. Qty Curr. Year frs"; "Purch. Qty Curr. Year frs")
                {
                    ApplicationArea = all;
                    Caption = 'Qte Achat Y';
                }

                field("Purch. Qty Last Year frs"; "Purch. Qty Last Year frs")
                {
                    ApplicationArea = all;
                    Caption = 'Qte Achat Y-1';
                }
                field("Item Last Date"; "Last Date")
                {
                    ApplicationArea = all;
                }

                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = all;
                }
                field("item No."; "item No.")
                {
                    ApplicationArea = all;
                }

                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = all;
                }
                field("Purch. Qty Curr. Year Vendor"; "Purch. Qty Curr. Year Vendor")
                {
                    ApplicationArea = all;
                    Caption = 'Qte Achat Y';
                }

                field("Purch. Qty Last Year Vendor"; "Purch. Qty Last Year Vendor")
                {
                    ApplicationArea = all;
                    Caption = 'Qte Achat Y-1';
                }
                field("Last Date"; "Starting Date")
                {
                    ApplicationArea = all;
                }

                field(master; master)
                {
                    ApplicationArea = all;
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action("Verif Filtre")
            {
                ApplicationArea = All;

                trigger OnAction();
                begin
                    // if ItemStk.get("Item No.") Then begin
                    //     ItemStk.SetFilter("Date filter 'Year'", '010123..311223');
                    //     ItemStk.SetFilter("Date filter 'Year-1'", '010122..311222');
                    //     Message('%1 - %2 - %3 - %4', "Item No.", ItemStk."No.", ItemStk."Date filter 'Year'", ItemStk."Date filter 'Year-1'");
                    // end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()

    begin
        rec.CalcFields("Purch. Qty Curr. Year frs", "Purch. Qty Last Year frs", "Current Year", "Last Year")
    end;

    var
}