pageextension 80199 "Vendor Cards" extends "Vendor Card"//26
{
    layout
    {
        // Add changes to page layout here
        addafter(Coefficient)
        {
            field("Default Marge"; "Default Marge")
            {
                Caption = 'Marque Par défaut en %';
            }

            field("Default Discount"; "Default Discount")
            {
                Caption = 'Remise Par défaut en %';
            }
        }

    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    trigger OnClosePage()

    var
        PurshaseRecSetup: record "Purchases & Payables Setup";
    begin

        PurshaseRecSetup.Reset();
        if PurshaseRecSetup.FindFirst() then begin
            TestField("VAT Registration No.");
            // if (PurshaseRecSetup."MF obligatoire") then begin
            //     if ("VAT Registration No." = '') then begin
            //         Error('Vous devez remplir le champ N° d''identification Intracom du fournisseur (Matricule Fiscal)');            //     end;
            // end;
        end;


    end;


    // trigger OnClosePage()
    // begin
    //     if ("VAT Registration No." = '') then Error('Vous devez remplir le champ N° d''identification Intracom du fournisseur (Matricule Fiscal)');
    // end;
}