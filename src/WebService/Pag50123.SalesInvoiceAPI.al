page 50123 "Sales Invoice API"
{
    PageType = API;
    Caption = 'sales Invoices Headers';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salesInvoiceAPI';
    EntitySetName = 'salesInvoices';
    SourceTable = "Sales Invoice Header";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; systemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                    Editable = false;
                }

            }
        }
    }

    actions
    {
    }



}

