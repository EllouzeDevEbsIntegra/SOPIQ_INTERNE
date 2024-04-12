page 50154 "Purch. Inv. Line Check"
{
    Caption = 'Vérification Ligne Facture Achat';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Purch. Inv. Line";
    Editable = true;
    ModifyAllowed = true;
    Permissions = TableData "Purch. Inv. Line" = rm;
    SourceTableView = sorting("Posting Date", "Document No.", "Line No.") order(descending) where(Verified = filter(false), "No." = Filter('<> '''''));
    layout
    {
        area(Content)
        {
            grid("Stat")
            {
                field(ref; ref)
                {
                    Caption = 'Ref';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Strong;
                }
                field(TotalAchat; recItem."Total Achete")
                {
                    Caption = 'Achat';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Unfavorable;
                }
                field(ajustPost; recItem."Total Ajust+")
                {
                    Caption = 'Ajust +';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Unfavorable;
                }
                field(TotalVente; recItem."Total Vendu")
                {
                    Caption = 'Vente';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Favorable;
                }
                field(ajustNeg; recItem."Total Ajust-")
                {
                    Caption = 'Ajust -';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Favorable;
                }

                field(Stk; recItem."Available Inventory")
                {
                    Caption = 'Stock';
                    ApplicationArea = all;
                    Editable = false;
                    Style = Strong;
                }
                field(MargMoy; MargMoy)
                {
                    Caption = 'Marg. Moy.';
                    ApplicationArea = all;
                    Editable = false;
                    DecimalPlaces = 2 : 2;
                    Style = StrongAccent;
                }

            }
            repeater("Purch. Inv. Line")
            {
                Caption = 'Ligne Facture Achat';
                field("Posting Date"; "Posting Date")
                {
                    Caption = 'Date';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Document No."; "Document No.")
                {
                    Caption = 'Facture N°';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    Caption = 'Frs';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("No."; "No.")
                {
                    Caption = 'Article';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(Description; Description)
                {
                    Caption = 'Description';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(Quantity; Quantity)
                {
                    Caption = 'Qte';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    Caption = 'UOM';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(inventory; inventory)
                {
                    Caption = 'STK';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    Caption = 'Prix HT';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    Caption = 'Rem %';
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Line Amount"; "Line Amount")
                {
                    Caption = 'Net HT';
                    ApplicationArea = all;
                    Editable = false;
                }
                field(Verified; Verified)
                {
                    Caption = 'Vérifié';
                    ApplicationArea = all;
                    Editable = false;

                }
                field(Observation; Observation)
                {
                    ApplicationArea = all;
                    Editable = true;
                }


            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ItemTransaction)
            {
                Caption = 'Transactions article';
                Image = Change;
                ShortcutKey = F9;
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");
            }
            action("Item Verified")
            {
                Caption = 'Ligne Vérifiée';
                Image = Approve;
                trigger OnAction()
                begin
                    rec.Verified := true;
                    rec.Modify();
                    //Commit();
                end;
            }
            // action("Item Not Verified")
            // {
            //     Caption = 'Ligne Non Vérifiée';
            //     Image = Cancel;
            //     trigger OnAction()
            //     begin
            //         rec.Verified := false;
            //         rec.Modify();
            //         Commit();
            //     end;
            // }
            action("All Item Verified")
            {
                Caption = 'Référence Vérifiée';
                Image = CompleteLine;
                trigger OnAction()
                var
                    PurchInvLine: Record "Purch. Inv. Line";
                begin
                    PurchInvLine.Reset();
                    PurchInvLine.SetRange("No.", rec."No.");
                    if PurchInvLine.FindSet() then begin
                        repeat
                            PurchInvLine.Verified := true;
                            PurchInvLine.Modify();
                        //Commit();
                        until PurchInvLine.Next() = 0;
                    end;
                end;

            }

            action("Invoice Verified")
            {
                Caption = 'Facture Vérifiée';
                Image = "Invoicing-Save";
                trigger OnAction()
                var
                    PurchInvLine: Record "Purch. Inv. Line";
                begin
                    PurchInvLine.Reset();
                    PurchInvLine.SetRange("Document No.", rec."Document No.");
                    if PurchInvLine.FindSet() then begin
                        repeat
                            PurchInvLine.Verified := true;
                            PurchInvLine.Modify();
                        //Commit();
                        until PurchInvLine.Next() = 0;
                    end;
                end;

            }
        }
    }

    var
        ref: Code[50];
        TotalAchat, TotalVente, MargMoy : Decimal;
        recItem: Record item;

    trigger OnAfterGetCurrRecord()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        qty, MntV, MntA : Decimal;
    begin
        ref := rec."No.";

        recItem.get(rec."No.");
        recItem.CalcFields("Available Inventory", "Total Achete", "Total Vendu", "Total Ajust+", "Total Ajust-");

        qty := 0;
        MntA := 0;
        MntV := 0;
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", rec."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        if ItemLedgerEntry.FindSet() then begin
            repeat
                ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)", "Sales Amount (Actual)", "Sales Amount (Expected)");
                qty := qty + Quantity;
                MntA := MntA + ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Expected)";
                MntV := MntV + (-ItemLedgerEntry."Sales Amount (Actual)") + (-ItemLedgerEntry."Sales Amount (Expected)");
            // Message('%1 - %2 -%3', qty, MntA, MntV);

            until ItemLedgerEntry.Next() = 0;
        end;
        if MntA <> 0 then
            MargMoy := ((MntV / MntA) - 1) * 100 else
            MargMoy := 0;
    end;
}