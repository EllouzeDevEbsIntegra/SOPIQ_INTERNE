pageextension 80116 "Vehicle SO Proc. Activities" extends "Vehicle SO Proc. Activities" //25006539
{
    layout
    {

        addbefore(B2B)
        {
            cuegroup(ADMIN)
            {
                Caption = 'Notification Admin';
                field("Unit price modified 2"; rec."Sales Line PU Modif")
                {
                    Caption = 'Prix vente modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }
                field("Discount modified"; rec."Sales Line Disc. Modif")
                {
                    Caption = 'Remise modifié';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;
                }

                field("Today Sum Sales"; rec."Today Sum Sales")
                {
                    Caption = 'Vente du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales line";
                    DrillDown = true;

                }

                field("Today Sum Return"; rec."Today Sum Return")
                {
                    Caption = 'Retour du jour';
                    ApplicationArea = All;
                    DrillDownPageId = "Sales Line";
                    DrillDown = true;
                }


                field("Vente Annuelle"; Vente3)
                {
                    ApplicationArea = Basic;
                    Caption = 'Année';
                    DecimalPlaces = 0 : 0;
                    Image = Calculator;
                }

                field("Achat Mensuel"; achat)
                {
                    ApplicationArea = Basic;
                    Caption = 'Achat Mensuel Frs Principal';
                    DecimalPlaces = 0 : 0;
                    Image = Calculator;
                    Visible = StatPurchaseCA;
                }

            }

            cuegroup("Paiment")
            {
                Caption = 'Paiement Client';
                field("Cheque En Coffre"; "Cheque En Coffre")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque En Coffre';
                    DecimalPlaces = 0 : 0;
                }

                field("Cheque Impaye"; "Cheque Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Total Cheque Impayé';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite En Coff."; "Traite En Coff.")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite En Coffre';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite En Escompte"; "Traite En Escompte")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Escompte';
                    DecimalPlaces = 0 : 0;
                }

                field("Traite Impaye"; "Traite Impaye")
                {
                    ApplicationArea = All;
                    Caption = 'Total Traite Impayee';
                    DecimalPlaces = 0 : 0;
                }
            }
        }

        addafter("Litige +")
        {
            field("Item Bin Count"; rec."Item Bin")
            {
                Caption = 'Article avec +Emplacement';
                ApplicationArea = All;
                DrillDownPageId = "Item Bin Contents";
                DrillDown = true;
            }

            field("Neg Ajust Year"; "Neg Ajust Year")
            {
                Caption = 'NB article Ajust Neg -';
                ApplicationArea = All;
                DrillDownPageId = "Item Ledger Entries";
                DrillDown = true;
            }
        }


    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    var
        recSetupPurchase: Record "Purchases & Payables Setup";
        defaultVendor: code[20];
    begin

        userSetup.SetFilter("User ID", UserId);
        if userSetup.FindFirst() then begin
            StatPurchaseCA := userSetup."Purchase Stat CA";
        end;

        recSetupPurchase.Reset();
        if recSetupPurchase.FindFirst() then begin
            defaultVendor := recSetupPurchase."Default Vendor";
        end;
        if "Default Vendor" <> defaultVendor then begin
            "Default Vendor" := defaultVendor;
            Modify();
        end;

        if "date jour" <> Today then begin
            "date jour" := Today;
            Modify();
        end;

        StartingDate := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        Setfilter("Date Filter2", '%1..', StartingDate);
        CalcFields("Sales (LCY)");
        Vente3 := "Sales (LCY)";


        debutMois := CalcDate('<-CM>', Today);
        FinMois := CalcDate('<CM>', Today);
        SetFilter("Date Filter Month", '%1..%2', debutMois, FinMois);
        CalcFields("Month Sum Purchase");
        achat := "Month Sum Purchase";

    end;

    var
        Vente3, achat : Decimal;
        StatPurchaseCA: Boolean;
        StartingDate, debutMois, FinMois : Date;
        userSetup: Record "User Setup";
}