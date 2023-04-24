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
    begin
        if "date jour" <> Today then begin
            "date jour" := Today;
            Modify();
        end;

        StartingDate := System.DMY2Date(1, 1, System.Date2DMY(Today, 3));
        Setfilter("Date Filter2", '%1..', StartingDate);
        CalcFields("Sales (LCY)");
        SetFilter("First Day Of Year", '%1..', StartingDate);
        Vente3 := "Sales (LCY)";


    end;

    var
        Vente3: Decimal;
        StartingDate: Date;
}