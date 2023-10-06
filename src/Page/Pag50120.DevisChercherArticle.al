page 50120 "Devis Chercher Article"
{
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = Item;
    Editable = true;
    //SourceTableTemporary = true;
    // SourceTableView Blocked=CONST(Yes)
    SourceTableView = sorting("No.");//where("Piece origine" = const(true));

    UsageCategory = Lists;
    ApplicationArea = all;
    Caption = 'Chercher Article';
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Article; ItemCode)
                {
                    Style = Strong;
                    StyleExpr = TRUE;
                    TableRelation = Item;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        //
                        SETFILTER("No.", ItemCode);
                        CurrPage."Produitéquivalent".Page.SetItemNo(ItemCode);
                        CurrPage."kit".Page.updatepage();
                        CurrPage."kit".Page.SetItemNo(ItemCode);
                        CurrPage.UPDATE;
                    end;
                }
                field("Désignation"; ItemName)
                {
                    Style = Strong;
                    StyleExpr = TRUE;
                    Importance = Promoted;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SETFILTER(Description, ItemName);
                        //SETFILTER("Order No", RecGOrder."No.");
                        CurrPage.UPDATE;
                    end;
                }

                field(ItemCategorie; ItemCategorie)
                {
                    TableRelation = "Item Category".Code where(Indentation = const(0));
                    ApplicationArea = All;
                    Caption = 'catégorie article';
                    Visible = false;
                    Importance = Promoted;
                    Editable = true;
                    trigger OnValidate()
                    begin
                        SETFILTER("Item Category Code", ItemCategorie);
                        //SETFILTER("Order No", RecGOrder."No.");
                        CurrPage.UPDATE;
                    end;
                }
                field(Itemfamille; Itemfamille)
                {
                    TableRelation = "Item Category".code where("Parent Category" = FIELD("Item Category Code"));
                    ApplicationArea = All;
                    Caption = 'Groupe article';
                    Importance = Promoted;
                    Visible = false;
                    Editable = true;
                    trigger OnValidate()
                    begin
                        SETFILTER("Item Product Code", Itemfamille);
                        //SETFILTER("Order No", RecGOrder."No.");
                        CurrPage.UPDATE;
                    end;
                }
                field(ItemSousFamille; ItemSousFamille)
                {
                    TableRelation = "Item Category".code where(Indentation = const(1));
                    ApplicationArea = All;
                    Caption = 'Sous groupe article';
                    Importance = Promoted;
                    Editable = true;
                    trigger OnValidate()
                    begin
                        SETFILTER("Item Sub Product Code", ItemSousFamille);
                        //SETFILTER("Order No", RecGOrder."No.");
                        CurrPage.UPDATE;
                    end;
                }
            }
            group("Liste de recherche")
            {
                repeater(Control1)
                {
                    Editable = true;
                    field("No."; "No.")
                    {
                        Editable = false;
                        //StyleExpr = FieldStyle;
                    }
                    // field(Description; Description)
                    // {
                    //     Editable = false;
                    //     //StyleExpr = FieldStyle;
                    // }
                    field("Description structurée"; Rec."Description structurée")
                    {
                        ToolTip = 'Specifies the value of the Description structurée field.';
                        ApplicationArea = All;
                        Editable = false;

                    }
                    field("Unit Price"; "Unit Price")
                    {
                        Editable = false;
                        //StyleExpr = FieldStyle;
                    }
                    field(Produit; Produit)
                    {
                        ApplicationArea = All;
                    }
                    // field("Manufacturer Code"; "Manufacturer Code")
                    // {
                    //     ApplicationArea = All;
                    //     Caption = 'Code fabriquant';
                    //     Style = Strong;
                    // }
                    field("Manufacturer Name"; Rec."Manufacturer Name")
                    {
                        ToolTip = 'Specifies the value of the Nom fabricant field.';
                        ApplicationArea = All;
                        Style = Strong;

                    }

                    // field(Stock; varInventory)
                    // {
                    //     Editable = false;
                    //     StyleExpr = FieldStyle;
                    //     DecimalPlaces = 0;
                    //     trigger OnAssistEdit()
                    //     var
                    //         myInt: Integer;
                    //     begin
                    //         item.reset;
                    //         item.setrange("No.", "No.");
                    //         if item.FindSet() then
                    //             page.RunModal(50031, item);
                    //     end;
                    // }
                    field(Stock2; Inventory)
                    {
                        Editable = false;
                        StyleExpr = FieldStyle;
                        DecimalPlaces = 0;
                        trigger OnAssistEdit()
                        var
                            myInt: Integer;
                        begin
                            item.reset;
                            item.setrange("No.", "No.");
                            if item.FindSet() then
                                page.RunModal(50031, item);
                        end;
                    }
                    field(NewLocation; NewLocation)
                    {
                        ApplicationArea = All;
                        Caption = 'Magasin de vente';
                        TableRelation = Location;
                        Style = StrongAccent;
                        trigger OnValidate()
                        var
                            myInt: Integer;
                        begin
                            Qty1 := GetLocationQty("No.", NewLocation);
                        end;

                    }
                    field(Qty1; Qty1)
                    {
                        CaptionClass = '3,' + LocationName[1];
                        StyleExpr = FieldStyle;
                        // Visible = VQty1;
                        Editable = false;

                    }

                    field(QteAcommander; QteAcommander)
                    {
                        Caption = 'Qté a vendre';
                        Editable = true;
                        Style = Strong;

                        trigger OnValidate()
                        begin
                            insertItem(Rec, NewLocation, QteAcommander);
                            QteAcommander := 0;
                            Qty1 := GetLocationQty("No.", NewLocation);
                        end;
                    }
                }
            }

            part("Produitéquivalent"; "Devis Produit équivalent")
            {
                Caption = 'Produit équivalent';
                UpdatePropagation = Both;

            }


            part("Kit"; "Devis Kit")
            {
                Caption = 'Kit';
                //SubPageLink = "Parent Item No." = FIELD("No.");
                UpdatePropagation = Both;
                //Provider = "Produitéquivalent";

            }




        }
    }

    // trigger OnFindRecord(Which: Text): Boolean
    // var
    //     myInt: Integer;
    // begin
    //     RectmpItem.setrange("Order No", RecGOrder."No.");
    //     if RectmpItem.FindSet() then
    //         RectmpItem.DeleteAll();
    // end;

    trigger OnAfterGetCurrRecord()
    var
        myInt: Integer;
        reclitem: Record Item;
    begin
        CurrPage.SetSelectionFilter(reclitem);
        CurrPage."Produitéquivalent".Page.SetItemNo("No.");
        //CurrPage."kit".Page.updatepage();
        CurrPage.Kit.Page.SetItemNo("No.");
        NewLocation := RecGOrder."Location Code";
        CalcFields(Inventory);
        varInventory := Inventory;
    end;

    trigger OnAfterGetRecord()
    begin
        CalcFields(Inventory);
        NewLocation := RecGOrder."Location Code";
        Qty1 := GetLocationQty("No.", NewLocation);

        varInventory := Inventory;

        SetStyle();
    end;

    trigger OnInit()
    begin
        //ExistKit := TRUE;
        I := 0;
    end;

    trigger OnOpenPage()
    begin

        // RectmpItem.RESET;
        // RectmpItem.SETRANGE("Order No", RecGOrder."No.");
        // if RectmpItem.FindSet then begin
        //     newProcedure();
        // end;
        //CurrPage."Produitéquivalent".Page.SetOrderNo(RecGOrder."No.");
        // Clear(CurrPage);
        CurrPage."Produitéquivalent".Page.GetOrderNo(RecGOrder);
        CurrPage."kit".Page.GetOrderNo(RecGOrder);
        LocationName[1] := 'Stock magasin vente';

    end;

    trigger OnClosePage()
    var
        ItemKit: Record ItemTmp;
    begin

        ItemKit.reset;
        ItemKit.setrange("Order No", RecGOrder."No.");
        if ItemKit.FindSet() then
            ItemKit.DeleteAll();
        //CurrPage.Update();

    end;

    var
        rafraichisir: Boolean;
        ItemCode: Code[20];
        ItemName: Text[50];
        ItemOrigine: Page 50017;
        Item: Record 27;
        ExistKit: Boolean;
        Location: Record 14;
        LocationName: array[80] of Text[100];
        ItemChoisie: Integer;
        Tranformer: Boolean;
        I: Integer;
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
        Qty4: Decimal;
        Qty5: Decimal;
        Qty6: Decimal;
        Qty7: Decimal;
        Qty8: Decimal;
        VQty1: Boolean;
        VQty2: Boolean;
        VQty3: Boolean;
        VQty4: Boolean;
        VQty5: Boolean;
        VQty6: Boolean;
        VQty7: Boolean;
        VQty8: Boolean;
        FieldStyle: Text[50];
        QteAcommander: Decimal;
        Window: Dialog;
        dialogWindow: Label 'création des lignes commande';
        Qtedepass: Label 'Attention : Stock insuffisant  pour l''article %1';
        RecGOrder: Record "Sales Header";
        OrderNo: code[20];
        ItemCategorie: code[20];
        Itemfamille: code[20];
        ItemSousFamille: Code[20];
        chnowMagasinDispo: Boolean;
        NewLocation: code[10];
        varInventory: Decimal;
        RectmpItem: Record ItemTmp;

    local procedure GetLocationQty(ItemNo: Code[20]; LocCode: Code[20]): Decimal
    var
        lItem: Record 27;
        lReservation: Record "Reservation Entry";
    begin
        // IF STRLEN(LocCode) < 11 THEN BEGIN
        lItem.SETRANGE("No.", ItemNo);
        lItem.SETRANGE("Location Filter", LocCode);
        if lItem.FindSet then
            lItem.CALCFIELDS(Inventory);
        lReservation.RESET;
        lReservation.setrange("Reservation Status", lReservation."Reservation Status"::Reservation);
        lReservation.setrange("Item No.", ItemNo);
        lReservation.setrange("Location Code", LocCode);
        lReservation.setrange("Source Type", 37);
        IF lReservation.FINDSET then
            lReservation.CalcSums("Quantity (Base)");
        EXIT(lItem.Inventory + lReservation."Quantity (Base)");
        // END;
    end;



    procedure insertItem(litem: Record Item; NewxlocationVar: code[10]; QtytoInsert: Decimal)
    var
        salesline: Record "Sales Line";
        Lineno: Integer;
        MsgConfirm: label 'l''article  %1 existe déja avec une quantité %2, \ si vou poursuivez, la nouvelle quantité devient %3 ? ';

    begin
        IF QtytoInsert > 0 THEN BEGIN
            //>>Delta Achour 13/09/2021
            salesline.RESET;
            salesline.setrange("Document Type", RecGOrder."Document Type");
            salesline.setrange("Document No.", RecGOrder."No.");
            salesline.setrange(Type, salesline.Type::Item);
            salesline.setrange("No.", litem."No.");
            IF salesline.FINDSET THEN begin
                IF CONFIRM(MsgConfirm, False, litem."No.", salesline.Quantity, salesline.Quantity + QtytoInsert) then
                    salesline.validate(Quantity, salesline.Quantity + QtytoInsert);
                salesline.MODIFY;
                salesline.AutoReserve();
            end else begin
                //<<Delta Achour 13/09/2021
                salesline.RESET;
                salesline.setrange("Document Type", RecGOrder."Document Type");
                salesline.setrange("Document No.", RecGOrder."No.");
                IF salesline.FindLast() THEN
                    Lineno := salesline."Line No." + 10000 else
                    Lineno := 10000;
                salesline.init;
                salesline."Document Type" := RecGOrder."Document Type";
                salesline."Document No." := RecGOrder."No.";
                salesline."Line No." := Lineno;
                salesline."Document Profile" := salesline."Document Profile"::"Spare Parts Trade";
                salesline.Type := salesline.Type::Item;
                salesline.validate("No.", litem."No.");
                salesline.validate("Location Code", NewxlocationVar);
                salesline.validate(quantity, QtytoInsert);
                salesline.insert;
                salesline.AutoReserve();
            end;
        END;
    end;

    procedure SetStyle()
    begin
        IF Inventory <= 0 THEN FieldStyle := 'Unfavorable' ELSE FieldStyle := 'Favorable';
    end;

    procedure GetOrderNo(ReclOrder: Record "Sales Header")
    begin
        // IF RecGOrder."No." <> ReclOrder."No." THEN
        RecGOrder := ReclOrder;
    end;

    local procedure FieldsVisibility(lvarLocation: Code[20]): Boolean
    begin
        if lvarLocation <> '' then exit(true) else exit(false);
    end;

    local procedure newProcedure()
    begin
        RectmpItem.DeleteAll();
    end;


}

