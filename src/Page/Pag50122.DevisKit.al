page 50122 "Devis Kit"
{
    PageType = ListPart;
    SourceTable = ItemTmp;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    Caption = 'Kit';
    //SourceTableTemporary = true;
    SourceTableView = sorting("No.");//where("Piece origine" = const(FALSE));
    layout
    {
        area(content)
        {
            // field(lItemNo; RecGOrder."No.")
            // {
            //     ApplicationArea = All;

            // }
            repeater(Group)
            {
                field("No."; "No.")
                {
                    Editable = false;
                    // StyleExpr = FieldStyle;
                }

                // field(Description; Description)
                // {
                //     Enabled = false;
                //     // StyleExpr = FieldStyle;
                // }
                field("Description structurée"; Rec."Description structurée")
                {
                    ToolTip = 'Specifies the value of the Description structurée field.';
                    ApplicationArea = All;
                }
                field("Unit Price"; "Unit Price")
                {
                    Editable = false;
                    //  StyleExpr = FieldStyle;
                }
                field("Piece origine"; "Piece origine")
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
                //         litem: Record item;
                //     begin
                //         litem.reset;
                //         litem.setrange("No.", "No.");
                //         if litem.FindSet() then
                //             page.RunModal(50031, litem);
                //     end;
                // }
                field(Stock; Inventory)
                {
                    Editable = false;
                    StyleExpr = FieldStyle;
                    DecimalPlaces = 0;
                    trigger OnAssistEdit()
                    var
                        myInt: Integer;
                        litem: Record item;
                    begin
                        litem.reset;
                        litem.setrange("No.", "No.");
                        if litem.FindSet() then
                            page.RunModal(50031, litem);
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
                    Editable = false;
                    StyleExpr = FieldStyle;
                    // Visible = VQty1;
                }
                field(QteAcommanders; QteAcommanders)
                {
                    Caption = 'Qté à Vendre';

                    trigger OnValidate()
                    begin
                        insertItem(Rec, NewLocation, QteAcommanders);
                        QteAcommanders := 0;
                        Qty1 := GetLocationQty("No.", NewLocation);
                        //pa.update;
                    end;
                }
            }
            // part("Kit"; "Kit")
            // {
            //     Caption = 'Kit';
            //     SubPageLink = "Parent Item No." = FIELD("No.");
            //     UpdatePropagation = Both;
            //     //Provider = "Produitéquivalent";

            // }

        }
    }

    actions
    {

    }
    trigger OnAfterGetCurrRecord()
    var
        myInt: Integer;
    begin
        // CurrPage.SetSelectionFilter(Rec);

        NewLocation := RecGOrder."Location Code";
        CalcFields(Inventory);
        varInventory := Inventory;
        SetRange("Order No", RecGOrder."No.");
    end;

    trigger OnAfterGetRecord()
    begin

        Qty1 := GetLocationQty("No.", NewLocation);
        CalcFields(Inventory);
        varInventory := Inventory;

        SetStyle();
    end;

    trigger OnOpenPage()
    begin
        NewLocation := RecGOrder."Location Code";
        LocationName[1] := 'Stock magasin vente';

    end;

    var
        Location: Record 14;
        LocationName: array[80] of Text[100];
        I: Integer;
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
        Qty4: Decimal;
        Qty5: Decimal;
        Qty6: Decimal;
        Qty7: Decimal;
        Qty8: Decimal;
        FieldStyle: Text[50];
        Qtedepass: Label 'Attention : Stock insuffisant  pour l''article %1';
        QteAcommanders: Decimal;
        LorderNo: code[20];
        VQty1: Boolean;
        VQty2: Boolean;
        VQty3: Boolean;
        VQty4: Boolean;
        VQty5: Boolean;
        VQty6: Boolean;
        VQty7: Boolean;
        VQty8: Boolean;
        RecGOrder: Record "Sales Header";
        lItemNo: code[20];
        RecgItem: Record item;
        chnowMagasinDispo: Boolean;
        NewLocation: code[10];
        varInventory: Decimal;
        //Kitpage: page Kit;
        chercheritem: page "Chercher Article";
        VarItem: code[20];

    procedure updatepage()
    var
        ItemKit: Record ItemTmp;
    begin
        ItemKit.reset;
        ItemKit.setrange("Order No", RecGOrder."No.");
        if ItemKit.FindSet() then
            ItemKit.DeleteAll();
        // CurrPage.Update();//13/10/2021
    end;

    procedure SetItemNo(PItemNo: Code[20])
    var
        BomComp: array[2] of Record "BOM Component";
        ItemFiltred: Record Item;
        ItemFiltred1: Record Item;
        ItemKit: Record ItemTmp;
        Itemcomposant: Record item;
    begin

        lItemNo := PItemNo;
        clear(ItemKit);
        ItemKit.setrange("Order No", RecGOrder."No.");
        if ItemKit.FindSet() then
            ItemKit.DeleteAll();
        //CurrPage.Update();//13/10/2021
        if FctKit(lItemNo) then begin  //Si Kit
            if RecgItem.get(lItemNo) then;
            if RecgItem."Reference Origine Lié" <> '' then begin
                ItemFiltred.SETFILTER("Reference Origine Lié", '%1', RecgItem."Reference Origine Lié");
                IF ItemFiltred.FINDSET THEN BEGIN
                    repeat
                        BomComp[1].setrange("Parent Item No.", ItemFiltred."No.");
                        IF BomComp[1].FINDSET THEN begin
                            repeat
                                if ItemFiltred1.get(BomComp[1]."No.") then
                                    if ItemFiltred1."Reference Origine Lié" <> '' then
                                        ItemKit.reset;
                                ItemKit.TransferFields(ItemFiltred1);
                                ItemKit."Order No" := RecGOrder."No.";
                                if not ItemKit.insert then ItemKit.modify;
                            until BomComp[1].next = 0;
                        end;
                    UNTIL ItemFiltred.NEXT = 0;
                    // CurrPage.Update(false);//13/10/2021
                end;
            end;
        end else begin
            if RecgItem.get(lItemNo) then
                if RecgItem."Reference Origine Lié" <> '' then begin
                    IF RecgItem.Produit THEN begin
                        ItemFiltred.SETFILTER("Reference Origine Lié", '%1', lItemNo);
                        // ItemFiltred.SetFilter("No.", '<>%1', lItemNo);
                        IF ItemFiltred.FINDSET THEN begin
                            repeat
                                BomComp[1].setrange("No.", ItemFiltred."No.");
                                IF BomComp[1].FINDSET THEN begin
                                    repeat
                                        if ItemFiltred1.get(BomComp[1]."Parent Item No.") then begin

                                            ItemKit.reset;
                                            ItemKit.TransferFields(ItemFiltred1);
                                            ItemKit."Order No" := RecGOrder."No.";
                                            if not ItemKit.insert then ItemKit.modify;
                                        end;
                                    UNTIL BomComp[1].NEXT = 0;
                                end;
                            UNTIL ItemFiltred.NEXT = 0;
                            // CurrPage.Update(false);//13/10/2021
                        end;

                        //CurrPage.Update();
                    end else begin
                        ItemFiltred.SETFILTER("Reference Origine Lié", '%1', RecgItem."Reference Origine Lié");
                        // ItemFiltred.SetFilter("No.", '<>%1', lItemNo);
                        IF ItemFiltred.FINDSET THEN begin
                            repeat
                                BomComp[1].setrange("No.", ItemFiltred."No.");
                                IF BomComp[1].FINDSET THEN begin
                                    repeat
                                        if ItemFiltred1.get(BomComp[1]."Parent Item No.") then begin

                                            ItemKit.reset;
                                            ItemKit.TransferFields(ItemFiltred1);
                                            ItemKit."Order No" := RecGOrder."No.";
                                            if not ItemKit.insert then ItemKit.modify;
                                        end;
                                    UNTIL BomComp[1].NEXT = 0;
                                end;
                            UNTIL ItemFiltred.NEXT = 0;
                            //  CurrPage.Update(false);//13/10/2021
                        end;

                    end;
                    //CurrPage.Update();
                end;
            //07/04/2021

        end;
        //CurrPage.Update();//13/10/2021
    end;

    procedure FctKit(VarlItem: Code[20]): Boolean;
    var
        BomComp: Record "BOM Component";
    begin
        BomComp.reset;
        BomComp.setrange("Parent Item No.", lItemNo);
        IF BomComp.FindFirst then
            exit(true) else
            exit(false)
    end;

    procedure SetItemNo5(PItemNo: Code[20])
    var
        BomComp: Record "BOM Component";
        ItemFiltred: Record Item;
        ItemFiltred1: Record Item;
        ItemKit: Record ItemTmp;
    begin
        lItemNo := PItemNo;
        clear(ItemKit);
        if ItemKit.FindFirst then
            ItemKit.DeleteAll();
        CurrPage.Update(false);
        //  Si il est un kit (1)
        if lItemNo <> '' then
            BomComp.reset;
        BomComp.setrange("Parent Item No.", lItemNo);
        IF BomComp.FINDSET THEN begin
            repeat
                if ItemFiltred.get(BomComp."No.") then
                    if ItemFiltred."Reference Origine Lié" <> '' then
                        ItemKit.reset;
                ItemKit.TransferFields(ItemFiltred);
                ItemKit."Order No" := RecGOrder."No.";
                ItemKit.insert;
                // end;
                IF ItemFiltred.Produit THEN begin
                    ItemFiltred1.reset;
                    ItemFiltred1.setrange("Reference Origine Lié", ItemFiltred."No.");
                    ItemFiltred1.SetFilter("No.", '<>%1', ItemFiltred."No.");
                    if ItemFiltred1.findset then begin
                        REPEAT
                            if ItemFiltred."Reference Origine Lié" <> '' then
                                ItemKit.TransferFields(ItemFiltred1);
                            ItemKit."Order No" := RecGOrder."No.";
                            ItemKit.insert;
                        //end;
                        UNTIL ItemFiltred1.next = 0;
                    end;
                end;

            UNTIL BomComp.NEXT = 0;
        end;
        CurrPage.Update(false);
    end;

    local procedure GetLocationQty(ItemNo: Code[20]; LocCode: Code[40]): Decimal
    var
        lItem: Record 27;
        lReservation: Record "Reservation Entry";
    begin
        //IF STRLEN(LocCode) < 11 THEN BEGIN
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

    procedure SetStyle()
    begin
        // IF Inventory <= 0 THEN FieldStyle := 'Unfavorable' ELSE FieldStyle := 'Favorable';
    end;

    procedure SetOrderNo(POrderNo: Code[20])
    var

    begin
        LorderNo := POrderNo;
    end;


    procedure GetOrderNo(ReclOrder: Record "Sales Header")
    begin
        RecGOrder := ReclOrder;
    end;

    local procedure FieldsVisibility(lvarLocation: Code[20]): Boolean
    begin
        if lvarLocation <> '' then exit(true) else exit(false);
    end;

    local procedure newProcedure(var ItemFiltred: Record Item; var ItemKit: Record ItemTmp) returnValue: Boolean
    begin
        returnValue := NOT ItemKit.GET(ItemFiltred."No.", RecGOrder."No.");
    end;

    procedure insertItem(litem: Record ItemTmp; NewxlocationVar: code[10]; QtytoInsert: Decimal)
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
            END;
        end;
    END;
}

