pageextension 80115 "Transit Folder card" extends "Transit Folder card" //50002
{
    layout
    {
        modify("Item Price Updated")
        {
            Editable = false;
        }

        addafter("Produit équivalent Comparateur")
        {

            part("Kit Comparateur"; "Kit Comparateur")
            {

                Caption = 'Composant / Kit';
                Provider = "Purchase Recep. Lines";
                SubPageLink = "Parent Item No." = FIELD("No.");
                UpdatePropagation = Both;

            }

        }

        addafter("Item Price Updated")
        {
            field("Update item info Date"; "Update item info Date")
            {
                Editable = false;
                Visible = true;
            }
        }

    }

    actions
    {
        addafter(Cloturer)
        {
            action("Tarification")
            {
                ApplicationArea = All;
                Caption = 'Tarification';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "Purch. Recept. Lines";
                RunPageLink = "Transit Folder No." = FIELD("No.");
                RunPageView = SORTING("Document No.", "Line No.")
                              WHERE(Type = FILTER(Item | "Fixed Asset"));

                Visible = true;
                Enabled = true;
            }
        }

        addafter(Print_)
        {
            action(Print_Homologation)
            {
                ApplicationArea = all;
                Caption = 'Imprimer Homlogation';

                Image = Receipt;

                trigger OnAction()
                var
                    NDossier: Record "Transit Folder";
                begin
                    NDossier.SetRange("No.", "No.");
                    if NDossier.FindFirst() then  // DocMgt.SelectForeignPurchDocReport(Rec, false);
                        Report.Run(50211, true, true, NDossier);
                end;
            }

        }

        modify(UpdateItemInfo)
        {
            Visible = false;
        }

        addafter(UpdateItemInfo)
        {
            action(UpdateItemInfo2)
            {
                ApplicationArea = all;
                Caption = 'Mettre à jour info. article';
                Image = UpdateUnitCost;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    TransitFolderFcts: Codeunit TransitFolderHook;
                begin
                    if not ("Item Price Updated") then begin
                        TransitFolderFcts.UpdateUnitPrice("No.");
                        InsertPriceLine("No.");
                        "Item Price Updated" := true;
                        "Update item info Date" := CurrentDateTime;
                    end

                    else begin
                        if Confirm('Mise à jours de prix est déja effectuée ! Voulez vous refaire la mise à jour ?') then begin
                            TransitFolderFcts.UpdateUnitPrice("No.");
                            InsertPriceLine("No.");
                            "Update item info Date" := CurrentDateTime;


                        end
                    end;





                end;
            }
        }

    }

    var
        myInt: Integer;

    procedure InsertPriceLine(TransitFolder: Code[20])
    var
        recCustomer: Record Customer;
        recSalesPrice: Record "Sales Price";
        lPurchRcptLine: Record "Purch. Rcpt. Line";
        recitem: Record Item;
        Unit: Text[20];

    begin
        lPurchRcptLine.RESET;
        lPurchRcptLine.SETRANGE("Transit Folder No.", TransitFolder);
        lPurchRcptLine.SETFILTER(Quantity, '<>%1', 0);
        lPurchRcptLine.SETRANGE(Correction, FALSE);
        IF lPurchRcptLine.FINDSET THEN
            REPEAT
                recCustomer.Reset();
                recCustomer.SetRange("Is Special Vendor", true);
                if recCustomer.FindSet() THEN
                    REPEAT
                        recSalesPrice.Reset();
                        recSalesPrice.SetRange("Sales Type", recSalesPrice."Sales Type"::Customer);
                        recSalesPrice.SetRange("Sales Code", recCustomer."No.");
                        recSalesPrice.SetRange("Item No.", lPurchRcptLine."No.");
                        if recSalesPrice.FindSet() then begin
                            repeat
                                recSalesPrice.Delete();
                            until recSalesPrice.Next = 0;
                        end;


                        if (lPurchRcptLine."Prix Special Vendor" <> 0) AND (lPurchRcptLine."New Unit Price" <> lPurchRcptLine."Prix Special Vendor") THEN BEGIN

                            recitem.Reset();
                            recitem.SetRange("No.", lPurchRcptLine."No.");
                            if recitem.FindSet() then Unit := recitem."Sales Unit of Measure";
                            // Message('%1 %2', recCustomer."No.", recitem."No.");
                            recSalesPrice.Init();
                            recSalesPrice."Sales Type" := recSalesPrice."Sales Type"::Customer;
                            recSalesPrice."Sales Code" := recCustomer."No.";
                            recSalesPrice."Item No." := lPurchRcptLine."No.";
                            recSalesPrice."Unit of Measure Code" := Unit;
                            recSalesPrice."Starting Date" := Today;
                            recSalesPrice."Unit Price" := lPurchRcptLine."Prix Special Vendor";
                            recSalesPrice."Minimum Quantity" := 1;
                            recSalesPrice.Insert;

                        END;
                    UNTIL recCustomer.Next = 0;
            UNTIL lPurchRcptLine.NEXT = 0;

    end;
}