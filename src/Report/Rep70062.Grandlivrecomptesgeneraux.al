report 50199 "Grand livre comptes generaux" //70039
{


    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/GL Details Trial Balance.rdl';
    CaptionML = ENU = 'G/L Detail Trial Balance',
                FRA = 'Grand/livre comptes généraux';


    dataset
    {
        dataitem("G/L Account"; 15)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Date Filter";
            column(COMPANYNAME; COMPANYNAME)
            {
            }
            column(STRSUBSTNO_Text004_PreviousStartDate_; STRSUBSTNO(Text004, PreviousStartDate))
            {
            }
            column(PageCaption; STRSUBSTNO(Text005, ' '))
            {
            }
            column(UserCaption; STRSUBSTNO(Text003, ''))
            {
            }
            column(GLAccountTABLECAPTIONAndFilter; "G/L Account".TABLECAPTION + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(FiscalYearStatusText; FiscalYearStatusText)
            {
            }
            column(Text009; Text009Lbl)
            {
            }
            column(GLAccountTypeFilter; GLAccountTypeFilter)
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(Name_GLAccount; Name)
            {
            }
            column(DebitAmount_GLAccount; "G/L Account"."Debit Amount")
            {
                AutoFormatExpression = GeneralLedgerSetup."LCY Code";
                AutoFormatType = 1;
            }
            column(CreditAmount_GLAccount; "G/L Account"."Credit Amount")
            {
                AutoFormatExpression = GeneralLedgerSetup."LCY Code";
                AutoFormatType = 1;
            }
            column(STRSUBSTNO_Text006_PreviousEndDate_; STRSUBSTNO(Text006, PreviousEndDate))
            {

            }
            column(DueDateCaptionLbl; DueDateCaptionLbl)
            {

            }
            column(DebitAmount_GLAccount2; GLAccount2."Debit Amount")
            {
                AutoFormatExpression = GeneralLedgerSetup."LCY Code";
                AutoFormatType = 1;
            }
            column(CreditAmount_GLAccount2; GLAccount2."Credit Amount")
            {
                AutoFormatExpression = GeneralLedgerSetup."LCY Code";
                AutoFormatType = 1;
            }
            column(STRSUBSTNO_Text006_EndDate_; STRSUBSTNO(Text006, EndDate))
            {
            }
            column(ShowBodyGLAccount; ShowBodyGLAccount)
            {
            }
            // column(G_L_Account_G_L_Entry_Type_Filter;"G/L Entry Type Filter")
            // {
            // }
            column(G_L_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(G_L_Account_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(G_L_Detail_Trial_BalanceCaption; G_L_Detail_Trial_BalanceCaptionLbl)
            {
            }
            column(ImprNonMvt; ImprNonMvt)
            {

            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(Source_CodeCaption; Source_CodeCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(External_Document_No_Caption; External_Document_No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(Grand_TotalCaption; Grand_TotalCaptionLbl)
            {
            }
            column(Picture; RecGCompanyInfo.Picture)
            {
            }
            column(RecGCompanyInfoCity; RecGCompanyInfo.City)
            {
            }
            column(Phone; RecGCompanyInfo."Phone No.")
            {

            }
            column(Fax; RecGCompanyInfo."Fax No.")
            {

            }
            column(MatriculeFiscal; RecGCompanyInfo."VAT Registration No.")
            {
            }
            column(TxtAdresse; TXTADRESSE)
            {

            }
            column(AfficherfiltreDate; AfficherfiltreDate)
            {

            }
            column(AfficherDate; AfficherDate)
            {

            }
            column(AfficherUtilisateur; AfficherUtilisateur)
            {

            }
            dataitem(Date; 2000000007)
            {
                DataItemTableView = SORTING("Period Type");
                PrintOnlyIfDetail = false;
                column(STRSUBSTNO_Text007_EndDate_; STRSUBSTNO(Text007, EndDate))
                {
                }
                column(Date_PeriodNo; Date."Period No.")
                {
                }
                // column(PostingYear; DATE2DMY("G/L Entry"."Posting Date", 3))
                //{
                //}
                column(Date_Period_Type; "Period Type")
                {
                }
                column(Total_Date_RangeCaption; Total_Date_RangeCaptionLbl)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = FIELD("No."),
                                   // "Entry Type"=FIELD("G/L Entry Type Filter"),
                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter");
                    DataItemLinkReference = "G/L Account";
                    DataItemTableView = SORTING("G/L Account No.");
                    column(DebitAmount_GLEntry; "G/L Entry"."Debit Amount")
                    {
                        AutoFormatExpression = GeneralLedgerSetup."LCY Code";
                        AutoFormatType = 1;
                    }
                    column(CreditAmount_GLEntry; "G/L Entry"."Credit Amount")
                    {
                        AutoFormatExpression = GeneralLedgerSetup."LCY Code";
                        AutoFormatType = 1;
                    }
                    column(PostingDate_GLEntry; FORMAT("Posting Date"))
                    {
                    }
                    column(Due_Date; "Due Date")
                    { }

                    column(SourceCode_GLEntry; "Source Code")
                    {
                    }
                    column(DocumentNo_GLEntry; "Document No.")
                    {
                    }
                    column(ExternalDocumentNo_GLEntry; "External Document No.")
                    {
                    }
                    column(Description_GLEntry; Description)
                    {
                    }
                    column(Solde; Solde)
                    {
                    }
                    column(EntryNo_GLEntry; "G/L Entry"."Entry No.")
                    {
                    }
                    column(Date_PeriodType_PeriodName; Text008 + ' ' + FORMAT(Date."Period Type") + ' ' + Date."Period Name")
                    {
                    }
                    column(TotalByInt; TotalByInt)
                    {
                    }
                    column(PostingYear; DATE2DMY("G/L Entry"."Posting Date", 3))
                    {
                    }
                    trigger OnAfterGetRecord();
                    begin
                        //>>DELTA RF 
                        // IF ("G/L Entry"."Debit Amount" = 0) AND ("G/L Entry"."Credit Amount" = 0) 

                        //THEN
                        //   CurrReport.SKIP;
                        //>>DELTA RF

                        Solde := Solde + "Debit Amount" - "Credit Amount";
                    end;

                    trigger OnPreDataItem();
                    begin
                        IF DocNumSort THEN
                            SETCURRENTKEY("G/L Account No.", "Document No.", "Posting Date");
                        SETRANGE("Posting Date", Date."Period Start", Date."Period End");
                    end;
                }

                trigger OnPreDataItem();
                begin
                    SETRANGE("Period Type", TotalBy);
                    SETRANGE("Period Start", StartDate, CLOSINGDATE(EndDate));
                    CurrReport.CREATETOTALS("G/L Entry"."Debit Amount", "G/L Entry"."Credit Amount");
                end;
            }

            trigger OnAfterGetRecord();
            begin
                GLAccount2.COPY("G/L Account");


                WITH GLAccount2 DO BEGIN
                    IF "Income/Balance" = 0 THEN
                        SETRANGE("Date Filter", PreviousStartDate, PreviousEndDate)
                    ELSE
                        SETRANGE("Date Filter", 0D, PreviousEndDate);
                    CALCFIELDS("Debit Amount", "Credit Amount");
                    Solde := "Debit Amount" - "Credit Amount";
                END;
                //<<DELTA RF 

                //                 IF NOT ImprNonMvt AND (
                // ((GLAccount2."Debit Amount" + "net Debit Amount" - GLAccount2."Credit Amount" - "net Credit Amount") = 0) AND ((GLAccount2."Debit Amount" + "net Debit Amount" - GLAccount2."Credit Amount" - "net Credit Amount") = 0)) and (GLAccount2."Debit Amount" = 0) AND ("net Debit Amount" = 0) and (GLAccount2."Credit Amount" = 0) and ("net Credit Amount" = 0)
                // THEN
                //                     CurrReport.SKIP;
                //>>DELTA RF 
                IF "Income/Balance" = 0 THEN
                    SETRANGE("Date Filter", StartDate, EndDate)
                ELSE
                    SETRANGE("Date Filter", 0D, EndDate);
                CALCFIELDS("Debit Amount", "Credit Amount");
                IF ("Debit Amount" = 0) AND ("Credit Amount" = 0) THEN
                    CurrReport.SKIP;

                ShowBodyGLAccount :=
                  ((GLAccount2."Debit Amount" = "Debit Amount") AND (GLAccount2."Credit Amount" = "Credit Amount")) OR ("Account Type" <> 0);
            end;

            trigger OnPreDataItem();
            begin
                IF GETFILTER("Date Filter") = '' THEN
                    ERROR(Text001, FIELDCAPTION("Date Filter"));
                IF COPYSTR(GETFILTER("Date Filter"), 1, 1) = '.' THEN
                    ERROR(Text002);
                StartDate := GETRANGEMIN("Date Filter");
                Period.SETRANGE("Period Start", StartDate);
                CASE TotalBy OF
                    TotalBy::" ":
                        Period.SETRANGE("Period Type", Period."Period Type"::Date);
                    TotalBy::Week:
                        Period.SETRANGE("Period Type", Period."Period Type"::Week);
                    TotalBy::Month:
                        Period.SETRANGE("Period Type", Period."Period Type"::Month);
                    TotalBy::Quarter:
                        Period.SETRANGE("Period Type", Period."Period Type"::Quarter);
                    TotalBy::Year:
                        Period.SETRANGE("Period Type", Period."Period Type"::Year);
                END;
                IF NOT Period.FINDFIRST THEN
                    ERROR(Text010, StartDate, Period.GETFILTER("Period Type"));
                PreviousEndDate := CLOSINGDATE(StartDate - 1);
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := CONVERTSTR(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := COPYSTR(TextDate, 1, 8);
                EVALUATE(PreviousStartDate, TextDate);
                IF COPYSTR(GETFILTER("Date Filter"), STRLEN(GETFILTER("Date Filter")), 1) = '.' THEN
                    EndDate := 0D
                ELSE
                    EndDate := GETRANGEMAX("Date Filter");
                CLEAR(Period);
                Period.SETRANGE("Period End", CLOSINGDATE(EndDate));
                CASE TotalBy OF
                    TotalBy::" ":
                        Period.SETRANGE("Period Type", Period."Period Type"::Date);
                    TotalBy::Week:
                        Period.SETRANGE("Period Type", Period."Period Type"::Week);
                    TotalBy::Month:
                        Period.SETRANGE("Period Type", Period."Period Type"::Month);
                    TotalBy::Quarter:
                        Period.SETRANGE("Period Type", Period."Period Type"::Quarter);
                    TotalBy::Year:
                        Period.SETRANGE("Period Type", Period."Period Type"::Year);
                END;
                IF NOT Period.FINDFIRST THEN
                    ERROR(Text011, EndDate, Period.GETFILTER("Period Type"));

                CurrReport.CREATETOTALS(GLAccount2."Debit Amount", GLAccount2."Credit Amount",
                  "Debit Amount", "Credit Amount",
                  "G/L Entry"."Debit Amount", "G/L Entry"."Credit Amount");
                // FiscalYearStatusText := STRSUBSTNO(Text012, FYFiscalClose.CheckFiscalYearStatus(GETFILTER("Date Filter")));

                TotalByInt := TotalBy;
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
                    CaptionML = ENU = 'Options',
                                FRA = 'Options';
                    field(CentralizedBy; TotalBy)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionML = ENU = 'Centralized by',
                                    FRA = 'Centralisé par';
                        OptionCaptionML = ENU = ' ,Week,Month,Quarter,Year',
                                          FRA = ' ,Semaine,Mois,Trimestre,Année';
                    }
                    field(SortedByDocumentNo; DocNumSort)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionML = ENU = 'Sorted by Document No.',
                                    FRA = 'Trié par n° document';
                    }
                    field("Afficher fitres"; AfficherfiltreDate)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionML = ENU = 'Show date filter',
                                    FRA = 'Afficher les fitres';
                    }
                    field("Afficher date"; AfficherDate)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionML = ENU = 'Show date',
                                    FRA = 'Afficher date';
                    }
                    field("Afficher fitre date"; AfficherUtilisateur)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionML = ENU = 'Show User',
                                    FRA = 'Afficher utilisateur';
                    }

                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport();
    begin
        TotalBy := TotalBy::Month;

        RecGCompanyInfo.GET;
        RecGCompanyInfo.CALCFIELDS(Picture);
        TXTADRESSE := RecGCompanyInfo.Address + ' ' + RecGCompanyInfo.City + ' ' + RecGCompanyInfo."Post Code";
        GeneralLedgerSetup.Get();

    end;

    trigger OnPreReport();
    begin
        Filter := "G/L Account".GETFILTERS;
        // GLAccountTypeFilter := "G/L Account".GETFILTER("G/L Entry Type Filter");
    end;

    var
        Text001: TextConst ENU = 'You must fill in the %1 field.', FRA = 'Vous devez renseigner le champ %1.';
        Text002: TextConst ENU = 'You must specify a Starting Date.', FRA = 'Vous devez spécifier une date de début.';
        Text003: TextConst ENU = 'Printed by %1', FRA = 'Imprimé par %1';
        Text004: TextConst ENU = 'Fiscal Year Start Date : %1', FRA = 'Début exercice comptable : %1';
        Text005: TextConst ENU = 'Page %1', FRA = 'Page %1';
        Text006: TextConst ENU = 'Balance at %1 ', FRA = 'Solde au %1 ';
        Text007: TextConst ENU = 'Balance at %1', FRA = 'Solde au %1';
        Text008: TextConst ENU = 'Total', FRA = 'Total';
        GLAccount2: Record 15;
        Period: Record 2000000007;
        FYFiscalClose: Codeunit 10862;
        FiltreDateCalc: Codeunit 70005;
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text;
        Solde: Decimal;
        TotalBy: Option " ",Week,Month,Quarter,Year;
        DueDateCaptionLbl: TextConst ENU = 'Due Date', FRA = 'Date d''échéance';
        DocNumSort: Boolean;
        ShowBodyGLAccount: Boolean;
        "Filter": Text;
        GLAccountTypeFilter: Text;
        Text010: TextConst ENU = 'The selected starting date %1 is not the start of a %2.', FRA = 'La date de début choisie (%1) ne correspond pas au début de %2.';
        Text011: TextConst ENU = 'The selected ending date %1 is not the end of a %2.', FRA = 'La date de fin choisie (%1) ne correspond pas ¨ la fin de %2.';
        FiscalYearStatusText: Text;
        Text012: TextConst ENU = 'Fiscal-Year Status: %1', FRA = 'Statut de l''exercice comptable : %1';
        TotalByInt: Integer;
        ImprNonMvt: Boolean;
        Text009Lbl: TextConst ENU = 'This report includes simulation entries.', FRA = 'Cet état inclut des écritures de simulation.';
        G_L_Detail_Trial_BalanceCaptionLbl: TextConst ENU = 'G/L Detail Trial Balance', FRA = 'Grand livre comptes généraux';
        Posting_DateCaptionLbl: TextConst ENU = 'Posting Date', FRA = 'Date comptabilisation';
        Source_CodeCaptionLbl: TextConst ENU = 'Source Code', FRA = 'Code journal';
        Document_No_CaptionLbl: TextConst ENU = 'Document No.', FRA = 'N° document';
        External_Document_No_CaptionLbl: TextConst ENU = 'External Document No.', FRA = 'N° doc. externe';
        DescriptionCaptionLbl: TextConst ENU = 'Description', FRA = 'Désignation';
        DebitCaptionLbl: TextConst ENU = 'Debit', FRA = 'Débit';
        CreditCaptionLbl: TextConst ENU = 'Credit', FRA = 'Crédit';
        BalanceCaptionLbl: TextConst ENU = 'Balance', FRA = 'Solde';
        Grand_TotalCaptionLbl: TextConst ENU = 'Grand Total', FRA = 'Total général';
        Total_Date_RangeCaptionLbl: TextConst ENU = 'Total Date Range', FRA = 'Total plage de dates';
        RecGCompanyInfo: Record 79;
        GeneralLedgerSetup: Record "General Ledger Setup";
        TXTADRESSE: Text;
        AfficherfiltreDate: Boolean;
        AfficherDate: Boolean;
        AfficherUtilisateur: Boolean;
}