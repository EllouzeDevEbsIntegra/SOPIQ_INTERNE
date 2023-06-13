pageextension 80170 "Service Advisor Activitie" extends "Service Advisor Activities" //25006058
{
    layout
    {
        // Add changes to page layout here
        addafter(ServiceQuotes)
        {
            cuegroup("Labor Total")
            {
                Caption = 'CA Main d''œuvre';
                field("CA MO"; "CA MO")
                {
                    Caption = 'Total CA MO';
                    ApplicationArea = all;
                    Editable = true;
                }
                field("CA MO SRV RAPID"; "CA MO SRV RAPIDE")
                {
                    Caption = 'Total CA SRV RAPIDE';
                    ApplicationArea = all;
                    Editable = true;
                }
                field("CA MO SRV MECA"; "CA MO SRV MECA")
                {
                    Caption = 'Total CA SRV MECANIQUE';
                    ApplicationArea = all;
                    Editable = true;
                }

                field("CA MO SRV ELECT"; "CA MO SRV ELECT")
                {
                    Caption = 'Total CA SRV ELECTRIQUE';
                    ApplicationArea = all;
                    Editable = true;
                }

                field("CA MO SRV CARR"; "CA MO SRV CARR")
                {
                    Caption = 'Total CA SRV CARROSSERIE';
                    ApplicationArea = all;
                    Editable = true;
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
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        achat: Decimal;
        StatPurchaseCA: Boolean;
        StartingDate, debutMois, FinMois : Date;
        userSetup: Record "User Setup";

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

        debutMois := CalcDate('<-CM>', Today);
        FinMois := CalcDate('<CM>', Today);
        SetFilter("Date Filter Month", '%1..%2', debutMois, FinMois);
        CalcFields("Month Sum Purchase");
        achat := "Month Sum Purchase";

    end;
}