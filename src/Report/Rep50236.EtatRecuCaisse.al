report 50236 "Etat Recu Caisse"
{

    RDLCLayout = './src/report/RDLC/etatRecuCaisse.rdl';
    Caption = 'Etat Reçu de caisse';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = ALL;

    dataset
    {
        dataitem("Recu Caisse"; "Recu Caisse")
        {
            // DataItemTableView = where("Internal Bill-to Customer" = const(false));
            RequestFilterFields = dateRecu;

            column(CompanyInfoName; CompanyInfo.Name)
            {
            }
            column(DateFilter; DateFilter)
            {

            }
            column(isACPTOrREG; isACPTOrREG)
            {

            }

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
            column(isAcompte; isAcompte)
            {

            }
            column(TotalDoc; TotalDoc)
            {

            }
            column(TotalReglement; TotalReglement)
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

                column(Montant_Reglement; "Montant Reglement")
                {

                }
                column(typeDoc; type)
                {

                }

                column(Total_TTC; "Total TTC")
                {

                }

                trigger OnAfterGetRecord()
                var
                // char13, char10 : char;
                // isACPTOrREG: Text;
                begin
                    // isACPTOrREG := '';
                    // if ("Recu Caisse".isAcompte = true) then isACPTOrREG := 'ACPT ' else isACPTOrREG := 'REG ';
                    // char10 := 10;
                    // char13 := 13;

                    // TotalDoc := TotalDoc + "Recu Caisse Document"."Montant Reglement";
                    // if (LibelleTicket = '') then
                    //     LibelleTicket := isACPTOrREG + FORMAT(char13) + FORMAT(char10) + '* ' + "Recu Caisse Document"."Document No"
                    // else
                    //     LibelleTicket := LibelleTicket + FORMAT(char13) + FORMAT(char10) + '* ' + "Recu Caisse Document"."Document No";
                end;

                // trigger OnPreDataItem()
                // begin
                //     Message('doc');
                //     LibelleTicket := '';
                //     TotalDoc := 0;
                // end;
            }

            dataitem("Recu Caisse Paiement"; "Recu Caisse Paiement")
            {
                // DataItemTableView = sorting(type);
                DataItemLink = "No Recu" = FIELD("No");
                //RequestFilterFields = type;

                column(No_Recu; "No Recu")
                {

                }

                column(Paiment_No; "Paiment No")
                {

                }
                column(typeReg; type)
                {

                }
                column(typeRegIndex; type.AsInteger())
                {

                }

                column(Montant_Calcul; "Montant Calcul")
                {

                }

                column(Name; Name)
                {

                }

                column(Echeance; Echeance)
                {

                }

                column(banque; banque)
                {

                }

                trigger OnAfterGetRecord()
                var
                // char13, char10 : char;
                // libelleNoPaiement: text;
                begin

                    // Message('Reg index <%1>', "Recu Caisse Paiement".type.AsInteger());
                    // char10 := 10;
                    // char13 := 13;
                    // //Message('%1',"Recu Caisse Paiement".type);
                    // if ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::AvoirEsp)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::Cheque)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::Depense)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::Espece)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::retourBS)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::RS)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::Transport)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::TPE)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::Traite)
                    //     OR ("Recu Caisse Paiement".type = "Recu Caisse Paiement".type::Virement)
                    //     then begin

                    //     TotalReglement := TotalReglement + "Recu Caisse Paiement"."Montant Calcul";
                    //     //Message('%1', TotalReglement);

                    // end;

                    // if ("Recu Caisse Paiement"."Paiment No" <> '') then libelleNoPaiement := 'N°';
                    // if (LibellePaiement = '') then
                    //     LibellePaiement := '* ' + Format("Recu Caisse Paiement".type) + ' ' + Format("Recu Caisse Paiement".banque) + ' ' + libelleNoPaiement + Format("Recu Caisse Paiement"."Paiment No") + ' ' + Format("Recu Caisse Paiement"."Montant Calcul", 0, '<Precision,3:3><Standard Format,0>') + ' ' + Format("Recu Caisse Paiement".Echeance) + ' ' + Format("Recu Caisse Paiement".Name)
                    // else
                    //     LibellePaiement := LibellePaiement + FORMAT(char13) + FORMAT(char10) + '* ' + Format("Recu Caisse Paiement".type) + ' ' + Format("Recu Caisse Paiement".banque) + ' ' + libelleNoPaiement + Format("Recu Caisse Paiement"."Paiment No") + ' ' + Format("Recu Caisse Paiement"."Montant Calcul", 0, '<Precision,3:3><Standard Format,0>') + ' ' + Format("Recu Caisse Paiement".Echeance) + ' ' + Format("Recu Caisse Paiement".Name);

                    //Message('%1', LibellePaiement);

                end;

                // trigger OnPreDataItem()
                // begin
                //     Message('reg');
                //     LibellePaiement := '';
                //     TotalReglement := 0;
                // end;


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
                isACPTOrREG := '';
                if ("Recu Caisse".isAcompte = true) then isACPTOrREG := 'ACOMPTE' else isACPTOrREG := 'REGLEMENT';
                char10 := 10;
                char13 := 13;
                Clear(recRecuCaisseLigne);
                LibelleTicket := '';
                LibellePaiement := '';
                TotalDoc := 0;
                TotalReglement := 0;
                recRecuCaisseLigne.SetRange("No Recu", "Recu Caisse".No);
                if recRecuCaisseLigne.FindSet() then begin
                    repeat
                        TotalDoc := TotalDoc + recRecuCaisseLigne."Montant Reglement";
                        if (LibelleTicket = '') then
                            if recRecuCaisseLigne.type = recRecuCaisseLigne.type::Divers then begin
                                LibelleTicket := '* ' + recRecuCaisseLigne.Libelle + ' / ' + Format(recRecuCaisseLigne."Montant Reglement", 0, '<Precision,3:3><Standard Format,0>')
                            end
                            else
                                if recRecuCaisseLigne.type = recRecuCaisseLigne.type::Acompte then begin
                                    LibelleTicket := '* Acompte Personnel > ' + recRecuCaisseLigne."Document No" + ' / ' + Format(recRecuCaisseLigne."Montant Reglement", 0, '<Precision,3:3><Standard Format,0>')
                                end
                                else begin
                                    LibelleTicket := '* ' + recRecuCaisseLigne."Document No" + ' / ' + Format(recRecuCaisseLigne."Total TTC", 0, '<Precision,3:3><Standard Format,0>')

                                end
                        else begin
                            if recRecuCaisseLigne.type = recRecuCaisseLigne.type::Divers then begin
                                LibelleTicket := LibelleTicket + FORMAT(char13) + FORMAT(char10) + '* ' + recRecuCaisseLigne.Libelle + ' / ' + Format(recRecuCaisseLigne."Montant Reglement", 0, '<Precision,3:3><Standard Format,0>');

                            end
                            else
                                if recRecuCaisseLigne.type = recRecuCaisseLigne.type::Acompte then begin
                                    LibelleTicket := LibelleTicket + FORMAT(char13) + FORMAT(char10) + '* Acompte Personnel > ' + recRecuCaisseLigne."Document No" + ' / ' + Format(recRecuCaisseLigne."Montant Reglement", 0, '<Precision,3:3><Standard Format,0>');

                                end
                                else begin
                                    LibelleTicket := LibelleTicket + FORMAT(char13) + FORMAT(char10) + '* ' + recRecuCaisseLigne."Document No" + ' / ' + Format(recRecuCaisseLigne."Total TTC", 0, '<Precision,3:3><Standard Format,0>');
                                end
                        end;

                    until recRecuCaisseLigne.Next() = 0;
                end;

                recRecuPaiement.SetRange("No Recu", "Recu Caisse".No);
                if recRecuPaiement.FindSet() then begin
                    repeat
                        libelleNoPaiement := '';
                        if (recRecuPaiement.type = recRecuPaiement.type::"AvoirEsp")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"Cheque")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"Depense")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"Espece")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"retourBS")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"RS")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"Transport")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"TPE")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"Traite")
                            OR (recRecuPaiement.type = recRecuPaiement.type::"Virement")
                            then begin

                            TotalReglement := TotalReglement + recRecuPaiement."Montant Calcul";

                        end;

                        if (recRecuPaiement."Paiment No" <> '') then libelleNoPaiement := 'N°';
                        if (LibellePaiement = '') then
                            LibellePaiement := '* ' + Format(recRecuPaiement.type) + ' ' + Format(recRecuPaiement.banque) + ' ' + libelleNoPaiement + Format(recRecuPaiement."Paiment No") + ' ' + Format(recRecuPaiement.Montant, 0, '<Precision,3:3><Standard Format,0>') + ' ' + Format(recRecuPaiement.Echeance) + ' ' + Format(recRecuPaiement.Name)
                        else
                            LibellePaiement := LibellePaiement + FORMAT(char13) + FORMAT(char10) + '* ' + Format(recRecuPaiement.type) + ' ' + Format(recRecuPaiement.banque) + ' ' + libelleNoPaiement + Format(recRecuPaiement."Paiment No") + ' ' + Format(recRecuPaiement.Montant, 0, '<Precision,3:3><Standard Format,0>') + ' ' + Format(recRecuPaiement.Echeance) + ' ' + Format(recRecuPaiement.Name);
                    until recRecuPaiement.Next() = 0;
                end;

            end;

            trigger OnPreDataItem()
            var
                myInt: Integer;
            begin

                DateFilter := GETFILTER(dateRecu);
                if DateFilter = '' then error(DatFilterError);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
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
        TotalDoc := 0;
        TotalReglement := 0;
        CompanyInfo.GET;

    end;

    var
        LibelleTicket, LibellePaiement : text;
        recRecuCaisseLigne: Record "Recu Caisse Document";
        recRecuPaiement: Record "Recu Caisse Paiement";
        TotalDoc, TotalReglement : Decimal;
        CompanyInfo: Record 79;
        DateFilter: text[20];
        DatFilterError: label 'Merci de renseigner la date de filtre';
        isACPTOrREG: Text;





}

