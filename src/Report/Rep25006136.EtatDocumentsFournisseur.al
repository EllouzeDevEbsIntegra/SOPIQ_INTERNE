report 25006136 "Etat Documents Fournisseur"
{


    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/etatDocFrs.rdl';
    Caption = 'Etat  Documents Fournisseur';


    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            column(VendorNo; "No.")
            {

            }
            column(companyName; COMPANYPROPERTY.DisplayName)
            {

            }

            column(VendorName; Name)
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
            column(dateDebut; dateDebut)
            {

            }
            column(dateFin; dateFin)
            {

            }
            column(includeRecpt; includeRecpt)
            {

            }
            column(includeReturn; includeReturn)
            {

            }

            dataitem(listeRcpt; "Purch. Rcpt. Header")
            {
                DataItemLink = "Buy-from Vendor No." = field("No.");
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Vendor Shipment No.", "Montant Ouvert";

                column(recptNo; "No.")
                {

                }
                column(recptDate; "Posting Date")
                {

                }
                column(recptVendorName; "Buy-from Vendor Name")
                {

                }
                column(recptVendorOrderNo_; "Vendor Order No.")
                {

                }
                column(recptVendorShipNo; "Vendor Shipment No.")
                {

                }
                column(recptOrderNo; "Order No.")
                {

                }
                column(recptTotalHT; "Total HT")
                {
                }
                column(recptTotalTTC; "Total TTC")
                {
                }
                column(recptMontantOuvert; "Montant Ouvert")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Montant Ouvert", "Total HT", "Total TTC");
                end;

                trigger OnPreDataItem()
                begin
                    if not (includeRecpt) then CurrReport.Break();
                    listeRcpt.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                end;
            }
            dataitem(listeRetour; "Purchase Header")
            {
                DataItemLink = "Buy-from Vendor No." = field("No.");
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Vendor Cr. Memo No.";

                column(returnNo; "No.")
                {

                }
                column(returnDate; "Posting Date")
                {

                }
                column(returnVendorName; "Buy-from Vendor Name")
                {

                }
                column(returnVendorOrderNo_; "Vendor Order No.")
                {

                }
                column(returnVendorNo; "Vendor Cr. Memo No.")
                {

                }
                column(returnTotalHT; Amount)
                {

                }
                column(returnTotalTTC; "Amount Including VAT")
                {

                }
                column(Completely_Received; "Completely Received")
                {

                }



                trigger OnAfterGetRecord()
                begin
                    CalcFields(Amount, "Amount Including VAT");
                end;

                trigger OnPreDataItem()
                begin
                    if not (includeReturn) then CurrReport.Break();
                    listeRetour.SetFilter("Posting Date", '%1..%2', dateDebut, dateFin);
                    listeRetour.SetRange("Document Type", listeRetour."Document Type"::"Return Order");
                    listeRetour.SetRange("Completely Received", true);

                end;
            }


            trigger OnPreDataItem()
            begin
                if (dateDebut = 0D) OR (dateFin = 0D)
                then
                    error('Merci de renseigner la date début et fin')
                else
                    if (dateDebut > dateFin)
                    then
                        error('Date début ne peut pas être supérieur à la date fin');

                if (includeRecpt = false) AND (includeReturn = false) then
                    Error('Vous devez choisir au minimum un type de document à afficher !');

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
                    field(includeRecpt; includeRecpt)
                    {
                        Caption = 'Inclure Réception Achat';
                        ApplicationArea = Basic, Suite;
                    }
                    field(includeReturn; includeReturn)
                    {
                        Caption = 'Inclure Retour Achat';
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
        includeRecpt, includeReturn : Boolean;
        RecCompany: Record "Company Information";
}
