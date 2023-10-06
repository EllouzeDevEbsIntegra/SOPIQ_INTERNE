tableextension 80210 "Finance Cue" extends "Finance Cue" //9054
{
    fields
    {
        field(80210; "Cheque En Coffre"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_CHEQUE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(21000)
                                                                 ));
            Caption = 'Chèque en coffre';
            Editable = false;
            FieldClass = FlowField;
            DecimalPlaces = 0 : 0;
        }

        field(80211; "Cheque Impaye"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_CHEQUE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(32000)
                                                                 ));
            Caption = 'Chèque Impayé';
            Editable = false;
            FieldClass = FlowField;

        }

        field(80212; "Traite En Coff."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(30000)
                                                                 ));
            Caption = 'Traite en coffre';
            Editable = false;
            FieldClass = FlowField;
        }
        field(80213; "Traite En Escompte"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                 "Copied To No." = FILTER('')
                                                                , "Status No." = FILTER(50030)
                                                                 , "Due Date" = filter('>a')));
            Caption = 'Traite en escompte';
            Editable = false;
            FieldClass = FlowField;
        }

        field(80214; "Traite Impaye"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Payment Line"."Amount (LCY)" WHERE("Type réglement" = CONST('ENC_TRAITE'),
                                                                 "Account Type" = FILTER(Customer),
                                                                  "Copied To No." = FILTER('')
                                                                  , "Status No." = FILTER(40050 | 50070)
                                                                 ));
            Caption = 'Traite Impayée';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    var
        myInt: Integer;
}