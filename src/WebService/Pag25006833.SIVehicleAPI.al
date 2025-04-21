page 25006833 "SI Vehicle  API"
{
    Caption = 'SI Vehicle  API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SIVehicleAPI';
    EntitySetName = 'SIVehicleAPI';
    SourceTable = Vehicle;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    ODataKeyFields = "Serial No.";
    PageType = API;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Vsn; "Serial No.")
                {
                    ApplicationArea = All;
                    Caption = 'SerialNo', Locked = true;
                    ToolTip = 'Specifies the serial number of the vehicle.';
                }
                field(VIN; VIN)
                {
                    ApplicationArea = All;
                    Caption = 'VIN';
                    ToolTip = 'Specifies the VIN of the vehicle.';
                }
                field(RegistrationNo; "Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Registration No.';
                    ToolTip = 'Specifies the registration No of the vehicle.';
                }
                field(FirstRegistrationDate; "First Registration Date")
                {
                    ApplicationArea = All;
                    Caption = 'First Registration Date';
                    ToolTip = 'Specifies the first registration date of the vehicle.';
                }
                field(MakeCode; "Make Code")
                {
                    ApplicationArea = All;
                    Caption = 'Make Code';
                    ToolTip = 'Specifies the make code of the vehicle.';
                }
                field(ModelCode; "Model Code")
                {
                    ApplicationArea = All;
                    Caption = 'Model Code';
                    ToolTip = 'Specifies the model code of the vehicle.';
                }
                field(ModelVersionNo; "Model Version No.")
                {
                    ApplicationArea = All;
                    Caption = 'Model Version No.';
                    ToolTip = 'Specifies the model version No of the vehicle.';
                }
                field(CustomerNo; "Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the customer No of the vehicle.';
                }
            }
        }
    }

    actions
    {
    }

}
