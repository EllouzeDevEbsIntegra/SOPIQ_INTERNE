pageextension 80520 "Posted Sales Invoices (Serv.)" extends "Posted Sales Invoices (Serv.)"//25006189
{
    layout
    {
        // Add changes to page layout here
        addafter(LocationCode)
        {
            field("Remaining Amount"; "Remaining Amount")
            {
                ApplicationArea = all;
                Caption = 'Montant Ouvert';
            }
            field(Initiateur; Initiateur)
            {
                ApplicationArea = all;
                Caption = 'Code Initiateur';
            }

        }
    }


    actions
    {
        // Add changes to page actions here
        addafter(Print)
        {
            action(modifyDate)
            {
                trigger OnAction()
                begin
                    CurrPage.Editable := true;
                    CurrPage.Update();

                end;
            }
        }
    }

    var
        myInt: Integer;

    trigger OnAfterGetRecord()
    begin
        CalcFields(Initiateur, "Remaining Amount");
    end;
}