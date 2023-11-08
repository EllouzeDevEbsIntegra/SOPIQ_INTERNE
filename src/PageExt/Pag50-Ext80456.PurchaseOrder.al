/// <summary>
/// PageExtension Purchase Order (ID 80456) extends Record Purchase Order //50.
/// </summary>
pageextension 80456 "Purchase Order" extends "Purchase Order" //50
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
        addafter(Post)
        {
            action(Post2)
            {
                ApplicationArea = Suite;
                Caption = 'Valider';
                Ellipsis = true;
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                ShortCutKey = 'F9';
                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                trigger OnAction()
                var
                    PurchLine: Record "Purchase Line";
                    SalesLine: Record "Sales Line";
                begin

                    // Update Posting date today when user post only today
                    UserSetup.Reset();
                    UserSetup.get(UserId);
                    if (UserSetup."Allow Posting Only Today" = true)
                    then begin
                        rec."Posting Date" := System.Today;
                        rec.Validate("Posting Date");
                        rec.Modify();
                    end;
                    PostDocument(CODEUNIT::"Purch.-Post (Yes/No)", NavigateAfterPost::"Posted Document");
                end;
            }
        }

        // Add changes to page actions here
    }

    var
        myInt: Integer;
        pagePurchOrder: page "Purchase Order";
        UserSetup: Record "User Setup";

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance;
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        CurrPage.ApprovalFactBox.PAGE.UpdateApprovalEntriesFromSourceRecord(RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);

        SetDMSIntegrationActionsVisibility;   // EB.ASM EDMS.Integration
    end;

    trigger OnAfterGetRecord()
    begin
        CalculateCurrentShippingAndPayToOption;
        ShowOverReceiptNotification();
        //EDMS >>
        VehicleTradeDocument := "Document Profile" = "document profile"::"Vehicles Trade";
        SparePartDocument := "Document Profile" = "document profile"::"Spare Parts Trade";
        //EDMS >>
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;



    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocProfileMgt: Codeunit "Document Profile Mgt. EDMS";
    begin
        "Responsibility Center" := UserMgt.GetPurchasesFilter;

        if (not DocNoVisible) and ("No." = '') then
            SetBuyFromVendorFromFilter;

        CalculateCurrentShippingAndPayToOption;
        //EDMS >>
        "Document Profile" := DocProfileMgt.GetDefaultDocProfile();
        case "Document Profile" of
            "Document Profile"::"Vehicles Trade":
                begin
                    VehicleTradeDocument := true;
                end;
            "Document Profile"::"Spare Parts Trade":
                begin
                    SparePartDocument := true;
                end;
        end;
        //EDMS >>
    end;

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        SetDocNoVisible;
        IsSaaS := EnvironmentInfo.IsSaaS;

        if UserMgt.GetPurchasesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetPurchasesFilter);
            FilterGroup(0);
        end;
        //EDMS >>
        FilterGroup(3);
        DocumentProfileFilter := GetFilter("Document Profile");
        FilterGroup(0);
        //EDMS <<
        if ("No." <> '') and ("Buy-from Vendor No." = '') then
            DocumentIsPosted := (not Get("Document Type", "No."));

        SetRange("Date Filter", 0D, WorkDate());

        ActivateFields;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if ShowReleaseNotification then
            if not InstructionMgt.ShowConfirmUnreleased then
                exit(false);
        if not DocumentIsPosted then
            exit(ConfirmCloseUnposted);
    end;

    var
        CopyPurchDoc: Report "Copy Purchase Document";
        MoveNegPurchLines: Report "Move Negative Purchase Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        NavigateAfterPost: Option "Posted Document","New Document","Do Nothing";
        [InDataSet]
        JobQueueVisible: Boolean;
        [InDataSet]
        JobQueueUsed: Boolean;
        HasIncomingDocument: Boolean;
        DocNoVisible: Boolean;
        VendorInvoiceNoMandatory: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        CanCancelApprovalForRecord: Boolean;
        DocumentIsPosted: Boolean;
        OpenPostedPurchaseOrderQst: Label 'The order is posted as number %1 and moved to the Posted Purchase Invoices window.\\Do you want to open the posted invoice?', Comment = '%1 = posted document number';
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        ShowShippingOptionsWithLocation: Boolean;
        IsSaaS: Boolean;
        IsBuyFromCountyVisible: Boolean;
        IsPayToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        [InDataSet]
        VehicleTradeDocument: Boolean;
        SparePartDocument: Boolean;
        DocumentProfileFilter: Text[250];
        ShowIntegrationActionGetPrice: Boolean;
        ShowIntegrationActionGetAvailability: Boolean;
        ShowIntegrationActionSubmitItemPO: Boolean;

    protected var
        ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address";
        PayToOptions: Option "Default (Vendor)","Another Vendor","Custom Address";

    local procedure ActivateFields()
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty("Buy-from Country/Region Code");
        IsPayToCountyVisible := FormatAddress.UseCounty("Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    local procedure PostDocument(PostingCodeunitID: Integer; Navigate: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        IsScheduledPosting: Boolean;
    begin
        if ApplicationAreaMgmtFacade.IsFoundationEnabled then
            LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(Rec);

        SendToPosting(PostingCodeunitID);

        IsScheduledPosting := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";
        DocumentIsPosted := (not PurchaseHeader.Get("Document Type", "No.")) or IsScheduledPosting;

        if IsScheduledPosting then
            CurrPage.Close;
        CurrPage.Update(false);

        if PostingCodeunitID <> CODEUNIT::"Purch.-Post (Yes/No)" then
            exit;

        case Navigate of
            NavigateAfterPost::"Posted Document":
                if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode) then
                    ShowPostedConfirmationMessage;
            NavigateAfterPost::"New Document":
                if DocumentIsPosted then begin
                    Clear(PurchaseHeader);
                    PurchaseHeader.Init();
                    PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
                    OnPostDocumentOnBeforePurchaseHeaderInsert(PurchaseHeader);
                    PurchaseHeader.Insert(true);
                    PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
                end;
        end;
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.PurchLines.PAGE.ApproveCalcInvDisc;
    end;

    local procedure SaveInvoiceDiscountAmount()
    var
        DocumentTotals: Codeunit "Document Totals";
    begin
        CurrPage.SaveRecord;
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmountsOnDocument(Rec);
        CurrPage.Update(false);
    end;

    local procedure PurchaserCodeOnAfterValidate()
    begin
        CurrPage.PurchLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.Update;
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.Update;
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.Update;
    end;

    local procedure Prepayment37OnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure ShowPreview()
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchPostYesNo.Preview(Rec);
    end;

    local procedure ShowPrepmtInvoicePreview()
    var
        PurchPostPrepmtYesNo: Codeunit "Purch.-Post Prepmt. (Yes/No)";
    begin
        PurchPostPrepmtYesNo.Preview(Rec, 2);
    end;

    local procedure ShowPrepmtCrMemoPreview()
    var
        PurchPostPrepmtYesNo: Codeunit "Purch.-Post Prepmt. (Yes/No)";
    begin
        PurchPostPrepmtYesNo.Preview(Rec, 3);
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.PurchaseDocumentNoIsVisible(DocType::Order, "No.");
    end;

    local procedure SetExtDocNoMandatoryCondition()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        VendorInvoiceNoMandatory := PurchasesPayablesSetup."Ext. Doc. No. Mandatory"
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    begin
        JobQueueVisible := "Job Queue Status" = "Job Queue Status"::"Scheduled for Posting";
        HasIncomingDocument := "Incoming Document Entry No." <> 0;
        SetExtDocNoMandatoryCondition;

        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);

        WorkflowWebhookMgt.GetCanRequestAndCanCancel(RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        OrderPurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not OrderPurchaseHeader.Get("Document Type", "No.") then begin
            PurchInvHeader.SetRange("No.", "Last Posting No.");
            if PurchInvHeader.FindFirst then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedPurchaseOrderQst, PurchInvHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode)
                then
                    PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
        end;
    end;

    local procedure ValidateShippingOption()
    begin
        case ShipToOptions of
            ShipToOptions::"Default (Company Address)",
            ShipToOptions::"Custom Address":
                begin
                    Validate("Location Code", '');
                    Validate("Sell-to Customer No.", '');
                end;
            ShipToOptions::Location:
                begin
                    Validate("Location Code");
                    Validate("Sell-to Customer No.", '');
                end;
            ShipToOptions::"Customer Address":
                begin
                    Validate("Sell-to Customer No.");
                    Validate("Location Code", '');
                end;
        end;
    end;

    local procedure ShowReleaseNotification(): Boolean
    var
        LocationsQuery: Query "Locations from items Purch";
    begin
        if TestStatusIsNotReleased then begin
            LocationsQuery.SetRange(Document_No, "No.");
            LocationsQuery.SetRange(Require_Receive, true);
            LocationsQuery.Open;
            if LocationsQuery.Read then
                exit(true);
            LocationsQuery.SetRange(Document_No, "No.");
            LocationsQuery.SetRange(Require_Receive);
            LocationsQuery.SetRange(Require_Put_away, true);
            LocationsQuery.Open;
            exit(LocationsQuery.Read);
        end;
        exit(false);
    end;

    local procedure CalculateCurrentShippingAndPayToOption()
    begin
        case true of
            "Sell-to Customer No." <> '':
                ShipToOptions := ShipToOptions::"Customer Address";
            "Location Code" <> '':
                ShipToOptions := ShipToOptions::Location;
            else
                if ShipToAddressEqualsCompanyShipToAddress then
                    ShipToOptions := ShipToOptions::"Default (Company Address)"
                else
                    ShipToOptions := ShipToOptions::"Custom Address";
        end;

        case true of
            ("Pay-to Vendor No." = "Buy-from Vendor No.") and BuyFromAddressEqualsPayToAddress:
                PayToOptions := PayToOptions::"Default (Vendor)";
            ("Pay-to Vendor No." = "Buy-from Vendor No.") and (not BuyFromAddressEqualsPayToAddress):
                PayToOptions := PayToOptions::"Custom Address";
            "Pay-to Vendor No." <> "Buy-from Vendor No.":
                PayToOptions := PayToOptions::"Another Vendor";
        end;

        OnAfterCalculateCurrentShippingAndPayToOption(ShipToOptions, PayToOptions, Rec);
    end;

    local procedure ShowOverReceiptNotification()
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptMgt.ShowOverReceiptNotificationFromOrder("No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateCurrentShippingAndPayToOption(var ShipToOptions: Option "Default (Company Address)",Location,"Customer Address","Custom Address"; var PayToOptions: Option "Default (Vendor)","Another Vendor","Custom Address"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentOnBeforePurchaseHeaderInsert(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    local procedure SetDMSIntegrationActionsVisibility()
    var
        DMSIntegrationMgt: Codeunit "Integration Management EDMS";
        ActionCode: array[10] of Code[20];
        ActionIsEnabled: array[10] of Boolean;
    begin
        if ActionCode[1] = '' then
            DMSIntegrationMgt.InitMethodAliasArrayBySource(ActionCode,
                                                         Database::"Purchase Header", "document type"::Order,
                                                         Page::"Purchase Order", 0);

        DMSIntegrationMgt.IsEnabledActionsByArr10(DMSIntegrationMgt.GetConnectorCodeByVendor("Buy-from Vendor No."),
                                                  ActionCode, ActionIsEnabled);
        ShowIntegrationActionGetPrice := ActionIsEnabled[1];
        ShowIntegrationActionGetAvailability := ActionIsEnabled[2];
        ShowIntegrationActionSubmitItemPO := ActionIsEnabled[3];
    end;


}