pageextension 80508 "Vendor By Manufacturer" extends "Vendor By Manufacturer" //50042
{
    layout
    {
        // Add changes to page layout here
        addbefore("Default Vendor")
        {
            field(fabricant; fabricant)
            {
                Caption = 'Fabricant';
                ApplicationArea = all;

            }
            field("Vendor No Format"; "Vendor No Format")
            {
                Caption = 'Format Référence Furnisseur';
                ApplicationArea = all;
                trigger OnValidate()
                begin
                    // @@@@@@@@ TO VERIFY
                end;
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