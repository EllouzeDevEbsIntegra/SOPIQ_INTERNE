pageextension 80131 "Purchase Quote" extends "Purchase Quote" //49
{
    layout
    {

        addafter(Status)
        {
            field("Etat Demande Prix"; "Etat Demande")
            {
                ApplicationArea = All;
                Editable = false;

            }
        }
        addafter("Import Vendor Response Date")
        {
            field("Total Line"; "Total Line")
            {
                ApplicationArea = all;
                Editable = false;
                Caption = 'Nb Lignes';
            }
        }
    }

    actions
    {
        modify(MakeOrder)
        {
            trigger OnBeforeAction()
            var
                recpurshLine: Record "Purchase Line";
            begin

                recpurshLine.Reset();

                recpurshLine.SetRange("Document No.", "No.");
                recpurshLine.SetFilter("asking price", '> 0');
                recpurshLine.SetRange("negotiated price", 0);
                if recpurshLine.FindFirst() then begin
                    //Message('Succés : %1 - %2 - %3', recpurshLine."Document No.", recpurshLine."asking price", recpurshLine."negotiated price");
                    Error('Vérifier les prix négociés dans la demande de prix %1', "No.");
                end;



            end;
        }

        addafter("Make Order")
        {
            action("Purshase Quote Verification")
            {
                ApplicationArea = all;
                Caption = 'Vérification de demande de prix';
                Image = TestFile;
                RunObject = Page "Purchase Quote Check";
                RunPageLink = "Document No." = FIELD("No.");
                ShortCutKey = 'F8';
                Enabled = "Etat Demande" = "Etat Demande"::"En attente Validation";
                //Enabled = Status <> Status::Open;
            }

            action("Validate Pursh. Qty")
            {
                ApplicationArea = all;
                Caption = 'Valider Qte à Commander';
                Image = Approval;
                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                begin
                    PurchaseLine.Reset();
                    PurchaseLine.Setfilter("Document No.", "No.");
                    if PurchaseLine.FindSet() then begin
                        repeat
                            PurchaseLine."Qty First Confirmation" := PurchaseLine.Quantity;
                            PurchaseLine.Modify();
                        until PurchaseLine.next = 0;
                    end;

                    "Etat Demande" := Enum::"Etat Demande Prix"::"En attente Validation";
                end;
            }
        }
    }



}