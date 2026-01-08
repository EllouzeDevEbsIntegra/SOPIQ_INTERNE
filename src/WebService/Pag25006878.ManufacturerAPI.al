page 25006878 "Manufacturer API"
{
    PageType = API;
    SourceTable = Manufacturer;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'Manufacturer';
    EntitySetName = 'Manufacturer';
    ODataKeyFields = Code;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;
    Editable = true;
    Caption = 'Manufacturer API';
    SourceTableView = where("Exclure Compared Tecdoc" = const(false));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                }

                field(Origine; "Origine")
                {
                    ApplicationArea = All;
                    Caption = 'Origine';
                }
                field(Actif; "Actif")
                {
                    ApplicationArea = All;
                    Caption = 'Actif';
                }
                field(IsSpecific; IsSpecific)
                {
                    ApplicationArea = All;
                    Caption = 'Is Specific';
                }

                field(IDTechDOC; "ID TechDOC")
                {
                    ApplicationArea = All;
                    Caption = 'ID TechDOC';
                }
                field(vendorNo; vendorNo)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor No.';
                }
            }
        }
    }

    var
        VendorByManufacturer: Record "Vendor By Manufacturer";
        vendorNo: Code[20];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // La table 5720 impose NotBlank sur Code, mais on peut sécuriser ici aussi :
        if (Code = '') then
            Error('Le code fabricant (Code) est obligatoire.');


        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        // Récupérer le Vendor No. associé au fabricant (s'il existe)
        VendorByManufacturer.Reset();
        VendorByManufacturer.SetRange("Manufacturer Code", Code);
        VendorByManufacturer."Default Vendor" := true;
        if VendorByManufacturer.FindFirst() then
            vendorNo := VendorByManufacturer."Vendor Code"
        else
            Clear(vendorNo);

    end;

}
