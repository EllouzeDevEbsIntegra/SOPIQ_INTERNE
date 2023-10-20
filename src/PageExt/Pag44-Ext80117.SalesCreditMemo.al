pageextension 80117 "Sales Credit Memo" extends "Sales Credit Memo" //44 
{
    layout
    {
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
                ApplicationArea = Basic, Suite;
                Caption = 'Valider';
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                trigger OnAction()
                var
                    recSalesLine: Record "Sales Line";
                    recSalesHeader: Record "Return Receipt Header";
                    numDoc: TEXT[50];

                begin

                    recSalesLine.Reset();
                    recSalesLine.SetRange("Document No.", "No.");
                    IF recSalesLine.FINDSET THEN
                        REPEAT
                            if (recSalesLine.Type = "Sales Line Type"::" ") THEN BEGIN
                                if (StrLen(recSalesLine.Description) > 25) then
                                    numDoc := recSalesLine.Description.Substring(22, 11)
                                else
                                    numDoc := '';

                                recSalesHeader.SetRange("No.", numDoc);
                                if recSalesHeader.FindFirst() THEN BEGIN
                                    recSalesLine."Description" := recSalesLine.Description + ' Du ' + FORMAT(recSalesHeader."Posting Date");
                                    recSalesLine.Modify();
                                END

                            END

                        UNTIL recSalesLine.Next() = 0;

                    PostDocument(CODEUNIT::"Sales-Post (Yes/No)");
                end;
            }
        }
    }



    // trigger OnOpenPage()
    // begin
    //     "STApply Stamp Fiscal" := false;
    //     "STStamp Amount" := 0.000;
    // end;

    // //Rendre le champs timbre fiscal désactvié par défaut
    // trigger OnAfterGetRecord()
    // begin
    //     "STApply Stamp Fiscal" := false;
    //     "STStamp Amount" := 0.000;
    // end;

    local procedure PostDocument(PostingCodeunitID: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeMgt: Codeunit "Office Management";
        InstructionMgt: Codeunit "Instruction Mgt.";
        PreAssignedNo: Code[20];
        IsScheduledPosting: Boolean;
    begin
        CheckSalesCheckAllLinesHaveQuantityAssigned;
        PreAssignedNo := "No.";

        SendToPosting(PostingCodeunitID);

        IsScheduledPosting := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";
        DocumentIsPosted := (not SalesHeader.Get("Document Type", "No.")) or IsScheduledPosting;
        OnPostOnAfterSetDocumentIsPosted(SalesHeader, IsScheduledPosting, DocumentIsPosted);

        if IsScheduledPosting then
            CurrPage.Close;
        CurrPage.Update(false);

        if PostingCodeunitID <> CODEUNIT::"Sales-Post (Yes/No)" then
            exit;

        if OfficeMgt.IsAvailable then begin
            SalesCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
            if SalesCrMemoHeader.FindFirst then
                PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
        end else
            if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
                ShowPostedConfirmationMessage(PreAssignedNo);
    end;

    local procedure CheckSalesCheckAllLinesHaveQuantityAssigned()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if ApplicationAreaMgmtFacade.IsFoundationEnabled then
            LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(Rec);
    end;

    local procedure ShowPostedConfirmationMessage(PreAssignedNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        if SalesCrMemoHeader.FindFirst then
            if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedSalesCrMemoQst, SalesCrMemoHeader."No."),
                 InstructionMgt.ShowPostedConfirmationMessageCode)
            then
                PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStatisticsAction(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOnAfterSetDocumentIsPosted(SalesHeader: Record "Sales Header"; var IsScheduledPosting: Boolean; var DocumentIsPosted: Boolean)
    begin
    end;

    var
        CopySalesDoc: Report "Copy Sales Document";
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        WorkDescription: Text;
        [InDataSet]
        JobQueueVisible: Boolean;
        [InDataSet]
        JobQueueUsed: Boolean;
        HasIncomingDocument: Boolean;
        DocNoVisible: Boolean;
        ExternalDocNoMandatory: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        OpenPostedSalesCrMemoQst: Label 'The credit memo is posted as number %1 and moved to the Posted Sales Credit Memos window.\\Do you want to open the posted credit memo?', Comment = '%1 = posted document number';
        CanCancelApprovalForRecord: Boolean;
        DocumentIsPosted: Boolean;
        IsCustomerOrContactNotEmpty: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        IsSaaS: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        CustomerSelected: Boolean;
        [InDataSet]
        VehicleTradeDocument: Boolean;
        SparePartDocument: Boolean;
        ServiceDocument: Boolean;
        DocumentProfileFilter: Text[250];
}