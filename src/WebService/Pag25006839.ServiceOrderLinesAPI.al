page 25006839 "Service Order Lines API"
{
    PageType = API;
    Caption = 'Service Order Lines';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ServiceOrderLine';
    EntitySetName = 'ServiceOrderLines';
    SourceTable = "Service Line EDMS";

    // Clés OData composées
    ODataKeyFields = "Document Type", "Document No.", "Line No.";
    ModifyAllowed = true;
    InsertAllowed = true;
    DeleteAllowed = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(DocumentType; "Document Type")
                {
                    Caption = 'Type Document';
                }
                field(DocumentNo; "Document No.")
                {
                    Caption = 'Document N°';
                }
                field(LineNo; "Line No.")
                {
                    Caption = 'N° Ligne';
                }
                field(Type; Type)
                {
                    Caption = 'Type Ligne';
                }
                field(EntryNo; "No.")
                {
                    Caption = 'Numéro';
                }
                field(Description; Description)
                {
                    Caption = 'Description';
                }
                field(Quantity; Quantity)
                {
                    Caption = 'Quantité';
                }
                field(UnitOfMeasureCode; "Unit of Measure Code")
                {
                    Caption = 'Unité de Mesure';
                }
                field(UnitCostLCY; "Unit Cost (LCY)")
                {
                    Caption = 'Coût Unitaire (LCY)';
                }
                // Ajoutez d'autres champs si nécessaire
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Logique éventuelle après lecture
    end;

    procedure GetNextLineNo(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]): Integer
    var
        ServiceLine: Record "Service Line EDMS";
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);

        if ServiceLine.FindLast then
            exit(ServiceLine."Line No." + 10000) // Incrément typique par pas de 10000
        else
            exit(10000); // Première ligne du document
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Line No." := GetNextLineNo("Document Type", "Document No.");
        Message('Line No. généré : %1', "Line No.");
        if "Line No." = 0 then
            Error('Le numéro de ligne ne peut pas être zéro.');

    end;

    // trigger OnNewRecord(BelowxRec: Boolean)
    // begin
    //     "Line No." := GetNextLineNo("Document Type", "Document No.");
    // end;

}