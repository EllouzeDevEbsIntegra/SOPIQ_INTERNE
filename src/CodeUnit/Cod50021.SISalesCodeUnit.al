codeunit 50021 SISalesCodeUnit
{
    procedure ConfirmBSPOST(var SalesHeader: Record "Sales Header"; DefaultOption: Integer): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Selection: Integer;
        ShipInvoiceQst: Label '&Ship';

        ReceiveInvoiceQst: Label 'Réceptionner';

        PostConfirmQst: Label 'Voulez-vous valider la %1?', Comment = '%1 = Document Type';

    begin

        with SalesHeader do begin
            case "Document Type" of
                // "Document Type"::Order:
                //     begin
                //         Selection := StrMenu(ShipInvoiceQst, DefaultOption);
                //         Ship := Selection in [1, 1];
                //         if Selection = 0 then
                //             exit(false);
                //     end;
                "Document Type"::"Return Order":
                    begin
                        //Message('Test : ', ReceiveInvoiceQst);
                        Selection := StrMenu(ReceiveInvoiceQst, DefaultOption);
                        // if Selection = 0 then
                        //     exit(false);
                        Receive := Selection in [1, 1];
                    end
                else
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(PostConfirmQst, LowerCase(Format("Document Type"))), true)
                    then
                        exit(false);
            end;
            "Print Posted Documents" := false;
        end;
        exit(true);
    end;
}