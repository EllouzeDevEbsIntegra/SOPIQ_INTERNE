tableextension 80105 "Sales Header" extends "Sales Header" //36
{
    fields
    {
        modify("Sell-to Customer No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
                GetCust("Sell-to Customer No.");
                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                // if not ApplicationAreaMgmt.IsSalesTaxEnabled then
                //    Cust.TestField("Gen. Bus. Posting Group");
                //OnAfterCheckSellToCust(Rec, xRec, Cust);
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

        field(80101; custNameImprime; Text[200])
        {
            Caption = 'Nom Client Imprimé';
        }

        field(80102; custAdresseImprime; Text[200])
        {
            Caption = 'Adresse Client Imprimé';
        }

        field(80103; custMFImprime; Text[200])
        {
            Caption = 'Matricule Fiscal Imprimé';
        }

        field(80104; custVINImprime; Text[200])
        {
            Caption = 'Vin Client Imprimé';
        }

    }

    var
        Cust: Record Customer;

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

    // Function for BS Return
    procedure GetPstdBSLinesToRevere()
    var
        SalesPostedDocLines: Page "Posted BS Lines";
    begin
        //GetCust("Sell-to Customer No.");
        if not (("Document Type" = "Document Type"::Quote) and ("Sell-to Customer No." = '')) then begin
            if "Sell-to Customer No." <> Cust."No." then
                Cust.Get("Sell-to Customer No.");
        end else
            Clear(Cust);
        SalesPostedDocLines.SetToSalesHeader(Rec);
        SalesPostedDocLines.SetRecord(Cust);
        SalesPostedDocLines.LookupMode := true;
        if SalesPostedDocLines.RunModal = ACTION::LookupOK then
            SalesPostedDocLines.CopyLineToDoc;

        Clear(SalesPostedDocLines);
    end;

}