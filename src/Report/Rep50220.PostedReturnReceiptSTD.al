report 50220 "Posted Return Receipt STD"
{
    ApplicationArea = All;
    Caption = 'Posted Return Receipt';

    RDLCLayout = './src/report/RDLC/ReturnReceiptVente.rdl';
    UsageCategory = ReportsAndAnalysis;
    dataset
    {
        dataitem("Return Receipt Header"; "Return Receipt Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Sales Return Order';

            // Afficher Entete et Pied - SOPIQ INTERNE 


            column(afficherPiedsPage; afficherPiedsPage)
            {

            }

            // Fin SOPIQ INTERNE
            column(No_SalesShipmentHeader; "No.")
            {
            }
            column(BilltoCustomerNo_SalesShipmentHeader; "Sell-to Customer No.")
            {
            }
            column(BilltoName_SalesShipmentHeader; "Sell-to Customer Name")
            {
            }
            column(PostingDate_SalesShipmentHeader; "Posting Date")
            {
            }
            column(BilltoAddress_SalesShipmentHeader; "Sell-to Address")
            {
            }
            column(OrderDate_SalesShipmentHeader; "Document Date")
            {
            }


            column(BilltoCity_SalesShipmentHeader; "Sell-to City")
            {
            }
            column(ShiptoName_SalesShipmentHeader; "Ship-to Name")
            {
            }
            column(OrderNo_SalesShipmentHeader; "External Document No.")
            {
            }




            column(TextENLettre; TexteLettre)
            {
            }
            column(SalespersonCode_SalesHeader; Salesperson.Name)
            {
            }
            column(VATRegistrationNo_SalesHeader; "VAT Registration No.")
            {
            }
            column(DescriptionMethodeReglement; PaymentMethod.Description)
            {
            }
            column(VATRegistrationNo_SalesInvoiceHeader; "VAT Registration No.")
            {
            }
            column(ResponsibilityCenter_SalesCrMemoHeader; "Responsibility Center")
            {
            }

            column(CodeTVA; CodeTVA)
            {
            }
            column(PaymentTermsCode_SalesCrHeader; "Payment Terms Code")
            {
            }
            column(OrderDate_SalesCrHeader; "Document Date")
            {
            }
            column(Picture; RecCompany.Picture)
            {
            }
            column(Header; RecCompany."Invoice Header Picture")
            {
            }
            column(Footer; RecCompany."Invoice Footer Picture")
            {
            }
            column(telclient; RecGClient."Phone No.")
            {
            }
            column(faxclient; RecGClient."Telex No.")
            {
            }

            dataitem("Return Receipt Line"; "Return Receipt Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.")
                                    ORDER(Ascending);
                RequestFilterFields = "Document No.";
                column(No_SalesShipmentLine; "No.")
                {
                }
                column(Description_SalesShipmentLine; Description)
                {
                }
                column(RemiseLigne; MontantRemiseLigne)
                {
                }
                column(Line_Discount; "Line Discount %")
                {
                }
                column(Amount; Amount)
                {
                }
                column(Amount_Including_VAT; "Amount Including VAT")
                {
                }
                column(Quantity_SalesShipmentLine; Quantity)
                {
                }
                column(UnitPrice; "Unit Price")
                {
                }
                column(Amount_SalesInvoiceLine; "Unit Price" * Quantity)
                {
                }
                column(VAT_SalesShipmentLine; "VAT %")
                {
                }
                column(VATBaseAmount_SalesShipmentLine; "VAT Base Amount")
                {
                }
                column(VariantCode_SalesShipmentLine; "Variant Code")
                {
                }
                column(UnitofMeasure_SalesCrMemoLine; "Unit of Measure")
                {
                }
                column(increment; increment)
                {
                }
                column(Shipment_Date; "Shipment Date")
                {
                }
                column(MontantLigneTVA; MontantLigneTVA)
                {
                }
                column(MTBaseTVA; MTBaseTVA)
                {
                }
                column(MontantLigne; MontantLigne)
                {

                }

                trigger OnAfterGetRecord()
                begin

                    IF (Type <> Type::"G/L Account") THEN
                        increment := increment + 1;
                    CLEAR(ReturnReceiptLine);
                    MontantLigne := 0;
                    MontantRemiseLigne := 0;
                    MontantLigneTVA := 0;
                    MTBaseTVA := 0;

                    IF Type = Type::Item THEN begin
                        MontantLigne := "Unit Price" * Quantity;
                        MontantRemiseLigne := MontantLigne * ("Line Discount %" / 100);
                        //MontantRemiseLigne := MontantRemiseLigne + ((Amount) * ("Line Discount %" / 100));
                        MTBaseTVA := Amount;
                        //MontantLigneTVA := ROUND((SalesShipLine."VAT %" * SalesShipLine."VAT Base Amount"))/100;
                        MontantLigneTVA := (Amount * ("VAT %" / 100));
                    end;





                end;

                trigger OnPostDataItem()
                begin
                    // message('%1', increment);
                end;
            }
            dataitem(DataItem1000000020; Integer)
            {
                DataItemTableView = SORTING(Number)
                                    ORDER(Ascending);
                column(Number; Number + increment)
                {
                }

                trigger OnPreDataItem()
                begin
                    SETRANGE(Number, 1, Number);
                end;
            }

            trigger OnAfterGetRecord()
            begin


                increment := 0;
                CLEAR(CodeTVA);
                CodeTVA := '';
                IF "VAT Registration No." <> '' THEN
                    CodeTVA := "VAT Registration No."
                ELSE BEGIN
                    IF RecGClient.GET("Bill-to Customer No.") THEN
                        CodeTVA := RecGClient."VAT Registration No."
                    ELSE
                        CodeTVA := '';
                END;

                IF PaymentMethod.GET("Payment Terms Code") THEN;



            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {

            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(afficherPiedsPage; afficherPiedsPage)
                    {
                        ApplicationArea = all;
                        Caption = 'Afficher entête et pied de page';
                    }

                }
            }

        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CLEAR(RecCompany);
        RecCompany.GET;
        RecCompany.CALCFIELDS(RecCompany.Picture);
        RecCompany.CALCFIELDS(RecCompany."Invoice Header Picture");
        RecCompany.CALCFIELDS(RecCompany."Invoice Footer Picture");
        afficherPiedsPage := true;

    end;

    var
        increment: Integer;
        RecGClient: Record Customer;
        CodeTVA: Code[20];
        DisplayLanguage: Code[10];
        ReturnReceiptLine: Record "Return Receipt Line";
        afficherPiedsPage: Boolean;
        TexteLettre: Text[1024];
        MontantLigne: Decimal;
        MontantRemiseLigne: Decimal;
        MontantLigneTVA: Decimal;
        PaymentMethod: Record "Payment Method";
        DescriptionMethodeReglement: Text[50];
        VATAmountLine: Record "VAT Amount Line" temporary;




        RecCompany: Record "Company Information";
        MTBaseTVA: Decimal;
        Salesperson: Record "Salesperson/Purchaser";

}
