pageextension 80496 "Get Post.Doc - S.ShptLn Sbfrm" extends "Get Post.Doc - S.ShptLn Sbfrm" //5851
{
    layout
    {
        // Add changes to page layout here
        addafter("Document No.")
        {
            field("Salesperson Code"; "Salesperson Code")
            {
                ApplicationArea = all;
                Caption = 'Code Vendeur';
            }
            field(BS; BS)
            {
                ApplicationArea = all;
                Caption = 'Bon sortie';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    procedure setTypeDoc(custNo: code[20])
    begin
        //message('Avant : %1', rec.GetFilters());
        rec.Reset();
        rec.SetRange("Sell-to Customer No.", custNo);
        rec.SetFilter(BS, '%1', true);
        //message('Aprés : %1', rec.GetFilters());
        SetTableView(rec);
        CurrPage.Update(true);
    end;


}