pageextension 80478 "Liste bon de sortie" extends "Liste bon de sortie" //50012
{
    layout
    {
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