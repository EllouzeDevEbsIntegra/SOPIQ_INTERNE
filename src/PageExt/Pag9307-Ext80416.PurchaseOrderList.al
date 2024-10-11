pageextension 80416 "Purchase Order List" extends "Purchase Order List"//9307
{
    layout
    {
        // Add changes to page layout here
        addafter("Buy-from Vendor Name")
        {
            field("Vendor Order No."; "Vendor Order No.")
            {
                Caption = 'N° Cmd Frs';
                ApplicationArea = all;
                Editable = false;
            }

            field("Vendor Shipment No."; "Vendor Shipment No.")
            {
                Caption = 'N° BL Frs';
                ApplicationArea = all;
                Editable = false;
            }
            field("Total Line"; "Total Line")
            {
                Caption = 'Nb Lignes';
                ApplicationArea = all;
            }
            field(Controle; Controle)
            {
                Caption = 'Contrôlé';
                ApplicationArea = all;
            }
            field("Nb Line To Receive"; "Nb Line To Receive")
            {
                ApplicationArea = all;
                Caption = 'Nb Ligne Avec Qty à Rcpt > 0 ';
            }
        }
    }

    actions
    {
        modify(Post)
        {
            Visible = false;
        }
        modify(PostAndPrint)
        {
            Visible = false;
        }
        addafter(Post)
        {
            action(Post2)
            {
                ApplicationArea = Suite;
                Caption = 'Pre-Valider';
                Ellipsis = true;
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Category8;
                PromotedIsBig = true;
                ShortCutKey = 'F9';
                ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                trigger OnAction()
                var
                    PurchLine, PurchLineBin : Record "Purchase Line";
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
                    if (PurchSetup."Activ. Def. Bin Purch.Order" = true) then begin
                        PurchLineBin.Reset();
                        PurchLineBin.SetRange("Document No.", rec."No.");
                        PurchLineBin.SetRange(Type, PurchLineBin.Type::Item);
                        if PurchLineBin.FindSet() then begin
                            repeat
                                if (PurchLineBin."Location Code" = '') OR (PurchLineBin."Bin Code" = '') then begin
                                    PurchLineBin."Location Code" := PurchSetup."Default Location Purch.Order";
                                    PurchLineBin."Bin Code" := PurchSetup."Default Bin Purch.Order";
                                    PurchLineBin.Modify();
                                end
                            until PurchLineBin.Next() = 0;
                        end;
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

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("Nb Line To Receive");
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