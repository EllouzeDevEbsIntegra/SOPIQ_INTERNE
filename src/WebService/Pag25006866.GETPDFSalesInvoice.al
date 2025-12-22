page 25006866 "GET PDF Sales Invoice"

{
    PageType = API;
    SourceTable = "Sales Invoice Header";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'getPdfSalesInvoice';
    EntitySetName = 'getPdfSalesInvoice';
    ODataKeyFields = "No.";
    DelayedInsert = true;

    Permissions = TableData "Sales Invoice Header" = R;
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
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        if ReportSelections.FindFirst() then
            ReportId := ReportSelections."Report ID";


        // Préparer le record
        SalesInvoiceHeader := Rec;
        SalesInvoiceHeader.SetRecFilter();

        // Fichier temporaire
        TempFileName := FileManagement.ServerTempFileName('pdf');

        // Générer le PDF
        Report.SaveAsPdf(ReportId, TempFileName, SalesInvoiceHeader);

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
