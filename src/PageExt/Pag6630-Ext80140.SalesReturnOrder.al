pageextension 80140 "Sales Return Order" extends "Sales Return Order"//6630
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify(Post)
        {
            Visible = false;
        }
        // Add changes to page actions here
        addafter(Post)
        {
            action(Post2)
            {
                ApplicationArea = SalesReturnOrder;
                Caption = 'Valider';
                Ellipsis = true;
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                trigger OnAction()
                var
                    recSalesLine: Record "Sales Line";
                    recSalesHeader: Record "Sales Shipment Header";
                    recInvoiceHeader: Record "Sales Invoice Header";
                    numDoc, numInvoice : TEXT[50];
                begin
                    recSalesLine.Reset();
                    recSalesLine.SetRange("Document No.", "No.");
                    IF recSalesLine.FINDSET THEN
                        REPEAT


                            if (recSalesLine.Type = "Sales Line Type"::" ") THEN BEGIN

                                if (recSalesLine.Description.IndexOf('N° facture') > 0) THEN begin
                                    recInvoiceHeader.Reset();
                                    numInvoice := '';
                                    numInvoice := recSalesLine.Description.Substring(12, 10);
                                    recInvoiceHeader.SetRange("No.", numInvoice);
                                    if recInvoiceHeader.FindFirst() THEN begin
                                        recSalesLine.Description := recSalesLine.Description + ' DU ' + Format(recInvoiceHeader."Posting Date");
                                        recSalesLine.Modify();
                                    end

                                end
                                else
                                    if (recSalesLine.Description.IndexOf('N° livraison') > 0) THEN begin
                                        numdoc := '';
                                        numdoc := recSalesLine.Description.Substring(15, 11);
                                        recSalesHeader.Reset();
                                        recSalesHeader.SetRange("No.", numdoc);
                                        if recSalesHeader.FindFirst() THEN begin
                                            recSalesLine.Description := 'N° expéd.' + recSalesLine.Description.Substring(15, 12) + ' DU ' + Format(recSalesHeader."Posting Date");
                                            recSalesLine.Modify();
                                        end

                                    end

                                    else
                                        if (recSalesLine.Description.IndexOf('N° expéd.') > 20) THEN begin
                                            numdoc := '';
                                            numDoc := recSalesLine.Description.Substring(32, 11);
                                            recSalesHeader.Reset();
                                            recSalesHeader.SetRange("No.", numDoc);
                                            if recSalesHeader.FindFirst() THEN begin
                                                recSalesLine.Description := recSalesLine.Description.Substring(23, 21) + ' DU ' + Format(recSalesHeader."Posting Date");
                                                recSalesLine.Modify();
                                            end

                                        end;

                            END

                        UNTIL recSalesLine.Next() = 0;

                    PostDocument(CODEUNIT::"Sales-Post (Yes/No)");
                end;
            }

        }
    }

    var
        DocumentIsPosted: Boolean;
        OpenPostedSalesReturnOrderQst: Label 'The return order is posted as number %1 and moved to the Posted Sales Credit Memos window.\\Do you want to open the posted credit memo?', Comment = '%1 = posted document number';

    local procedure PostDocument(PostingCodeunitID: Integer)
    var
        SalesHeader: Record "Sales Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        SendToPosting(PostingCodeunitID);

        DocumentIsPosted := not SalesHeader.Get("Document Type", "No.");

        if "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting" then
            CurrPage.Close;
        CurrPage.Update(false);

        if PostingCodeunitID <> CODEUNIT::"Sales-Post (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
            ShowPostedConfirmationMessage;
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        ReturnOrderSalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not ReturnOrderSalesHeader.Get("Document Type", "No.") then begin
            SalesCrMemoHeader.SetRange("No.", "Last Posting No.");
            if SalesCrMemoHeader.FindFirst then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedSalesReturnOrderQst, SalesCrMemoHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode)
                then
                    PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
        end;
    end;
}