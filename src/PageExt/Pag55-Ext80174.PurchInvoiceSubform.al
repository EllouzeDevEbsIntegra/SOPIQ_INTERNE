pageextension 80174 "Purch. Invoice Subform" extends "Purch. Invoice Subform"//55
{
    layout
    {
        addafter("VAT Prod. Posting Group")
        {
            field("Gen. Prod. Posting Group92415"; "Gen. Prod. Posting Group")
            {
                ApplicationArea = All;
            }
        }
    }
}