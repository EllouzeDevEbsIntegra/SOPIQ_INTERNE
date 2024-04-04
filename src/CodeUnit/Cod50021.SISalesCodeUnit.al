codeunit 50021 SISalesCodeUnit
{
    Permissions = tabledata "Sales Header" = rimd,
                    tabledata "Sales Line" = rimd,
                    tabledata "Entete archive BS" = rimd,
                    tabledata "Ligne archive BS" = rimd,
                    tabledata "items Master" = rimd,
                    tabledata "Sales Shipment Line" = rimd,
                    tabledata "Return Receipt Header" = rimd,
                    tabledata "Return Receipt Line" = rimd,
                    tabledata "Sales Shipment Header" = rimd;
    procedure ConfirmBSPOST(var SalesHeader: Record "Sales Header"; DefaultOption: Integer): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
        ShipInvoiceQst: Label '&Ship';

        ReceiveInvoiceQst: Label 'Réceptionner';

        PostConfirmQst: Label 'Voulez-vous valider la %1?', Comment = '%1 = Document Type';

    begin

        with SalesHeader do begin
            case "Document Type" of
                // "Document Type"::Order:
                //     begin
                //         Selection := StrMenu(ShipInvoiceQst, DefaultOption);
                //         Ship := Selection in [1, 1];
                //         if Selection = 0 then
                //             exit(false);
                //     end;
                "Document Type"::"Return Order":
                    begin
                        //Message('Test : ', ReceiveInvoiceQst);
                        Selection := StrMenu(ReceiveInvoiceQst, DefaultOption);
                        // if Selection = 0 then
                        //     exit(false);
                        Receive := Selection in [1, 1];
                    end
                else
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostConfirmQst, LowerCase(Format("Document Type"))), true)
                    then
                        exit(false);
            end;
            "Print Posted Documents" := false;
        end;
        exit(true);
    end;

    procedure afterInsertReturnReceiptLine(var rec: Record "Return Receipt Line")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        retourRecLine: Record "Return Receipt Line";
    begin
        ReturnReceiptHeader.Reset();
        if ReturnReceiptHeader.get(rec."Document No.") then begin
            if ReturnReceiptHeader.BS = true then begin
                SalesShipmentLine.Reset();
                SalesShipmentLine.SetRange("No.", rec."No.");
                SalesShipmentLine.SetRange(BS, true);
                SalesShipmentLine.SetRange("Quantity Invoiced", 0);
                SalesShipmentLine.SetRange(Quantity, rec.Quantity);
                SalesShipmentLine.SetFilter("Qty BS To Invoice", '>%1', 0);
                if SalesShipmentLine.FindFirst() then begin
                    SalesShipmentLine."Qty BS To Invoice" := 0;
                    SalesShipmentLine."Document No BS Inverse" := rec."Document No.";
                    SalesShipmentLine."Line No BS Inverse" := rec."Line No.";
                    rec."Qty BS To Purchase" := 0;
                    rec."Document No BS Inverse" := SalesShipmentLine."Document No.";
                    rec."Line No BS Inverse" := rec."Line No.";
                    // @@@@@@ TO VERIFY
                    SalesShipmentLine.Modify();
                    //Commit();
                end
                else begin
                    rec."Qty BS To Purchase" := rec.Quantity;
                end;
                // @@@@@@ TO VERIFY
                rec.Modify();
                //Commit();
            end
            else begin
                retourRecLine.Reset();
                retourRecLine.SetRange("Document No.", ReturnReceiptHeader."No.");
                retourRecLine.SetRange(Type, retourRecLine.Type::Item);
                if retourRecLine.FindSet() then begin
                    repeat
                        if rec.Amount = 0 then begin
                            rec.Amount := (rec."Unit Price" * rec.Quantity) * (1 - (rec."Line Discount %" / 100));
                            rec."Amount Including VAT" := (rec."Unit Price" * rec.Quantity) * (1 - (rec."Line Discount %" / 100)) * (1 + (rec."VAT %" / 100));
                            // @@@@@@ TO VERIFY
                            retourRecLine.Modify();
                            //Commit();
                        end
                    until retourRecLine.Next() = 0;
                end

            end;
        end;

    end;

    procedure afterInsertSalesShipLine(var rec: Record "Sales Shipment Line")
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Reset();
        if SalesShipmentHeader.get(rec."Document No.") then begin
            if SalesShipmentHeader.BS = true then begin
                ReturnReceiptLine.Reset();
                ReturnReceiptLine.SetRange("No.", rec."No.");
                ReturnReceiptLine.SetRange(BS, true);
                ReturnReceiptLine.SetRange("Quantity Invoiced", 0);
                ReturnReceiptLine.SetRange(Quantity, rec.Quantity);
                ReturnReceiptLine.SetFilter("Qty BS To Purchase", '>%1', 0);
                if ReturnReceiptLine.FindFirst() then begin
                    ReturnReceiptLine."Qty BS To Purchase" := 0;
                    ReturnReceiptLine."Document No BS Inverse" := rec."Document No.";
                    ReturnReceiptLine."Line No BS Inverse" := rec."Line No.";
                    rec."Qty BS To Invoice" := 0;
                    rec."Document No BS Inverse" := ReturnReceiptLine."Document No.";
                    rec."Line No BS Inverse" := ReturnReceiptLine."Line No.";
                    ReturnReceiptLine.Modify();
                    //Commit();
                end
                else begin
                    rec."Qty BS To Invoice" := rec.Quantity;
                end;
                rec.Modify();
                //Commit();
            end;
        end;
    end;





    // Garder prix initial dans la facturation des lignes BS
    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEventSalesShipLine(var Rec: Record "Sales Shipment Line"; RunTrigger: Boolean)
    Var
        SalesLine: Record 37;
        SalesShipmLine: Record 111;
        Contreremboursement: Record "Contre remboursement";
        SalesShipmHead: Record 110;
        salessetup: Record "Sales & Receivables Setup";
    begin
        salessetup.get;
        salessetup.TestField("Prix de vente 1 % remise");
        salessetup.TestField("Prix de vente 2 % remise");
        SalesShipmLine := Rec;
        SalesLine.RESET;
        SalesLine.setrange("Document No.", SalesShipmLine."Order No.");
        SalesLine.setrange("Line No.", SalesShipmLine."Order Line No.");
        IF SalesLine.FindFirst THEN
            SalesShipmLine.CalcFields(BS);
        IF SalesShipmLine.BS then begin
            if (salessetup."Same Price Order/BS" = true) OR (SalesLine."Unit Cost" = 0) then begin
                SalesShipmLine."Prix Vente 1" := SalesLine."Unit Price";
                SalesShipmLine."Prix Vente 2" := SalesLine."Unit Price" * (1 - (SalesLine."Line Discount %" / 100));
                SalesShipmLine."Line Discount %" := SalesLine."Line Discount %";
                SalesShipmLine."Montant ligne HT BS" := SalesLine.Amount;
                SalesShipmLine."Montant ligne TTC BS" := SalesLine."Amount Including VAT";
            end else begin
                SalesShipmLine."Prix Vente 1" := SalesShipmLine."Unit Cost" * (1 + (salessetup."Prix de vente 1 % remise" / 100));
                SalesShipmLine."Prix Vente 2" := SalesShipmLine."Prix Vente 1" * (1 - (salessetup."Prix de vente 2 % remise" / 100));
                SalesShipmLine."Line Discount %" := SalesSetup."Prix de vente 2 % remise";
                SalesShipmLine."Montant ligne HT BS" := (SalesShipmLine."Prix Vente 2" * SalesShipmLine.Quantity);
                IF SalesShipmLine."VAT %" > 0 then
                    SalesShipmLine."Montant ligne TTC BS" := (SalesShipmLine."Prix Vente 2" * SalesShipmLine.Quantity) * (1 + (SalesShipmLine."VAT %" / 100)) else
                    SalesShipmLine."Montant ligne TTC BS" := (SalesShipmLine."Prix Vente 2" * SalesShipmLine.Quantity);
            end;
            SalesShipmLine."Line Amount Order" := SalesLine."Line Amount";
            SalesShipmLine."Quantity Order" := SalesLine.Quantity;
        end;

        SalesShipmLine."% Discount" := SalesLine."Line Discount %";
        IF SalesLine.Quantity > SalesShipmLine.Quantity then
            SalesShipmLine."Line Amount" := (SalesLine."Amount Including VAT" / SalesLine.Quantity) * SalesShipmLine.Quantity else
            SalesShipmLine."Line Amount" := SalesLine."Amount Including VAT";
        IF SalesLine."VAT %" <> 0 then
            SalesShipmLine."Line Amount HT" := SalesShipmLine."Line Amount" / (1 + (SalesLine."VAT %" / 100)) else
            SalesShipmLine."Line Amount HT" := SalesShipmLine."Line Amount";
        SalesShipmLine.Modify;
    END;
}