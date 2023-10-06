tableextension 80160 "Company Information" extends "Company Information" //79
{
    fields
    {
        field(80159; "Company"; Text[100])
        {
            TableRelation = Company.Name;
        }
        // Add changes to table fields here
        field(80160; "Base Company"; Boolean)
        {
            InitValue = false;
            trigger OnValidate()
            var
                recCompanyInformation: Record "Company Information";
                recCompany: Record Company;
            begin
                if (rec."Base Company" = true) then begin

                    recCompany.Reset();
                    if recCompany.FindSet() then begin
                        REPEAT
                            recCompanyInformation.Reset();
                            recCompanyInformation.ChangeCompany(recCompany.Name);
                            if recCompanyInformation.FindFirst() then begin
                                if recCompanyInformation."Base Company" = true then begin
                                    Message('La société "%1" est marqué comme société de base !', recCompanyInformation.name);
                                    rec."Base Company" := false;
                                    exit;
                                end
                            end;

                        UNTIL recCompany.Next() = 0;
                    end;
                end;


            end;
        }
    }

    var
        myInt: Integer;
}