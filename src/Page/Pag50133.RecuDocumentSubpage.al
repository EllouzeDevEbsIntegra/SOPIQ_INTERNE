page 50133 "Recu Document Subpage"
{
    PageType = ListPart;
    Caption = 'Document à payer';
    SourceTable = "Recu Caisse Document";

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
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                }

                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                }

                field("Document No"; "Document No")
                {
                    ApplicationArea = all;
                }

                field("Total HT"; "Total HT")
                {
                    ApplicationArea = all;
                }

                field("Total Remise"; "Total Remise")
                {
                    ApplicationArea = all;
                }

                field("Total TTC"; "Total TTC")
                {
                    ApplicationArea = all;
                }

                field("Montant Ouvert"; "Montant Ouvert")
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
            action("Add Sales Invoice")
            {
                ApplicationArea = All;
                Caption = 'Ajouter Factures';
                // RunObject = Page "Sales Invoice To Pay";
                // RunPageView = where("Remaining Amount" = filter(> 0));
                trigger OnAction()
                var
                    SalesInvoiceToPay: Page "Sales Invoice To Pay";
                    recSalesInvoice: Record "Sales Invoice Header";
                begin
                    recSalesInvoice.SetFilter("Remaining Amount", '>0');
                    recSalesInvoice.SetRange("Bill-to Customer No.", custNo);
                    SalesInvoiceToPay.SetTableView(recSalesInvoice);
                    SalesInvoiceToPay.setRecuCaisse(rec);
                    SalesInvoiceToPay.RunModal();
                end;
            }

            action("Add BS")
            {
                ApplicationArea = All;
                Caption = 'Ajouter Bon de Sortie';
                // RunObject = Page "Sales Invoice To Pay";
                // RunPageView = where("Remaining Amount" = filter(> 0));
                trigger OnAction()
                var
                    SalesInvoiceToPay: Page "Liste archive Bon de sortie";
                    recSalesInvoice: Record "Entete archive BS";
                begin
                    recSalesInvoice.SetRange("Bill-to Customer No.", custNo);
                    SalesInvoiceToPay.SetTableView(recSalesInvoice);
                    SalesInvoiceToPay.setRecuCaisse(rec);
                    SalesInvoiceToPay.RunModal();
                end;
            }
        }
    }

    var
        custNo: code[20];

    procedure setFilter(recuCaisse: Record "Recu Caisse")
    begin
        SetFilter("No Recu", recuCaisse.No);
        SetFilter("Customer No", recuCaisse."Customer No");
        CurrPage.Update();
        custNo := recuCaisse."Customer No";
    end;


}