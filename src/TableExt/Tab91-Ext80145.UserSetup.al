tableextension 80145 "User Setup" extends "User Setup" //91
{
    fields
    {
        // Add changes to table fields here
        field(80145; "Purchase Stat CA"; Boolean)
        {
            InitValue = false;
            DataClassification = ToBeClassified;
        }

        field(80146; "Follow Up Controler"; Boolean)
        {
            InitValue = false;
            DataClassification = ToBeClassified;
        }

    }

    var
        myInt: Integer;
}