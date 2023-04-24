report 50212 "Impression Cheques"
{
    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    RDLCLayout = './src/report/RDLC/cheques.rdl';
    ApplicationArea = All;
    dataset
    {
        dataitem(DataItem1000000009; 10865)
        {
            RequestFilterFields = "No.";
            dataitem("Payment Line"; 10866)
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("No.", "Line No.");
                RequestFilterFields = "No.";
                column(PaymentLineMontantinitial; "Payment Line"."STMontant Initial")
                {
                }
                column(Line_No_; "Line No.")
                {

                }
                column(PaymentLineNcommande; "Payment Line"."Posting Group")
                {
                }
                column(dateEcheance; "Payment Line"."Due Date")
                {
                }
                column(libelle; "Payment Line"."STLibellé")
                {
                }
                column(No_document; "Payment Line"."Document No.")
                {
                }
                column(dateDoc; dateDoc)
                {
                }
                column(amount; "Payment Line".Amount)
                {
                }
                column(CodeBeneficaire; RecGPaymentHeader."Account No.")
                {
                }
                // column(NomBeneficaire; RecGPaymentHeader."Type Règlement")
                // {
                // }
                column(date_comtabilisation; RecGPaymentHeader."Posting Date")
                {
                }
                column(MntTTLettre; montant_en_lettre)
                {
                }
                column(nom_banque; RecGPaymentHeader."Bank Name")
                {
                }
                column(N_borderau; RecGPaymentHeader."No.")
                {
                }
                column(N_bord; RecGPaymentHeader."No.")
                {
                }
                column(Adressefou; Adressefou)
                {
                }
                column(InfSoc_city; RecCompany.City)
                {
                }
                column(RIB; RIB)
                {
                }
                column(TypeBank; RecBankAccount."STModèle chèques")
                {
                }
                column(MontantD; MontantD)
                {
                }
                column(Nom_Fournisseur; Rec_fournisseur.Name)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    RecGPaymentHeader.GET("Payment Line"."No.");
                    montant_en_lettre := '';
                    RecGPaymentHeader.CALCFIELDS("Amount (LCY)");
                    TotalMontant := ABS((RecGPaymentHeader."Amount (LCY)"));
                    Convert_cdu."Montant en texte"(montant_en_lettre, amount);
                    CLEAR(RecBankAccount);
                    IF RecBankAccount.GET(RecGPaymentHeader."Account No.") THEN;


                    MntTTlettre := '';
                    Convert_cdu."Montant en texte"(MntTTlettre, ABS(Amount));
                end;

                trigger OnPreDataItem()
                begin
                    TotalMontant := 0;

                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        montant_en_lettre: Text;
        Rec_salesInvoices: Record 112;
        TotalMontant: Decimal;
        RecPaymentLine: Record 10866;
        RecCompany: Record 79;
        Adresse: Text[100];
        Siege: Text[100];
        CP: Text[50];
        Rec_fournisseur: Record 23;
        Convert_cdu: Codeunit 70004;
        Adressefou: Text;
        Rec_salesinvoice: Record 112;
        dateDoc: Date;
        RIB: Code[30];
        RecBankAccount: Record 270;
        Rkey: Text[2];
        TotalMontantIN: Decimal;
        TotalRetenue: Decimal;
        RecGPaymentHeader: Record 10865;
        MntTTlettre: Text;
        MontantD: Text;
}

