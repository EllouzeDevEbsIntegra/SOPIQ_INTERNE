page 25006852 "Salesperson API"
{
    PageType = API;
    SourceTable = "Salesperson/Purchaser";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'salespersonsAPI';
    EntitySetName = 'salespersonsAPI';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            field(id; SystemId) { }
            field(code; Code) { }
            field(name; Name) { }
            field(email; "E-Mail") { }
            field(phoneNo; "Phone No.") { }
            field(commissionPercent; "Commission %") { }
            field(Departement; Departement) { }
        }
    }
}