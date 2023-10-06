page 50121 "Devis Produit équivalent"
{
    PageType = ListPart;
    SourceTable = Item;
    // DeleteAllowed = false;
    // InsertAllowed = false;
    // ModifyAllowed = false;
    Editable = true;
    //SourceTableTemporary = true;
    Caption = 'Produit équivalent';
    SourceTableView = sorting("No."); //where("Reference Origine Lié" = filter(<> ''));

    layout
    {
        area(content)
        {
            // field(VarItem; VarItem)
            // {
            //     ApplicationArea = All;
            // }
            // field(lItemNo; lItemNo)
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


                // field("Unit Cost"; "Unit Cost")
                // {
                //     Editable = false;
                //     ApplicationArea = All;
                // }

                // field(Inventory; Inventory)
                // {
                //     StyleExpr = FieldStyle;
                //     Editable = false;
                //     ApplicationArea = All;

                // }
                // field(Qty1; Qty1)
                // {
                //     CaptionClass = '3,' + LocationName[1];
                //     Editable = false;
                //     StyleExpr = FieldStyle;
                //     // Visible = VQty1;

                // }

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
                field(Stock2; Inventory)
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
                // field(Qty1; Qty1)
                // {
                //     CaptionClass = '3,' + LocationName[1];
                //     Editable = false;
                //     StyleExpr = FieldStyle;
                //     // Visible = VQty1;
                //     Visible = NonVisibleIncomparateur;
                // }
                // field(chnowMagasinDispo; chnowMagasinDispo)
                // {
                //     // ApplicationArea = All;
                //     Caption = 'Disponibilité par magsin';
                //     Editable = true;
                //     trigger OnValidate()
                //     var
                //         myInt: Integer;

                //     begin
                //         RecgItem.reset;
                //         RecgItem.setrange("No.", "No.");
                //         if RecgItem.FindSet() then
                //             page.RunModal(492, RecgItem);
                //         chnowMagasinDispo := false;

                //     end;
                // }
                field(NewLocation; NewLocation)
                {
                    ApplicationArea = All;
                    Caption = 'Magasin de vente';
                    TableRelation = Location;
                    Style = StrongAccent;
                    Visible = NonVisibleIncomparateur;

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
                    Visible = NonVisibleIncomparateur;

                    trigger OnValidate()
                    begin
                        insertItem(Rec, NewLocation, QteAcommanders);
                        QteAcommanders := 0;
                        Qty1 := GetLocationQty("No.", NewLocation);
                        //pa.update;
                    end;
                    //end;
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
    trigger OnInit()
    begin
        NonVisibleIncomparateur := true;
    end;

    trigger OnAfterGetCurrRecord()
    var
        myInt: Integer;
    begin
        // if findset then
        // VarItem := "No.";
        // Pkit.RetourItem(VarItem);
        // Pkit.Update();
        NewLocation := RecGOrder."Location Code";
        CalcFields(Inventory);
        varInventory := Inventory;
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
        //Kitpage.SetItemNo("No.");
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
        chercheritem: page "Chercher Article";
        Pkit: Page Kit;
        VarItem: code[20];
        Affichekit: Boolean;
        [InDataSet]
        NonVisibleIncomparateur: Boolean;

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
        IF Inventory <= 0 THEN FieldStyle := 'Unfavorable' ELSE FieldStyle := 'Favorable';
    end;

    procedure SetOrderNo(POrderNo: Code[20])
    var

    begin
        LorderNo := POrderNo;
    end;

    procedure SetItemNo(PItemNo: Code[20])
    var

    begin
        lItemNo := PItemNo;
        if RecgItem.get(lItemNo) then
            IF RecgItem.Produit THEN begin
                SETFILTER("Reference Origine Lié", '%1', lItemNo);
                SetFilter("No.", '<>%1', lItemNo);

                //  CurrPage.Update();
            end else begin
                if RecgItem."Reference Origine Lié" <> '' then begin
                    SETFILTER("Reference Origine Lié", '%1', RecgItem."Reference Origine Lié");
                    SetFilter("No.", '<>%1', lItemNo);


                end;

            end;
        CurrPage.Update(false);
    end;

    procedure GetOrderNo(ReclOrder: Record "Sales Header")
    begin
        RecGOrder := ReclOrder;
    end;

    local procedure FieldsVisibility(lvarLocation: Code[20]): Boolean
    begin
        if lvarLocation <> '' then exit(true) else exit(false);
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
            END;
        end;
    end;
}

