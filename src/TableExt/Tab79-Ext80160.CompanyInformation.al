tableextension 80160 "Company Information" extends "Company Information" //79
{
    fields
    {
        // Gestion des BS
        field(80158; "BS"; Boolean)
        {
            DataClassification = ToBeClassified;
        }


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
        field(80161; "Com VN"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }
        field(80162; "Com PDR"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }
        field(80163; "Other"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Customer;
        }
        field(80164; "Inter Society 1"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Company.Name;
        }
        field(80165; "Inter Society 2"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Company.Name;
        }
    }

    var
        myInt: Integer;
}