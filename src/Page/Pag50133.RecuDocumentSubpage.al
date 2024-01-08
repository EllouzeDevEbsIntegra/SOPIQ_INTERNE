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
                    // Visible = false;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    //Visible = false;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    //Editable = false;
                    trigger OnValidate()
                    begin
                        "Customer No" := custNo;
                    end;

                }

                field("Customer No"; "Customer No")
                {
                    ApplicationArea = all;
                    Editable = false;
                }

                field("Document No"; "Document No")
                {
                    ApplicationArea = all;
                    //Editable = false;                 
                    TableRelation = if (type = const(Invoice)) "Sales Invoice Header" where("Bill-to Customer No." = field("Customer No"))
                    else
                    if (type = const(BS)) "Entete archive BS" where("Bill-to Customer No." = field("Customer No"))
                    else
                    if (type = const(CreditMemo)) "Sales Cr.Memo Header" where("Bill-to Customer No." = field("Customer No"));


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
                    SalesInvoiceToPay: Page "Bon Sortie Archive To Pay";
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