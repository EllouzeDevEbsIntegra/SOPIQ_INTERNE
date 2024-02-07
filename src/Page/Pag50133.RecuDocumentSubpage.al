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
                    ValuesAllowed =;
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
                    Visible = false;
                }

                field("Document No"; "Document No")
                {
                    ApplicationArea = all;
                    Editable = NOT (isDivers);
                    //Visible = NOT (libelleVisible);
                    TableRelation = if (type = const(Invoice)) "Sales Invoice Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(BS)) "Entete archive BS" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(CreditMemo)) "Sales Cr.Memo Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(RetourBS)) "Return Receipt Header" where("Bill-to Customer No." = field("Customer No"), BS = filter('Oui'), solde = filter('Non'))
                    else
                    if (type = const(BL)) "Sales Shipment Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'))
                    else
                    if (type = const(RetourBL)) "Return Receipt Header" where("Bill-to Customer No." = field("Customer No"), solde = filter('Non'));

                    trigger OnValidate()

                    var
                        recBs: Record "Entete archive BS";
                        recInvoice: Record "Sales Invoice Header";
                        recCrMemo: Record "Sales Cr.Memo Header";
                        recRetourBS: Record "Return Receipt Header";
                        recBL: Record "Sales Shipment Header";
                        recRetourBL: Record "Return Receipt Header";

                    begin

                        if (rec."Document No" <> xrec."Document No") then begin
                            "Montant Reglement" := 0;
                            "Total TTC" := 0;
                            Modify(true);
                            case rec.type of
                                type::BS:
                                    begin
                                        recBs.SetRange("No.", "Document No");

                                        if recBs.FindFirst() then begin
                                            recBs.CalcFields("Montant reçu caisse", "Montant TTC");
                                            "Montant Reglement" := recBs."Montant TTC" - recBs."Montant reçu caisse";
                                            "Total TTC" := recBs."Montant TTC";
                                            Modify(true);
                                        end;
                                    end;
                                type::Invoice:
                                    begin
                                        recInvoice.SetRange("No.", "Document No");
                                        if recInvoice.FindFirst() then begin
                                            recInvoice.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                            "Montant Reglement" := recInvoice."STStamp Amount" + recInvoice."Amount Including VAT" - recInvoice."Montant reçu caisse";
                                            "Total TTC" := recInvoice."Amount Including VAT" + recInvoice."STStamp Amount";
                                            Modify(true);
                                        end
                                    end;
                                type::RetourBS:
                                    begin
                                        recRetourBS.SetRange("No.", "Document No");
                                        if recRetourBS.FindFirst() then begin
                                            recRetourBS.CalcFields("Line Amount HT", "Line Amount", "Montant reçu caisse");
                                            "Montant Reglement" := -recRetourBS."Line Amount";
                                            "Total TTC" := -recRetourBS."Line Amount";
                                            Modify(true);
                                        end
                                    end;
                                type::CreditMemo:
                                    begin

                                        recCrMemo.SetRange("No.", "Document No");
                                        if recCrMemo.FindFirst() then begin
                                            recCrMemo.CalcFields("Amount Including VAT", "Montant reçu caisse");
                                            "Montant Reglement" := -recCrMemo."Amount Including VAT";
                                            "Total TTC" := -recCrMemo."Amount Including VAT";
                                            Modify(true);
                                        end;
                                    end;
                                type::BL:
                                    begin
                                        recBL.SetRange("No.", "Document No");
                                        if recBL.FindFirst() then begin
                                            recBL.CalcFields("Total line amount", "Line Amount", "Montant reçu caisse");
                                            "Montant Reglement" := recBL."Line Amount" - recBL."Montant reçu caisse";
                                            "Total TTC" := recBL."Line Amount";
                                            Modify(true);
                                        end;
                                    end;
                                type::RetourBL:
                                    begin
                                        recRetourBL.SetRange("No.", "Document No");
                                        if recRetourBL.FindFirst() then begin
                                            recRetourBL.CalcFields("Line Amount", "Montant reçu caisse");
                                            "Montant Reglement" := -recRetourBL."Line Amount";
                                            "Total TTC" := -recRetourBL."Line Amount";
                                        end;

                                    end;
                                else begin

                                end;
                            end;

                        end;
                    end;

                }

                field(Libelle; Libelle)
                {
                    ApplicationArea = all;
                    //Visible = libelleVisible;
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
        custNo: code[20];
        totalDoc: Decimal;
        nbDoc: Integer;
        isDivers: Boolean;

    procedure setFilter(recuCaisse: Record "Recu Caisse")
    var
        cust: Record Customer;
    begin
        SetFilter("No Recu", recuCaisse.No);
        SetFilter("Customer No", recuCaisse."Customer No");
        cust.Reset();
        cust.SetRange("No.", recuCaisse."Customer No");
        if cust.FindFirst() then begin
            isDivers := cust."Is Divers";
        end;
        CurrPage.Update();
        custNo := recuCaisse."Customer No";
    end;

    procedure setDiversCustomer(recuCaisse: Record "Recu Caisse")
    var
        recCust: Record Customer;
    begin
        recCust.Reset();
        recCust.Get(recuCaisse."Customer No");
        if recCust.Find() then begin
            if recCust."Is Divers" = true then begin
                isDivers := true;
                CurrPage.Update();
            end

        end;

    end;

}