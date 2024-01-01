codeunit 50020 API
{
    procedure SendRequest(HttpMethod: Text[6]) ResponseText: Text
    var
        Client: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        RequestHeaders: HttpHeaders;
        RequestURI: Text;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        RequestURI := 'https://jsonplaceholder.typicode.com/todos/3';

        // This shows how you can set or change HTTP content headers in your request
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'multipart/form-data;boundary=boundary');

        // This shows how you can set HTTP request headers in your request
        HttpRequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/json');
        RequestHeaders.Add('Accept-Encoding', 'utf-8');
        RequestHeaders.Add('Connection', 'Keep-alive');
        RequestHeaders.Add('api-key', 'ABCDEFGHIJKLM');

        HttpRequestMessage.SetRequestUri(RequestURI);
        HttpRequestMessage.Method(HttpMethod);

        // from here on, the method must deal with calling out to the external service. 
        // see example code snippets below
    end;

    procedure GetRequest() ResponseText: Text
    var
        Client: HttpClient;
        IsSuccessful: Boolean;
        Response: HttpResponseMessage;
    begin
        IsSuccessful := Client.Get('https://jsonplaceholder.typicode.com/todos/3', Response);

        if not IsSuccessful then begin
            // handle the error
        end;

        if not Response.IsSuccessStatusCode() then begin
            // HttpStatusCode := response.HttpStatusCode();
            // handle the error (depending on the HTTP status code)
        end;

        Response.Content().ReadAs(ResponseText);
        // Expected output:
        //   GET https://jsonplaceholder.typicode.com/todos/3 HTTP/1.1
        //   {
        //     "userId": 1,
        //     "id": 3,
        //     "title": "fugiat veniam minus",
        //     "completed": false
        //   }

    end;


}
