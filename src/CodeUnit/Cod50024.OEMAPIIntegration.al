codeunit 50024 "OEM API Integration"
{
    procedure GetOEMCount(OEMCode: Text): Integer
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: Text;
        OEMCount: Integer;
    begin
        Request.SetRequestUri('http://192.168.1.11/api/ext/oem-count?oem=' + OEMCode);
        Request.Method := 'GET';

        if Client.Send(Request, Response) then begin
            Response.Content().ReadAs(Content);

            if Content <> '' then begin
                if not Evaluate(OEMCount, Content) then
                    OEMCount := 0;
            end else
                OEMCount := 0;

            exit(OEMCount);
        end else
            exit(0);
    end;



}