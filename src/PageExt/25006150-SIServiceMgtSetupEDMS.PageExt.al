pageextension 80150 "Service Mgt. Setup EDMS" extends "Service Mgt. Setup EDMS" //25006150
{
    layout
    {
        addafter(ControlMechanicTimeEntry)
        {
            field("Begin Pack"; "Begin Pack")
            {
                ApplicationArea = All;
            }
            field("End Pack"; "End Pack")
            {
                ApplicationArea = All;
            }
        }
    }
}
