pageextension 80135 "Customer Statistics FactBox 2" extends "Customer Statistics FactBox" //9082
{
    layout
    {

        addafter("Balance (LCY)")
        {
            group("Encours (Client Facturé)")
            {
                Caption = 'Encours Client';
                field("Opened Invoice"; "Opened Invoice")
                {
                    Caption = 'Facture et Avoir Ouverts';
                }
                field("Shipped Not Invoiced"; "Shipped Not Invoiced BL")
                {
                    Caption = 'Bon de livraison non facturé';
                }

                field("Return Receipts Not Invoiced"; "Return Receipts Not Invoiced")
                {
                    Caption = 'Réception retour non facturé';
                }

                field(FindNoTInvoicedLines; FindNotInvoiced(rec))
                {
                    Caption = 'BL non facturés';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        SalesShipmentLine: Record "Sales Shipment Line";
                    begin
                        SalesShipmentLine.Reset();
                        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
                        SalesShipmentLine.SetRange("Quantity Invoiced", 0);
                        SalesShipmentLine.SetRange(BS, false);
                        SalesShipmentLine.SetRange("Sell-to Customer No.", "No.");
                        Page.Run(Page::"Posted Sales Shipment Lines", SalesShipmentLine);
                    end;
                }
                field(FindNotInvoicedLinesRetur; FindNotInvoicedReturn(rec))
                {
                    Caption = 'Retour non facturés';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        ReturnReceiptLine: Record "Return Receipt Line";
                    begin
                        ReturnReceiptLine.Reset();
                        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::Item);
                        ReturnReceiptLine.SetRange("Quantity Invoiced", 0);
                        ReturnReceiptLine.SetRange("Sell-to Customer No.", "No.");
                        Page.Run(Page::"Posted Return Receipt Lines", ReturnReceiptLine);
                    end;
                }

                field("Total Encours"; TotalEncours)
                {
                    Caption = 'Total Encours';
                    StyleExpr = FieldStyle;
                }

                field("Nb facture NP"; "Nb Opened Invoice")
                {
                    Caption = 'Nombre de facture non payée';
                }

            }
        }
        // Add changes to page layout here
        // addafter("Balance (LCY)")
        // {
        //     field("Opened Invoice"; "Opened Invoice")
        //     {
        //         Caption = 'Total Facture et Avoir Ouverts';
        //     }
        // }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        TotalEncours, Depassement : Decimal;
        FieldStyle: Text;
        CountSSH: Integer;
        TempSalesShipmentHead: Record "Sales Shipment header" temporary;
        TempReturReceiptHeader: Record "Return Receipt Header" temporary;


    trigger OnAfterGetRecord()
    begin
        CalcFields("Opened Invoice", "Shipped Not Invoiced BL");

        TotalEncours := "Opened Invoice" + "Shipped Not Invoiced BL" + "Return Receipts Not Invoiced";
        Depassement := "Credit Limit (LCY)" - TotalEncours;
        FieldStyle := SetStyleAmount(Depassement);
    end;

    procedure SetStyleAmount(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    local procedure FindNotInvoiced(recCustomer: Record Customer): Integer
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesShipmentH: Record "Sales Shipment Header";
    begin
        CountSSH := 0;
        TempSalesShipmentHead.Reset();
        TempSalesShipmentHead.DeleteAll();
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("Quantity Invoiced", 0);
        SalesShipmentLine.SetRange("Sell-to Customer No.", recCustomer."No.");
        if SalesShipmentLine.FindSet() then begin
            CountSSH := 0;
            repeat
                if SalesShipmentH.Get(SalesShipmentLine."Document No.") and not SalesShipmentH.BS then begin
                    TempSalesShipmentHead.Init();
                    TempSalesShipmentHead."No." := SalesShipmentH."No.";
                    if TempSalesShipmentHead.Insert() then
                        CountSSH += 1;
                end;
            until SalesShipmentLine.Next() = 0;
        end;
        exit(CountSSH);
    end;

    local procedure FindNotInvoicedReturn(recCustomer: Record Customer): Integer
    var

        ReturnReceiptLine: Record "Return Receipt Line";
        CountRRH: Integer;
    begin
        CountSSH := 0;
        TempReturReceiptHeader.Reset();
        TempReturReceiptHeader.DeleteAll();
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::Item);
        ReturnReceiptLine.SetRange("Quantity Invoiced", 0);
        ReturnReceiptLine.SetRange("Sell-to Customer No.", recCustomer."No.");
        if ReturnReceiptLine.FindSet() then begin
            CountRRH := 0;
            repeat
                TempReturReceiptHeader.Init();
                TempReturReceiptHeader."No." := ReturnReceiptLine."Document No.";
                if TempReturReceiptHeader.Insert() then
                    CountRRH += 1;
            until ReturnReceiptLine.Next() = 0;
        end;
        exit(CountRRH);
    end;
}