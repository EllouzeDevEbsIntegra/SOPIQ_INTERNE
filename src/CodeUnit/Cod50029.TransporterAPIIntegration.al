codeunit 50029 "Transporter API Integration"
{
    Access = Public;

    procedure GetOrders(var TransporterSetup: Record "Transporter Setup")
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        TransporterOrderBuffer: Record "Transporter Order Buffer";
        ExistingOrder: Record "Transporter Order Buffer";
        JsonObj: JsonObject;
        JsonArrayToken: JsonToken;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        OrderObj: JsonObject;
        HttpHeaders: HttpHeaders;
        RequestURI: Text;
        ResponseText: Text;
        NewOrdersCount: Integer;
        LastEntryNo: Integer;
        UpdatedOrdersCount: Integer;
        SkippedOrdersCount: Integer;
        TotalOrdersInResponse: Integer;
        SuccessMsg: Label 'Fetch complete. New: %1, Updated: %2, Skipped: %3, Total in response: %4.', Comment = '%1=New, %2=Updated, %3=Skipped, %4=Total';
        ConnectErr: Label 'Failed to connect to the transporter API. Please check the API URL and your network connection.';
        HttpErr: Label 'Transporter API returned an error. Status Code: %1, Reason: %2, Response: %3';
        JsonParseErr: Label 'Failed to parse JSON response from transporter API.';
        ErrorMessage: Text;
        ApiCallUnsuccessfulErr: Label 'Transporter API returned an unsuccessful status without a specific message.';
        OrdersArrayNotFoundErr: Label 'The "orders" array was not found or is not a valid array in the API response.';
        IsSuccess: Boolean;
        TempInt: Integer;
        TempDecimal: Decimal;
        TempDateTime: DateTime;
        DateTimeText: Text;
    begin
        TransporterSetup.TestField("API URL");
        TransporterSetup.TestField("API Key");

        RequestURI := TransporterSetup."API URL";

        // 1. Set up the HTTP request
        HttpRequestMessage.SetRequestUri(RequestURI);
        HttpRequestMessage.Method := 'GET';
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Authorization', 'Bearer ' + TransporterSetup."API Key");

        // 2. Send the request
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            Error(ConnectErr);
        end;

        // 3. Check response status
        if not HttpResponseMessage.IsSuccessStatusCode then begin
            HttpResponseMessage.Content().ReadAs(ResponseText);
            ErrorMessage := StrSubstNo(HttpErr,
                                       HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase, ResponseText);
            Error(ErrorMessage);
        end;

        // 4. Read and parse the response
        HttpResponseMessage.Content().ReadAs(ResponseText);

        if not JsonObj.ReadFrom(ResponseText) then
            Error(JsonParseErr);

        // 5. Check if the API call was successful based on the "success" field in the response
        // Inlining the GetJsonBoolean logic to bypass a compiler issue (ALAL0133)
        IsSuccess := false;
        if JsonObj.Get('success', JsonToken) then
            if not JsonToken.AsValue().IsNull() then
                IsSuccess := JsonToken.AsValue().AsBoolean();

        if not IsSuccess then begin
            if JsonObj.Get('message', JsonToken) then
                ErrorMessage := JsonToken.AsValue().AsText()
            else
                ErrorMessage := ApiCallUnsuccessfulErr;
            Error(ErrorMessage);
        end;

        // 6. Get the orders array and process it
        if not JsonObj.Get('orders', JsonArrayToken) or not JsonArrayToken.IsArray() then
            Error(OrdersArrayNotFoundErr);

        JsonArray := JsonArrayToken.AsArray();
        TotalOrdersInResponse := JsonArray.Count;

        // Récupérer le dernier N° écriture pour gérer manuellement l'incrémentation
        // et éviter l'erreur "L'enregistrement existe déjà".
        TransporterOrderBuffer.Reset();
        if TransporterOrderBuffer.FindLast() then
            LastEntryNo := TransporterOrderBuffer."Entry No."
        else
            LastEntryNo := 0;

        ExistingOrder.SetCurrentKey("Order ID");
        foreach JsonToken in JsonArray do begin
            if JsonToken.IsObject() then begin
                OrderObj := JsonToken.AsObject();
                TempInt := 0;
                if OrderObj.Get('id', JsonToken) then
                    if not JsonToken.AsValue().IsNull() then
                        if Evaluate(TempInt, JsonToken.AsValue().AsText()) then;

                if TempInt <> 0 then begin
                    // Upsert Logic: Update if exists, Insert if new.
                    ExistingOrder.SetRange("Order ID", TempInt);
                    if ExistingOrder.FindFirst() then begin
                        // --- UPDATE PATH ---
                        // The record is now positioned on the existing order.
                        FillBufferRecord(ExistingOrder, OrderObj);
                        ExistingOrder.Modify(true);
                        UpdatedOrdersCount += 1;
                    end else begin
                        // --- INSERT PATH ---
                        LastEntryNo += 1;
                        TransporterOrderBuffer.Init();
                        TransporterOrderBuffer."Entry No." := LastEntryNo;
                        TransporterOrderBuffer."Order ID" := TempInt;
                        FillBufferRecord(TransporterOrderBuffer, OrderObj);
                        TransporterOrderBuffer.Insert(true);
                        NewOrdersCount += 1;
                    end;
                end else
                    SkippedOrdersCount += 1;
            end;
        end;

        // 7. Update last fetched date in setup
        TransporterSetup."Last Fetched DateTime" := CurrentDateTime();
        TransporterSetup.Modify();

        Message(SuccessMsg, NewOrdersCount, UpdatedOrdersCount, SkippedOrdersCount, TotalOrdersInResponse);
    end;

    local procedure FillBufferRecord(var TransporterOrderBuffer: Record "Transporter Order Buffer"; OrderObj: JsonObject)
    var
        JsonToken: JsonToken;
        TempInt: Integer;
        TempDecimal: Decimal;
        TempDateTime: DateTime;
        DateTimeText: Text;
    begin
        if OrderObj.Get('deliveryName', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Name" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Name"));
        if OrderObj.Get('deliveryAddress', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Address" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Address"));
        if OrderObj.Get('deliveryCity', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery City" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery City"));
        if OrderObj.Get('deliveryCp', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Post Code" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Post Code"));
        if OrderObj.Get('deliveryGovernorat', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Governorate" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Governorate"));
        if OrderObj.Get('deliveryPhone', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Phone" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Phone"));
        if OrderObj.Get('deliveryEmail', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Email" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Email"));

        TempInt := 0;
        if OrderObj.Get('totalColis', JsonToken) then if not JsonToken.AsValue().IsNull() then if Evaluate(TempInt, JsonToken.AsValue().AsText()) then;
        TransporterOrderBuffer."Total Colis" := TempInt;

        if OrderObj.Get('typeColis', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Type Colis" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Type Colis"));

        TempDecimal := 0;
        if OrderObj.Get('totalCr', JsonToken) then if not JsonToken.AsValue().IsNull() then if Evaluate(TempDecimal, JsonToken.AsValue().AsText()) then;
        TransporterOrderBuffer."Total CR" := TempDecimal;

        if OrderObj.Get('paymentMethod', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Payment Method" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Payment Method"));
        if OrderObj.Get('deliveryStatus', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Delivery Status" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Delivery Status"));
        if OrderObj.Get('paymentStatus', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer."Payment Status" := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer."Payment Status"));

        TempDateTime := 0DT;
        if OrderObj.Get('createdAt', JsonToken) then
            if not JsonToken.AsValue().IsNull() then begin
                DateTimeText := JsonToken.AsValue().AsText().Replace(' ', 'T');
                if Evaluate(TempDateTime, DateTimeText) then;
            end;
        TransporterOrderBuffer."Created At" := TempDateTime;

        if OrderObj.Get('comment', JsonToken) then if not JsonToken.AsValue().IsNull() then TransporterOrderBuffer.Comment := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(TransporterOrderBuffer.Comment));

        TransporterOrderBuffer."Fetched DateTime" := CurrentDateTime();
    end;

    procedure GetOrderPdf(OrderId: Integer; var TransporterSetup: Record "Transporter Setup"; var TempBlob: Codeunit "Temp Blob")
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        RequestURI: Text;
        InStr: InStream;
        OutStr: OutStream;
        ConnectErr: Label 'Failed to connect to the transporter API.';
        HttpErr: Label 'Transporter API returned an error. Status Code: %1, Reason: %2';
    begin
        if TransporterSetup."API URL".EndsWith('/') then
            RequestURI := TransporterSetup."API URL" + Format(OrderId) + '/pdf'
        else
            RequestURI := TransporterSetup."API URL" + '/' + Format(OrderId) + '/pdf';

        HttpClient.DefaultRequestHeaders.Add('Authorization', 'Bearer ' + TransporterSetup."API Key");

        if not HttpClient.Get(RequestURI, HttpResponseMessage) then
            Error(ConnectErr);

        if not HttpResponseMessage.IsSuccessStatusCode then
            Error(HttpErr, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);

        // Lecture directe du flux binaire (PDF)
        HttpResponseMessage.Content().ReadAs(InStr);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    procedure CreateOrder(OrderJson: JsonObject; var TransporterSetup: Record "Transporter Setup") OrderId: Integer
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponseMessage: HttpResponseMessage;
        RequestURI: Text;
        ResponseText: Text;
        ContentHeaders: HttpHeaders;
        ConnectErr: Label 'Failed to connect to the transporter API.';
        HttpErr: Label 'Transporter API returned an error. Status Code: %1, Reason: %2, Response: %3, Request Body: %4';
        JsonText: Text;
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
    begin
        TransporterSetup.TestField("API URL");
        TransporterSetup.TestField("API Key");

        RequestURI := TransporterSetup."API URL"; // L'URL de base est utilisée pour le POST (selon votre exemple)

        OrderJson.WriteTo(JsonText);
        HttpContent.WriteFrom(JsonText);
        HttpContent.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        HttpClient.DefaultRequestHeaders.Add('Authorization', 'Bearer ' + TransporterSetup."API Key");

        if not HttpClient.Post(RequestURI, HttpContent, HttpResponseMessage) then
            Error(ConnectErr);

        if not HttpResponseMessage.IsSuccessStatusCode then begin
            HttpResponseMessage.Content().ReadAs(ResponseText);
            Error(HttpErr, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase, ResponseText, JsonText);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        if ResponseJson.ReadFrom(ResponseText) then
            if ResponseJson.Get('orderId', JsonToken) then
                OrderId := JsonToken.AsValue().AsInteger();
    end;
}