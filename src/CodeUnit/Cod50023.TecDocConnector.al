codeunit 50023 "TecDoc Connector"
{
    procedure RechercherArticleTecdoc(Reference: Text)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestContent: HttpContent;
        Headers: HttpHeaders;
        JsonRequest: JsonObject;
        GetArticlesObj: JsonObject;
        BodyText: Text;
        URL: Text;
        Pays: Text;
        FournisseurID: Integer;
        Langue: Text;
        APIKey: Text;
    begin
        // Initialisation des paramètres
        Pays := 'TN';           // Code pays (ex. Tunisie)
        FournisseurID := 24879; // ID du fournisseur
        Langue := 'en';         // Langue de la réponse
        APIKey := '2BeBXg6QH1oQtitZABFPjuLczwZ2Z6xPazrcg69tHKnTkAEsv7Y3'; // Clé API

        // Construction de l'URL avec la clé API
        URL := 'https://webservice.tecalliance.services/pegasus-3-0/services/TecdocToCatDLB.jsonEndpoint?api_key=' + APIKey;

        // Construction du corps JSON
        GetArticlesObj.Add('articleCountry', Pays);
        GetArticlesObj.Add('provider', FournisseurID);
        GetArticlesObj.Add('searchQuery', Reference);
        GetArticlesObj.Add('lang', Langue);
        //GetArticlesObj.Add('includeAll', true);

        JsonRequest.Add('getArticles', GetArticlesObj);
        JsonRequest.WriteTo(BodyText);

        // Configuration de la requête
        RequestContent.WriteFrom(BodyText);
        RequestContent.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        Request.Method := 'POST';
        Request.SetRequestUri(URL);
        Request.Content := RequestContent;

        // Envoi de la requête et gestion de la réponse
        if not Client.Send(Request, Response) then
            Error('Erreur lors de l''envoi de la requête HTTP.');
        if not Response.IsSuccessStatusCode then
            Error('Erreur API : %1 - %2', Response.HttpStatusCode, Response.ReasonPhrase);

        Response.Content.ReadAs(BodyText);
        Message('Réponse : %1', BodyText);
    end;
}
