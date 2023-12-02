pageextension 80166 "Posted Sales Shipment" extends "Posted Sales Shipment"//130
{
    layout
    {
        // Add changes to page layout here
        addafter(Billing)
        {
            group(Paiement)
            {
                Caption = 'Paiement';
                field(Acopmpte; Acopmpte)
                {
                    Caption = 'Acompte';
                    ApplicationArea = all;
                }
            }
        }

    }

    actions
    {
        // Add changes to page actions here
        addafter("Imprimer BL")
        {
            action("Imprimer BL Agence")
            {
                ApplicationArea = all;
                Caption = 'Imprimer BL Agence';
                Visible = not BS;
                Promoted = true;
                Image = Print;
                PromotedIsBig = true;
                PromotedCategory = Report;
                trigger OnAction()
                var
                    PostedSalesShipment: Record "Sales Shipment Header";
                    Posted: Page "Posted Sales Shipment";
                    reportBL: Report 50207;
                begin
                    CurrPage.SetSelectionFilter(PostedSalesShipment);
                    reportBL.SetTableView(PostedSalesShipment);
                    reportBL.Run();
                end;
            }

        }
        addafter("Update Document")
        {
            action("Update Bill To Customer")
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Modifier Client Facturé';
                Image = Dimensions;
                ToolTip = 'Modifier le client facturé du BL';
                Visible = testLigneFacture;

                trigger OnAction()
                var
                    PostSalesHeader: Record "Sales Shipment Header";
                    txtmessage: label 'pas de BL sélectionné';
                begin
                    CurrPage.SETSELECTIONFILTER(PostSalesHeader);
                    IF PostSalesHeader.FINDSET THEN begin

                        report.run(50222, TRUE, TRUE, PostSalesHeader);
                    end;
                end;
            }
        }
    }

    var
        myInt: Integer;
        testLigneFacture: Boolean;
        recSalesShpLine: Record "Sales Shipment Line";

    trigger OnAfterGetRecord()
    begin
        //@@@@@@@@ Test des lignes facturé dans le BL
        testLigneFacture := true;
        recSalesShpLine.Reset();
        recSalesShpLine.SetRange("Document No.", "No.");
        if recSalesShpLine.FindSet() then begin
            repeat
                if (recSalesShpLine."Quantity Invoiced" > 0) then begin
                    testLigneFacture := false;
                    exit;
                end;
            until recSalesShpLine.next = 0;
        end;

        rec.CalcFields(Acopmpte);
    end;

}