page 50137 "Recu Document List"
{
    PageType = List;
    Caption = 'Liste docuement paye';
    SourceTable = "Recu Caisse Document";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    layout
    {
        area(content)
        {
            repeater(Group)
            {

                field("No Recu"; "No Recu")
                {
                    ApplicationArea = All;
                    TableRelation = "Recu Caisse";
                    Visible = true;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    Visible = false;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field("Document No"; "Document No")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Total TTC"; "Total TTC")
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field("Montant Reglement"; "Montant Reglement")
                {
                    ApplicationArea = all;
                }

            }

        }
    }

    actions
    {
        area(Processing)
        {

        }
    }

    var



}