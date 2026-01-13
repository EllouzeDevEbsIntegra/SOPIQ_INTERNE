pageextension 80478 "Liste bon de sortie" extends "Liste bon de sortie" //50012
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Nom 2"; "Sell-to Customer Name 2")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the second name of the customer.';
            }
        }
        // Add changes to page layout here
        addafter("No. Printed")
        {
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
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}