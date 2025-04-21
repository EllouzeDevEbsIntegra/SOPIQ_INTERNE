codeunit 50023 "TecDoc Connector"
{

    procedure RechercherArticleTecdoc(Reference: Text)
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        BodyText: Text;
        URL: Text;
        Pays: Text;
        FournisseurID: Integer;
        Langue: Text;
        APIKey: Text;
        Buffer: Record "TecDoc Article Buffer";
        JsonArrayPart: Text;
        Remaining: Text;
        ItemJson: Text;
        PosArrStart: Integer;
        OffsetStart: Integer;
        PosArrEnd: Integer;
        OffsetEnd: Integer;
        PosObjSep: Integer;
        KeyArticle: Text;
        KeyBrand: Text;
        KeyDescription: Text;
        KeyFamille: Text;
        StartPos: Integer;
        EndPos: Integer;
        ArticleNo: Text;
        Brand: Text;
        Description: Text;
        Famille: Text;
        JsonResponse: JsonObject;
        StatusToken: JsonToken;
        ErrorToken: JsonToken;
    begin
        // 1) Paramètres
        Pays := 'TN';
        FournisseurID := 24879;   // votre variable
        Langue := 'en';
        APIKey := '2BeBXg6QH1oQtitZABFPjuLczwZ2Z6xPazrcg69tHKnTkAEsv7Y3';          // votre clé

        // 2) Construction du JSON body
        BodyText :=
          '{' +
            '"getArticles":{' +
              '"articleCountry":"' + Pays + '",' +
              '"provider":' + Format(FournisseurID) + ',' +
              '"searchQuery":"' + Reference + '",' +
              '"lang":"' + Langue + '",' +
              '"includeAll": true,' +
              '"searchType": 99,' +
            '}' +
          '}';

        // 3) URL de l’API
        URL :=
          'https://webservice.tecalliance.services/pegasus-3-0/services/' +
          'TecdocToCatDLB.jsonEndpoint?api_key=' + APIKey;

        // 4) Préparer le Content et le header Content-Type
        Content.WriteFrom(BodyText);

        // Récupère les en‑têtes existants
        Content.GetHeaders(Headers);
        // Supprime toute occurrence précédente de Content-Type
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        // Ajoute le Content-Type correct
        Headers.Add('Content-Type', 'application/json');

        // 5) Appel POST
        if not Client.Post(URL, Content, Response) then
            Error('Erreur HTTP lors de l''appel.');
        if not Response.IsSuccessStatusCode() then
            Error('Erreur API TecDoc : %1', Response.HttpStatusCode());

        // 6) Lecture du JSON brut
        Response.Content().ReadAs(BodyText);

        // 7) Vérifier la structure de la réponse JSON
        if not JsonResponse.ReadFrom(BodyText) then begin
            Message('La réponse JSON est invalide ou mal formée : %1', BodyText);
            exit;
        end;

        // Vérifier si la réponse contient une erreur
        if JsonResponse.Get('error', ErrorToken) then begin
            Message('Erreur renvoyée par l''API TecDoc : %1', ErrorToken.AsValue().AsText());
            exit;
        end;

        // Vérifier le statut
        if JsonResponse.Get('status', StatusToken) then begin
            if StatusToken.AsValue().AsInteger() <> 200 then begin
                Message('La requête a échoué avec le statut : %1', StatusToken.AsValue().AsInteger());
                exit;
            end;
        end;

        // 8) Isolation du tableau "articles"
        PosArrStart := STRPOS(BodyText, '"articles":[');
        if PosArrStart = 0 then begin
            Message('Aucun tableau "articles" trouvé dans la réponse : %1', BodyText);
            exit;
        end;
        OffsetStart := STRPOS(COPYSTR(BodyText, PosArrStart), '[');
        PosArrStart := PosArrStart + OffsetStart;
        OffsetEnd := STRPOS(COPYSTR(BodyText, PosArrStart), ']');
        PosArrEnd := PosArrStart + OffsetEnd - 1;
        JsonArrayPart := COPYSTR(BodyText, PosArrStart + 1, PosArrEnd - PosArrStart - 1);
        Remaining := JsonArrayPart;

        // 9) Vérifier si le tableau "articles" est vide
        if JsonArrayPart = '' then begin
            Message('Aucun article trouvé pour la référence "%1".', Reference);
            exit;
        end;

        // 10) Parsing manuel et remplissage du buffer
        Buffer.DeleteAll();
        KeyArticle := '"articleNumber":"';
        KeyBrand := '"mfrName":"';
        KeyDescription := '"genericArticleDescription":"';
        KeyFamille := '"assemblyGroupName":"';

        while STRLEN(Remaining) > 0 do begin
            PosObjSep := STRPOS(Remaining, '},{');
            if PosObjSep > 0 then begin
                ItemJson := COPYSTR(Remaining, 1, PosObjSep + 1);
                Remaining := DELSTR(Remaining, 1, PosObjSep + 3);
            end else begin
                ItemJson := Remaining;
                Remaining := '';
            end;

            // Extraction articleNumber
            StartPos := STRPOS(ItemJson, KeyArticle);
            if StartPos > 0 then begin
                StartPos := StartPos + STRLEN(KeyArticle);
                EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
                if EndPos > 0 then begin
                    EndPos := EndPos - 1;
                    if EndPos >= 0 then
                        ArticleNo := COPYSTR(ItemJson, StartPos, EndPos)
                    else
                        ArticleNo := '';
                end else
                    ArticleNo := '';
            end else
                ArticleNo := '';

            // Extraction mfrName
            StartPos := STRPOS(ItemJson, KeyBrand);
            if StartPos > 0 then begin
                StartPos := StartPos + STRLEN(KeyBrand);
                EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
                if EndPos > 0 then begin
                    EndPos := EndPos - 1;
                    if EndPos >= 0 then
                        Brand := COPYSTR(ItemJson, StartPos, EndPos)
                    else
                        Brand := '';
                end else
                    Brand := '';
            end else
                Brand := '';

            // Extraction genericArticleName (Description)
            StartPos := STRPOS(ItemJson, KeyDescription);
            if StartPos > 0 then begin
                StartPos := StartPos + STRLEN(KeyDescription);
                EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
                if EndPos > 0 then begin
                    EndPos := EndPos - 1;
                    if EndPos >= 0 then
                        Description := COPYSTR(ItemJson, StartPos, EndPos)
                    else
                        Description := '';
                end else
                    Description := '';
            end else
                Description := '';

            // Extraction assemblyGroupName (Famille)
            StartPos := STRPOS(ItemJson, KeyFamille);
            if StartPos > 0 then begin
                StartPos := StartPos + STRLEN(KeyFamille);
                EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
                if EndPos > 0 then begin
                    EndPos := EndPos - 1;
                    if EndPos >= 0 then
                        Famille := COPYSTR(ItemJson, StartPos, EndPos)
                    else
                        Famille := '';
                end else
                    Famille := '';
            end else
                Famille := '';

            // Insérer dans le buffer si au moins une référence est trouvée
            if ArticleNo <> '' then begin
                Buffer.Init();
                Buffer.Référence := CopyStr(ArticleNo, 1, 20); // Limiter à la longueur du champ
                Buffer.Fabricant := Brand;
                Buffer.Description := Description;
                Buffer.Famille := Famille;
                Buffer.Insert(true);
            end;
        end;

        // 11) Afficher la liste
        if Buffer.IsEmpty then
            Message('Aucun article trouvé pour la référence "%1".', Reference)
        else
            PAGE.Run(Page::"TecDoc Articles", Buffer);
    end;
}
