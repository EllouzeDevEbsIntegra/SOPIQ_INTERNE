// page 50170 "Follow Up Card"
// {
//     PageType = Card;
//     SourceTable = "Follow Up Header";
//     Caption = 'Fiche Suivi Client';
//     DeleteAllowed = false;
//     InsertAllowed = false;

//     layout
//     {
//         area(Content)
//         {
//             group("Follow Up Details")
//             {
//                 Caption = 'Général';

//                 field(No; No)
//                 {
//                     Caption = 'Fiche Suivi N°';
//                     Editable = false;

//                 }

//                 field("Date"; "Date")
//                 {
//                     Editable = false;
//                 }
//                 field(statut; statut)
//                 {
//                     Editable = false;

//                 }
//                 field(type; type)
//                 {
//                     Editable = true;
//                     trigger OnValidate()
//                     var
//                         recFollowUpLines: Record "Follow Up Lines";
//                     begin
//                         recFollowUpLines.DeleteLines(No);
//                         recFollowUpLines.AddLines(Rec);
//                     end;

//                 }
//             }
//             group("Sales Invoice Details")
//             {
//                 Caption = 'Détails Facture Client';

//                 field("Sales Invoice No"; "Sales Invoice No")
//                 {
//                     Editable = false;
//                     Caption = 'Facture N°';
//                 }

//                 field("Sales Invoice Date"; "Sales Invoice Date")
//                 {
//                     Editable = false;
//                     Caption = 'Date Facture';
//                 }

//                 field("Customer No"; "Customer No")
//                 {
//                     Editable = false;
//                     Caption = 'Code Client';
//                 }

//                 field("Customer Name"; "Customer Name")
//                 {
//                     Editable = false;
//                     Caption = 'Nom Client';
//                 }

//                 field("Customer Phone No"; "Customer Phone No")
//                 {
//                     Editable = false;
//                     Caption = 'Téléphone';
//                 }
//                 field("Customer Adress"; "Customer Adress")
//                 {
//                     Editable = false;
//                     Caption = 'Adresse';
//                 }


//                 field("Service Order No"; "Service Order No")
//                 {
//                     Editable = false;
//                     Caption = 'Commande N°';
//                 }

//                 field("Service Order Date"; "Service Order Date")
//                 {
//                     Editable = false;
//                     Caption = 'Date Commande';
//                 }

//                 field("Service Order Type"; "Service Order Type")
//                 {
//                     Editable = false;
//                     Caption = 'Type Service';
//                 }

//                 field("Work Description"; "Work Description")
//                 {
//                     Editable = false;
//                     MultiLine = true;
//                     Caption = 'Description de travail';
//                 }
//                 field("Salesperson Code"; "Salesperson Code")
//                 {
//                     Editable = false;
//                     Caption = 'Code Vendeur';
//                 }


//             }


//             part("Follow Up Questions"; "FollowUpLines")
//             {
//                 Caption = 'Questionnaire (Réponse par Oui/Non)';
//                 UpdatePropagation = SubPart;
//                 SubPageLink = "Follow Up No" = field(No);
//                 ApplicationArea = All;
//                 Editable = subpartQuestion;
//             }

//             group("Obs & Comment")
//             {
//                 field(Comment; Comment)
//                 {
//                     Caption = 'Commentaire';
//                 }

//                 field(note; note)
//                 {
//                     Caption = 'Note en %';
//                     DecimalPlaces = 2;
//                     Editable = false;
//                 }
//             }



//         }
//     }

//     actions
//     {
//         area(Processing)
//         {

//             action(Reporter)
//             {
//                 caption = 'Reporter';
//                 ApplicationArea = All;
//                 Image = Aging;
//                 Visible = BtnActionisVisible;
//                 trigger OnAction();
//                 begin
//                     if Confirm('Voulez vous reporter (Client injoignable) ?') then begin
//                         rec.statut := statut::unreachable;
//                         Message('Ficher suivi reportée avec succées !');
//                         CurrPage.Close();
//                     end
//                 end;
//             }

//             action("not satisfied")
//             {
//                 caption = 'Réclamation - Client non satisfait';
//                 ApplicationArea = All;
//                 Image = Comment;
//                 Visible = BtnActionisVisible;
//                 trigger OnAction();
//                 begin
//                     if Confirm('Voulez vous faire une réclamation pour cette facture ?') then begin
//                         rec.statut := statut::"not satisfied";
//                         Message('Réclamation créer avec succées !');
//                         CurrPage.Close();
//                     end
//                 end;
//             }
//             action(Validate)
//             {
//                 caption = 'Valider';
//                 ApplicationArea = All;
//                 Image = Approval;
//                 Visible = BtnActionisVisible;
//                 trigger OnAction();
//                 begin
//                     if Confirm('Voulez vous valider cette fiche de suivi ?') then begin
//                         rec.statut := statut::validated;
//                         calculateNote(Rec);
//                         Message('Fiche Suivi validée avec succèes !');
//                         CurrPage.Close();
//                     end
//                 end;
//             }

//             action(Cloture)
//             {
//                 caption = 'Clôturer';
//                 ApplicationArea = All;
//                 Visible = userPermission;
//                 Image = Completed;
//                 trigger OnAction();
//                 begin

//                     if Confirm('Voulez vous clôturer cette fiche de suivi ?') then begin
//                         rec.statut := statut::Closed;
//                         Message('Fiche Suivi clôturée avec succèes !');
//                         CurrPage.Close();
//                     end

//                 end;

//             }


//         }


//     }

//     var
//         subpartQuestion, userPermission, BtnActionisVisible : Boolean;


//     procedure calculateNote(FollowUpHeader: Record "Follow Up Header")
//     var
//         recFollowUpLines: Record "Follow Up Lines";
//         countQuestions, sumNote, sumQuestionNote, moyenne : Decimal;
//     begin
//         if FollowUpHeader.statut = statut::validated then begin
//             countQuestions := 0;
//             sumNote := 0;
//             sumQuestionNote := 0;
//             moyenne := 0;


//             recFollowUpLines.SetRange("Follow Up No", FollowUpHeader.No);
//             if recFollowUpLines.FindSet() then begin
//                 repeat
//                     countQuestions := countQuestions + 1;
//                     sumQuestionNote := sumQuestionNote + recFollowUpLines.weight;
//                     if recFollowUpLines.Answer = true then sumNote := sumNote + recFollowUpLines.weight;

//                 until recFollowUpLines.Next() = 0;
//             end;

//             moyenne := (sumNote / sumQuestionNote) * 100;
//             FollowUpHeader.note := moyenne;
//             FollowUpHeader.Modify();
//         end;



//     end;

//     procedure GetRecordFromPostedInvoicePage(var Rec: Record "Sales Invoice Header"; FollowUpNo: Integer)

//     var
//         recFollowUp: Record "Follow Up Header";

//         MyOutStream: OutStream;
//         MyInStream: InStream;
//         Result: Text;

//     begin


//         recFollowUp.Reset();
//         recFollowUp.SetRange(No, FollowUpNo);
//         if recFollowUp.FindFirst() then begin
//             recFollowUp."Sales Invoice No" := rec."No.";
//             recFollowUp."Sales Invoice Date" := rec."Posting Date";
//             recFollowUp."Customer No" := rec."Sell-to Customer No.";
//             recFollowUp."Customer Name" := rec."Sell-to Customer Name";
//             recFollowUp."Customer Adress" := rec."Sell-to Address";
//             recFollowUp."Customer Phone No" := rec."Sell-to Phone No.";
//             recFollowUp.Date := System.CurrentDateTime();
//             recFollowUp."Salesperson Code" := rec."Salesperson Code";

//             if rec."Order No." = '' then
//                 recFollowUp."Service Order No" := rec."Service Order No."
//             else
//                 recFollowUp."Service Order No" := rec."Order No.";

//             rec.CalcFields("Work Description");
//             recFollowUp."Work Description" := rec.GetWorkDescription();
//             recFollowUp."Service Order Date" := rec."Order Date";
//             recFollowUp."Service Order Type" := rec."Type Booking";
//             recFollowUp.Modify();

//         end;
//     end;

//     trigger OnClosePage()
//     var
//         recFollowUP: Record "Follow Up Header";
//         recFollowUpLines: Record "Follow Up Lines";
//     begin

//         case statut of
//             statut::unreachable:
//                 begin
//                     recFollowUpLines.Reset();
//                     recFollowUpLines.SetRange("Follow Up No", rec.No);
//                     if recFollowUpLines.FindSet() then begin
//                         repeat
//                             recFollowUpLines.Delete();
//                         until recFollowUpLines.Next() = 0;
//                     end
//                 end;
//         end;


//     end;



//     trigger OnAfterGetRecord()
//     begin
//         if rec.statut = statut::Created then begin
//             subpartQuestion := true;
//         end;

//     end;



//     trigger OnOpenPage()
//     var
//         recUserSetup: Record "User Setup";
//     begin
//         BtnActionisVisible := true;
//         recUserSetup.SetFilter("User ID", UserId);
//         if recUserSetup.FindFirst() then begin
//             userPermission := recUserSetup."Follow Up Controler";
//         end;

//         if statut <> statut::Created then begin
//             CurrPage."Follow Up Questions".Page.Editable := false;
//             BtnActionisVisible := false;
//         end
//         else
//             CurrPage.Editable(true);

//     end;


// }