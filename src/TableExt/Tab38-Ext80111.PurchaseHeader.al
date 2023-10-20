tableextension 80111 "Purchase Header" extends "Purchase Header" //38
{
    fields
    {
        modify("Buy-from Vendor No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
            end;
        }

        modify("Vendor Invoice No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
            end;
        }

        modify("Vendor Cr. Memo No.")
        {
            trigger OnAfterValidate()
            begin
                ModifyPostingDesc(rec);
            end;
        }

        field(80111; "Etat Demande"; Enum "Etat Demande Prix")
        {
            Caption = 'Etat Demande Prix';
            Editable = false;
        }
    }

    var
        myInt: Integer;

    procedure ModifyPostingDesc(Prec: Record "Purchase Header")
    VAR
        typeDoc: TEXT[2];
        vendorDocNo: TEXT;
        recVendor: Record Vendor;
        recVendorName: TEXT;
    begin
        recVendor.Reset();
        recVendor.SetRange("No.", prec."Buy-from Vendor No.");
        if recVendor.FindFirst() THEN BEGIN
            IF recVendor."Search Name" <> '' THEN
                recVendorName := recVendor."Search Name"
            ELSE
                recVendorName := recVendor."Name";
        END;

        case "Document Type" OF
            "Document Type"::Order:
                BEGIN
                    typeDoc := 'FA';
                    vendorDocNo := "Vendor Invoice No."
                END;
            "Document Type"::Invoice:
                BEGIN
                    typeDoc := 'FA';
                    vendorDocNo := "Vendor Invoice No."
                END;
            "Document Type"::"Return Order":
                BEGIN
                    typeDoc := 'AV';
                    vendorDocNo := "Vendor Cr. Memo No."
                END;
            "Document Type"::"Credit Memo":
                BEGIN
                    typeDoc := 'AV';
                    vendorDocNo := "Vendor Cr. Memo No."
                END;

        END;

        "Posting Description" := typeDoc.ToUpper() + ' ' + recVendorName + ' N°' + vendorDocNo;
        Validate("Posting Description");
        // Message('%1', "Posting Description");
    end;

    trigger OnBeforeInsert()
    begin
        "Etat Demande" := Enum::"Etat Demande Prix"::encours;
    end;

    procedure ignoreStamp(Prec: Record "Purchase Header")
    begin
        "STApply Stamp Fiscal" := false;
        "STStamp Fiscal Amount" := 0.000;
    end;


    trigger OnInsert()
    begin
        ModifyPostingDesc(rec);
        if (rec."Document Type" = "Document Type"::"Credit Memo") then
            ignoreStamp(rec);
    end;

}