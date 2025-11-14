page 25006864 "GET PDF Sales Shipment"

{
    PageType = API;
    SourceTable = "Sales Shipment Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'getPdfSalesShipment';
    EntitySetName = 'getPdfSalesShipment';
    ODataKeyFields = "No.";
    DelayedInsert = true;

    Permissions = TableData "Sales Shipment Header" = R;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(id; Rec."No.")
                {
                    Caption = 'id';
                }
                field(pdfBase64; PdfBase64)
                {
                    Caption = 'PDF en Base64';
                }


            }
        }
    }

    var
        PdfBase64: Text;
        ReportSelections: Record "Report Selections";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;

    trigger OnAfterGetRecord()
    var
        ReportId: Integer;
        TempFileName: Text;
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Shipment");
        if ReportSelections.FindFirst() then
            ReportId := ReportSelections."Report ID";


        // Préparer le record
        SalesShipmentHeader := Rec;
        SalesShipmentHeader.SetRecFilter();

        // Fichier temporaire
        TempFileName := FileManagement.ServerTempFileName('pdf');

        // Générer le PDF
        Report.SaveAsPdf(ReportId, TempFileName, SalesShipmentHeader);

        // Importer
        FileManagement.BLOBImportFromServerFile(TempBlob, TempFileName);

        // Vérifier
        if not TempBlob.HasValue() then
            Error('Le PDF est vide.');

        // Base64
        TempBlob.CreateInStream(InStream);
        PdfBase64 := Base64Convert.ToBase64(InStream);

        // Nettoyer
        Erase(TempFileName);
    end;

}
