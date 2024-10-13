pageextension 80256 "Sales Order List" extends "Sales Order List"//9305
{
    layout
    {
        addafter("Shipping Agent Code")
        {
            field("Shipping Agent Code SI"; "Shipping Agent Code SI")
            {
                Caption = 'Code Transporteur SI';
                ApplicationArea = all;
            }
        }
        // Add changes to page layout here
        addafter("Montant réglement")
        {
            field(Acopmpte; Acopmpte)
            {
                ApplicationArea = all;
                Editable = false;
            }

            field(custNameImprime; custNameImprime)
            {

            }

            field(custAdresseImprime; custAdresseImprime)
            {

            }

            field(custMFImprime; custMFImprime)
            {

            }

            field(custVINImprime; custVINImprime)
            {

            }
        }

        modify("Montant réglement")
        {
            Visible = false;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        rec.CalcFields(Acopmpte);
    end;

}