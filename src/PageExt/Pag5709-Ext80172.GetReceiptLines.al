pageextension 80172 "Get Receipt Lines" extends "Get Receipt Lines"//5709
{
    layout
    {
        addafter("Buy-from Vendor No.")
        {
            field("N° Doc Frs"; NoDocFrs)
            {
                ApplicationArea = All;
                Caption = 'N° Doc Frs';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    var
        RecptHeader: Record "Purch. Rcpt. Header";

    begin
        RecptHeader.SetRange("No.", rec."Document No.");
        if RecptHeader."Vendor Shipment No." <> '' then
            NoDocFrs := RecptHeader."Vendor Shipment No."
        else
            if RecptHeader."Vendor Order No." <> '' then NodocFrs := RecptHeader."Vendor Order No.";

    end;

    var
        NoDocFrs: Text[50];
}