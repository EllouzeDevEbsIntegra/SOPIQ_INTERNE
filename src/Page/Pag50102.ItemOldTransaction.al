page 50102 "Item Old Transaction"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Item Old Transaction";
    Caption = 'Mouvement articles 2020-2021';
    ModifyAllowed = false;
    DeleteAllowed = false;
    InsertAllowed = false;


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Document N°"; "Document N°")
                {
                    Caption = 'N° Document';
                    Editable = false;
                }

                field("Document Type"; "Document Type")
                {
                    Caption = 'Type';
                    Editable = false;
                }

                field("Is Output"; "Is Output")
                {
                    Caption = 'Sortie';
                    Editable = false;
                }

                field("Is Input"; "Is Input")
                {
                    Caption = 'Entré';
                    Editable = false;
                }

                field("Tier N°"; "Tier N°")
                {
                    Caption = 'N° Tier';
                    Editable = false;
                }

                field("Tier Name"; "Tier Name")
                {
                    Caption = 'Nom Tier';
                    Editable = false;
                }

                field("Document date"; "Document date")
                {
                    Caption = 'Date';
                    Editable = false;
                }

                field("Year"; "Year")
                {
                    Caption = 'Année';
                    Editable = false;
                }

                field("Item N°"; "Item N°")
                {
                    Caption = 'Réf Article';
                    Editable = false;
                }

                field("Item Description"; "Item Description")
                {
                    Caption = 'Désignation article';
                    Editable = false;
                }

                field("Sales Qty"; "Sales Qty")
                {
                    Caption = 'Qté sortie';
                    Editable = false;
                }

                field("Purshase Qty"; "Purshase Qty")
                {
                    Caption = 'Qté entrée';
                    Editable = false;
                }

                field("Unit Price HT"; "Unit Price HT")
                {
                    Caption = 'PU H.T';
                    Editable = false;
                }

                field("Discount Percent"; "Discount Percent")
                {
                    Caption = 'Remise (%)';
                    Editable = false;
                }

                field("Amount HT"; "Amount HT")
                {
                    Caption = 'Net H.T';
                    Editable = false;
                }

                field("VAT Tax Amount"; "VAT Tax Amount")
                {
                    Caption = 'Montant TVA';
                    Editable = false;
                }

                field("Total Line HT"; "Total Line HT")
                {
                    Caption = 'Total NET H.T';
                    Editable = false;
                }

                field("Total Line TTC"; "Total Line TTC")
                {
                    Caption = 'Total NET TTC';
                    Editable = false;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    var
        myInt: Integer;
}