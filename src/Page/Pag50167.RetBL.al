page 50167 "Ret BL"
{
    Caption = 'Retour BL';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Return Receipt Header";
    SourceTableView = WHERE(BS = FILTER(false));
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

                field("Line Amount HT"; "Line Amount HT")
                {
                    ApplicationArea = all;
                    Caption = 'Net HT';
                }

                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = all;
                    Caption = 'Net TTC';
                }
                field("Montant reçu caisse"; "Montant reçu caisse")
                {
                    ApplicationArea = all;
                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field("Montant Ouvert"; "Montant Ouvert")
                {
                    ApplicationArea = all;
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
        rec.CalcFields("Montant reçu caisse");
    end;

    local procedure DoDrillDown()
    var
        recuCaisseDoc: Record "Recu Caisse Document";
    begin
        recuCaisseDoc.SetRange("Document No", rec."No.");
        PAGE.Run(PAGE::"Recu Document List", recuCaisseDoc);
    end;



    procedure SetSoldeFilter(soldeFilter: Boolean)
    var
        recCompanyInformation: Record "Company Information";
    begin
        recCompanyInformation.get();


        if recCompanyInformation.BS = false then begin
            if soldeFilter = true then begin
                SetFilter(Solde, '');
                CurrPage.Update();
            end else begin
                SetFilter(Solde, '%1', false);
                CurrPage.Update();
            end;
        end else begin
            CalcFields("Montant Ouvert");
            if soldeFilter = true then begin
                setfilter("Montant Ouvert", '');
                CurrPage.Update();
            end else begin
                setfilter("Montant Ouvert", '<>%1', 0);
                CurrPage.Update();
            end;
        end;

    end;
}

