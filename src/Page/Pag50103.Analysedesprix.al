page 50103 "Analyse des prix"
{
    AdditionalSearchTerms = 'product,finished good,component,raw material,assembly item';
    ApplicationArea = All;
    CardPageID = "Item Card";
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Item,History,Special Prices & Discounts,Request Approval,Periodic Activities,Inventory,Attributes';
    QueryCategory = 'Item List';
    RefreshOnActivate = true;
    SourceTable = Item;
    UsageCategory = Lists;
    SourceTableView = SORTING("Item Type") WHERE("Item Type" = CONST(Item));
    Caption = 'Analyse des prix';
    //, "Statut Prix" = FILTER("Plus cher" | "Moins cher")

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Caption = 'Item';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the item.';
                    StyleExpr = FieldStyle;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the item.';
                    StyleExpr = FieldStyle;
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'Stock';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost per unit of the item.';
                    StyleExpr = FieldStyle;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = All;

                }
                field("Prix vente unitaire"; "Prix vente unitaire")
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + 'Prix vente unitaire (' + Parvente."Société base analyseur prix" + ' )';
                    StyleExpr = FieldStyle;
                }
                field(etatStkFrsBase; etatStkFrsBase)
                {
                    StyleExpr = FieldEtatStyle;
                    CaptionClass = '3,' + 'Etat Stock (' + Parvente."Société base analyseur prix" + ' )';
                }
                field("Statut Prix"; "Statut Prix")
                {
                    ApplicationArea = All;
                    StyleExpr = FieldStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // group(ItemActionGroup)
            // {
            //     Caption = 'Appliquer les nouveaux valeurs';
            //     Image = DataEntry;
            action("Appliquer les nouveaux valeurs")
            {
                Caption = 'Appliquer les nouveaux valeurs';
                Ellipsis = true;
                Image = Calculate;
                Promoted = true;
                //PromotedCategory = Category4;
                trigger OnAction()
                var
                    myInt: Integer;
                    PItem: Record Item;
                begin
                    CurrPage.SETSELECTIONFILTER(PItem);
                    PItem.setfilter("Statut Prix", '%1|%2', "Statut Prix"::"Moins cher", "Statut Prix"::"Plus cher");
                    IF PItem.FINDSET THEN begin
                        repeat
                            PItem."Unit Price" := PItem."Prix vente unitaire";
                            PItem."Statut Prix" := PItem."Statut Prix"::" ";
                            PItem.modify;
                            Message('REF %1 - Prix MPAA %2 - Prix SOPIQ %3', PItem."No.", PItem."Unit Price", PItem."Prix vente unitaire");
                        UNTIL PItem.NEXT = 0;

                    end;
                end;
            }
            //}
        }

    }

    // trigger OnAfterGetCurrRecord()
    // var
    //     CRMCouplingManagement: Codeunit "CRM Coupling Management";
    //     SocialListeningMgt: Codeunit "Social Listening Management";
    //     WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    // begin

    // end;

    trigger OnAfterGetRecord()
    var
        recFabricant: Record Manufacturer;
    begin
        CalcFields(Inventory);
        GItem.ChangeCompany(Parvente."Société base analyseur prix");
        IF GItem.GET("No.") then begin
            recFabricant.Reset();
            recFabricant.SetRange(code, rec."Manufacturer Code");
            if recFabricant.FindFirst() then begin
                if recFabricant.IsSpecific = true then
                    "Prix vente unitaire" := GItem."Unit Price" * (1 + Parvente.margeSpecifique / 100)
                else
                    "Prix vente unitaire" := GItem."Unit Price" * (1 + Parvente.margeStandard / 100);
            end;
        end;

        SetStyle();

        recItem.ChangeCompany(Parvente."Société base analyseur prix");
        IF recItem.GET("No.") then begin
            recItem.CalcFields(StockQty, ImportQty);
            if (recItem.StockQty > 0) then rec.etatStkFrsBase := etatStkFrsBase::"En Stock";
            if (recItem.StockQty = 0) AND (recItem.ImportQty = 0) then rec.etatStkFrsBase := etatStkFrsBase::Rupture;
            if (recItem.StockQty = 0) AND (recItem.ImportQty > 0) then rec.etatStkFrsBase := etatStkFrsBase::"En arrivage";
            // rec.Modify();
        end;
        SetEtatStyle();

    end;

    // trigger OnFindRecord(Which: Text): Boolean
    // var
    //     Found: Boolean;
    // begin
    //     setfilter("inventory", '<>0');
    //     SetFilter("Statut Prix", '%1 | %2', "Statut Prix"::"Moins cher", "Statut Prix"::"Plus cher");
    // end;

    trigger OnInit()
    begin
        Parvente.get;
        if Parvente."Activer analyseur de prix" then begin
            Parvente.TestField("Société base analyseur prix");

        end;
    end;

    trigger OnOpenPage()
    begin

    end;

    procedure SetEtatStyle()
    begin
        IF etatStkFrsBase = etatStkFrsBase::Rupture THEN begin
            FieldEtatStyle := 'Attention';
        end else begin
            if etatStkFrsBase = etatStkFrsBase::"En arrivage" THEN begin
                FieldEtatStyle := 'StandardAccent';
            end else begin
                FieldEtatStyle := 'Favorable';
            end;

        end;
    end;

    // trigger OnNextRecord(Steps: Integer): Integer
    // var
    //     ResultSteps: Integer;
    // begin

    // end;

    // trigger OnOpenPage()
    // var
    //     SocialListeningSetup: Record "Social Listening Setup";
    //     CRMIntegrationManagement: Codeunit "CRM Integration Management";
    //     ClientTypeManagement: Codeunit "Client Type Management";
    // begin
    // end;
    procedure SetStyle()
    begin
        IF ("Unit Price" <> 0) AND ("Prix vente unitaire" <> 0) then begin
            IF ("Unit Price" > "Prix vente unitaire") AND (("Unit Price" / "Prix vente unitaire") > (1 + Parvente.Tolerance / 100)) THEN begin
                FieldStyle := 'Attention';
                "Statut Prix" := "Statut Prix"::"Plus cher";
                Modify;
            end else begin
                if ("Unit Price" < "Prix vente unitaire") AND (("Prix vente unitaire" / "Unit Price") > (1 + Parvente.Tolerance / 100)) THEN begin
                    "Statut Prix" := "Statut Prix"::"Moins cher";
                    FieldStyle := 'StandardAccent';
                    Modify;
                end else begin
                    "Statut Prix" := "Statut Prix"::" ";
                    FieldStyle := 'Standard';
                    Modify;
                end;

            end;
        end;





        // "Unit Cost" < "Prix vente unitaire" THEN  FieldStyle := 'Attention';
    end;

    var
        Parvente: Record "Sales & Receivables Setup";
        GItem: Record Item;
        FieldStyle: Text[50];
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        TempItemFilteredFromAttributes: Record Item temporary;
        TempItemFilteredFromPickItem: Record Item temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        SkilledResourceList: Page "Skilled Resource List";
        IsFoundationEnabled: Boolean;
        [InDataSet]
        SocialListeningSetupVisible: Boolean;
        [InDataSet]
        SocialListeningVisible: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        OpenApprovalEntriesExist: Boolean;
        EnabledApprovalWorkflowsExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        IsOnPhone: Boolean;
        RunOnTempRec: Boolean;
        EventFilter: Text;
        PowerBIVisible: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        [InDataSet]
        IsNonInventoriable: Boolean;
        [InDataSet]
        IsInventoriable: Boolean;
        RunOnPickItem: Boolean;
        FieldEtatStyle: Text[50];
        recItem: Record Item;






}

