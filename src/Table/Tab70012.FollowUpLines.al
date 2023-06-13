table 70012 "Follow Up Lines"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Line No"; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }

        field(100; "Question Line No"; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = "Follow Up Questions";
        }

        field(2; "Question Order"; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(3; Question; Text[250])
        {
            DataClassification = ToBeClassified;
        }

        field(4; "Follow Up No"; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = "Follow Up Header";
        }
        field(5; "Answer"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

        field(7; weight; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(6; "Comment"; Text[1000])
        {
            DataClassification = ToBeClassified;
        }



    }

    keys
    {
        key(Key1; "Line No")
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

    procedure DeleteLines(FollowUpNo: Integer)
    var
    begin
        rec.Reset();
        Rec.SetRange("Follow Up No", FollowUpNo);
        if Rec.FindSet() then begin
            repeat
                Rec.Delete();
            until Rec.Next() = 0;
        end

    end;


    procedure AddLines(FollowUpHeader: Record "Follow Up Header")
    var
        recQuestion: Record "Follow Up Questions";
        recFollowUpLine: Record "Follow Up Lines";
        "Line No": Integer;
    begin
        recFollowUpLine.Reset();
        if recFollowUpLine.FindLast() then "Line No" := recFollowUpLine."Line No" + 1000;
        recQuestion.Reset();
        recQuestion.SetRange("Type Follow Up", FollowUpHeader.type);
        if recQuestion.FindSet() then begin
            repeat
                "Line No" := "Line No" + 1;
                rec.init();
                rec."Line No" := "Line No";
                rec."Follow Up No" := FollowUpHeader.No;
                rec."Question Order" := recQuestion."Question Order";
                rec.Question := recQuestion.Question;
                rec.weight := recQuestion.weight;
                rec.Insert();
            until recQuestion.next = 0;
        end;

    end;



    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}