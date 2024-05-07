query 25006652 ServLabor
{

    Caption = 'Service Labor';
    elements
    {
        dataitem(ServLaborAllocApplication; "Serv. Labor Alloc. Application")
        {
            column(Document_No_; "Document No.")
            {

            }
            column(Document_Line_No_; "Document Line No.")
            {

            }
            column(Resource_No_; "Resource No.")
            {

            }
            column(Date; Date)
            {

            }
            column(Finished_Quantity__Hours_; "Finished Quantity (Hours)")
            {

            }
            column(Document_Type; "Document Type")
            {

            }
            dataitem(Resources; Resource)
            {
                DataItemLink = "No." = ServLaborAllocApplication."Resource No.";
                column(Name; Name)
                {

                }
                column(Picture; Image)
                {

                }
            }
        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}