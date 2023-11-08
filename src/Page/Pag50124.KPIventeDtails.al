page 50124 "KPI vente Détails"
{
    Caption = 'KPIs';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Sales Cue";

    layout
    {
        area(content)
        {
            cuegroup("Special Order")
            {
                Caption = 'Commandes Spéciales';
                field("Purchase Special Order Echu"; "Purchase Special Order Echu")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Achat échu';
                    DrillDownPageID = "Special Purchase Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes achats spéciales avec date planifié echue.';
                }

                field("Purchase Special Order"; "Purchase Special Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Achat en attente';
                    DrillDownPageID = "Special Purchase Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes achats spéciales avec date planifié non echue.';
                }

                field("Reci. Purch. Special Order"; "Reci. Purch. Special Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Achat reçu';
                    DrillDownPageID = "Special Purchase Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes achats spéciales réceptionnées';
                }
                field("Spec. Order Not Purch. Order"; "Spec. Order Not Purch. Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vente non commandée';
                    DrillDownPageID = "Sales Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes ventes spéciales non commandées';
                }

                field("Sal. Spec. Order Not Ship."; "Sal. Spec. Order Not Ship.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vente en attente';
                    DrillDownPageID = "Sales Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes ventes spéciales en attente';
                }

                field("Sal. Spec. Order ready Ship."; "Sal. Spec. Order ready Ship.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vente prête';
                    DrillDownPageID = "Sales Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes ventes spéciales prêt pour expédition';
                }
            }


            cuegroup("Order & Shipment")
            {
                Caption = 'Commande, BL, retour & Facture';
                field("Sales Order Not Ship."; "Sales Order Not Ship.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cmd non livrée';
                    DrillDownPageID = "Sales Line";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes ventes non livrées';
                }

                field("Sales Ship. Not Invoiced"; "Sales Ship. Not Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BL non facturé';
                    DrillDownPageID = "Posted Sales Shipment Lines";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes BL non facturés';
                }

                field("Sales Return Not Invoiced"; "Sales Return Not Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Retour non facturé';
                    DrillDownPageID = "Posted Return Receipt Lines";
                    DrillDown = true;
                    ToolTip = 'Liste des lignes Retour non facturés';
                }

                field("unpaid invoice"; "unpaid invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Facture Non réglée';
                    DrillDownPageID = "Customer Ledger Entries";
                    DrillDown = true;
                    ToolTip = 'Liste des factures non réglées';
                }

            }

            cuegroup("Item")
            {
                Caption = 'Article';

                field(ItemHasStockWithoutUnitPrice; ItemHasStockWithoutUnitPrice)
                {
                    Caption = 'Stk>0 & PU=0';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        lItem: Record Item;
                    begin
                        lItem.SetRange("Unit Price", 0);
                        lItem.SetFilter("Location Filter", '<>%1 & <>%2', PurchSetup."Import Location Code", InvSetup."Magasin litige");
                        lItem.CalcFields(Inventory);
                        lItem.SetFilter(Inventory, '<>0');
                        lItem.Setfilter(Type, 'Stock');
                        Page.Run(Page::"Item List", lItem);
                    end;
                }

                field(Reception; FilterCentralReception)
                {
                    Caption = 'Reception';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin Central");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Reception");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }

                field("Item Bin Count"; rec."Item Bin")
                {
                    Caption = 'Avec +Casier';
                    ApplicationArea = All;
                    DrillDownPageId = "Item Bin Contents";
                    DrillDown = true;
                }

            }

            cuegroup("Paiment")
            {
                Caption = 'Paiement Client';
                field("Cheque En Coffre"; "Cheque En Coffre")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque En Coffre';
                    DecimalPlaces = 0 : 0;
                }

                field("Cheque Impaye"; "Cheque Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque Impayé';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite En Coff."; "Traite En Coff.")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite En Coffre';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite En Escompte"; "Traite En Escompte")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Escompte';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite Impaye"; "Traite Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Impayee';
                    DecimalPlaces = 0 : 0;
                }
            }


        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }


        }


    }

    trigger OnAfterGetCurrRecord()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        RoleCenterNotificationMgt.HideEvaluationNotificationAfterStartingTrial;
    end;

    trigger OnAfterGetRecord()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // CalculateCueFieldValues;
        ShowDocumentsPendingDodExchService := false;
        if DocExchServiceSetup.Get then
            ShowDocumentsPendingDodExchService := DocExchServiceSetup.Enabled;
    end;

    trigger OnOpenPage()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetRespCenterFilter;
        //SetRange("Date Filter", 0D, WorkDate - 1);
        SetFilter("Date Filter", '..%1', WorkDate);
        SetFilter("Date Filter2", '>=%1', WorkDate);
        SetFilter("User ID Filter", UserId);

        RoleCenterNotificationMgt.ShowNotifications;
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent;

    end;

    var
        CuesAndKpis: Codeunit "Cues And KPIs";
        UserTaskManagement: Codeunit "User Task Management";
        ShowDocumentsPendingDodExchService: Boolean;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;
        OpenSalesOrdersCnt: Integer;
        OpenSalesQuotesCnt: Integer;
        OpenReturnOrdersCnt: Integer;
        OpenCreditMemosCnt: Integer;
        InvSetup: Record "Inventory Setup";
        PurchSetup: Record "Purchases & Payables Setup";



    local procedure FilterCentralReception(): Integer
    var
        BinContent: Record "Bin Content";
    begin
        InvSetup.Get();
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin Central");
        BinContent.SetRange("Bin Code", InvSetup."Emplacement Reception");
        BinContent.Setfilter(Quantity, '>0');
        exit(BinContent.Count);
    end;
}

