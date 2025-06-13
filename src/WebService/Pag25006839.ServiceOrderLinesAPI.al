page 25006839 "Service Order Lines API"
{
    PageType = API;
    Caption = 'Service Order Lines';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ServiceOrderLine';
    EntitySetName = 'ServiceOrderLines';
    SourceTable = "Service Line";

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
}