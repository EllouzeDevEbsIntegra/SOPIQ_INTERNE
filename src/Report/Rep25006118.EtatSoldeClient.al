report 25006118 "Etat Solde Client"
{


    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/etatSoldeClient.rdl';
    Caption = 'Etat Solde Client';


    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Tax Area Code";

            column(custNo; "No.")
            {

            }
            column(companyName; COMPANYPROPERTY.DisplayName)
            {

            }
            column(CompanyBS; RecCompany.BS)
            {

            }
            column(custName; Name)
            {
            }

            column(Tax_Area_Code; "Tax Area Code")
            {

            }
            column(zone; zone)
            {

            }
            column(Phone_No_; "Phone No.")
            {

            }

            column(Address; Address)
            {

            }

            column(City; City)
            {

            }
            column(includeBL; includeBL)
            {

            }
            column(includeBS; includeBS)
            {

            }
            column(includeFV; includeFV)
            {

            }
            column(includeCV; includeCV)
            {

            }
            column(dateDebut; dateDebut)
            {

            }
            column(dateFin; dateFin)
            {

            }
            column(totalByZone; totalByZone)
            {

            }
            column(showTotalBelow; showTotalBelow)
            {

            }
            column(showDetails; showDetails)
            {

            }
            dataitem(listeCV; "Sales Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = sorting("No.") where("Document Type" = const(Order), "Completely Shipped" = filter(false));
                column(numCV; "No.")
                {

                }
                column(date_CV; "Posting Date")
                {

                }
                column(custImprime_CV; "Bill-to Name")
                {
                }
                column(custCvNo; "Bill-to Customer No.")
                {

                }
                column(soldeCV; mntNonSolde_CV)
                {

                }
                column(mntRecuCaisseCV; Acopmpte)
                {

                }

                column(mntTTC_CV; "Amount Including VAT")
                {

                }


                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_CV := 0;
                    listeCV.CalcFields(Acopmpte, "Amount Including VAT", "Completely Shipped");
                    mntNonSolde_CV := "Amount Including VAT" - Acopmpte;
                end;

                trigger OnPreDataItem()
                begin
                    if not (includeCV) then CurrReport.Break();
                    listeCV.SetFilter("Order Date", '%1..%2', dateDebut, dateFin);
                end;
            }

            dataitem(listeRV; "Sales Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = sorting("No.") where("Document Type" = const("Return Order"), "Completely Shipped" = filter(false));
                column(numRV; "No.")
                {

                }
                column(date_RV; "Posting Date")
                {

                }
                column(custImprime_RV; "Bill-to Name")
                {
                }
                column(custRvNo; "Bill-to Customer No.")
                {

                }
                column(soldeRV; mntNonSolde_RV)
                {

                }
                column(mntRecuCaisseRV; Acopmpte)
                {

                }

                column(mntTTC_RV; "Amount Including VAT")
                {

                }


                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_RV := 0;
                    listeRV.CalcFields(Acopmpte, "Amount Including VAT", "Completely Shipped");
                    mntNonSolde_RV := "Amount Including VAT" - Acopmpte;
                end;

                trigger OnPreDataItem()
                begin
                    if not (includeCV) then CurrReport.Break();
                    listeRV.SetFilter("Order Date", '%1..%2', dateDebut, dateFin);
                end;
            }
            dataitem(listeBonLiv; "Sales Shipment Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = sorting("No.") where("solde" = filter(false), BS = const(false));
                column(numBL; "No.")
                {

                }
                column(date_BL; "Posting Date")
                {

                }
                column(custImprime_BL; custNameImprime)
                {
                }
                column(custBlNo; "Bill-to Customer No.")
                {

                }
                column(soldeBL; mntNonSolde_BL)
                {

                }
                column(mntRecuCaisseBL; "Montant reçu caisse")
                {

                }

                column(mntTTC_BL; "Line Amount")
                {

                }

                column(mntTTC_BL_companyBS; "Montant Ouvert")
                {

                }
                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_BL := 0;
                    listeBonLiv.CalcFields("Montant reçu caisse", "Montant Ouvert", "Line Amount");
                    if RecCompany.BS then
                        mntNonSolde_BL := "Montant Ouvert" - "Montant reçu caisse"
                    else
                        mntNonSolde_BL := "Line Amount" - "Montant reçu caisse"
                end;

                trigger OnPreDataItem()
                begin
                    if not (includeBL) then CurrReport.Break();
                    listeBonLiv.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;
            }

            dataitem(listeRetour_BL; "Return Receipt Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = SORTING("No.") where("solde" = filter(false), "BS" = const(false));
                column(numRetour_BL; "No.")
                {

                }
                column(date_Retour_BL; "Posting Date")
                {

                }
                column(custImprime_Retour_BL; custNameImprime)
                {
                }
                column(custRetour_BL; "Bill-to Customer No.")
                {

                }
                column(soldeRetour_BL; mntNonSolde_RetBL)
                {

                }

                column(mntRecuCaisseRetour_BL; "Montant reçu caisse")
                {

                }

                column(mntTTCRetour_BL; "Line Amount")
                {

                }

                column(mntTTCRetour_BL_companyBS; "Montant Ouvert")
                {

                }

                trigger OnPreDataItem()
                begin
                    if not (includeBL) then CurrReport.Break();
                    listeRetour_BL.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;

                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_RetBL := 0;
                    listeRetour_BL.CalcFields("Montant reçu caisse", "Montant Ouvert", "Line Amount");
                    if RecCompany.BS then
                        mntNonSolde_RetBL := "Montant Ouvert" - "Montant reçu caisse"
                    else
                        mntNonSolde_RetBL := "Line Amount" - "Montant reçu caisse";
                end;
            }

            dataitem(listeRetour_BS; "Return Receipt Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = SORTING("No.") where("solde" = filter(false), "BS" = filter(true));
                column(numRetour_BS; "No.")
                {

                }
                column(date_Retour_BS; "Posting Date")
                {

                }
                column(custImprime_Retour_BS; custNameImprime)
                {
                }
                column(custRetour_BS; "Bill-to Customer No.")
                {

                }
                column(soldeRetour_BS; mntNonSolde_RetBS)
                {

                }
                column(mntRecuCaisseRetour_BS; "Montant reçu caisse")
                {

                }

                column(mntTTCRetour_BS; "Line Amount")
                {

                }

                trigger OnPreDataItem()
                begin
                    if not (includeBS) then CurrReport.Break();
                    listeRetour_BS.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;

                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_RetBS := 0;
                    listeRetour_BS.CalcFields("Montant reçu caisse", "Line Amount");
                    mntNonSolde_RetBS := "Line Amount" - "Montant reçu caisse";
                end;
            }

            dataitem(listeBS; "Entete archive BS")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = SORTING("No.") where("solde" = filter(false));
                column(numBS; "No.")
                {

                }
                column(custImprime_BS; custNameImprime)
                {

                }
                column(date_BS; "Posting Date")
                {

                }
                column(custBsNo; "Bill-to Customer No.")
                {

                }
                column(soldeBS; mntNonSolde_BS)
                {

                }
                column(mntRecuCaisseBS; "Montant reçu caisse")
                {

                }
                column(mntTTC_BS; "Montant TTC")
                {

                }

                trigger OnPreDataItem()
                begin
                    if not (includeBS) then CurrReport.Break();
                    listeBS.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;

                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_BS := 0;
                    listeBS.CalcFields("Montant reçu caisse", "Montant TTC");
                    mntNonSolde_BS := "Montant TTC" - "Montant reçu caisse";
                end;

            }

            dataitem(listeFV; "Sales Invoice Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = SORTING("No.") where("solde" = filter(false));
                column(numFV; "No.")
                {

                }
                column(custImprime_FV; custNameImprime)
                {

                }
                column(date_FV; "Posting Date")
                {

                }
                column(custFVNo; "Bill-to Customer No.")
                {

                }
                column(soldeFV; mntNonSolde_FV)
                {

                }
                column(mntRecuCaisseFV; "Montant reçu caisse")
                {

                }
                column(mntTTC_FV; "Amount Including VAT" + "STStamp Amount")
                {

                }

                trigger OnPreDataItem()
                begin
                    if not (includeFV) then CurrReport.Break();
                    listeFV.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;

                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_FV := 0;
                    listeFV.CalcFields("Amount Including VAT", "Montant reçu caisse");
                    mntNonSolde_FV := "Amount Including VAT" + "STStamp Amount" - "Montant reçu caisse";
                end;
            }

            dataitem(listeAV; "Sales Cr.Memo Header")
            {
                DataItemLink = "Bill-to Customer No." = field("No.");
                DataItemTableView = SORTING("No.") where("solde" = filter(false));
                column(numAV; "No.")
                {

                }
                column(custImprime_AV; custNameImprime)
                {

                }
                column(date_AV; "Posting Date")
                {

                }
                column(custAVNo; "Bill-to Customer No.")
                {

                }
                column(soldeAV; mntNonSolde_AV)
                {

                }
                column(mntRecuCaisseAV; "Montant reçu caisse")
                {

                }
                column(mntTTC_AV; "Amount Including VAT" + "STStamp Amount")
                {

                }

                trigger OnPreDataItem()
                begin
                    if not (includeFV) then CurrReport.Break();
                    listeAV.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;

                trigger OnAfterGetRecord()
                begin
                    mntNonSolde_AV := 0;
                    listeAV.CalcFields("Amount Including VAT", "Montant reçu caisse");
                    mntNonSolde_AV := "Amount Including VAT" + "STStamp Amount" - "Montant reçu caisse";
                end;
            }


            trigger OnAfterGetRecord()
            var
                recZone: Record "Tax Area";
            begin
                recZone.Reset();
                recZone.SetRange(Code, Customer."Tax Area Code");
                if recZone.FindFirst() then zone := recZone.Description else zone := 'Non affecté';

            end;

            trigger OnPreDataItem()
            begin
                if (dateDebut = 0D) OR (dateFin = 0D)
                then
                    error('Merci de renseigner la date début et fin')
                else
                    if (dateDebut > dateFin)
                    then
                        error('Date début ne peut pas être supérieur à la date fin');

                if (includeCV = false) AND (includeBL = false) AND (includeBS = false) AND (includeFV = false) then
                    Error('Vous devez choisir au minimum un type (CV, BL, BS, FV) !');

                if NOT (RecCompany.BS) AND (includeBS = true OR includeFV = true) then
                    Error('Vous n''êtes pas autorisé à utiliser les types (BS/FV) pour état de solde clients !');
            end;

        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = '';
                    field(showDetails; showDetails)
                    {
                        Caption = 'Afficher les détails';
                        ApplicationArea = Basic, Suite;
                    }
                    field(dateDebut; dateDebut)
                    {
                        Caption = 'Date Début';
                        ApplicationArea = Basic, Suite;
                    }
                    field(dateFin; dateFin)
                    {
                        Caption = 'Date Fin';
                        ApplicationArea = Basic, Suite;
                    }
                    field(includeCV; includeCV)
                    {
                        Caption = 'Inclure Commande et Reour';
                        ApplicationArea = Basic, Suite;
                    }
                    field(IncludeBL; includeBL)
                    {
                        Caption = 'Inclure BL et Retour BL';
                        ApplicationArea = Basic, Suite;
                    }
                    field(IncludeBS; includeBS)
                    {
                        Caption = 'Inclure BS et Retour BS';
                        ApplicationArea = Basic, Suite;
                    }
                    field(includeFV; includeFV)
                    {
                        Caption = 'Inclure Facture et Avoir';
                        ApplicationArea = Basic, Suite;
                    }

                    field(totalByZone; totalByZone)
                    {
                        Caption = 'Afficher total par zone';
                        ApplicationArea = Basic, Suite;
                    }
                    field(showTotalBelow; showTotalBelow)
                    {
                        Caption = 'Afficher Total Général par client en bas';
                        ApplicationArea = Basic, Suite;
                    }
                }
            }
        }

    }
    trigger OnInitReport()
    begin
        Clear(RecCompany);
        RecCompany.Get();
    end;

    var
        zone: Text;
        mntNonSolde_BL, mntNonSolde_BS, mntNonSolde_RetBL, mntNonSolde_RetBS, mntNonSolde_FV, mntNonSolde_AV, mntNonSolde_CV, mntNonSolde_RV : decimal;
        dateDebut, dateFin : Date;
        includeCV, includeBL, includeBS, includeFV, totalByZone : Boolean;
        RecCompany: Record "Company Information";
        showTotalBelow, showDetails : Boolean;
}
