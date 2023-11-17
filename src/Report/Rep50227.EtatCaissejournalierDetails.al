report 50227 "Etat Caisse journalier Details"
{
    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Etat de caisse journalier Détaillé';
    ApplicationArea = All;
    RDLCLayout = './src/report/RDLC/EtatCaisseJournalierDetaille.rdl';
    dataset
    {
        dataitem(PaymentLine; "Payment Line")
        {
            DataItemTableView = SORTING("Date Comptabilité", "Type réglement")
                                    ORDER(ascending)
                                    WHERE(Amount = FILTER(<> 0), IsCopy = filter(false), Posted = filter(true));

            RequestFilterFields = "posting date", "Payment Class";//, "Type réglement";
            column(ChowDetail; ChowDetail)
            {

            }
            column(TypeReglement; PaymentLine."Payment Class")
            {

            }
            column(NameReglement; Paiementclass.Name)
            {

            }
            column(DateCompta; PaymentLine."posting date")
            {

            }
            column(DocumentNo; PaymentLine."No.")
            {

            }
            column(TypeCompte; PaymentLine."Account Type")
            {

            }
            column(NoCompte; PaymentLine."Account No.")
            {

            }
            column(TiersName; TiersName)
            {

            }
            column(Montant; -PaymentLine.Amount)
            {

            }

            column(STCommentaires; STCommentaires)
            {

            }

            trigger OnPostDataItem()
            var
                myInt: Integer;
            begin
                if UserSetup.get(UserId) then
                    if not UserSetup."Print etat caisse" then begin
                        //message(msgdroitreport);
                        Error(msgdroitreport);
                    end;
                if PaymentLine.GetFilter("Posting Date") = '' then error(ErrorDatFilter);
            end;

            trigger OnAfterGetRecord()
            var
                myInt: Integer;
            begin
                if Paiementclass.get(PaymentLine."Type réglement") then;
                TiersName := '';
                TiersName := GetNameTiers(PaymentLine);

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
                group(GroupName)
                {
                    field(ChowDetail; ChowDetail)
                    {
                        ApplicationArea = All;
                        Caption = 'Afficher détail';

                    }
                }
            }
        }

        actions
        {
            area(processing)
            {
                action(ActionName)
                {
                    ApplicationArea = All;

                }
            }
        }
    }
    local procedure GetNameTiers(Var Rec: Record "Payment Line"): text[80]
    var
        myInt: Integer;
    begin
        case Rec."Account Type" of

            Rec."Account Type"::Customer:
                begin
                    Customer.get(PaymentLine."Account No.");
                    exit(Customer.Name);
                end;
            Rec."Account Type"::Vendor:
                begin
                    Vendor.get(PaymentLine."Account No.");
                    exit(Vendor.Name);
                end;
        end
    end;

    var
        myInt: Integer;
        Paiementclass: Record "Payment Class";
        Vendor: Record Vendor;
        Customer: Record Customer;
        TiersName: Text[80];
        ChowDetail: Boolean;
        ErrorDatFilter: label 'Merci de renseigner une date de filtre';
        UserSetup: Record "User Setup";
        msgdroitreport: label 'Vous n''êtes pas autorisé d''imprimer\ état de caisse';
}