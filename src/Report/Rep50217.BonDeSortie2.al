report 50217 "Bon De Sortie 2"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/BonDeSortie2.rdl';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = all;
    Caption = 'Bon de sortie';
    dataset
    {
        dataitem(CompanyInfo; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1));
            PrintOnlyIfDetail = true;

            column(Logo; RecInfoSociete.Picture)
            {

            }
            column(LogoEntête; RecInfoSociete."Invoice Header Picture")
            {

            }
            column(LogoPieds_Page; RecInfoSociete."Invoice Footer Picture")
            {

            }
            column(afficherPiedsPage; afficherPiedsPage)
            {
            }

            column(VIN; lVehicle.VIN)
            {

            }
            column(Modele; lVehicle."Model Code")
            {

            }
            column(Serie; lVehicle."Registration No.")
            {

            }
            column(Marque; lVehicle."Make Code")
            {

            }
            column(Name; customer.Name)
            {

            }
            column(CustomerNo; customer."No.")
            {

            }

            dataitem(PaymentHead; "Payment Header")
            {
                CalcFields = "Amount (LCY)";
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.";
                column(Type; Type)
                {

                }
                column(PaymentHeaderNo; "No.")
                {
                }
                column(recpaiementlineAccountNo; recpaiementline."Account No.")
                {
                }
                column(recpaiementlineLibelle; recpaiementline."STLibellé")
                {
                }

                column(ABSPaymentHeaderAmountLCY; "Amount (LCY)")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(PaymentHeaderPostingDate; "Posting Date")
                {
                }
                column(PaymentClassTypeBordereau; RecGPaymentClass.STType_Reg)
                {
                }

                dataitem(PaymentLine; "Payment Line")
                {
                    DataItemLink = "No." = FIELD("No.");
                    PrintOnlyIfDetail = true;

                    column(Line_No_; "Line No.")
                    {

                    }
                    column(AccountNo; "Account No.")
                    {

                    }
                    column(PaymentLineExternalDocumentNo; PaymentLine."External Document No.")
                    {
                    }
                    column(PaymentLineBankAccountName; PaymentLine."Bank Account Name")
                    {
                    }
                    column(DateEch; DateEch)
                    {
                    }

                    column(ABSPaymentLineAmountLCY; PaymentLine."Amount (LCY)")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }

                    column(Order_Type; "STOrder Type")
                    {

                    }
                    column(Order_No; "STOrder No.")
                    {

                    }
                    column(ValeurTimbre; RecSalesHeader."STStamp Amount")
                    {

                    }
                    column(AmountIncludingVAT; RecSalesLine."Amount Including VAT")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                    {

                        DataItemLink = "Applies-to ID" = FIELD("Applies-to ID"), "Customer No." = field("Account No.");
                        DataItemLinkReference = PaymentLine;

                        column(Document_No_; "Document No.")
                        {

                        }
                        column(Amount_to_Apply; "Amount to Apply")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;

                        }
                        column(External_Document_No_; "External Document No.")
                        {

                        }
                        trigger OnAfterGetRecord()
                        begin
                            if salesInvoiceHeader.get("Document No.") then begin
                                if (salesInvoiceHeader."Document Profile" <> salesInvoiceHeader."Document Profile"::Service) then
                                    CurrReport.skip();
                                lVehicle.Get(salesInvoiceHeader."Vehicle Serial No.")
                            end;
                        end;
                    }
                    trigger OnAfterGetRecord()

                    begin
                        customer.Reset();
                        customer.SetRange("No.", "Account No.");
                        if customer.FindFirst() then;

                        RecGPaymentClass.RESET;
                        RecGPaymentClass.SETRANGE(Code, PaymentHead."Payment Class");
                        IF RecGPaymentClass.FINDFIRST THEN BEGIN
                            CASE RecGPaymentClass.STType_Reg OF
                                RecGPaymentClass.STType_Reg::"Chèque", RecGPaymentClass.STType_Reg::Traite:
                                    DateEch := "Due Date";
                                ELSE
                                    DateEch := PaymentHead."Document Date";
                            END;
                        END;

                        RecSalesHeader.Reset();
                        RecSalesHeader.SetRange("No.", "STOrder No.");
                        if RecSalesHeader.FindFirst() then;
                        RecSalesLine.Reset();
                        RecSalesLine.SetRange("Document No.", "STOrder No.");
                        if RecSalesLine.FindFirst() then;

                    end;
                }


                trigger OnPreDataItem()
                begin
                    if (PaymentHead.GetFilters = '') then
                        CurrReport.Break();
                end;

                trigger OnPostDataItem()
                var
                    PostServiceHeader: Record "Posted Serv. Order Header";
                    ServiceSetup: Record "Service Mgt. Setup EDMS";
                    paymentline: Record "Payment Line";
                    SalesInvoiHeader: Record "Sales Invoice Header";
                    CustLeagerEntry: Record "Cust. Ledger Entry";
                    NewChar: Code[1024];
                begin
                    if (PaymentHead.GetFilters = '') then
                        CurrReport.Break();
                    ServiceSetup.get();
                    SalesInvoiHeader.Reset();
                    paymentline.SetRange("No.", "No.");
                    paymentline.SetFilter("Applies-to ID", '<>%1', '');
                    if paymentline.FindFirst() then begin
                        CustLeagerEntry.SetRange("Customer No.", paymentline."Account No.");
                        CustLeagerEntry.SetFilter("Applies-to ID", paymentline."Applies-to ID");
                        if CustLeagerEntry.FindSet() then
                            repeat
                                SalesInvoiHeader.SetRange("No.", CustLeagerEntry."Document No.");
                                SalesInvoiHeader.SetRange("Document Profile", SalesInvoiHeader."Document Profile"::Service);
                                if SalesInvoiHeader.FindSet() then begin
                                    repeat
                                        if PostServiceHeader.get(SalesInvoiHeader."Service Order No.") then begin
                                            PostServiceHeader."Document Status" := ServiceSetup."Statut Print BS";
                                            PostServiceHeader.Modify();
                                        end;
                                    until SalesInvoiHeader.Next() = 0;
                                end;
                            until CustLeagerEntry.Next() = 0
                    end;
                end;
            }

            dataitem("Service Header EDMS"; "Service Header EDMS")
            {

                PrintOnlyIfDetail = false;
                RequestFilterFields = "No.";
                DataItemTableView = WHERE("Document Type" = const(order));
                column(No_; "No.")
                {

                }
                column(Amount_Including_VAT; "Amount Including VAT")
                {

                }
                column(DLT_Stamp_Amount; "Stamp Amount")
                {

                }
                trigger OnAfterGetRecord()

                begin
                    if lVehicle.Get("Service Header EDMS"."Vehicle Serial No.") then;
                    if customer.get("Service Header EDMS"."Sell-to Customer No.") then;

                end;

                trigger OnPreDataItem()
                begin
                    if ("Service Header EDMS".GetFilters = '') then
                        CurrReport.Break();
                end;

                trigger OnPostDataItem()
                var
                    PostServiceHeader: Record "Posted Serv. Order Header";
                    ServiceSetup: Record "Service Mgt. Setup EDMS";
                begin
                    if ("Service Header EDMS".GetFilters = '') then
                        CurrReport.Break();
                    ServiceSetup.get();
                    "Service Header EDMS"."Document Status" := ServiceSetup."Statut Print BS";
                    "Service Header EDMS".Modify();

                end;



            }

            dataitem("Posted Serv. Order Header"; "Posted Serv. Order Header")
            {

                PrintOnlyIfDetail = false;
                RequestFilterFields = "No.";
                column(PoNo_; "No.")
                {

                }
                column(PoAmount_Including_VAT; "Amount Including VAT")
                {

                }
                column(InvoiceNo; salesInvoiceHeader."No.")
                {

                }
                column(PDLT_Stamp_Amount; "Stamp Amount")
                {

                }

                column(DLT_Internal_Bill_to_Customer; "Internal Bill-to Customer")
                {

                }
                trigger OnAfterGetRecord()
                begin
                    if lVehicle.Get("Posted Serv. Order Header"."Vehicle Serial No.") then;
                    if customer.get("Posted Serv. Order Header"."Sell-to Customer No.") then;
                    salesInvoiceHeader.SetRange("Service Order No.", "Posted Serv. Order Header"."No.");
                    if (salesInvoiceHeader.FindFirst()) then;
                end;

                trigger OnPreDataItem()
                begin
                    if ("Posted Serv. Order Header".GetFilters = '') then
                        CurrReport.Break();
                end;

                trigger OnPostDataItem()
                var
                    PostServiceHeader: Record "Posted Serv. Order Header";
                    ServiceSetup: Record "Service Mgt. Setup EDMS";
                begin
                    if ("Posted Serv. Order Header".GetFilters = '') then
                        CurrReport.Break();
                    ServiceSetup.get();
                    "Posted Serv. Order Header"."document Status" := ServiceSetup."Statut Print BS";
                    "Posted Serv. Order Header".Modify();

                end;


            }

        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(afficherPiedsPage; afficherPiedsPage)
                {
                    ApplicationArea = all;
                    Caption = 'Afficher entête et pied de page';
                }
            }
        }

    }

    trigger OnInitReport()
    begin
        RecInfoSociete.GET();
        RecInfoSociete.CALCFIELDS(Picture);
        RecInfoSociete.CALCFIELDS("Invoice Header Picture");
        RecInfoSociete.CALCFIELDS("Invoice Footer Picture");
    end;


    var
        RecInfoSociete: Record "Company Information";
        RecCentreGestion: Record "Responsibility Center";
        customer: Record Customer;
        RecSalesHeader: Record 36;
        recpaiementline: Record 10866;
        DateEch: Date;
        Type: Text[30];
        RecGPaymentClass: Record 10860;
        RecSalesLine: Record 37;
        salesInvoiceLine: Record "Sales Invoice Line";
        lServiceHeader: Record "Service Header EDMS";
        lVehicle: Record Vehicle;
        UserSetup: Record "User Setup";
        afficherPiedsPage: Boolean;
        salesInvoiceHeader: Record "Sales Invoice Header";
        Vehicule: Record Vehicle;

}

