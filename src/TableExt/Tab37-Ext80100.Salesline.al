tableextension 80100 "Sales line" extends "Sales line" //37
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
            begin
                "Initial Unit Price" := "Unit Price";
                "Initial Discount" := "Line Discount %";

                // recItem.Reset();
                // recItem.SetRange("No.", "No.");
                // if recItem.FindFirst() then begin
                //     // Message('Here %1 - %2', recItem."No.", recItem."Manufacturer Code");
                //     if (recItem."Manufacturer Code" = 'FAB0001') then Begin

                //         rec."Line Discount %" := 2;
                //         Validate(rec."Line Discount %");
                //     End;
                // end;
            end;


        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            var
                recItem: Record Item;
                recProfitAdd: Record "Customer Additional Profit";

            begin

                recItem.Reset();
                recItem.SetRange("No.", "No.");
                if recItem.FindFirst() then begin

                    recProfitAdd.Reset();
                    recProfitAdd.SetRange(Type, recProfitAdd.Type::"Remise Exceptionnelle");
                    recProfitAdd.SetRange("Item Manufacturer", recItem."Manufacturer Code");
                    recProfitAdd.SetRange(Customers, rec."Sell-to Customer No.");
                    if recProfitAdd.FindSet() then begin
                        repeat
                            if (recProfitAdd."Item Group" = 'PR') OR (recProfitAdd."Item Group" = recItem."Item Product Code") then begin

                                rec."Line Discount %" := recProfitAdd.Taux;
                                Validate(rec."Line Discount %");
                            end;

                        // Message('Here %1 - %2', recItem."No.", recItem."Manufacturer Code");

                        until recProfitAdd.next = 0;

                    end;

                end;
            end;
        }

        modify("Unit Price")
        {
            trigger OnAfterValidate()
            begin
                if ("Unit Price" = "Initial Unit Price") Then begin
                    "Price modified" := false;
                end
                else
                    if ("Initial Unit Price" = 0) then begin
                        "Price modified" := false;
                    end
                    else
                        "Price modified" := true;

            end;
        }

        modify("Line Discount %")
        {


            trigger OnAfterValidate()

            begin
                if ("Line Discount %" = "Initial Discount") then begin
                    "Discount modified" := false;
                end
                else
                    "Discount modified" := true;
            end;
        }

        field(50100; "Initial Unit Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50101; "Price modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
            Editable = false;
        }
        field(50110; "Discount modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
            Editable = false;
        }
        field(14; "Ctrl Modified Price"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }

        field(187; "Ctrl Modified Discount"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }


        field(50104; "Initial Discount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }

    }




}