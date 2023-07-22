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

    procedure GetWorkRecommendation(): Text
    Var
        TypeHelper: Codeunit "Type Helper";
        InStreamData: InStream;
        Description: Text;
    Begin
        CALCFIELDS("Work Recommendation");
        //   IF NOT "dlt Work Recommendation".HASVALUE THEN
        //       EXIT('');
        "Work Recommendation".CreateInstream(InStreamData, Textencoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStreamData, TypeHelper.LFSeparator));
        //InStreamData.ReadText(Description);
        //exit(Description);

    end;


    procedure GetWorkDesc(): Text
    Var
        TypeHelper: Codeunit "Type Helper";
        InStreamData: InStream;
        Description: Text;
    Begin
        CALCFIELDS("Work Description");
        "Work Description".CreateInstream(InStreamData, Textencoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStreamData, TypeHelper.LFSeparator));

    end;

    var
        WorkRecommendation: Text;
        WorkDes: Text;
}