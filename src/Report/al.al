report 25006128 "Batch Réf Fournisseur"
{

    ProcessingOnly = true;
    Caption = 'Batch Réf Fournisseur';
    Permissions = tabledata item = rimd;

    dataset
    {
        dataitem("Vendor By Manufacturer"; "Vendor By Manufacturer")
        {
            RequestFilterFields = "Manufacturer Code", "Vendor Code";
            DataItemTableView = Sorting("Manufacturer Code", "Vendor Code") where("Default Vendor" = filter(true));

            trigger OnAfterGetRecord()
            var
                recItem: Record item;
            begin
                //Message('Hello Mohamed %1 %2', "Manufacturer Code", "Vendor Code");
                recItem.Reset();
                recItem.SetRange("Manufacturer Code", "Manufacturer Code");
                if recItem.FindSet() then begin
                    repeat
                        recItem."Vendor Item No." := recItem."No.";
                        recItem."Vendor No." := "Vendor Code";
                        recItem.Modify;
                    // @@@@@@@@ TO VERIFY
                    until recItem.Next() = 0;
                end
            end;
        }
    }


}