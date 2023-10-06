pageextension 80124 "Purchase Order Subform" extends "Purchase Order Subform"//54
{
    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {

            field("Marge à définir"; rec.Marge)
            {
                ApplicationArea = All;
            }

            field("Vendor Item No."; "Vendor Item No.")
            {
                ApplicationArea = All;
            }



        }

        addafter("Direct Unit Cost")
        {
            field("Last Direct Cost"; "Last Direct Cost")
            {
                ApplicationArea = all;
            }
            field("asking price"; "asking price")
            {
                ApplicationArea = All;
                Caption = 'Prix demandé';
            }

            field("asking qty"; "asking qty")
            {
                ApplicationArea = All;
                Caption = 'Qté demandé';
            }

            field("negotiated price"; "negotiated price")
            {
                ApplicationArea = All;
                Caption = 'Prix négocié';
            }
            field("negotiated qty"; "negotiated qty")
            {
                ApplicationArea = All;
                Caption = 'Qté négocié';
            }
        }
    }

    actions
    {

        addafter(DataExchangeAction)
        {
            action("Item Profit update")
            {
                ApplicationArea = All;
                Caption = 'Mettre à jour les marges';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()

                var
                    messageValidate: Label 'Voulez vous vraiment mettre à jour les marges défini sur cette commande dans fiche article !';
                    recPurshLine: Record "Purchase Line";


                begin
                    recPurshLine.Reset();
                    recItem.Reset();

                    if Confirm(messageValidate) then begin
                        recPurshLine.SetRange("Document No.", "Document No.");
                        IF recPurshLine.FINDSET THEN
                            REPEAT
                                if recItem.Get(recPurshLine."No.") then begin
                                    recItem."Profit %" := recPurshLine.Marge;
                                    recItem."Price/Profit Calculation New" := recItem."Price/Profit Calculation New"::"No Relationship";
                                    recItem."Price/Profit Calculation" := recItem."Price/Profit Calculation"::"No Relationship";

                                    if recItem."Profit %" <= 50 then begin
                                        GetGLSetup;
                                        recItem."Unit Price" :=
                                        //   Round(
                                        //     (recItem."Unit Cost" / (1 - recItem."Profit %" / 100)) *
                                        //     (1 + CalcVAT),
                                        //     GLSetup."Unit-Amount Rounding Precision");
                                         Round(
                                            (recPurshLine."Direct Unit Cost" / (1 - recItem."Profit %" / 100)) *
                                            (1 + CalcVAT),
                                            GLSetup."Unit-Amount Rounding Precision");
                                    end;


                                    ;
                                    recItem.Modify();
                                end
                            UNTIL recPurshLine.NEXT = 0;
                    end
                end;



            }


        }

        addafter("Co&mments")
        {
            action("Transaction Article")
            {
                Caption = 'Transactions articles';
                ShortcutKey = F8;
                RunObject = page "Specific Item Ledger Entry";
                RunPageLink = "Item No." = field("No.");
                Image = Change;
            }

        }

    }

    var
        Text006: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        recItem: Record "Item";
        GLSetupRead: Boolean;


    local procedure CalcVAT(): Decimal
    begin
        if recItem."Price Includes VAT" then begin
            VATPostingSetup.Get(recItem."VAT Bus. Posting Gr. (Price)", "VAT Prod. Posting Group");
            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text006,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;
        end else
            Clear(VATPostingSetup);

        exit(VATPostingSetup."VAT %" / 100);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure CalcUnitPriceExclVAT(): Decimal
    begin
        GetGLSetup;
        if 1 + CalcVAT = 0 then
            exit(0);
        exit(Round(recitem."Unit Price" / (1 + CalcVAT), GLSetup."Unit-Amount Rounding Precision"));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Last Direct Cost");
    end;


}