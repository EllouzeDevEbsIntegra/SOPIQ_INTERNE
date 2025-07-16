pageextension 80570 "Vehicle Card" extends "Vehicle Card" //25006032
{
    layout
    {
        // Add changes to page layout here
        addbefore(Specification)
        {
            group(Notification)
            {
                Caption = 'Notification';
                field("Date Assurance"; Rec."Date Assurance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the date of the vehicle insurance.';
                }
                field("Periode Assurance"; Rec."Periode Assurance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the period of the vehicle insurance.';
                }
                field("Assurance Compagnie"; Rec."Assurance Compagnie")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the insurance company for the vehicle.';
                }
                field("Date Visite Technique"; Rec."Date Visite Technique")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the date of the technical visit for the vehicle.';
                }
                field("Type Proprietaire"; Rec."Type Proprietaire")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the type of owner for the vehicle.';
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