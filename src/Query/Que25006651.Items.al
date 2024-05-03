query 25006651 Items
{
    Caption = 'Items';


    elements
    {
        dataitem(Item; Item)
        {
            column(No_; "No.")
            {

            }
            column(Manufacturer_Code; "Manufacturer Code")
            {

            }
            column(Manufacturer_Name; "Manufacturer Name")
            {

            }
            column("Reference_Origine_Lié"; "Reference Origine Lié")
            {

            }
            column(Make_Code; "Make Code")
            {

            }
            column(Small_Parts; "Small Parts")
            {

            }
            column(Groupe; Groupe)
            {

            }
            column(Sous_Groupe; "Sous Groupe")
            {

            }
            column(Gen__Prod__Posting_Group; "Gen. Prod. Posting Group")
            {

            }
            column(VAT_Prod__Posting_Group; "VAT Prod. Posting Group")
            {

            }
            column(Inventory_Posting_Group; "Inventory Posting Group")
            {

            }



        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}