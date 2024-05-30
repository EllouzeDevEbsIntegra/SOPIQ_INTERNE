page 50166 "Cr Memo Subform"
{
    Caption = 'Avoirs';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Cr.Memo Header";
    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = all;
                    Caption = 'Date';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                    Style = Attention;
                    Caption = 'NET HT';
                }

                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Style = Attention;
                    Caption = 'NET TTC';
                }
                field("Cust Name Imprime"; custNameImprime)
                {
                    ApplicationArea = All;
                    Caption = 'Client Imprimé';
                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field(solde; solde)
                {
                    ApplicationArea = all;
                }



            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Amount Including VAT", Amount);
    end;

    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;

    procedure SetSoldeFilter(soldeFilter: Boolean)
    begin
        if soldeFilter = true then begin
            SetFilter(Solde, '');
            CurrPage.Update();
        end else begin
            SetFilter(Solde, '%1', false);
            CurrPage.Update();
        end;

    end;
}

