pageextension 80200 "Posted Service Order EDMS" extends "Posted Service Order EDMS"//25006195
{

    layout
    {


    }
    actions
    {

        addafter(Print)
        {
            action("Print Bon Sortie")
            {
                ApplicationArea = All;
                Caption = 'Imprimer Bon de sortie';
                Image = PrintReport;
                trigger OnAction()
                var
                    BonSortie: Report "Bon De Sortie 2";
                    AutorisationMsg: Label 'Vous n''êtes pas autorisés à imprimer un bon de sortie';
                    UserSetup: Record "User Setup";
                    Cust: Record Customer;
                begin
                    UserSetup.get(UserId);
                    Cust.get("Bill-to Customer No.");
                    if ((UserSetup."BonSortie")) or ("Internal Bill-to Customer" = true) then begin
                        CurrPage.SetSelectionFilter(rec);
                        BonSortie.SetTableView(rec);
                        BonSortie.Run();
                    end
                    else
                        ERROR(AutorisationMsg);

                end;
            }
        }

    }
    trigger OnAfterGetRecord()
    begin
        WorkRecommendation := GetWorkRecommendation();
        WorkDes := GetWorkDesc();
    end;


    var
        WorkRecommendation: Text;
        WorkDes: Text;
}