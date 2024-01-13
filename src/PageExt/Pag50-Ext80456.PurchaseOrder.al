pageextension 80456 "Purchase Order" extends "Purchase Order" //50
{
    layout
    {
        // Add changes to page layout here
        modify("Vendor Shipment No.")
        {
            trigger OnBeforeValidate()
            var
                PurchRcptHeader: Record "Purch. Rcpt. Header";
            begin
                if ("Vendor Shipment No." <> '') then begin
                    PurchRcptHeader.Reset();
                    PurchRcptHeader.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
                    PurchRcptHeader.SetRange("Vendor Shipment No.", "Vendor Shipment No.");
                    if PurchRcptHeader.FindFirst() then Error('N° BL pour le fournisseur %1 existe déja !', "Buy-from Vendor Name");
                end;

            end;
        }
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
                    isUpdate: Boolean;
                    PurchSetup: Record "Purchases & Payables Setup";
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

                    PurchSetup.Get();
                    if (PurchSetup.PurchaserCodeRequired = false) OR ((PurchSetup.PurchaserCodeRequired = true) AND ("Purchaser Code" <> '')) then begin
                        if (PurchSetup.UpdateProfitOblogatoire = true) then begin
                            isUpdate := false;
                            purchLine.reset();
                            purchLine.SetRange("Document No.", "No.");
                            if PurchLine.FindSet() then begin
                                repeat
                                    if (PurchLine.margeUpdate = false) then begin
                                        isUpdate := false;
                                        break;
                                    end
                                    else begin
                                        isUpdate := true;
                                    end;
                                until PurchLine.Next() = 0;
                            end;
                            if (isUpdate = false) then
                                Error('Vous devez appliquer les marges avant de valider !') else
                                PostDocument(CODEUNIT::"Purch.-Post (Yes/No)", NavigateAfterPost::"Posted Document");

                        end else
                            PostDocument(CODEUNIT::"Purch.-Post (Yes/No)", NavigateAfterPost::"Posted Document");

                    end
                    else begin
                        if rec."Purchaser Code" = '' then
                            Message('Code acheteur obligatoire !');
                    end;


                end;
            }

            action(Controle)
            {
                Caption = 'Contrôler';
                ApplicationArea = all;
                Image = CarryOutActionMessage;
                Visible = isControleur;
                Enabled = NOT (Controle);
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    purchHeader: Record "Purchase Header";
                    PurchLine: Record "Purchase Line";
                    PurchSetup: Record "Purchases & Payables Setup";
                    PurchRcptHeader: Record "Purch. Rcpt. Header";
                    PurchOrderPage: Page "Purchase Order";
                begin


                    PurchSetup.Get();
                    if (PurchSetup.controlePurshOrder = true) then begin

                        if "Vendor Shipment No." = '' then
                            Message('N° BL fournisseur Obligatoire !')
                        else begin

                            Controle := true;
                            rec.Modify();
                            Commit();

                            PurchLine.Reset();
                            PurchLine.SetRange("Document No.", rec."No.");
                            if PurchLine.FindSet() then begin
                                repeat
                                    PurchLine.Controle := true;
                                    PurchLine.Modify();
                                until PurchLine.Next() = 0;
                            end;
                            PurchRcptHeader.Reset();
                            PurchRcptHeader.SetRange("Order No.", "No.");
                            if PurchRcptHeader.FindSet() then begin
                                repeat
                                    PurchRcptHeader.Controle := true;
                                    PurchRcptHeader."Vendor Shipment No." := "Vendor Shipment No.";
                                    PurchRcptHeader.Modify();
                                until PurchRcptHeader.Next() = 0;
                            end;
                        end;

                        Message('Commande contrôlée avec succès.');
                        CurrPage.Close();
                    end;

                end;
            }
        }

        // Add changes to page actions here
    }

    var
        myInt: Integer;
        pagePurchOrder: page "Purchase Order";
        UserSetup: Record "User Setup";
        isControleur: Boolean;




    trigger OnOpenPage()
    begin
        UserSetup.Reset();
        UserSetup.get(UserId);
        if (UserSetup."Contrôleur Cmd Achat" = true)
        then begin
            isControleur := true;
        end;

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
        DocumentIsPosted: Boolean;
        OpenPostedPurchaseOrderQst: Label 'The order is posted as number %1 and moved to the Posted Purchase Invoices window.\\Do you want to open the posted invoice?', Comment = '%1 = posted document number';


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


    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentOnBeforePurchaseHeaderInsert(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}