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
                    Visible = false;
                }
                field("Line No"; "Line No")
                {
                    ApplicationArea = all;
                    Visible = false;
                }
                field(type; type)
                {
                    ApplicationArea = all;
                    //Editable = false;
                    trigger OnValidate()
                    begin
                        if (type = type::null) then
                            Error('Vous devez spécifier le type de document !') else begin
                            if (rec.type <> xRec.type) then begin
                                "Customer No" := custNo;
                                "Document No" := '';
                                "Montant Reglement" := 0;
                                "Total TTC" := 0;
                            end
                        end;



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

                    TableRelation = if (type = const(Invoice)) "Sales Invoice Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(BS)) "Entete archive BS" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(CreditMemo)) "Sales Cr.Memo Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'));

                    trigger OnValidate()

                    var
                        recBs: Record "Entete archive BS";
                        recInvoice: Record "Sales Invoice Header";
                        recCrMemo: Record "Sales Cr.Memo Header";

                    begin

                        if (rec."Document No" <> xrec."Document No") then begin
                            "Montant Reglement" := 0;
                            "Total TTC" := 0;
                            Modify(true);
                            if (rec.type = type::BS)
                                                     then begin
                                recBs.SetRange("No.", "Document No");

                                if recBs.FindFirst() then begin
                                    recBs.CalcFields("Montant reçu caisse", "Montant TTC");
                                    "Montant Reglement" := recBs."Montant TTC" - recBs."Montant reçu caisse";
                                    "Total TTC" := recBs."Montant TTC";
                                    Modify(true);
                                end;
                            end
                            else
                                if (rec.type = type::Invoice) then begin
                                    recInvoice.SetRange("No.", "Document No");
                                    if recInvoice.FindFirst() then begin
                                        recInvoice.CalcFields("Amount Including VAT");
                                        "Montant Reglement" := recInvoice."STStamp Amount" + recInvoice."Amount Including VAT" - recInvoice."Montant reçu caisse";
                                        "Total TTC" := recInvoice."Amount Including VAT" + recInvoice."STStamp Amount";
                                        Modify(true);
                                    end
                                end
                                else begin
                                    recCrMemo.SetRange("No.", "Document No");
                                    if recCrMemo.FindFirst() then begin
                                        recCrMemo.CalcFields("Amount Including VAT");
                                        "Montant Reglement" := -recCrMemo."Amount Including VAT";
                                        "Total TTC" := -recCrMemo."Amount Including VAT";
                                        Modify(true);
                                    end;
                                end;
                        end;


                    end;

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
                Visible = false;
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
                Visible = false;
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
        totalDoc: Decimal;
        nbDoc: Integer;

    procedure setFilter(recuCaisse: Record "Recu Caisse")
    begin
        SetFilter("No Recu", recuCaisse.No);
        SetFilter("Customer No", recuCaisse."Customer No");
        CurrPage.Update();
        custNo := recuCaisse."Customer No";
    end;



}