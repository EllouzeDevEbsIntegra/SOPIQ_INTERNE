pageextension 80417 "Sales Quotes" extends "Sales Quotes"//9300
{
    layout
    {

        // Add changes to page layout here
        addafter("Document Profile")
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