pageextension 80127 "Item Card" extends "Item Card"//30
{
    layout
    {
        addafter("No.")
        {
            field("No. 2"; "No. 2")
            {
                ApplicationArea = all;
                Caption = 'Réf. Imp.';
            }
        }
        addafter("Count Item Manual ")
        {
            field("Count OEM Update Date"; "Count OEM Update Date")
            {
                ApplicationArea = all;
                Caption = 'Date MAJ Compte OEM';
                Editable = false;
            }
        }

        addafter("Last Purchase Date")
        {
            field("Last Purch Price Devise"; "Last Purch Price Devise")
            {
                Caption = 'Dernier Prix Achat (Devise)';
                ApplicationArea = all;
            }
            field("Last. Pursh. Date"; "Last. Pursh. Date")
            {
                ApplicationArea = All;
                Caption = 'Date dernier achat validé';
            }


            field("Last. Pursh. cost DS"; "Last. Pursh. cost DS")
            {
                ApplicationArea = All;
                Caption = 'Dernier prix calculé DS';
            }

            field("Last. Preferential"; "Last. Preferential")
            {
                ApplicationArea = All;
                Caption = 'Dernier préférentiel';
            }

        }
        addafter(Verified)
        {
            field(Promotion; Promotion)
            {
                ApplicationArea = all;
                Caption = 'En Promotion';
            }
        }
        addafter(Produit)
        {
            field(isOem; isOem)
            {
                ApplicationArea = all;
                Caption = 'Article OEM';
            }
        }

    }

    actions
    {
        addafter("Item Reclassification Journal")
        {
            action(verifyItem)
            {
                ApplicationArea = All;
                Caption = 'Article vérifié';
                Image = Approve;
                trigger OnAction()
                begin
                    rec."To verify" := false;
                    rec.Modify();
                end;
            }
        }

    }


    // trigger OnClosePage()
    // var
    //     recitem, tempItem : Record Item;
    //     recCompany: Record Company;
    //     recCompanyInformation: Record "Company Information";
    // begin
    //     recitem.Reset();
    //     recitem.SetRange("No.", rec."No.");
    //     if recitem.FindFirst() then begin
    //         tempItem := recitem;
    //         // Message('Item Temporaire : %1 --- Item : %2', tempItem."No.", recitem."No.");
    //     end;


    //     recCompanyInformation.Reset();
    //     recCompanyInformation.SetRange("Base Company", true);
    //     if recCompanyInformation.FindFirst() then begin


    //         if (Database.CompanyName = recCompanyInformation.Company) then begin

    //             recCompany.Reset();
    //             if recCompany.FindSet() then begin
    //                 REPEAT

    //                     if (recCompany.Name <> recCompanyInformation.Company) then begin
    //                         tempItem.ChangeCompany(recCompany.Name);
    //                         recitem.Reset();
    //                         recitem.SetRange("No.", rec."No.");
    //                         recitem.ChangeCompany(recCompany.Name);

    //                         if recitem.FindFirst() then begin
    //                             recitem := rec;
    //                             recitem.Modify();
    //                             // Message('Item Modified : %1 Dans société : %2', recitem."No.", recCompany.Name);
    //                         end

    //                     end

    //                 UNTIL recCompany.Next() = 0;
    //             end;


    //         end
    //     end;


    // end;

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields(isOem);
    end;

}