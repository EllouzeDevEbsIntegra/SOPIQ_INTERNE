tableextension 80105 "Sales Header" extends "Sales Header" //36
{
    fields
    {
        modify("Sell-to Customer No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
            end;
        }

        modify("bill-to Customer No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
            end;
        }

        modify("Bill-to Name")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
            end;
        }
        // Add changes to table fields here
        field(80999; CustVIN; code[50])
        {
            Caption = 'VIN';
            Description = 'Vehicule client';
            FieldClass = Normal;
            TableRelation = Vehicle where("Customer No." = field("Bill-to Customer No."));
        }

        field(80100; Acopmpte; Decimal)
        {
            Caption = 'Total Acompte';

            FieldClass = FlowField;
            CalcFormula = sum("Payment Line"."Credit Amount" where("STOrder No." = field("No."), "Account No." = field("Sell-to Customer No."), Posted = filter(true)));
        }


    }

    var
        myInt: Integer;

    procedure ModifyPostingDesc(Prec: Record "Sales Header")
    begin
        "Posting Description" := (FORMAT("Document Type").ToUpper()) + ' ' + "Bill-to Name";
        Validate("Posting Description");
        // Message('%1', "Posting Description");
    end;

    procedure ignoreStamp(Prec: Record "Sales Header")
    begin
        "STApply Stamp Fiscal" := false;
        "STStamp Amount" := 0.000;
        // Message('%1', "Posting Description");
    end;


    trigger OnInsert()
    begin
        ModifyPostingDesc(rec);
        if (rec."Document Type" = "Document Type"::"Credit Memo") OR (rec."Document Type" = "Document Type"::"Return Order") then
            // Message('%1', "Document Type");
        ignoreStamp(rec);
        "Shipping Agent Code" := "External Document No.";
        Validate("Shipping Agent Code");
    end;

}