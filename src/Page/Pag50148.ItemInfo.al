page 50148 "Item Info"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Item;

    layout
    {
        area(Content)
        {
            group(item)
            {
                Caption = 'Article';
                field(No; "No.")
                {
                    ApplicationArea = All;
                    Editable = false;

                }
                field(Description; Description)
                {
                    ApplicationArea = all;
                    Editable = false;
                }
            }
            part(ItemPicture; "Item Picture")
            {
                ApplicationArea = All;
                Caption = 'Image';
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Variant Filter" = FIELD("Variant Filter");
            }
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                Caption = 'Attributs Article';
                ApplicationArea = Basic, Suite;
            }
        }
        area(factboxes)
        {

            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Fichiers Joints';
                SubPageLink = "Table ID" = CONST(27),
                              "No." = FIELD("No.");
            }

        }
    }

    actions
    {

    }

    var
        myInt: Integer;
}