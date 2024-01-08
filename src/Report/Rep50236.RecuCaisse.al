report 50236 "Recu Caisse"
{
    RDLCLayout = './src/report/RDLC/recuCaisse.rdl';
    Caption = 'Reçu de caisse';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = ALL;

    dataset
    {
        dataitem("Recu Caisse"; "Recu Caisse")
        {
            // DataItemTableView = where("Internal Bill-to Customer" = const(false));
            RequestFilterFields = No;


            column(recuNo; "No")
            {

            }
            column(Date_Time; dateTime)
            {

            }
            column(dateRecu; dateRecu)
            {

            }
            column(user; user)
            {

            }
            column(Customer_No; "Customer No")
            {

            }
            column(custName; custName)
            {

            }

            column(LibelleTicket; LibelleTicket)
            {

            }

            column(LibellePaiement; LibellePaiement)
            {

            }

            dataitem("Recu Caisse Document"; "Recu Caisse Document")
            {
                // DataItemTableView = where("Small Parts" = const(false));
                DataItemLink = "No Recu" = FIELD("No");


                column(NoRecu; "No Recu")
                {

                }

                column(Document_No; "Document No")
                {

                }



                trigger OnAfterGetRecord()
                begin

                end;
            }

            dataitem("Recu Caisse Paiement"; "Recu Caisse Paiement")
            {
                DataItemTableView = where(type = filter('<>0'));
                DataItemLink = "No Recu" = FIELD("No");

                column(No_Recu; "No Recu")
                {

                }

                column(Paiment_No; "Paiment No")
                {

                }
                column(Name; Name)
                {

                }

                column(type; type)
                {

                }
                column(Montant; Montant)
                {

                }
                column(Montant_Calcul; "Montant Calcul")
                {

                }
                column(banque; banque)
                {

                }
                column(Echeance; Echeance)
                {

                }

                trigger OnAfterGetRecord()
                begin

                end;
            }
            /* dataitem(DataItem18; 50046)
             {
                 DataItemLink = Posted invoice No.=FIELD(No.);
                 column(Description_Multiplepaymentmethod; "Multiple payment method".Description)
                 {
                 }
                 column(Amount_Multiplepaymentmethod; "Multiple payment method".Amount)
                 {
                 }
                 column(Dateofpayment_Multiplepaymentmethod; "Multiple payment method"."Date of payment")
                 {
                 }
             }*/
            // dataitem(DataItem1000000041; 2000000026)
            // {
            //     DataItemTableView = SORTING(Number)
            //                         ORDER(Ascending);
            //     column(Number; Number + increment)
            //     {
            //     }

            //     trigger OnPreDataItem()
            //     begin
            //         SETRANGE(Number, 1, 22 - (increment MOD 22));
            //     end;
            // }

            trigger OnAfterGetRecord()
            var
                char13, char10 : char;
                libelleNoPaiement: text;
            begin
                char10 := 10;
                char13 := 13;
                Clear(recRecuCaisseLigne);
                LibelleTicket := '';
                LibellePaiement := '';
                recRecuCaisseLigne.SetRange("No Recu", "Recu Caisse".No);
                if recRecuCaisseLigne.FindSet() then begin
                    repeat
                        if (LibelleTicket = '') then
                            LibelleTicket := recRecuCaisseLigne."Document No"
                        else
                            LibelleTicket := LibelleTicket + ' / ' + recRecuCaisseLigne."Document No";
                    until recRecuCaisseLigne.Next() = 0;
                end;

                recRecuPaiement.SetRange("No Recu", "Recu Caisse".No);
                if recRecuPaiement.FindSet() then begin
                    repeat
                        if (recRecuPaiement."Paiment No" <> '') then libelleNoPaiement := 'N°';
                        if (LibellePaiement = '') then
                            LibellePaiement := '* ' + Format(recRecuPaiement.type) + ' ' + Format(recRecuPaiement.banque) + ' ' + libelleNoPaiement + Format(recRecuPaiement."Paiment No") + ' ' + Format(recRecuPaiement.Montant, 0, '<Precision,3:3><Standard Format,3>') + ' ' + Format(recRecuPaiement.Echeance) + ' ' + Format(recRecuPaiement.Name)
                        else
                            LibellePaiement := LibellePaiement + FORMAT(char13) + FORMAT(char10) + '* ' + Format(recRecuPaiement.type) + ' ' + Format(recRecuPaiement.banque) + ' ' + libelleNoPaiement + Format(recRecuPaiement."Paiment No") + ' ' + Format(recRecuPaiement.Montant, 0, '<Precision,3:3><Standard Format,3>') + ' ' + Format(recRecuPaiement.Echeance) + ' ' + Format(recRecuPaiement.Name);
                    until recRecuPaiement.Next() = 0;
                end;

            end;
        }
    }

    requestpage
    {

        layout
        {
            area(Content)
            {

            }
        }

        actions
        {
        }
    }

    labels
    {
    }
    trigger OnInitReport()
    begin
        LibelleTicket := '';
        LibellePaiement := '';
    end;

    trigger OnPostReport()
    var
        recCaisse: Record "Recu Caisse";
    begin
        recCaisse.setPrinted("Recu Caisse");
    end;

    var
        LibelleTicket, LibellePaiement : text;
        recRecuCaisseLigne: Record "Recu Caisse Document";
        recRecuPaiement: Record "Recu Caisse Paiement";

}

