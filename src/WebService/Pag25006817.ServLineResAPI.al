page 25006817 "Serv. Line Res. API"
{
    PageType = API;
    Caption = 'Service Line Resources API';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ServLineResources';
    EntitySetName = 'ServLineResources';
    SourceTable = "Serv. Labor Alloc. Application";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(AllocationEntryNo; "Allocation Entry No.")
                {
                    Caption = 'Ligne Ressource N°';
                }
                field(Date; Date)
                {
                    Caption = 'Date';
                }
                field(beginTime; "Begin Time")
                {
                    Caption = 'Heure Début';
                }
                field(EndTime; "End Time")
                {
                    Caption = 'Heure Fin';
                }
                field(DocumentType; "Document Type")
                {
                    Caption = 'Type Document';
                }
                field(DocumentNo; "Document No.")
                {
                    Caption = 'Document N°';
                }
                field(DocumentLineNo; "Document Line No.")
                {
                    Caption = 'Ligne Doc N°';
                }
                field(ResourceNo; "Resource No.")
                {
                    Caption = 'Ressource N°';
                }
                field(FinishedQuantity; "Finished Quantity (Hours)")
                {
                    Caption = 'Qté Fini (Heures)';
                }

            }
        }

    }
    var
        ServiceHeaderEDMS: Record "Service Header EDMS";

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if rec."Document No." = '' then
            Error('Service Order No can not be empty !') else
            if rec."Begin Time" = 0DT then
                Error('Begin date can not be empty !') else
                if rec."Resource No." = '' then
                    Error('Ressource No can not be empty !') else
                    if (rec."End Time" <> 0DT) AND (rec."End Time" < rec."Begin Time") then begin
                        Error('End date must be earlier than the start date!');
                    end
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if rec."End Time" < rec."Begin Time" then begin
            Error('End date must be earlier than the start date!');
        end
    end;

}