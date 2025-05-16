page 25006835 "Recu Caisse API"
{
    Caption = 'Recu Caisse API';
    PageType = API;
    SourceTable = "Recu Caisse";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaisseAPI';
    EntitySetName = 'recuCaisseAPI';
    DelayedInsert = true;
    ODataKeyFields = "No";

    layout
    {
        area(Content)
        {
            group("Reçu de Caisse")
            {
                field(No; No) { Caption = 'N° Reçu'; }
                field(CustomerNo; "Customer No")
                {
                    Caption = 'Client';
                    trigger OnValidate()
                    var
                        recSalesSetup: Record "Sales & Receivables Setup";
                        recSeries: Record "No. Series Line";
                        recCust: Record Customer;
                        serieNoMgt: Codeunit NoSeriesManagement;
                        recuDocument: Record "Recu Caisse Document";
                        recuPaiment: Record "Recu Caisse Paiement";

                    begin
                        if (xRec."Customer No" = '') then begin
                            recSalesSetup.Get;
                            rec.dateTime := System.CurrentDateTime;
                            rec.dateRecu := System.Today;
                            rec.No := serieNoMgt.GetNextNo(recSalesSetup."Reçu Caisse Serie", dateRecu, true);


                        end
                        else
                            if (xRec."Customer No" <> rec."Customer No") then begin
                                recuDocument.Reset();
                                recuDocument.SetRange("No Recu", rec.No);
                                if recuDocument.FindSet() then begin
                                    repeat
                                        recuDocument.Delete();
                                    until recuDocument.Next() = 0;
                                end;

                                recuPaiment.Reset();
                                recuPaiment.SetRange("No Recu", rec.No);
                                if recuPaiment.FindSet() then begin
                                    repeat
                                        recuPaiment.Delete();
                                    until recuPaiment.Next() = 0;
                                end;

                            end;


                        recCust.Reset();
                        if recCust.get("Customer No") then rec.custName := recCust.Name;


                    end;
                }
                field(custName; custName) { Caption = 'Nom Client'; }
                field(dateTime; dateTime) { Caption = 'Date et Heure'; }
                field(dateRecu; dateRecu) { Caption = 'Date Reçu'; }
                field(user; user) { Caption = 'Code Vendeur'; }
                field(isAcompte; isAcompte) { Caption = 'Acompte ?'; }
                field(Printed; Printed) { Caption = 'Imprimé'; }
                field(totalReg; "totalRéglement") { Caption = 'Total Règlement'; }
                field(totalDoc; totalDocToPay) { Caption = 'Total Document à Payer'; }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        rec.CalcFields("totalRéglement", totalDocToPay);
    end;
}
