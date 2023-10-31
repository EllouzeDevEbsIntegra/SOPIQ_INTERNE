page 50110 "Specific Item Ledger Entry"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Specific Item Ledger Entry";
    SourceTableView = sorting("Posting Date") order(descending) Where("Document No." = Filter('<>''RECTR STK 2022'''));
    Caption = 'Ecriture Comptable Article Spécifique';
    DataCaptionExpression = GetCaption;
    Editable = false;

    layout
    {
        area(Content)
        {
            grid(Quantité)
            {
                field(QuantityTotal; Item.Inventory)
                {
                    Caption = 'Quantité totale';

                }
                field(ItemI; "Out")
                {
                    Caption = 'Quantité entrante';
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 0;

                }
                field(ItemO; "In")
                {
                    Caption = 'Quantité sortante';
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 0;

                }

                field(NbJourRupture; nbJourRupture)
                {
                    Caption = 'Total jours en rupture';
                    ApplicationArea = All;
                    DecimalPlaces = 2 : 0;
                }
            }
            repeater(GroupName)
            {
                field("Posting Date"; "Posting Date")
                {
                    Caption = 'Date Comptabilisation';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;

                }

                field("Entry Type"; "Entry Type")
                {
                    Caption = 'Type d''entrée';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Document Type"; "Document Type")
                {
                    Caption = 'Type Document';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;

                }

                field("Document No."; "Document No.")
                {
                    Caption = 'Document N°';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Source No."; "Source No.")
                {
                    Caption = 'Source N°';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Item No."; "Item No.")
                {
                    Caption = 'No.';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;

                }

                field("Description"; "Description")
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Location Code"; "Location Code")
                {
                    Caption = 'Code Magasin';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }
                field(Quantity; Quantity)
                {
                    Caption = 'Quantité';
                    DecimalPlaces = 0 : 5;
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Invoiced Qty"; "Invoiced Quantity")
                {
                    Caption = 'Qté Facturée';
                    DecimalPlaces = 0 : 5;
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Remaining Qty"; "Remaining Quantity")
                {
                    Caption = 'Qté Restante';
                    DecimalPlaces = 0 : 5;
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }


                field("Amount HT"; "Sales Amount (Actual)")
                {
                    Caption = 'Montant Vente';
                    DecimalPlaces = 0 : 5;
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Cost HT"; "Cost Amount (Actual)")
                {
                    Caption = 'Cout';
                    DecimalPlaces = 0 : 5;
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }

                field("Entry No"; "Entry No.")
                {
                    Caption = 'Ecriture N°';
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                    Editable = false;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action("Transaction Year -1 ")

            {
                ApplicationArea = All;
                Caption = 'Transaction Année -1';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ShortcutKey = F9;


                trigger OnAction()
                begin
                    if (entredonce = false) then begin
                        SetFilter("Posting Date", '%1..%2', FirstDayLastYear - 1, StartingDate - 1);
                        entredonce := true;
                        "In" := "InYear-1";
                        Out := "OutYear-1";
                        nbJourRupture := "nbRuptureYear-1";
                        CurrPage.Update();

                    end
                    else begin
                        Setfilter("Posting Date", '%1..', StartingDate);
                        entredonce := false;
                        "In" := "InYear";
                        Out := "OutYear";
                        nbJourRupture := "nbRuptureYear";
                        CurrPage.Update();

                    end;


                end;
            }



            action("Old Transaction")
            {
                ApplicationArea = All;
                Caption = 'Ancien Historique';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ShortcutKey = F8;
                //RunObject = page "Item Old Transaction";
                //RunPageLink = "Item N°" = field("Item No.");
                trigger OnAction()
                var
                    ItemOldTransaction: Record "Item Old Transaction";
                begin
                    ItemOldTransaction.SetRange("Item N°", Rec."Item No.");
                    Page.Run(Page::"Item Old Transaction", ItemOldTransaction);
                end;

            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        FieldStyle := SetStyle("Entry Type");
    end;


    trigger OnOpenPage()
    var

        SPLeadgerEntry: Record "Specific Item Ledger Entry";
    begin
        StartingDate := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        FirstDayLastYear := System.DMY2Date(1, 1, System.Date2DMY(Today, 3) - 1);

        Setfilter("Posting Date", '%1..', StartingDate);
        entredonce := false;

        if Item.get("Item No.") then BEGIN
            Item.CalcFields(Inventory);
            // Item.CalcFields(NbJourRupture);
            // nbJourRupture := Item.NbJourRupture;
        END;
        InYear := 0;
        OutYear := 0;
        "nbRuptureYear" := 0;
        SPLeadgerEntry.SetFilter("Posting Date", '%1..', StartingDate);
        SPLeadgerEntry.SetFilter("Item No.", "Item No.");
        SPLeadgerEntry.SetFilter("Document No.", '<>''RECTR STK 2022''');
        if SPLeadgerEntry.FindSet() then begin
            repeat

                Case SPLeadgerEntry."Entry Type" Of
                    SPLeadgerEntry."Entry Type"::"Negative Adjmt.":
                        InYear := InYear + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::Sale:
                        InYear := InYear + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::"Positive Adjmt.":
                        OutYear := OutYear + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::Purchase:
                        OutYear := OutYear + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::Rupture:
                        begin
                            // Message('year %1', "nbRuptureYear");
                            "nbRuptureYear" := "nbRuptureYear" + SPLeadgerEntry.Quantity;
                        end;

                end;

            until SPLeadgerEntry.next = 0;
        end;
        "In" := InYear;
        Out := OutYear;
        nbJourRupture := nbRuptureYear;



        "InYear-1" := 0;
        "OutYear-1" := 0;
        "nbRuptureYear-1" := 0;

        SPLeadgerEntry.Reset();
        SPLeadgerEntry.SetFilter("Posting Date", '%1..%2', FirstDayLastYear - 1, StartingDate - 1);
        SPLeadgerEntry.SetFilter("Item No.", "Item No.");
        SPLeadgerEntry.SetFilter("Document No.", '<>''RECTR STK 2022''');
        if SPLeadgerEntry.FindSet() then begin
            repeat

                Case SPLeadgerEntry."Entry Type" Of
                    SPLeadgerEntry."Entry Type"::"Negative Adjmt.":
                        "InYear-1" := "InYear-1" + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::Sale:
                        "InYear-1" := "InYear-1" + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::"Positive Adjmt.":
                        "OutYear-1" := "OutYear-1" + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::Purchase:
                        "OutYear-1" := "OutYear-1" + SPLeadgerEntry.Quantity;
                    SPLeadgerEntry."Entry Type"::Rupture:
                        begin

                            "nbRuptureYear-1" := "nbRuptureYear-1" + SPLeadgerEntry.Quantity;
                            // Message('Year -1  : Qte %1 / Rupture %2', SPLeadgerEntry.Quantity, "nbRuptureYear-1");
                        end;

                end;
            until SPLeadgerEntry.next = 0;
        end;



    end;

    procedure SetStyle(EntryType: Option): Text[50]
    begin
        IF EntryType = 10 THEN exit('Unfavorable');
    end;

    local procedure GetCaption(): Text
    var
        GLSetup: Record "General Ledger Setup";
        ObjTransl: Record "Object Translation";
        Item: Record Item;
        ProdOrder: Record "Production Order";
        Cust: Record Customer;
        Vend: Record Vendor;
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        SourceTableName: Text;
        SourceFilter: Text;
        Description: Text[100];
    begin
        Description := '';

        case true of
            GetFilter("Item No.") <> '':
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27);
                    SourceFilter := GetFilter("Item No.");
                    if MaxStrLen(Item."No.") >= StrLen(SourceFilter) then
                        if Item.Get(SourceFilter) then
                            Description := Item.Description;
                end;
            (GetFilter("Order No.") <> '') and ("Order Type" = "Order Type"::Production):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5405);
                    SourceFilter := GetFilter("Order No.");
                    if MaxStrLen(ProdOrder."No.") >= StrLen(SourceFilter) then
                        if ProdOrder.Get(ProdOrder.Status::Released, SourceFilter) or
                           ProdOrder.Get(ProdOrder.Status::Finished, SourceFilter)
                        then begin
                            SourceTableName := StrSubstNo('%1 %2', ProdOrder.Status, SourceTableName);
                            Description := ProdOrder.Description;
                        end;
                end;
            GetFilter("Source No.") <> '':
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            SourceTableName :=
                              ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 18);
                            SourceFilter := GetFilter("Source No.");
                            if MaxStrLen(Cust."No.") >= StrLen(SourceFilter) then
                                if Cust.Get(SourceFilter) then
                                    Description := Cust.Name;
                        end;
                    "Source Type"::Vendor:
                        begin
                            SourceTableName :=
                              ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 23);
                            SourceFilter := GetFilter("Source No.");
                            if MaxStrLen(Vend."No.") >= StrLen(SourceFilter) then
                                if Vend.Get(SourceFilter) then
                                    Description := Vend.Name;
                        end;
                end;
            GetFilter("Document Type") <> '':
                begin
                    SourceTableName := GetFilter("Document Type");
                    SourceFilter := GetFilter("Document No.");
                    Description := GetFilter("Document Line No.");
                end;
        end;
        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, Description));
    end;

    var
        In, Out, "InYear", "OutYear", "InYear-1", "OutYear-1" : Decimal;
        FieldStyle, Caption : Text[50];
        StartingDate, FirstDayLastYear : Date;
        Item: Record Item;
        nbJourRupture, nbRuptureYear, "nbRuptureYear-1" : Decimal;
        entredonce, isVisible : Boolean;
        itemFilter: Text;
}