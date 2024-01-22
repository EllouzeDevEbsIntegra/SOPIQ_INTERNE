page 50143 "Posted BS Lines"

{
    Caption = 'Posted Sales Document Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ShowRevLine; ShowRevLinesOnly)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Reversible Lines Only';
                    Enabled = ShowRevLineEnable;
                    ToolTip = 'Specifies if only lines with quantities that are available to be reversed are shown. For example, on a posted sales invoice with an original quantity of 20, and 15 of the items have already been returned, the quantity that is available to be reversed on the posted sales invoice is 5.';

                    trigger OnValidate()
                    begin
                        case CurrentMenuType of
                            0:
                                CurrPage.PostedShpts.PAGE.Initialize(
                                  ShowRevLinesOnly,
                                  CopyDocMgt.IsSalesFillExactCostRevLink(
                                    ToSalesHeader, CurrentMenuType, ToSalesHeader."Currency Code"), true);

                        end;
                        ShowRevLinesOnlyOnAfterValidat;
                    end;
                }
                field(OriginalQuantity; OriginalQuantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Original Quantity';
                    ToolTip = 'Specifies whether to use the original quantity to receive quantities associated with specific shipments. For example, on a posted sales invoice with an original quantity of 20, you can match the 20 items with a specific shipment.';
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                group(Control9)
                {
                    ShowCaption = false;
                    field(PostedShipmentsBtn; CurrentMenuTypeOpt)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = OptionCaptionServiceTier;
                        OptionCaption = 'Bon Sortie Enregistré';

                        trigger OnValidate()
                        begin

                            if CurrentMenuTypeOpt = CurrentMenuTypeOpt::x0 then
                                x0CurrentMenuTypeOptOnValidate;
                        end;
                    }
                    field("STRSUBSTNO('(%1)',""No. of Pstd. BS"")"; StrSubstNo('(%1)', "No. of Pstd. BS"))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bon Sortie Enregistré';
                        Editable = false;
                        ToolTip = 'Specifies the lines that represent posted shipments.';
                    }

                    field(CurrentMenuTypeValue; CurrentMenuType)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                }
            }
            group(Control18)
            {
                ShowCaption = false;

                part(PostedShpts; "Get Post.Doc - S.ShptLn Sbfrm")
                {
                    ApplicationArea = All;
                    SubPageLink = "Sell-to Customer No." = FIELD("No.");
                    SubPageView = SORTING("Sell-to Customer No.") WHERE(BS = filter(true));
                    Visible = PostedShptsVisible;
                }


            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("No. of Pstd. BS");
        CurrentMenuTypeOpt := CurrentMenuType;
    end;

    trigger OnInit()
    begin
        ShowRevLineEnable := true;
    end;

    trigger OnOpenPage()
    begin
        CurrentMenuType := 1;
        ChangeSubMenu(CurrentMenuType);
        SetRange("No.", "No.");
    end;

    var
        ToSalesHeader: Record "Sales Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        OldMenuType: Integer;
        CurrentMenuType: Integer;
        LinesNotCopied: Integer;
        ShowRevLinesOnly: Boolean;
        MissingExCostRevLink: Boolean;
        Text000: Label 'The document lines that have a G/L account that does not allow direct posting have not been copied to the new document.';
        OriginalQuantity: Boolean;
        Text002: Label 'Document Type Filter';
        [InDataSet]
        PostedShptsVisible: Boolean;
        [InDataSet]
        PostedInvoicesVisible: Boolean;
        [InDataSet]
        PostedReturnRcptsVisible: Boolean;
        [InDataSet]
        PostedCrMemosVisible: Boolean;
        [InDataSet]
        ShowRevLineEnable: Boolean;
        CurrentMenuTypeOpt: Option x0;

    [Scope('OnPrem')]
    procedure CopyLineToDoc()
    var
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        OnBeforeCopyLineToDoc(CopyDocMgt);

        ToSalesHeader.TestField(Status, ToSalesHeader.Status::Open);
        LinesNotCopied := 0;

        case CurrentMenuType of
            0:
                begin
                    CurrPage.PostedShpts.PAGE.GetSelectedLine(FromSalesShptLine);
                    CopyDocMgt.SetProperties(false, false, false, false, true, true, OriginalQuantity);
                    CopyDocMgt.CopySalesLinesToDoc(
                      SalesDocType::"Posted Shipment", ToSalesHeader,
                      FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
                end;

        end;
        Clear(CopyDocMgt);

        if LinesNotCopied <> 0 then
            Message(Text000);
    end;

    local procedure ChangeSubMenu(NewMenuType: Integer)
    begin
        if OldMenuType <> NewMenuType then
            SetSubMenu(OldMenuType, false);
        SetSubMenu(NewMenuType, true);
        OldMenuType := NewMenuType;
        CurrentMenuType := NewMenuType;
    end;

    procedure GetCurrentMenuType(): Integer
    begin
        exit(CurrentMenuType);
    end;

    local procedure SetSubMenu(MenuType: Integer; Visible: Boolean)

    begin



        if ShowRevLinesOnly and (MenuType in [0]) then
            ShowRevLinesOnly :=
              CopyDocMgt.IsSalesFillExactCostRevLink(ToSalesHeader, MenuType, ToSalesHeader."Currency Code");
        ShowRevLineEnable := MenuType in [0];
        case MenuType of
            0:
                begin
                    PostedShptsVisible := Visible;
                    CurrPage.PostedShpts.PAGE.Initialize(
                      ShowRevLinesOnly,
                      CopyDocMgt.IsSalesFillExactCostRevLink(
                        ToSalesHeader, MenuType, ToSalesHeader."Currency Code"), Visible);
                    CurrPage.PostedShpts.Page.setTypeDoc("No.");
                end;

        end;
    end;

    procedure SetToSalesHeader(NewToSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader := NewToSalesHeader;
    end;

    local procedure OptionCaptionServiceTier(): Text[70]
    begin
        exit(Text002);
    end;

    local procedure ShowRevLinesOnlyOnAfterValidat()
    begin
        CurrPage.Update(true);
    end;

    local procedure x0CurrentMenuTypeOptOnPush()
    begin
        ChangeSubMenu(0);
    end;

    local procedure x0CurrentMenuTypeOptOnValidate()
    begin
        x0CurrentMenuTypeOptOnPush;
    end;



    local procedure NoOfPostedPrepmtInvoices(): Integer
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Sell-to Customer No.", "No.");
        SalesInvHeader.SetRange("Prepayment Invoice", true);
        exit(SalesInvHeader.Count);
    end;

    local procedure NoOfPostedPrepmtCrMemos(): Integer
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", "No.");
        SalesCrMemoHeader.SetRange("Prepayment Credit Memo", true);
        exit(SalesCrMemoHeader.Count);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLineToDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt.")
    begin
    end;
}

