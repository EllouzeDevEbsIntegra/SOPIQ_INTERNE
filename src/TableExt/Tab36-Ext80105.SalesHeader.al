tableextension 80105 "Sales Header" extends "Sales Header" //36
{
    fields
    {

        field(50100; "Shipping Agent Code SI"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent".Code;

        }
        field(50101; "Location Code SI"; Code[10])
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Code';
            TableRelation = Location.Code;

        }
        modify("Sell-to Customer No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec, rec.custNameImprime);
                GetCust("Sell-to Customer No.");
                Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);

            end;
        }

        modify("bill-to Customer No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec, rec.custNameImprime);
            end;
        }

        modify("Bill-to Name")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec, rec.custNameImprime);
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
            trigger OnValidate()
            begin
                ModifyPostingDesc(rec, rec.custNameImprime);
            end;
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
    //shippingAgentCode: Code[10];

    procedure ModifyPostingDesc(Prec: Record "Sales Header"; ClientImp: Text[200])
    var
        recCompany: Record "Company Information";
    begin

        recCompany.Get();
        if recCompany."Posting Description Spécifique" then begin


            if rec.custNameImprime = '' then
                "Posting Description" := (FORMAT("Document Type").ToUpper()) + ' ' + "Bill-to Name"
            else
                "Posting Description" := (FORMAT("Document Type").ToUpper()) + ' ' + ClientImp;
        end
        else begin
            "Posting Description" := (FORMAT("Document Type").ToUpper()) + ' ' + "Bill-to Name";
        end;
        Validate("Posting Description");
    end;

    procedure ignoreStamp(Prec: Record "Sales Header")
    begin
        "STApply Stamp Fiscal" := false;
        "STStamp Amount" := 0.000;
        // Message('%1', "Posting Description");
    end;


    trigger OnInsert()
    begin
        ModifyPostingDesc(rec, rec.custNameImprime);
        if (rec."Document Type" = "Document Type"::"Credit Memo") OR (rec."Document Type" = "Document Type"::"Return Order") then
            // Message('%1', "Document Type");
        ignoreStamp(rec);
        ReporterChampsSI();
    end;

    trigger OnModify()
    begin
        // Reapro peut envoyer le depot a la creation comme dans une mise a jour.
        // On ne recopie que si le champ SI vient de changer : une saisie faite dans
        // l'interface sur le champ standard n'est donc jamais ecrasee.
        if "Location Code SI" <> xRec."Location Code SI" then
            if "Location Code SI" <> '' then
                Validate("Location Code", "Location Code SI");

        if "Shipping Agent Code SI" <> xRec."Shipping Agent Code SI" then
            if "Shipping Agent Code SI" <> '' then
                Validate("Shipping Agent Code", "Shipping Agent Code SI");
    end;

    // Les champs "... SI" sont ceux exposes par les API (page 25006816 salesOrdersEBS).
    // Ils portent le meme numero dans "Sales Order Entity Buffer" et dans "Sales Header",
    // ils arrivent donc jusqu'ici, mais le standard ne renseigne pas pour autant les
    // champs standards, que la validation d'expedition controle ("Location Code must
    // have a value in Sales Line").
    //
    // La recopie est conditionnee a une valeur non vide : sans cela, toute commande
    // creee hors API, ou ces champs sont vides, verrait son depot et son transporteur
    // effaces. C'est ce defaut qui avait conduit a commenter la recopie du depot en
    // juillet 2025, en laissant celle du transporteur active.
    local procedure ReporterChampsSI()
    begin
        if "Location Code SI" <> '' then
            Validate("Location Code", "Location Code SI");

        if "Shipping Agent Code SI" <> '' then
            Validate("Shipping Agent Code", "Shipping Agent Code SI");
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