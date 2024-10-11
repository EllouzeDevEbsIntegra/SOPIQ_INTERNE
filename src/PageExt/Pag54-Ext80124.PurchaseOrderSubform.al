pageextension 80124 "Purchase Order Subform" extends "Purchase Order Subform"//54
{
    layout
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recVendor: Record Vendor;
                marge, remise : Decimal;
                recBin: Record "Bin Content";
                recLocation: Record Location;
            begin
                recVendor.Reset();
                recVendor.Get("Buy-from Vendor No.");
                if recVendor.Find() then begin
                    if recVendor."Default Marge" > 0 then begin
                        marge := recVendor."Default Marge";
                        rec.Validate(Marge, marge);
                    end;

                    if recVendor."Default Discount" > 0 then begin
                        remise := recVendor."Default Discount";
                        rec.Validate("Line Discount %", remise);
                    end;

                end;

                if ("Location Code" <> '') then begin
                    recBin.Reset();
                    recBin.SetRange("Item No.", "No.");
                    if recbin.IsEmpty then begin
                        recLocation.Reset();
                        recLocation.get("Location Code");
                        if recLocation.Find() then begin
                            if recLocation."Default reception location" <> '' then begin
                                rec.Validate("Bin Code", recLocation."Default reception location");
                            end
                        end;

                    end;
                end;


            end;
        }


        modify("Quantity")
        {
            trigger OnAfterValidate()
            begin
                rec."Prix vente calculé" := Round((rec."Direct Unit Cost" / (1 - rec.Marge / 100)) *
                                                            (1 + CalcVAT),
                                                            GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        modify("Direct Unit Cost")
        {
            trigger OnAfterValidate()
            begin
                rec."Prix vente calculé" := Round((rec."Direct Unit Cost" / (1 - rec.Marge / 100)) *
                                                            (1 + CalcVAT),
                                                            GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        // Add changes to page layout here


        addafter(Quantity)
        {
            field("Stk Mg Principal"; "Stk Mg Principal")
            {
                ApplicationArea = All;
                Editable = false;
                StyleExpr = FieldStyleQty;
                DecimalPlaces = 0 : 2;

            }

            field("Marge à définir"; rec.Marge)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    if (rec.Marge <= 75) then
                        rec."Prix vente calculé" := Round((rec."Direct Unit Cost" / (1 - rec.Marge / 100)) *
                                                                    (1 + CalcVAT),
                                                                    GLSetup."Unit-Amount Rounding Precision")
                    else
                        error('Marge ne doit pas dépasser 75%');
                end;
            }

            field("Special Order"; "Special Order")
            {
                ApplicationArea = All;
                Editable = false;
            }

            field("Special Order Sales No."; "Special Order Sales No.")
            {
                ApplicationArea = All;
                Editable = false;
            }



            field("Prix vente calculé"; "Prix vente calculé")
            {
                ApplicationArea = All;
                Editable = false;
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
                Image = UpdateUnitCost;
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
                                if recPurshLine.Type = Type::Item then begin
                                    if recItem.Get(recPurshLine."No.") then begin
                                        recItem."Profit %" := recPurshLine.Marge;
                                        recItem."Price/Profit Calculation New" := recItem."Price/Profit Calculation New"::"No Relationship";
                                        recItem."Price/Profit Calculation" := recItem."Price/Profit Calculation"::"No Relationship";
                                        recItem."Last Direct Cost" := recPurshLine."Direct Unit Cost";
                                        if recItem."Profit %" <= 75 then begin
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

                                            recItem.Modify();
                                            recPurshLine.margeUpdate := true;
                                            recPurshLine.Modify();
                                        end
                                        else
                                            Error('Marge ne doit pas dépasser 75% !');
                                        ;

                                    end;
                                end


                            UNTIL recPurshLine.NEXT = 0;
                    end
                end;



            }

            action(UpdateSalesCalcPrice)
            {
                Caption = 'Prix de vente calculé';
                Image = CalculateRegenerativePlan;
                trigger OnAction()
                var
                    PurchaseLine: Record "Purchase Line";
                begin
                    PurchaseLine.Reset();
                    PurchaseLine.SetRange("Document No.", rec."Document No.");
                    if PurchaseLine.FindSet() then begin
                        repeat
                            if PurchaseLine.Type = Type::Item then begin
                                PurchaseLine."Prix vente calculé" := Round((PurchaseLine."Direct Unit Cost" / (1 - PurchaseLine.Marge / 100)) *
                                                                    (1 + CalcVAT),
                                                                    GLSetup."Unit-Amount Rounding Precision");
                                PurchaseLine.Modify();
                            end;

                        until PurchaseLine.Next() = 0;
                    end;
                    CurrPage.Update();

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
        recInventorySetup: Record "Inventory Setup";
        FieldStyleQty: Text[50];


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


    procedure SetStyleQte(PDecimal: Decimal): Text[50]
    begin
        IF PDecimal <= 0 THEN exit('Unfavorable') ELSE exit('Favorable');
    end;

    trigger OnAfterGetRecord()
    begin
        FieldStyleQty := SetStyleQte("Stk Mg Principal");
    end;


}