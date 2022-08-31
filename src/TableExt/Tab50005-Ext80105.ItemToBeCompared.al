tableextension 80105 "Item To Be Compared" extends "Item To Be Compared" //50005
{
    fields
    {
        // Add changes to table fields here
    }

    var
        myInt: Integer;

    trigger OnAfterInsert()
    begin
        Message('Yes %1', "No.");
    end;
}