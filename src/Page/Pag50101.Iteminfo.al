page 50101 "Item info"  // Afficher l'image et les attributs d'un article
{
    PageType = Card;
    ApplicationArea = all;
    UsageCategory = Administration;
    SourceTable = Item;


    layout
    {
        area(content)
        {
            part(Picture; "Picture FactBox")
            {
                ApplicationArea = Basic, Suite;

            }

            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
            }

        }
    }

    actions
    {
        area(Processing)
        {
            // action(ActionName)
            // {

            // }
        }
    }

    var
        myInt: Integer;

}