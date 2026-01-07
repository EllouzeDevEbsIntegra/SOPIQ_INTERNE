page 25006983 "Purchase Cart List"
{
    ApplicationArea = All;
    Caption = 'Liste du Panier d''Achat';
    PageType = List;
    SourceTable = "Purchase Cart";
    UsageCategory = Lists;
    Editable = true;



    layout
    {
        area(content)
        {
            repeater(General)
            {
                Editable = LineIsEditable;

                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le numéro de ligne unique.';
                    Visible = false; // Souvent masqué dans les listes
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le numéro du fournisseur.';
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le type de la ligne (Article, Compte général, etc.).';
                    Editable = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le numéro de l''article, du compte général ou autre.';
                }
                field("Ref Master"; Rec."Ref Master")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie la référence de l''article maître.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie la description de la ligne.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie un commentaire pour la ligne.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie la quantité.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le coût unitaire direct.';
                }
                field("Compare Quote No."; Rec."Compare Quote No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le numéro du comparateur de prix associé.';
                }
                field("Added Date"; Rec."Added Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie la date d''ajout au panier.';
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le statut de la ligne du panier.';
                    Editable = false;
                }
                field("Purchase Quote No."; Rec."Purchase Quote No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Spécifie le numéro de la demande de prix associée.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Convert to Quote")
            {
                Caption = 'Transformer en Demande de Prix';
                Image = Convert;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    PurchaseCart: Record "Purchase Cart";
                    PurchaseHeader: Record "Purchase Header";
                    SelectedVendorNo: Code[20];
                    Choice: Integer;
                    NewQuoteMsg: Label 'Créer une nouvelle demande de prix';
                    ExistingQuoteMsg: Label 'Ajouter à une demande existante';
                    SelectionErr: Label 'Aucune ligne n''est sélectionnée.';
                    StatusErr: Label 'Une ou plusieurs lignes sélectionnées ont déjà été traitées (statut %1 ou %2).', Comment = '%1=Converted to Quote, %2=Cancelled';
                    VendorErr: Label 'Toutes les lignes sélectionnées doivent appartenir au même fournisseur.';
                    NoOpenQuotesErr: Label 'Aucune demande de prix ouverte n''a été trouvée pour le fournisseur %1.', Comment = '%1 = Vendor No.';
                    DuplicateCounter: Dictionary of [Code[20], Integer];
                    DuplicateList: Text;
                    ItemNo: Code[20];
                    Count: Integer;
                    DuplicateErr: Label 'Des références en double ont été trouvées dans la sélection. Veuillez ne sélectionner qu''une seule ligne pour chacun des articles suivants :';
                    DuplicateLineMsg: Label '%1 (trouvé %2 fois)', Comment = '%1=Item No., %2=Count';
                begin
                    CurrPage.SetSelectionFilter(PurchaseCart);
                    if not PurchaseCart.FindSet() then
                        Error(SelectionErr);

                    // Validations
                    SelectedVendorNo := PurchaseCart."Buy-from Vendor No.";

                    // Check for duplicate item references in the selection
                    DuplicateList := '';
                    repeat
                        if DuplicateCounter.ContainsKey(PurchaseCart."No.") then begin
                            Count := DuplicateCounter.Get(PurchaseCart."No.");
                            DuplicateCounter.Set(PurchaseCart."No.", Count + 1);
                        end else
                            DuplicateCounter.Add(PurchaseCart."No.", 1);
                    until PurchaseCart.Next() = 0;

                    foreach ItemNo in DuplicateCounter.Keys do begin
                        Count := DuplicateCounter.Get(ItemNo);
                        if Count > 1 then
                            DuplicateList += '\- ' + StrSubstNo(DuplicateLineMsg, ItemNo, Count);
                    end;

                    if DuplicateList <> '' then
                        Error(DuplicateErr + DuplicateList);

                    // Reset recordset for next validation loop
                    PurchaseCart.FindSet();
                    repeat
                        if PurchaseCart.Status in [PurchaseCart.Status::"Converted to Quote", PurchaseCart.Status::Cancelled] then
                            Error(StatusErr, PurchaseCart.Status::"Converted to Quote", PurchaseCart.Status::Cancelled);

                        if PurchaseCart."Buy-from Vendor No." <> SelectedVendorNo then
                            Error(VendorErr);
                    until PurchaseCart.Next() = 0;

                    // Dialog for user choice
                    Choice := StrMenu(NewQuoteMsg + ',' + ExistingQuoteMsg, 1);

                    if Choice = 0 then
                        exit; // User cancelled

                    if Choice = 1 then begin // Create new quote
                        CreatePurchaseQuote(PurchaseCart);
                    end;

                    if Choice = 2 then begin // Add to existing quote
                        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
                        PurchaseHeader.SetRange("Buy-from Vendor No.", SelectedVendorNo);
                        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Open);

                        if not PurchaseHeader.FindSet() then
                            Error(NoOpenQuotesErr, SelectedVendorNo);

                        // CORRECTION: Utiliser la page de type LISTE pour la sélection
                        if PAGE.RunModal(PAGE::"Purchase Quotes", PurchaseHeader) = ACTION::LookupOK then begin
                            AddToExistingPurchaseQuote(PurchaseCart, PurchaseHeader);
                            PAGE.Run(PAGE::"Purchase Quote", PurchaseHeader);
                        end;
                    end;
                end;
            }
        }
    }

    var
        LineIsEditable: Boolean;

    trigger OnAfterGetRecord()
    begin
        // This pattern is more stable and avoids the error "The identifier 'Rec.Status' could not be found".
        LineIsEditable := (Rec.Status <> Rec.Status::"Converted to Quote");
    end;


    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        // Assigner la date du jour par défaut, comme pour l'API.
        Rec."Added Date" := Today;
    end;

    local procedure CreatePurchaseQuote(var SelectedPurchaseCart: Record "Purchase Cart")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        // CORRECTION: Utiliser le nom correct du codeunit standard
        NoSeriesMgt: Codeunit "NoSeriesManagement";
        PurchSetup: Record "Purchases & Payables Setup";
        NextLineNo: Integer;
        QuoteCreatedMsg: Label 'La demande de prix %1 a été créée.', Comment = '%1 = Quote No.';
    begin
        PurchSetup.Get();
        PurchSetup.TestField("Quote Nos.");

        // Create Header
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader."No." := NoSeriesMgt.GetNextNo(PurchSetup."Quote Nos.", Today, true);
        PurchaseHeader.Validate("Buy-from Vendor No.", SelectedPurchaseCart."Buy-from Vendor No.");
        PurchaseHeader.Insert(true);

        // Create Lines and update cart
        AddToExistingPurchaseQuote(SelectedPurchaseCart, PurchaseHeader);

        Message(QuoteCreatedMsg, PurchaseHeader."No.");
        PAGE.Run(PAGE::"Purchase Quote", PurchaseHeader);
    end;

    local procedure AddToExistingPurchaseQuote(var SelectedPurchaseCart: Record "Purchase Cart"; var SelectedPurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        NextLineNo: Integer;
    begin
        if SelectedPurchaseCart.FindSet() then begin
            NextLineNo := GetLastLineNo(SelectedPurchaseHeader) + 10000;
            repeat
                PurchaseLine.Init();
                PurchaseLine."Document Type" := SelectedPurchaseHeader."Document Type";
                PurchaseLine."Document No." := SelectedPurchaseHeader."No.";
                PurchaseLine."Line No." := NextLineNo;
                PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
                PurchaseLine.Validate("No.", SelectedPurchaseCart."No.");
                PurchaseLine.Validate(Description, SelectedPurchaseCart.Description);
                PurchaseLine.Validate(Quantity, SelectedPurchaseCart.Quantity);
                PurchaseLine.Validate("Direct Unit Cost", SelectedPurchaseCart."Direct Unit Cost");
                PurchaseLine."From Purchase Cart" := true;
                PurchaseLine.Insert(true);
                NextLineNo += 10000;

                // Update Cart Line
                SelectedPurchaseCart.Status := SelectedPurchaseCart.Status::"Converted to Quote";
                SelectedPurchaseCart."Purchase Quote No." := SelectedPurchaseHeader."No.";
                SelectedPurchaseCart.Modify();
            until SelectedPurchaseCart.Next() = 0;
        end;
    end;

    local procedure GetLastLineNo(var PurchaseHeader: Record "Purchase Header"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No.")
        else
            exit(0);
    end;
}
