pageextension 80505 "Posted Purch. Invoice Subform" extends "Posted Purch. Invoice Subform" //139
{
    layout
    {
        // Add changes to page layout here
        addafter("Total Amount Incl. VAT")
        {
            field(TimbreFiscal; TimbreFiscal)
            {
                ApplicationArea = all;
                Caption = 'Timbre Fiscal';
            }
            field(NetAPayer; NetAPayer)
            {
                ApplicationArea = all;
                Caption = 'Net à payer';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        NetAPayer, TimbreFiscal : Decimal;
        PurchInvHeader: Record "Purch. Inv. Header";
        VATAmount: Decimal;


    trigger OnOpenPage()
    begin

    end;

    trigger OnAfterGetCurrRecord()
    begin
        PurchInvHeader.Reset();
        if PurchInvHeader.get("Document No.") then begin
            PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
            NetAPayer := PurchInvHeader."Amount Including VAT" + PurchInvHeader."STStamp Fiscal Amount";
            TimbreFiscal := PurchInvHeader."STStamp Fiscal Amount";
        end;
    end;
}