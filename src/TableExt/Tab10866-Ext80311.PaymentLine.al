tableextension 80311 "Payment Line" extends "Payment Line" //10866
{
    fields
    {
        field(80378; AbreviationPaimentType; Code[10])
        {
            caption = 'Abréviation Type Paiement';
        }
        modify("Credit Amount")
        {
            trigger OnAfterValidate()
            VAR
                PaimentClass: Record "Payment Class";
            begin
                PaimentClass.Reset();
                PaimentClass.SetRange(Code, "Payment Class");
                if PaimentClass.FindFirst() then rec.AbreviationPaimentType := PaimentClass.AbreviationPaimentType;
                updateComment(rec);

            end;
        }

        modify("Debit Amount")
        {
            trigger OnAfterValidate()
            VAR
                PaimentClass: Record "Payment Class";
            begin
                PaimentClass.Reset();
                PaimentClass.SetRange(Code, "Payment Class");
                if PaimentClass.FindFirst() then rec.AbreviationPaimentType := PaimentClass.AbreviationPaimentType;
                updateComment(rec);

            end;
        }
        // Add changes to table fields here

        modify("Due Date")
        {
            trigger OnAfterValidate()
            begin
                updateComment(rec);
            end;
        }

        modify("Account No.")
        {
            trigger OnAfterValidate()
            begin
                updateComment(rec);
            end;
        }

        modify("External Document No.")
        {
            trigger OnAfterValidate()
            begin
                updateComment(rec);
            end;
        }

        modify("Applies-to Invoices Nos.")
        {
            trigger OnAfterValidate()
            begin
                updateComment(rec);
            end;
        }

        modify("STOrder No.")
        {
            trigger OnAfterValidate()
            begin
                updateComment(rec);
            end;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    procedure updateComment(PaimentLine: Record "Payment Line")
    var
        param, param1, param2 : Text;
        paramCompta: Record "General Ledger Setup";
    begin
        paramCompta.get();
        if (paramCompta.AutoComment = true) then begin
            param := '';
            param1 := '';
            param2 := '';
            if ("STOrder Type" = "STOrder Type"::" ") then begin
                if "Applies-to Invoices Nos." <> '' then
                    param := ' /' + "Applies-to Invoices Nos." + ' '
                else
                    param := ' ';

            end
            else begin
                param := ' Acompte/' + "STOrder No." + ' ';
            end;
            if ("External Document No." <> '') AND (("Type réglement" = 'ENC_CHEQUE') OR ("Type réglement" = 'DEC_CHEQUE')) then param1 := "External Document No." + ' ';
            if ("Type réglement" = 'ENC_TRAITE') then param2 := ' ' + Format("Due Date") + ' ';
            if ("Type réglement" = 'DEC_TRAITE') then param2 := 'EFF' + Format("Due Date") + ' ';


            STCommentaires := "AbreviationPaimentType" + param1 + ' ' + STLibellé + param + param2;
        end;


    end;

    trigger OnAfterModify()
    begin
        if (rec."Applies-to Invoices Nos." <> xrec."Applies-to Invoices Nos.") then begin
            updateComment(rec);
        end;
        if (postedModified = true) then rec.Posted := true;
        rec.Modify();

    end;

    trigger OnBeforeModify()
    begin
        if (rec."Due Date" <> xrec."Due Date") AND (Posted = true) AND ("Copied To No." = '') then begin
            rec.Posted := false;
            postedModified := true;
        end;
    end;

    var
        postedModified: Boolean;
}