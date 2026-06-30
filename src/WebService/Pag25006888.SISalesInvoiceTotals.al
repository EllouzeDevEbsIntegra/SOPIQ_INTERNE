page 25006888 "SI Sales Invoice Totals"
{
    PageType = List;
    SourceTable = "Sales Invoice Header";
    Caption = 'SI Sales Invoice Totals';
    Editable = false;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(no; Rec."No.")
                {
                    Caption = 'no';
                }
                field(donneurOrdreNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'donneurOrdreNo';
                }
                field(donneurOrdreName; Rec."Sell-to Customer Name")
                {
                    Caption = 'donneurOrdreName';
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'billToCustomerNo';
                }
                field(billToCustomerName; Rec."Bill-to Name")
                {
                    Caption = 'billToCustomerName';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'postingDate';
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'documentDate';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'dueDate';
                }
                field(salesperson; Rec."Salesperson Code")
                {
                    Caption = 'salesperson';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'currencyCode';
                }
                field(documentProfile; Rec."Document Profile")
                {
                    Caption = 'documentProfile';
                }
                field(initiateur; Rec.Initiateur)
                {
                    Caption = 'initiateur';
                }
                field(zoneRecouvrement; Rec."Tax Area Code")
                {
                    Caption = 'zoneRecouvrement';
                }
                field(totalAmountIncludingTax; Rec."Amount Including VAT")
                {
                    Caption = 'totalAmountIncludingTax';
                }
                field(remainingAmount; Rec."Remaining Amount")
                {
                    Caption = 'remainingAmount';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Initiateur);
    end;
}
