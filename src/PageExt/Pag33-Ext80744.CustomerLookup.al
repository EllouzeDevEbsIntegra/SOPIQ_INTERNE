pageextension 80744 "Customer Lookup" extends "Customer Lookup" //33

{
    layout
    {
        // Add changes to page layout here
        addafter("Name")
        {
            field("Nom 2"; "Name 2")
            {
                ToolTip = 'Specifies the second name of the customer.';
                Importance = Promoted;
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