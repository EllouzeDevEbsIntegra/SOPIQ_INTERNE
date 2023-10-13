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


    }

    var
        myInt: Integer;

    procedure ModifyPostingDesc(Prec: Record "Sales Header")
    begin
        "Posting Description" := (FORMAT("Document Type").ToUpper()) + ' ' + "Bill-to Name";
        Validate("Posting Description");
        // Message('%1', "Posting Description");
    end;



    trigger OnInsert()
    begin
        ModifyPostingDesc(rec);
        "Shipping Agent Code" := "External Document No.";
        Validate("Shipping Agent Code");
    end;

}