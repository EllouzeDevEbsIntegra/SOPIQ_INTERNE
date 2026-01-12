pageextension 80342 "Sales Return Order Subform" extends "Sales Return Order Subform"//6631
{
    layout
    {

        modify("Location Code")
        {

            Editable = locationEditable;

        }
        modify("Bin Code")
        {

            Editable = locationEditable;

        }
        // Add changes to page layout here
        modify("Unit Price")
        {
            Editable = EditPrice;
            trigger OnAfterValidate()
            var
                myInt: Integer;
            begin
                CurrPage.SaveRecord();
                getTTC();
                //TTCInitial := 0;
                NewTTCAmount := 0;
                NewTHAmount := 0;
                RemiseCalculated := 0;
                CurrPage.Update();
            end;
        }
        modify("Line Amount")
        {
            Editable = EditPrice;
        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            var
                myInt: Integer;
            begin
                getTTC();
                //TTCInitial := 0;
                NewTTCAmount := 0;
                NewTHAmount := 0;
                RemiseCalculated := 0;
                CurrPage.Update();
            end;
        }
        modify("Line Discount %")
        {
            Editable = Editdiscount;
            trigger OnAfterValidate()
            var
                myInt: Integer;
            begin
                CurrPage.SaveRecord();
                getTTC();
                //TTCInitial := 0;
                NewTTCAmount := 0;
                NewTHAmount := 0;
                RemiseCalculated := 0;
                NewTTCAmount := 0;
                CurrPage.Update();
            end;
        }
        modify("Invoice Discount Amount")
        {
            Editable = false;


        }

        modify("Invoice Disc. Pct.")
        {
            Editable = false;

        }
        addafter("Total Amount Incl. VAT")
        {
            field(StampAmount; StampAmount)
            {
                ApplicationArea = All;
                caption = 'Montant Timbre';
                Style = Attention;
                Editable = false;
            }
            field(TTCInitial; TTCInitial)
            {
                ApplicationArea = All;
                Caption = 'Total TTC INITIAL';
                Editable = false;
                Style = Attention;
            }

            field(NewTTCAmount; NewTTCAmount)
            {
                ApplicationArea = All;
                caption = 'Total TTC souhaité';
                Style = Strong;
                Editable = ModifAmountInvoice;
                trigger OnValidate()
                var
                    myInt: Integer;
                    lsalesline: Record "Sales Line";
                    lsalesheader: Record "Sales Header";
                    Appliquer: label 'Appliquer les nouveaux valeurs ? ';
                begin

                    if lsalesheader.get("Document Type", "Document No.") then begin
                        lsalesheader.CalcFields("Total line amount", "Amount Including VAT");
                        // lsalesheader."Old Amount Including VAT" := lsalesheader."Amount Including VAT" + lsalesheader."Stamp Amount";
                        // lsalesheader.modify;
                        TTCInitial := lsalesheader."Old Amount Including VAT";
                        lsalesline.setrange("Document Type", "Document Type");
                        lsalesline.setrange("Document No.", "Document No.");
                        lsalesline.setrange(Type, lsalesline.Type::Item);
                        if lsalesline.FindFirst then;


                        IF (NewTTCAmount <> 0) and (lsalesheader."Amount Including VAT" <> 0) THEN begin
                            //getInitialTTC();
                            /// Si déja saisie 
                            IF lsalesheader."Old Amount Including VAT" > 0 then begin
                                if (lsalesheader."Old Amount Including VAT" - NewTTCAmount) > UserSetup."Ajuster montant facture à" then begin
                                    Message(Autorisationdepassed, UserSetup."Ajuster montant facture à", (lsalesheader."Old Amount Including VAT" - NewTTCAmount) - UserSetup."Ajuster montant facture à");
                                    error('Montant dépassé');
                                end;
                                //Première arroundissement
                            end else begin
                                if (lsalesheader."Amount Including VAT" - NewTTCAmount) > UserSetup."Ajuster montant facture à" then begin
                                    Message(Autorisationdepassed, UserSetup."Ajuster montant facture à", (lsalesheader."Amount Including VAT" - NewTTCAmount) - UserSetup."Ajuster montant facture à");
                                    error('Montant dépassé');
                                end;
                            end;


                            IF lsalesheader."Old Amount Including VAT" = 0 THEN begin
                                //getInitialTTC();
                                lsalesheader."Old Amount Including VAT" := lsalesheader."Amount Including VAT" + lsalesheader."STStamp Amount";
                                lsalesheader.modify;
                                TTCInitial := lsalesheader."Old Amount Including VAT";
                            end;
                            if lsalesline."VAT %" > 0 then
                                NewTHAmount := NewTTCAmount / (1 + (lsalesline."VAT %" / 100)) else
                                NewTHAmount := NewTTCAmount;
                            RemiseCalculated := (1 - (NewTHAmount / lsalesheader."Total line amount")) * 100;
                            CurrPage.Update(true);
                            // IF CONFIRM(Appliquer, true) then begin
                            lsalesline.setrange("Document Type", "Document Type");
                            lsalesline.setrange("Document No.", "Document No.");
                            lsalesline.setrange(Type, lsalesline.Type::Item);
                            lsalesline.SetFilter("Line Amount", '>%1', 0);
                            if lsalesline.Findset then begin
                                repeat
                                    lsalesline.validate("Line Amount", lsalesline."Line Amount" * (1 - (RemiseCalculated / 100)));
                                    lsalesline.modify;
                                UNTIL lsalesline.NEXT = 0;

                            end;
                            // end;

                        end;
                    end;

                end;
            }
            field(NewTHAmount; NewTHAmount)
            {
                ApplicationArea = All;
                caption = 'Total HT souhaité';
                Style = Favorable;
                Editable = false;
            }
            field(RemiseCalculated; RemiseCalculated)
            {
                ApplicationArea = All;
                caption = 'Remise calculé';
                Style = AttentionAccent;
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addafter(ApplyDiscount)
        {
            action(ApplyLocation)
            {
                Caption = 'Appliquer Emplacement';
                Image = Home;
                trigger OnAction()
                var
                    salesLine, salesLine2 : Record "Sales Line";
                begin
                    CurrPage.SetSelectionFilter(SalesLine);
                    SalesLine.FindFirst();
                    salesLine2.Reset();
                    salesLine2.SetRange("Document Type", SalesLine."Document Type");
                    salesLine2.SetRange("Document No.", SalesLine."Document No.");
                    salesLine2.SetRange(Type, salesLine2.Type::Item);
                    salesLine2.SetRange("Appl.-from Item Entry", 0);
                    if salesLine2.FindSet() then
                        repeat
                            // salesLine2.Validate("Location Code", salesLine."Location Code");
                            // salesLine2.Validate("Bin Code", SalesLine."Bin Code");
                            salesLine2."Location Code" := salesLine."Location Code";
                            salesLine2."Bin Code" := salesLine."Bin Code";
                            salesLine2.Modify();
                        until salesLine2.Next() = 0;

                end;
            }
        }
        addafter(ApplyLocation)
        {
            action(CalculateInitialPrice)
            {
                Caption = 'Calculer prix initial';
                Image = Calculate;
                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    getTTC();
                    //TTCInitial := 0;
                    NewTTCAmount := 0;
                    NewTHAmount := 0;
                    RemiseCalculated := 0;
                    NewTTCAmount := 0;
                    CurrPage.Update();
                end;
            }
            action("Set By Reception Bin")
            {
                ApplicationArea = All;
                Caption = 'Retour dans Empl. Reception';
                Image = Bin;

                trigger OnAction()
                var
                    InventorySetup: Record "Inventory Setup";
                    SalesLine: Record "Sales Line";
                    ConfirmMsg: Label 'Voulez-vous vraiment appliquer l''emplacement de réception par défaut à toutes les lignes article de ce document ?';
                    SuccessMsg: Label 'Emplacement de réception appliqué avec succès.';
                begin
                    if not Confirm(ConfirmMsg, true) then
                        exit;

                    InventorySetup.Get();
                    InventorySetup.TestField("Magasin Central");
                    InventorySetup.TestField("Emplacement Reception");

                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", Rec."Document Type");
                    SalesLine.SetRange("Document No.", Rec."Document No.");
                    SalesLine.SetRange(Type, SalesLine.Type::Item);
                    if SalesLine.FindSet(true) then
                        repeat
                            SalesLine."Location Code" := InventorySetup."Magasin Central";
                            SalesLine."Bin Code" := InventorySetup."Emplacement Reception";
                            SalesLine.Modify(false);
                        until SalesLine.Next() = 0;

                    CurrPage.Update(false);
                    Message(SuccessMsg);
                end;
            }
        }

    }

    trigger OnModifyRecord(): Boolean
    begin
        if ("Appl.-from Item Entry" <> 0) then Error('Impossible de modifier une ligne extraite d''une expédition ou d''une facture.');
    end;

    trigger OnAfterGetRecord()
    var
        myInt: Integer;
    begin
        salesheader.get("Document Type", "Document No.");
        TTCInitial := salesheader."Old Amount Including VAT";
        StampAmount := salesheader."STStamp Amount";
        // TTCInitial := salesheader."Old Amount Including VAT" + salesheader."Stamp Amount";
        // getInitialTTC();

        if "Appl.-from Item Entry" = 0 then locationEditable := true else locationEditable := false;
    end;


    trigger OnOpenPage()
    var
        myInt: Integer;

    begin

        if UserSetup.get(UserId) then;
        EditPrice := UserSetup."Allow Modify Price";
        Editdiscount := UserSetup."Allow Modify discount";
        ModifAmountInvoice := UserSetup."Allow modify amount invoice";
        AdjaustAmntInvoice := UserSetup."Ajuster montant facture à";
        if salesheader.get("Document Type", "Document No.") then
            TTCInitial := salesheader."Old Amount Including VAT";

        //getInitialTTC();
        StampAmount := salesheader."STStamp Amount";
    end;

    local procedure getInitialTTC()
    var
        myInt: Integer;
        lsalesline: Record "Sales Line";
        lsalesheader: Record "Sales Header";
    begin
        TTCInitial := 0;

        if lsalesheader.get(lsalesheader."Document Type"::"Return Order", "Document No.") then
            lsalesline.setrange("Document Type", "Document Type");
        lsalesline.setrange("Document No.", "Document No.");
        lsalesline.setrange(Type, lsalesline.Type::Item);
        lsalesline.SetFilter("Line Amount", '>%1', 0);
        if lsalesline.Findset then begin
            repeat
                TTCInitial += (lsalesline.Quantity * lsalesline."Unit Price") * (1 - lsalesline."Line Discount %" / 100)
                * (1 + (lsalesline."VAT %" / 100));
            //TTCInitial += lsalesline."Amount Including VAT";
            UNTIL lsalesline.NEXT = 0;
            TTCInitial := TTCInitial + lsalesheader."STStamp Amount";
            lsalesheader."Old Amount Including VAT" := TTCInitial;
            lsalesheader.modify;

        end;
    end;

    local procedure getTTC()
    var
        myInt: Integer;
        lsalesline: Record "Sales Line";
        lsalesheader: Record "Sales Header";
    begin
        TTCInitial := 0;
        if lsalesheader.get(lsalesheader."Document Type"::"Return Order", "Document No.") then
            lsalesheader.CalcFields("Amount Including VAT");
        lsalesheader."Old Amount Including VAT" := lsalesheader."Amount Including VAT";
        lsalesheader.modify;
        TTCInitial := lsalesheader."Old Amount Including VAT";

        //message('%1 %2', lsalesheader."Amount Including VAT", lsalesheader."Stamp Amount");
        //lsalesheader."Old Amount Including VAT" := TTCInitial;
        //lsalesheader.modify;

    end;

    var
        locationEditable: Boolean;
        initial_unit_price: Decimal;
        initial_discount: Decimal;
        UpdateAmount: Boolean;
        NewTTCAmount: Decimal;
        TTCInitial: Decimal;
        StampAmount: Decimal;
        NewTHAmount: Decimal;
        RemiseCalculated: Decimal;
        UserSetup: Record "User Setup";
        EditPrice: Boolean;
        Editdiscount: Boolean;
        ModifAmountInvoice: Boolean;
        AdjaustAmntInvoice: Decimal;
        salesheader: Record "Sales Header";
        Autorisationdepassed: label 'Montant ajustement facture dépassé \Montant permis : %1\ dépassement : %2';


}