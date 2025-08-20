page 25006851 "Sales Invoice API"
{
    Caption = 'salesInvoices';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesInvoiceAPI';
    EntitySetName = 'salesInvoicesAPI';
    ODataKeyFields = "No.";
    PageType = API;
    SourceTable = "Sales Invoice Header";
    DelayedInsert = true;
    ModifyAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                    Editable = false;
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalDocumentNumber', Locked = true;
                    Editable = false;

                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        DocumentDateVar := "Document Date";
                        DocumentDateSet := true;
                    end;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;

                    trigger OnValidate()
                    begin
                        DueDateVar := "Due Date";
                        DueDateSet := true;
                    end;
                }
                field(customerPurchaseOrderReference; "Your Reference")
                {
                    ApplicationArea = All;
                    Caption = 'customerPurchaseOrderReference', Locked = true;
                    Editable = false;
                }
                field(donneurOrdreNo; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNumber', Locked = true;
                    Editable = false;

                }
                field(donneurOrdreName; "Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'customerName', Locked = true;
                    Editable = false;
                }
                field(billToCustomerNo; "Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'billToCustomerNumber', Locked = true;
                    Editable = false;
                }
                field(billToCustomerName; "Bill-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'billToCustomerName', Locked = true;
                    Editable = false;

                }
                field(billToCustomerAdress; "Bill-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'billToAddress', Locked = true;
                    Editable = false;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;
                }
                field(orderNumber; "Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'orderNumber', Locked = true;
                    Editable = false;
                }
                field(salesperson; "Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'salesperson', Locked = true;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;
                    Editable = false;
                }
                part(salesInvoiceLines; "Sales Invoice Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'salesInvoiceLine';
                    EntitySetName = 'salesInvoiceLines';
                    SubPageLink = "Document Id" = FIELD(Id);
                }
                part(pdfDocument; "PDF Document Entity")
                {
                    ApplicationArea = All;
                    Caption = 'PDF Document', Locked = true;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = FIELD(Id);
                }
                field(discountAmount; "Invoice Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'discountAmount', Locked = true;
                }

                field(totalAmountExcludingTax; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountExcludingTax', Locked = true;
                    Editable = false;
                }

                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;
                    Editable = false;
                }
                field(phoneNumber; "Sell-to Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'PhoneNumber', Locked = true;
                }
                field(email; "Sell-to E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'Email', Locked = true;

                }
                field(RemainingAmount; "Remaining Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Remaining Amount', Locked = true;
                    Editable = false;
                }
                field(feedback; feedback)
                {
                    ApplicationArea = All;
                    Caption = 'Feedback', Locked = true;
                    ToolTip = 'Specifies whether the invoice has feedback.';

                }
                field(MontantRecuCaisse; "Montant reçu caisse")
                {
                    ApplicationArea = All;
                    Caption = 'Montant reçu caisse', Locked = true;
                    ToolTip = 'Specifies the amount received in cash.';
                    Editable = false;

                }
                field(DocumentProfile; "Document Profile")
                {
                    ApplicationArea = All;
                    Caption = 'Document Profile', Locked = true;
                    ToolTip = 'Specifies the document profile for the invoice.';

                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
    end;

    trigger OnModifyRecord(): Boolean
    var
    begin

    end;


    var
        SISalesCodeUnit: Codeunit SISalesCodeUnit;
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        TempFieldBuffer: Record "Field Buffer" temporary;
        Customer: Record Customer;
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        BillingPostalAddressJSONText: Text;
        BillingPostalAddressSet: Boolean;
        CustomerNotProvidedErr: Label 'A customerNumber or a customerId must be provided.', Locked = true;
        CustomerValuesDontMatchErr: Label 'The customer values do not match to a specific Customer.', Locked = true;
        CouldNotFindCustomerErr: Label 'The customer cannot be found.', Locked = true;
        ContactIdHasToHaveValueErr: Label 'Contact Id must have a value set.', Locked = true;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        BlankGUID: Guid;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        DocumentDateSet: Boolean;
        DocumentDateVar: Date;
        DueDateSet: Boolean;
        DueDateVar: Date;
        PostedInvoiceActionErr: Label 'The action can be applied to a posted invoice only.', Locked = true;
        DraftInvoiceActionErr: Label 'The action can be applied to a draft invoice only.', Locked = true;
        CannotFindInvoiceErr: Label 'The invoice cannot be found.', Locked = true;
        CancelingInvoiceFailedCreditMemoCreatedAndPostedErr: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted.', Locked = true;
        CancelingInvoiceFailedCreditMemoCreatedButNotPostedErr: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted.', Locked = true;
        CancelingInvoiceFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.', Locked = true;
        EmptyEmailErr: Label 'The send-to email is empty. Specify email either for the customer or for the invoice in email preview.', Locked = true;
        AlreadyCanceledErr: Label 'The invoice cannot be canceled because it has already been canceled.', Locked = true;
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.', Locked = true;
        HasWritePermissionForDraft: Boolean;





}