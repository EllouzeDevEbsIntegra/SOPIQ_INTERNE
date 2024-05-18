page 50129 "Admin Comm. Gros KPI"
{
    Caption = 'Indicateurs clés d''activités';
    PageType = CardPart;
    RefreshOnActivate = false;
    SourceTable = "Sales Cue";

    layout
    {
        area(content)
        {
            cuegroup(ADMIN)
            {
                Caption = 'Notification Admin';
                field("Unit price modified 2"; rec."Sales Line PU Modif")
                {
                    Caption = 'Prix vente modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }
                field("Discount modified"; rec."Sales Line Disc. Modif")
                {
                    Caption = 'Remise modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }

                field("Today Sum Sales"; rec."Today Sum Sales")
                {
                    Caption = 'Vente du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;

                }

                field("Today Sum Return"; rec."Today Sum Return")
                {
                    Caption = 'Retour du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales Line";
                    DrillDown = true;
                }


                field("Vente Annuelle"; Vente4)
                {
                    ApplicationArea = Basic;
                    Caption = 'Année';
                    DecimalPlaces = 0 : 0;
                    Image = Calculator;
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

            // cuegroup(B2B)
            // {
            //     Caption = 'Commandes et retours';
            //     field(Waiting; B2BStatusArray[1])
            //     {
            //         Caption = 'En attente';
            //         StyleExpr = EnAttente1;
            //         DrillDownPageID = "Sales Order List";
            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Commande en attente");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;

            //     }
            //     field(Released; B2BStatusArray[2])
            //     {
            //         Caption = 'Lancée';
            //         DrillDownPageID = "Sales Order List";
            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Commande lancée");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;
            //     }
            //     field("In preparation"; B2BStatusArray[3])
            //     {
            //         Caption = 'En cours de préparation';
            //         DrillDownPageID = "Sales Order List";
            //         StyleExpr = EnAttente3;

            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En cours de préparation");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;
            //     }
            //     field(Prepared; B2BStatusArray[4])
            //     {
            //         Caption = 'Préparée';
            //         DrillDownPageID = "Sales Order List";

            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Préparé");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;
            //     }
            //     field("Pointing in progress"; B2BStatusArray[5])
            //     {
            //         Caption = 'En cours de pointage';
            //         DrillDownPageID = "Sales Order List";
            //         StyleExpr = EnAttente5;

            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En cours de pointage");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;
            //     }
            //     field("Awaiting Delivery"; B2BStatusArray[6])
            //     {
            //         Caption = 'En attente de livraison';
            //         DrillDownPageID = "Sales Order List";
            //         StyleExpr = EnAttente6;

            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En attente de livraison");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;
            //     }
            //     field(Delivered; B2BStatusArray[7])
            //     {
            //         Caption = 'Livrée';
            //         DrillDownPageID = "Sales Order List";

            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         begin
            //             SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Livré");
            //             PAGE.RUN(PAGE::"Sales Order List", SalesOrders);
            //         end;
            //     }
            //     field(Return; Return)
            //     {
            //         DrillDownPageID = "Sales Return Order List";
            //         ApplicationArea = All;
            //     }

            // }
            // cuegroup(BLBR)
            // {
            //     Caption = 'Bons de livraison et Réceptions retour validées';
            //     field(FindNoTInvoicedLines; FindNotInvoiced())
            //     {
            //         Caption = 'BL non facturés';
            //         ApplicationArea = All;
            //         trigger OnDrillDown()
            //         var
            //             SalesShipmentLine: Record "Sales Shipment Line";
            //         begin
            //             SalesShipmentLine.Reset();
            //             SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
            //             SalesShipmentLine.SetRange("Quantity Invoiced", 0);
            //             SalesShipmentLine.SetRange(BS, false);
            //             Page.Run(Page::"Posted Sales Shipment Lines", SalesShipmentLine);
            //         end;
            //     }
            //     field(FindNotInvoicedLinesRetur; FindNotInvoicedReturn())
            //     {
            //         Caption = 'Retour non facturés';
            //         ApplicationArea = All;
            //         Image = Receipt;
            //         trigger OnDrillDown()
            //         var
            //             ReturnReceiptLine: Record "Return Receipt Line";
            //         begin
            //             ReturnReceiptLine.Reset();
            //             ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::Item);
            //             ReturnReceiptLine.SetRange("Quantity Invoiced", 0);
            //             Page.Run(Page::"Posted Return Receipt Lines", ReturnReceiptLine);
            //         end;
            //     }
            // }
            cuegroup("Reglement Reçu de caisse")
            {
                Caption = 'Non Réglée Reçu de caisse';
                field(TotalFactNonRegleeRC; TotalFactureNonRegleeRC)
                {
                    Caption = 'Factures Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesInvoice: Record "Sales Invoice Header";
                    begin
                        salesInvoice.Reset();
                        salesInvoice.SetRange(solde, false);
                        Page.Run(Page::"Posted Sales Invoices", salesInvoice);

                    end;
                }
                field(TotalAVNonRegleeRC; -TotalAvoirNonRegleeRC)
                {
                    Caption = 'Avoir Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesCrMemo: Record "Sales Cr.Memo Header";
                    begin
                        salesCrMemo.Reset();
                        salesCrMemo.SetRange(solde, false);
                        Page.Run(Page::"Posted Sales Credit Memos", salesCrMemo);

                    end;
                }

                field(TotalBSNonRegleRC; TotalBSNonRegleeRC)
                {
                    Caption = 'BS Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesBS: Record "Entete archive BS";
                    begin
                        salesBS.Reset();
                        salesBS.SetRange(solde, false);
                        Page.Run(Page::"Liste archive Bon de sortie", salesBS);

                    end;
                }

                field(TotalRetourBSNonRegleRC; -TotalRetourBSNonRegleeRC)
                {
                    Caption = 'Retour BS Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesReturnBS: Record "Return Receipt Header";
                    begin
                        salesReturnBS.Reset();
                        salesReturnBS.SetRange(solde, false);
                        salesReturnBS.SetRange(bs, true);
                        Page.Run(Page::"Posted Return Receipts BS", salesReturnBS);

                    end;
                }

                field(TotalBLNonRegleRC; TotalBLNonRegleeRC)
                {
                    Caption = 'BL Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesBL: Record "Sales Shipment Header";
                    begin
                        salesBL.Reset();
                        salesBL.SetRange(solde, false);
                        salesBL.SetRange(bs, false);
                        Page.Run(Page::"Posted Sales Shipments", salesBL);

                    end;
                }

                field(TotalReturnBLNonRegleRC; -TotalRetourBLNonRegleeRC)
                {
                    Caption = 'Retour BL Non Reg RC';
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    var
                        salesReturnBL: Record "Return Receipt Header";
                    begin
                        salesReturnBL.Reset();
                        salesReturnBL.SetRange(solde, false);
                        salesReturnBL.SetRange(bs, false);
                        Page.Run(Page::"Posted Return Receipt List", salesReturnBL);

                    end;
                }
            }
            cuegroup(FactureNonRegle)
            {
                Caption = 'Factures';
                field(factureNonReg; FactureNonReglee)
                {
                    Caption = 'Facture non réglée';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        CustomerLedEntries: Record "Cust. Ledger Entry";
                    begin
                        CustomerLedEntries.Reset();
                        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::Invoice);
                        CustomerLedEntries.SetRange(Open, true);
                        Page.Run(Page::"Customer Ledger Entries", CustomerLedEntries);
                    end;
                }
                field(TotalfactureNonReg; TotalFactureNonReglee)
                {
                    Caption = 'Total Facture non réglée';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        CustomerLedEntries: Record "Cust. Ledger Entry";
                    begin
                        CustomerLedEntries.Reset();
                        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::Invoice);
                        CustomerLedEntries.SetRange(Open, true);
                        Page.Run(Page::"Customer Ledger Entries", CustomerLedEntries);
                    end;
                }
            }
            cuegroup(PanierBS)
            {
                Caption = 'Panier BS';
                field("Total BS Ligne Inc. VAT"; "Total BS Ligne Inc. VAT")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        SalesShitLine: Record "Sales Shipment Line";
                    begin
                        SalesShitLine.SetRange(BS, true);
                        Page.Run(Page::"Ligne Bon de sortie", SalesShitLine);
                    end;
                }
            }
            cuegroup(Article)
            {
                Caption = 'Articles';
                // field(Reception; FilterCentralReception)
                // {
                //     ApplicationArea = All;
                //     trigger OnDrillDown()
                //     var
                //         BinContent: Record "Bin Content";
                //     begin
                //         InvSetup.Get();
                //         BinContent.Reset();
                //         BinContent.SetRange("Location Code", InvSetup."Magasin Central");
                //         BinContent.SetRange("Bin Code", InvSetup."Emplacement Reception");
                //         BinContent.Setfilter(Quantity, '>0');
                //         Page.Run(Page::"Item Bin Contents", BinContent);
                //     end;
                // }
                field("Litige +"; FilterLitige)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }

                // field("Item Bin Count"; rec."Item Bin")
                // {
                //     Caption = 'Article avec +Emplacement';
                //     ApplicationArea = All;
                //     DrillDownPageId = "Item Bin Contents";
                //     DrillDown = true;
                // }

                field("Neg Ajust Year"; "Neg Ajust Year")
                {
                    Caption = 'NB article Ajust Neg -';
                    ApplicationArea = All;
                    DrillDownPageId = "Item Ledger Entries";
                    DrillDown = true;
                }

                field(ItemHasStockWithoutUnitPrice; ItemHasStockWithoutUnitPrice)
                {
                    Caption = 'En Stock & Sans prix vente';
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
                // field("Nbr Of Items recently created"; "Nbr Of Items recently created")
                // {
                //     ApplicationArea = All;
                // }
                // field("Nbr Of Non Verified Items"; "Nbr Of Non Verified Items")
                // {
                //     ApplicationArea = All;
                // }

            }

            cuegroup(AjustLitige)
            {
                Caption = 'Ajustements et litige ';
                field(AjustPosi; FilterPositiveAdj())
                {
                    Caption = 'Ajust. positif (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        ItemLedgerEntries: Record "Item Ledger Entry";
                    begin
                        GLSetup.Get();
                        ItemLedgerEntries.Reset();
                        ItemLedgerEntries.SetRange("Entry Type", ItemLedgerEntries."Entry Type"::"Positive Adjmt.");
                        // ItemLedgerEntries.SetFilter("Posting Date", '%1..', CalcDate('<CD+2D>', GLSetup."Allow Posting From"));
                        ItemLedEnt.SetFilter("Posting Date", '%1..%2', System.DMY2Date(3, 1, System.Date2DMY(Today, 3)), WorkDate()); //TODO:
                        ItemLedgerEntries.SetFilter("Remaining Quantity", '<>0');
                        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntries);
                    end;
                }
                field(AjustNeg; FilterNegAdj())
                {
                    Caption = 'Ajust. négatif (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        ItemLedgerEntries: Record "Item Ledger Entry";
                    begin
                        GLSetup.Get();
                        ItemLedgerEntries.Reset();
                        ItemLedgerEntries.SetRange("Entry Type", ItemLedgerEntries."Entry Type"::"Negative Adjmt.");
                        ItemLedgerEntries.SetFilter("Posting Date", '%1..', CalcDate('<CD+2D>', GLSetup."Allow Posting From"));
                        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntries);
                    end;
                }
                field("Litige + Valeur"; FilterLitigeValeur(1))
                {
                    Caption = 'Litige + (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
                field("Litige - Valeur"; FilterLitigeValeur(2))
                {
                    Caption = 'Litige - (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige -");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
                field("Endommage Valeur"; FilterLitigeValeur(3))
                {
                    Caption = 'Endommagé (£)';
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        BinContent: Record "Bin Content";
                    begin
                        InvSetup.Get();
                        BinContent.Reset();
                        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
                        BinContent.SetRange("Bin Code", InvSetup."Emplacement Endommagé");
                        BinContent.Setfilter(Quantity, '>0');
                        Page.Run(Page::"Item Bin Contents", BinContent);
                    end;
                }
            }
            // cuegroup("Sales Orders Released Not Shipped")
            // {
            //     Caption = 'Sales Orders Released Not Shipped';
            //     field(ReadyToShip; "Ready to Ship")
            //     {
            //         ApplicationArea = Basic, Suite;
            //         Caption = 'Ready To Ship';
            //         DrillDownPageID = "Sales Order List";
            //         ToolTip = 'Specifies the number of sales documents that are ready to ship.';

            //         trigger OnDrillDown()
            //         begin
            //             ShowOrders(FieldNo("Ready to Ship"));
            //         end;
            //     }
            //     field(PartiallyShipped; "Partially Shipped")
            //     {
            //         ApplicationArea = Basic, Suite;
            //         Caption = 'Partially Shipped';
            //         DrillDownPageID = "Sales Order List";
            //         ToolTip = 'Specifies the number of sales documents that are partially shipped.';

            //         trigger OnDrillDown()
            //         begin
            //             ShowOrders(FieldNo("Partially Shipped"));
            //         end;
            //     }
            //     field(DelayedOrders; Delayed)
            //     {
            //         ApplicationArea = Basic, Suite;
            //         Caption = 'Delayed';
            //         DrillDownPageID = "Sales Order List";
            //         ToolTip = 'Specifies the number of sales documents where your delivery is delayed.';

            //         trigger OnDrillDown()
            //         begin
            //             ShowOrders(FieldNo(Delayed));
            //         end;
            //     }
            //     field("Average Days Delayed"; "Average Days Delayed")
            //     {
            //         ApplicationArea = Basic, Suite;
            //         DecimalPlaces = 0 : 1;
            //         Image = Calendar;
            //         ToolTip = 'Specifies the number of days that your order deliveries are delayed on average.';
            //     }

            //     actions
            //     {
            //         action(Navigate)
            //         {
            //             ApplicationArea = Basic, Suite;
            //             Caption = 'Navigate';
            //             RunObject = Page Navigate;
            //             ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';
            //         }
            //     }
            // }
            // cuegroup(Returns)
            // {
            //     Caption = 'Returns';
            //     field(OpenReturnOrdersCnt; OpenReturnOrdersCnt)
            //     {
            //         ApplicationArea = SalesReturnOrder;
            //         DrillDownPageID = "Sales Return Order List";
            //         ToolTip = 'Specifies the number of sales return orders documents that are displayed in the Sales Cue on the Role Center. The documents are filtered by today''s date.';
            //     }
            //     field(OpenCreditMemosCnt; OpenCreditMemosCnt)
            //     {
            //         ApplicationArea = Basic, Suite;
            //         DrillDownPageID = "Sales Credit Memos";
            //         ToolTip = 'Specifies the number of sales credit memos that are not yet posted.';
            //     }

            //     actions
            //     {
            //         action("New Sales Return Order")
            //         {
            //             ApplicationArea = SalesReturnOrder;
            //             Caption = 'New Sales Return Order';
            //             RunObject = Page "Sales Return Order";
            //             RunPageMode = Create;
            //             ToolTip = 'Process a return or refund that requires inventory handling by creating a new sales return order.';
            //         }
            //         action("New Sales Credit Memo")
            //         {
            //             ApplicationArea = Basic, Suite;
            //             Caption = 'New Sales Credit Memo';
            //             RunObject = Page "Sales Credit Memo";
            //             RunPageMode = Create;
            //             ToolTip = 'Process a return or refund by creating a new sales credit memo.';
            //         }
            //     }
            // }
            // cuegroup("Document Exchange Service")
            // {
            //     Caption = 'Document Exchange Service';
            //     Visible = ShowDocumentsPendingDodExchService;
            //     field("Sales Inv. - Pending Doc.Exch."; "Sales Inv. - Pending Doc.Exch.")
            //     {
            //         ApplicationArea = Suite;
            //         ToolTip = 'Specifies sales invoices that await sending to the customer through the document exchange service.';
            //         Visible = ShowDocumentsPendingDodExchService;
            //     }
            //     field("Sales CrM. - Pending Doc.Exch."; "Sales CrM. - Pending Doc.Exch.")
            //     {
            //         ApplicationArea = Suite;
            //         ToolTip = 'Specifies sales credit memos that await sending to the customer through the document exchange service.';
            //         Visible = ShowDocumentsPendingDodExchService;
            //     }
            // }
            // cuegroup("My User Tasks")
            // {
            //     Caption = 'My User Tasks';
            //     field("UserTaskManagement.GetMyPendingUserTasksCount"; UserTaskManagement.GetMyPendingUserTasksCount)
            //     {
            //         ApplicationArea = Basic, Suite;
            //         Caption = 'Pending User Tasks';
            //         Image = Checklist;
            //         ToolTip = 'Specifies the number of pending tasks that are assigned to you or to a group that you are a member of.';

            //         trigger OnDrillDown()
            //         var
            //             UserTaskList: Page "User Task List";
            //         begin
            //             UserTaskList.SetPageToShowMyPendingUserTasks;
            //             UserTaskList.Run;
            //         end;
            //     }
            // }
            // usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            // {
            //     ApplicationArea = Basic, Suite;
            //     trigger ResponseReceived(Status: Integer; Response: Text)
            //     var
            //         SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
            //     begin
            //         SatisfactionSurveyMgt.TryShowSurvey(Status, Response);
            //     end;

            //     trigger ControlAddInReady();
            //     begin
            //         IsAddInReady := true;
            //         CheckIfSurveyEnabled();
            //     end;
            // }
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
        CalculateCueFieldValues;
        ShowDocumentsPendingDodExchService := false;
        if DocExchServiceSetup.Get then
            ShowDocumentsPendingDodExchService := DocExchServiceSetup.Enabled;
    end;

    trigger OnOpenPage()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        RecentDate: Date;
        recSetupPurchase: Record "Purchases & Payables Setup";
        defaultVendor: code[20];
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetRespCenterFilter;
        SetRange("Date Filter", 0D, WorkDate - 1);
        SetFilter("Date Filter2", '>=%1', WorkDate);
        SetFilter("User ID Filter", UserId);

        RoleCenterNotificationMgt.ShowNotifications;
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent;

        // if PageNotifier.IsAvailable then begin
        //     PageNotifier := PageNotifier.Create;
        //     PageNotifier.NotifyPageReady;
        // end;

        PurchSetup.Get();
        PurchSetup.TestField(PurchSetup."Nbr Days Item recently created");
        RecentDate := CalcDate('<CD-' + format(PurchSetup."Nbr Days Item recently created") + 'D>', Today);
        SetFilter("Date Filter 3", '%1..%2', RecentDate, Today());
        InvSetup.Get();
        SalesOrderFitlers();
        if B2BStatusArray[1] > 10 then
            EnAttente1 := 'Unfavorable';

        if B2BStatusArray[3] > 10 then
            EnAttente3 := 'Unfavorable';

        if B2BStatusArray[5] > 10 then
            EnAttente5 := 'Unfavorable';

        if B2BStatusArray[6] > 10 then
            EnAttente6 := 'Unfavorable';

        SetRange("Date Filter2", Today);
        CalcFields("Sales (LCY)");
        Vente1 := "Sales (LCY)";

        StartingDate := System.DMY2Date(1, System.Date2DMY(Today, 2), System.Date2DMY(Today, 3));
        SetRange("Date Filter2", StartingDate, WorkDate);
        CalcFields("Sales (LCY)");
        Vente2 := "Sales (LCY)";


        StartingDate := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        Setfilter("Date Filter2", '%1..', StartingDate);
        CalcFields("Sales (LCY)");
        Vente3 := "Sales (LCY)";

        userSetup.SetFilter("User ID", UserId);
        if userSetup.FindFirst() then begin
            StatPurchaseCA := userSetup."Purchase Stat CA";
        end;

        recSetupPurchase.Reset();
        if recSetupPurchase.FindFirst() then begin
            defaultVendor := recSetupPurchase."Default Vendor";
        end;
        if "Default Vendor" <> defaultVendor then begin
            "Default Vendor" := defaultVendor;
            Modify();
        end;

        if "date jour" <> Today then begin
            "date jour" := Today;
            Modify();
        end;

        StartingDate2 := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        Setfilter("Date Filter2", '%1..', StartingDate2);
        CalcFields("Sales (LCY)");
        Vente4 := "Sales (LCY)";


        debutMois := CalcDate('<-CM>', Today);
        FinMois := CalcDate('<CM>', Today);
        SetFilter("Date Filter Month", '%1..%2', debutMois, FinMois);
        CalcFields("Month Sum Purchase");
        achat := "Month Sum Purchase";
    end;


    local procedure SalesOrderFitlers()
    var
        UserMgt: Codeunit "User Setup Management";

    begin
        SalesOrders.Reset();
        SalesOrders.SetRange("Document Type", SalesOrders."Document Type"::Order);

        IF UserMgt.GetRespCenter(1, '') <> '' THEN BEGIN
            FILTERGROUP(2);
            SalesOrders.SETRANGE("Responsibility Center", UserMgt.GetServiceFilterEDMS);
            FILTERGROUP(0);
        END;

        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Commande en attente");
        B2BStatusArray[1] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Commande lancée");
        B2BStatusArray[2] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En cours de préparation");
        B2BStatusArray[3] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Préparé");
        B2BStatusArray[4] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En cours de pointage");
        B2BStatusArray[5] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"En attente de livraison");
        B2BStatusArray[6] := SalesOrders.Count;
        SalesOrders.SetRange("Statut B2B", SalesOrders."Statut B2B"::"Livré");
        B2BStatusArray[7] := SalesOrders.Count;

    end;

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

    local procedure FilterLitige(): Integer
    var
        BinContent: Record "Bin Content";
    begin
        InvSetup.Get();
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
        BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +");
        BinContent.Setfilter(Quantity, '>0');
        exit(BinContent.Count);

    end;

    local procedure FilterPositiveAdj(): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CostPositiveAdjust: Decimal;

    begin
        CostPositiveAdjust := 0;
        GLSetup.Get();
        ItemLedEnt.Reset();
        ItemLedEnt.SetRange("Entry Type", ItemLedEnt."Entry Type"::"Positive Adjmt.");
        // ItemLedEnt.SetFilter("Posting Date", '%1..', CalcDate('<CD+2D>', GLSetup."Allow Posting From"));
        ItemLedEnt.SetFilter("Posting Date", '%1..%2', System.DMY2Date(3, 1, System.Date2DMY(Today, 3)), WorkDate()); //TODO:

        ItemLedEnt.SetFilter("Remaining Quantity", '<>0');
        if ItemLedEnt.FindSet() then begin
            repeat
                ItemLedEnt.CalcFields("Cost Amount (Actual)");
                CostPositiveAdjust := CostPositiveAdjust + ((ItemLedEnt."Cost Amount (Actual)" / ItemLedEnt.Quantity) * ItemLedEnt."Remaining Quantity");
            until ItemLedEnt.Next() = 0;
            CurrencyExchangeRate.Reset();
            CurrencyExchangeRate.SetRange("Currency Code", GLSetup."Currency Euro");
            CurrencyExchangeRate.SetCurrentKey("Starting Date");
            if CurrencyExchangeRate.FindLast() then
                exit(CostPositiveAdjust * CurrencyExchangeRate."Exchange Rate Amount");
        end;
    end;

    local procedure FilterNegAdj(): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CostNegatAdjust: Decimal;

    begin
        CostNegatAdjust := 0;
        GLSetup.Get();
        ItemLedEnt.Reset();
        ItemLedEnt.SetRange("Entry Type", ItemLedEnt."Entry Type"::"Negative Adjmt.");
        ItemLedEnt.SetFilter("Posting Date", '%1..', CalcDate('<CD+2D>', GLSetup."Allow Posting From"));
        if ItemLedEnt.FindSet() then
            repeat
                ItemLedEnt.CalcFields("Cost Amount (Actual)");
                CostNegatAdjust += (ItemLedEnt."Cost Amount (Actual)");
            until ItemLedEnt.Next() = 0;
        CurrencyExchangeRate.Reset();
        CurrencyExchangeRate.SetRange("Currency Code", GLSetup."Currency Euro");
        CurrencyExchangeRate.SetCurrentKey("Starting Date");
        if CurrencyExchangeRate.FindLast() then
            exit(CostNegatAdjust * CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure FilterLitigeValeur(V: Integer): Decimal
    var
        BinContent: Record "Bin Content";
        lItem: Record Item;
        TotalCost: Decimal;
        CurrencyExchangeRate: Record "Currency Exchange Rate";

    begin
        InvSetup.Get();

        TotalCost := 0;
        BinContent.Reset();
        BinContent.SetRange("Location Code", InvSetup."Magasin litige");
        if v = 1 then
            BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige +")
        else
            if v = 2 then
                BinContent.SetRange("Bin Code", InvSetup."Emplacement Litige -")
            else
                if v = 3 then
                    BinContent.SetRange("Bin Code", InvSetup."Emplacement Endommagé");

        BinContent.Setfilter(Quantity, '>0');
        if BinContent.FindSet() then
            repeat
                lItem.Get(BinContent."Item No.");
                TotalCost += lItem."Unit Cost" * BinContent.CalcQtyUOM;
            until BinContent.Next() = 0;
        CurrencyExchangeRate.Reset();
        CurrencyExchangeRate.SetRange("Currency Code", GLSetup."Currency Euro");
        CurrencyExchangeRate.SetCurrentKey("Starting Date");
        if CurrencyExchangeRate.FindLast() then
            exit(TotalCost * CurrencyExchangeRate."Exchange Rate Amount");

    end;

    local procedure FindNotInvoiced(): Integer
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesShipmentH: Record "Sales Shipment Header";
    begin
        TempSalesShipmentHead.Reset();
        TempSalesShipmentHead.DeleteAll();
        SalesShipmentLine.Reset();
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("Quantity Invoiced", 0);
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

    local procedure FindNotInvoicedReturn(): Integer
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        CountRRH: Integer;
    begin
        TempReturReceiptHeader.Reset();
        TempReturReceiptHeader.DeleteAll();
        ReturnReceiptLine.Reset();
        ReturnReceiptLine.SetRange(Type, ReturnReceiptLine.Type::Item);
        ReturnReceiptLine.SetRange("Quantity Invoiced", 0);
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

    local procedure FactureNonReglee(): Integer
    var
        CustomerLedEntries: Record "Cust. Ledger Entry";
    begin
        CustomerLedEntries.Reset();
        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::Invoice);
        CustomerLedEntries.SetRange(Open, true);
        exit(CustomerLedEntries.Count);
    end;

    local procedure TotalFactureNonReglee(): Decimal
    var
        CustomerLedEntries: Record "Cust. Ledger Entry";
    begin
        sumNotPaiedInvoice := 0;
        CustomerLedEntries.Reset();
        CustomerLedEntries.SetRange("Document Type", CustomerLedEntries."Document Type"::Invoice);
        CustomerLedEntries.SetRange(Open, true);
        if CustomerLedEntries.FindSet() then begin
            repeat
                CustomerLedEntries.CalcFields("Remaining Amount");
                sumNotPaiedInvoice := sumNotPaiedInvoice + CustomerLedEntries."Remaining Amount";
            until CustomerLedEntries.Next() = 0;
        end;
        exit(sumNotPaiedInvoice);
    end;

    local procedure TotalFactureNonRegleeRC(): Decimal
    var
        salesInvoice: Record "Sales Invoice Header";
        sumInvNotPaidRC: Decimal;
    begin
        sumInvNotPaidRC := 0;
        salesInvoice.SetRange(solde, false);
        if salesInvoice.FindSet() then begin
            repeat
                salesInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
                sumInvNotPaidRC := sumInvNotPaidRC + salesInvoice."Amount Including VAT" + salesInvoice."STStamp Amount" - salesInvoice."Montant reçu caisse";
            until salesInvoice.Next() = 0;
        end;
        exit(sumInvNotPaidRC);
    end;

    local procedure TotalAvoirNonRegleeRC(): Decimal
    var
        salesCrMemo: Record "Sales Cr.Memo Header";
        sumCrMemoNotPaidRC: Decimal;
    begin
        sumCrMemoNotPaidRC := 0;
        salesCrMemo.SetRange(solde, false);
        if salesCrMemo.FindSet() then begin
            repeat
                salesCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                sumCrMemoNotPaidRC := sumCrMemoNotPaidRC + salesCrMemo."Amount Including VAT" - salesCrMemo."Montant reçu caisse";
            until salesCrMemo.Next() = 0;
        end;
        exit(sumCrMemoNotPaidRC);
    end;

    local procedure TotalBLNonRegleeRC(): Decimal
    var
        salesShipment: Record "Sales Shipment Header";
        sumShipNotPaidRC: Decimal;
    begin
        sumShipNotPaidRC := 0;
        salesShipment.SetRange(solde, false);
        salesShipment.SetRange(BS, false);
        if salesShipment.FindSet() then begin
            repeat
                salesShipment.CalcFields("Line Amount", "Montant reçu caisse");
                sumShipNotPaidRC := sumShipNotPaidRC + salesShipment."Line Amount" - salesShipment."Montant reçu caisse";
            until salesShipment.Next() = 0;
        end;
        exit(sumShipNotPaidRC);
    end;

    local procedure TotalBSNonRegleeRC(): Decimal
    var
        salesShipment: Record "Entete archive BS";
        sumShipNotPaidRC: Decimal;
    begin
        sumShipNotPaidRC := 0;
        salesShipment.SetRange(solde, false);
        if salesShipment.FindSet() then begin
            repeat
                salesShipment.CalcFields("Montant TTC", "Montant reçu caisse");
                sumShipNotPaidRC := sumShipNotPaidRC + salesShipment."Montant TTC" - salesShipment."Montant reçu caisse";
            until salesShipment.Next() = 0;
        end;
        exit(sumShipNotPaidRC);
    end;

    local procedure TotalRetourBLNonRegleeRC(): Decimal
    var
        salesReturnShip: Record "Return Receipt Header";
        sumReturnShipNotPaidRC: Decimal;
    begin
        sumReturnShipNotPaidRC := 0;
        salesReturnShip.SetRange(solde, false);
        salesReturnShip.SetRange(BS, false);
        if salesReturnShip.FindSet() then begin
            repeat
                salesReturnShip.CalcFields("Line Amount", "Montant reçu caisse");
                sumReturnShipNotPaidRC := sumReturnShipNotPaidRC + salesReturnShip."Line Amount" - salesReturnShip."Montant reçu caisse";
            until salesReturnShip.Next() = 0;
        end;
        exit(sumReturnShipNotPaidRC);
    end;

    local procedure TotalRetourBSNonRegleeRC(): Decimal
    var
        salesReturnShip: Record "Return Receipt Header";
        sumReturnShipNotPaidRC: Decimal;
    begin
        sumReturnShipNotPaidRC := 0;
        salesReturnShip.SetRange(solde, false);
        salesReturnShip.SetRange(BS, true);
        if salesReturnShip.FindSet() then begin
            repeat
                salesReturnShip.CalcFields("Line Amount", "Montant reçu caisse");
                sumReturnShipNotPaidRC := sumReturnShipNotPaidRC + salesReturnShip."Line Amount" - salesReturnShip."Montant reçu caisse";
            until salesReturnShip.Next() = 0;
        end;
        exit(sumReturnShipNotPaidRC);
    end;

    var
        Vente4, achat : Decimal;
        StatPurchaseCA: Boolean;
        StartingDate2, debutMois, FinMois : Date;
        userSetup: Record "User Setup";
        sumNotPaiedInvoice: Decimal;
        B2BStatusArray: array[20] of integer;
        SalesOrders: Record "Sales Header";
        PurchSetup: Record "Purchases & Payables Setup";
        InvSetup: Record "Inventory Setup";
        Item: Record Item;
        ItemLedEnt: Record "Item Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        [InDataSet]
        EnAttente1, EnAttente3, EnAttente5, EnAttente6 : Code[20];
        CountSSH: Integer;
        TempSalesShipmentHead: Record "Sales Shipment header" temporary;
        TempReturReceiptHeader: Record "Return Receipt Header" temporary;
        Vente1, Vente2, Vente3 : Decimal;
        StartingDate: Date;
        CuesAndKpis: Codeunit "Cues And KPIs";
        UserTaskManagement: Codeunit "User Task Management";
        // [RunOnClient]
        // [WithEvents]
        //PageNotifier: DotNet PageNotifier;
        ShowDocumentsPendingDodExchService: Boolean;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;
        OpenSalesOrdersCnt: Integer;
        OpenSalesQuotesCnt: Integer;
        OpenReturnOrdersCnt: Integer;
        OpenCreditMemosCnt: Integer;


    local procedure CalculateCueFieldValues()
    var
        SalesHeader: Record "Sales Header";
        DocProfMgt: Codeunit "Document Profile Mgt. EDMS";
        DocProfFilter: Text;

    begin
        if FieldActive("Average Days Delayed") then
            "Average Days Delayed" := CalculateAverageDaysDelayed;

        if FieldActive("Ready to Ship") then
            "Ready to Ship" := CountOrders(FieldNo("Ready to Ship"));

        if FieldActive("Partially Shipped") then
            "Partially Shipped" := CountOrders(FieldNo("Partially Shipped"));

        if FieldActive(Delayed) then
            Delayed := CountOrders(FieldNo(Delayed));

        DocProfFilter := DocProfMgt.GetDocProfileFilter();
        SalesHeader.Reset();
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        SalesHeader.SetFilter("Document Profile", DocProfFilter);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        OpenSalesOrdersCnt := SalesHeader.Count;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        OpenSalesQuotesCnt := SalesHeader.Count;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        OpenReturnOrdersCnt := SalesHeader.Count;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        OpenCreditMemosCnt := SalesHeader.Count;
    end;

    // trigger PageNotifier::PageReady()
    // begin
    //     IsPageReady := true;
    //     CheckIfSurveyEnabled();
    // end;

    // local procedure CheckIfSurveyEnabled()
    // var
    //     SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
    //     CheckUrl: Text;
    // begin
    //     if not IsAddInReady then
    //         exit;
    //     if not IsPageReady then
    //         exit;
    //     if not SatisfactionSurveyMgt.DeactivateSurvey() then
    //         exit;
    //     if not SatisfactionSurveyMgt.TryGetCheckUrl(CheckUrl) then
    //         exit;
    //     CurrPage.SATAsyncLoader.SendRequest(CheckUrl, SatisfactionSurveyMgt.GetRequestTimeoutAsync());
    // end;
}

