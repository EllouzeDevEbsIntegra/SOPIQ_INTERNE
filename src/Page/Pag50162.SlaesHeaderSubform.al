page 50162 "Slaes Header Subform"
{
    Caption = 'Commande Vente';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER(Order), "Completely Shipped" = filter(false));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = all;
                    Caption = 'Date';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    Caption = 'N° Document';
                    ToolTip = 'Specifies the number of a general ledger account, item, additional cost, or fixed asset, depending on what you selected in the Type field.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Style = Attention;
                    Caption = 'Total HT';
                }

                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Style = Attention;
                    Caption = 'Total TTC';
                }

            }

        }
    }

}