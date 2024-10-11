report 25006129 "Etat Credit Agence"
{


    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/etatCreditAgence.rdl';
    Caption = 'Etat Crédit Clients';


    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = SORTING("Posting Date");
            RequestFilterFields = Initiateur;
            column(companyName; COMPANYPROPERTY.DisplayName)
            {

            }
            column(dateDebut; dateDebut)
            {

            }
            column(dateFin; dateFin)
            {

            }
            column(No_; "No.")
            {

            }
            column(Bill_to_Customer_No_; "Bill-to Customer No.")
            {

            }
            column(Bill_to_Name; "Bill-to Name")
            {

            }
            column(Sell_to_Customer_Name; "Sell-to Customer Name")
            {

            }
            column(Amount_Including_VAT; "Amount Including VAT" + "STStamp Amount")
            {

            }
            column(Remaining_Amount; "Remaining Amount")
            {

            }
            column("Montant_reçu_caisse"; "Montant reçu caisse")
            {

            }
            column(initiateurName; initiateurName)
            {

            }
            column(Initiateur; Initiateur)
            {

            }
            column(Posting_Date; "Posting Date")
            {

            }



            trigger OnAfterGetRecord()
            var
                SalespersonPurchaser: Record "Salesperson/Purchaser";
                CompanyInformation: Record "Company Information";
            begin
                initiateurName := '';
                CalcFields(Initiateur, "Remaining Amount", "Amount Including VAT", "Montant reçu caisse");
                SalespersonPurchaser.Reset();
                SalespersonPurchaser.SetRange(Code, "Sales Invoice Header".Initiateur);
                if SalespersonPurchaser.FindFirst() then begin
                    initiateurName := SalespersonPurchaser.Name;
                end
                else begin
                    CompanyInformation.Get();
                    if ("Sales Invoice Header"."Bill-to Customer No." = CompanyInformation."Com VN")
                    OR ("Sales Invoice Header"."Bill-to Customer No." = CompanyInformation."Com PDR")
                    OR ("Sales Invoice Header"."Bill-to Customer No." = CompanyInformation.Other)
                    then begin
                        initiateurName := "Sales Invoice Header"."Bill-to Name";
                    end
                    else
                        initiateurName := 'Revendeurs / Non Affectés';
                end;

            end;

            trigger OnPreDataItem()
            begin
                "Sales Invoice Header".SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                "Sales Invoice Header".SetFilter("Remaining Amount", '>0');
                "Sales Invoice Header".SetFilter("Internal Bill-to Customer", '%1', false);
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
        dateDebut, dateFin : Date;
        RecCompany: Record "Company Information";
        showTotalBelow, showDetails : Boolean;
        initiateurName: Text;
}
