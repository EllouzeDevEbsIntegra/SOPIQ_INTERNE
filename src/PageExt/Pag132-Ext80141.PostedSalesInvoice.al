pageextension 80141 "Posted Sales Invoice" extends "Posted Sales Invoice"//132
{

    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter(Print)
        {
            action(PrintPR)
            {
                Caption = 'Imprimer PR';
                ApplicationArea = All;
                Visible = true;
                // RunObject = report "Invoice PR";
                Image = Print;
                trigger OnAction()
                VAR
                    SalesHeader: Record "Sales Invoice Header";

                begin
                    CurrPage.SETSELECTIONFILTER(SalesHeader);
                    REPORT.RUNMODAL(REPORT::"Invoice PR", TRUE, FALSE, SalesHeader);
                end;




            }

            // action("Follow UP List")
            // {
            //     Caption = 'Consulter Fiches de Suivi';
            //     ApplicationArea = All;
            //     Visible = true;
            //     Image = Answers;
            //     RunObject = Page "Follow Up List";
            //     RunPageLink = "Sales Invoice No" = field("No.");
            //     // RunPageMode = View;

            // }

            // action("Add Follow UP")
            // {
            //     AccessByPermission = TableData "Follow Up Header" = R;

            //     Caption = 'Ajouter Fiche de Suivi';
            //     ApplicationArea = All;
            //     Visible = true;
            //     Enabled = addFollowUpAction;
            //     Image = AdjustEntries;
            //     trigger OnAction()
            //     var
            //         FollowUpPage: page "Follow Up Card";
            //         RecFollowUp, recFollowUp2 : Record "Follow Up Header";
            //         FollowUpNo: Integer;
            //         recFollowUpLine: Record "Follow Up Lines";
            //         "Line No": Integer;
            //         StatutFollowUp: Enum "Follow Up Statut";
            //         ifExist: Boolean;
            //     begin
            //         ifExist := false;
            //         RecFollowUp2.Reset();
            //         RecFollowUp2.SetRange("Sales Invoice No", rec."No.");
            //         recFollowUp2.SetRange(statut, StatutFollowUp::Created);
            //         if recFollowUp2.FindFirst() then begin
            //             FollowUpNo := recFollowUp2.No;
            //             ifExist := true;
            //         end
            //         else begin
            //             if RecFollowUp.FindLast() then FollowUpNo := RecFollowUp.No + 1 else FollowUpNo := 1000;
            //             RecFollowUp.Init();
            //             RecFollowUp.No := FollowUpNo;
            //             RecFollowUp.Insert();
            //             ifExist := false;
            //         end;



            //         recFollowUp2.Reset();
            //         RecFollowUp2.SetRange(No, FollowUpNo);
            //         if RecFollowUp2.FindFirst() then begin

            //             if ifExist = false then begin
            //                 recFollowUpLine.DeleteLines(RecFollowUp2.No);
            //                 recFollowUpLine.AddLines(recFollowUp2);
            //             end;


            //             // // Insertion des ligne fiche suivi
            //             // if recFollowUpLine.FindLast() then "Line No" := recFollowUpLine."Line No" + 1000;

            //             // recQuestion.Reset();
            //             // recQuestion.SetRange("Type Follow Up", RecFollowUp2.type);
            //             // if recQuestion.FindSet() then begin
            //             //     repeat
            //             //         "Line No" := "Line No" + 1;
            //             //         recFollowUpLine2.init();
            //             //         recFollowUpLine2."Line No" := "Line No";
            //             //         recFollowUpLine2."Follow Up No" := recFollowUp.No;
            //             //         recFollowUpLine2."Question Order" := recQuestion."Question Order";
            //             //         recFollowUpLine2.Question := recQuestion.Question;
            //             //         recFollowUpLine2.weight := recQuestion.weight;
            //             //         recFollowUpLine2.Insert();
            //             //     until recQuestion.next = 0;
            //             // end;


            //             //Ouvrir la page Fiche Suivi
            //             // Message('%1  -- RecFollowUP %2', FollowUpNo, RecFollowUp2.No);
            //             FollowUpPage.SetTableView(RecFollowUp2);
            //             FollowUpPage.GetRecordFromPostedInvoicePage(Rec, FollowUpNo);
            //             FollowUpPage.Editable(true);
            //             FollowUpPage.Run();

            //         end;

            //     end;



            // }
        }
        // Add changes to page actions here
    }

    var
        addFollowUpAction: Boolean;


    // trigger OnOpenPage()
    // var
    //     recFollowUp: Record "Follow Up Header";
    // begin
    //     addFollowUpAction := true;
    //     recFollowUp.Reset();
    //     recFollowUp.SetRange("Sales Invoice No", "No.");
    //     recFollowUp.SetRange(statut, Enum::"Follow Up Statut"::validated);
    //     if recFollowUp.FindFirst() then addFollowUpAction := false;

    //     recFollowUp.Reset();
    //     recFollowUp.SetRange("Sales Invoice No", "No.");
    //     recFollowUp.SetRange(statut, Enum::"Follow Up Statut"::Closed);
    //     if recFollowUp.FindFirst() then addFollowUpAction := false;

    // end;

}