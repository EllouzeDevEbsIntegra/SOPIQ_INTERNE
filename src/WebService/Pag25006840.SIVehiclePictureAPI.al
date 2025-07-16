page 25006840 "SI Vehicle Picture API"
{
    PageType = API;
    SourceTable = Picture;
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SIVehiclePicture';
    EntitySetName = 'SIVehiclePictures';
    ODataKeyFields = "No.";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(No; "No.") { Caption = 'Picture No.'; }
                field(VehicleSerialNo; "Vehicle Serial No.") { Caption = 'Vehicle Serial No.'; }
                field(Description; Description) { Caption = 'Description'; }
                field(Default; Default) { Caption = 'Default'; }
                field(ImageBase64; ImageBase64)
                {
                    Caption = 'Image (Base64)';
                    ToolTip = 'Image extraite depuis Picture.Blob encodée en base64.';
                }
            }
        }
    }

    var
        ImageBase64: Text[100000];
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;

    trigger OnAfterGetRecord()
    begin
        Clear(ImageBase64);
        CalcFields(Blob);

        if Blob.HasValue then begin
            Blob.CreateInStream(InStream);
            ImageBase64 := Base64Convert.ToBase64(InStream);
        end;
    end;
}
