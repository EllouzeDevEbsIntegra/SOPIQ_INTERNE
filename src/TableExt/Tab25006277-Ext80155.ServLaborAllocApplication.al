tableextension 80155 "Serv. Labor Alloc. Application" extends "Serv. Labor Alloc. Application"//25006277
{
    fields
    {
        field(80155; "Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(80156; "beginTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(80157; "EndTime"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(80158; "ConstructorTemps"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(80159; "StandardTime"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}