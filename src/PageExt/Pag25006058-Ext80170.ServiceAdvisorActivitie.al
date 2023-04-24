pageextension 80170 "Service Advisor Activitie" extends "Service Advisor Activities" //25006058
{
    layout
    {
        // Add changes to page layout here
        addafter(ServiceQuotes)
        {
            cuegroup("Labor Total")
            {
                Caption = 'CA Main d''œuvre';
                field("CA MO"; "CA MO")
                {
                    Caption = 'Total CA MO';
                    ApplicationArea = all;
                    Editable = true;
                }
                field("CA MO SRV RAPID"; "CA MO SRV RAPIDE")
                {
                    Caption = 'Total CA SRV RAPIDE';
                    ApplicationArea = all;
                    Editable = true;
                }
                field("CA MO SRV MECA"; "CA MO SRV MECA")
                {
                    Caption = 'Total CA SRV MECANIQUE';
                    ApplicationArea = all;
                    Editable = true;
                }

                field("CA MO SRV ELECT"; "CA MO SRV ELECT")
                {
                    Caption = 'Total CA SRV ELECTRIQUE';
                    ApplicationArea = all;
                    Editable = true;
                }

                field("CA MO SRV CARR"; "CA MO SRV CARR")
                {
                    Caption = 'Total CA SRV CARROSSERIE';
                    ApplicationArea = all;
                    Editable = true;
                }

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