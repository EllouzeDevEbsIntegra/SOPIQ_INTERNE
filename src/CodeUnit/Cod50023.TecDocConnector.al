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
        JsonResponse: JsonObject;
        StatusToken: JsonToken;
        ErrorToken: JsonToken;
        ArticlesToken: JsonToken;
        ArticleToken: JsonToken;
        ArticlesArray: JsonArray;
        ArticleObj: JsonObject;
        ArticleNo: Text;
        Brand: Text;
        Description: Text;
        Famille: Text;
        recItem: Record Item;
        searchType: Integer;
        GenericArticlesArray: JsonArray;
        GenericArticleObj: JsonObject;
        DescriptionToken: JsonToken;
        FamilleToken: JsonToken;
        j: Integer;
    begin
        // 0) Vérification de la référence Origine ou non
        searchType := 0;
        recItem.Reset();
        recItem.SetRange("No.", Reference);
        if recItem.FindFirst() then begin
            if recItem."Item Class" = recItem."Item Class"::Original then begin
                Reference := recItem."Vendor Item No.";
                searchType := 1;
            end else begin
                Reference := recItem."No.";
                searchType := 0;
            end;
        end else begin
            Message('La référence "%1" n''existe pas dans la base de données.', Reference);
            exit;
        end;

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
              '"searchType":"' + Format(searchType) + '",' +
              '"lang":"' + Langue + '",' +
              '"includeAll": true,' +
            '}' +
          '}';

        // 3) URL de l’API
        URL :=
          'https://webservice.tecalliance.services/pegasus-3-0/services/' +
          'TecdocToCatDLB.jsonEndpoint?api_key=' + APIKey;

        // 4) Préparer le Content et le header Content-Type
        Content.WriteFrom(BodyText);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        // 5) Appel POST
        if not Client.Post(URL, Content, Response) then
            Error('Erreur HTTP lors de l''appel.');
        if not Response.IsSuccessStatusCode() then
            Error('Erreur API TecDoc : %1', Response.HttpStatusCode());

        // 6) Lecture du JSON brut
        Response.Content().ReadAs(BodyText);

        // 7) Charger le JSON dans un objet
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

        // 8) Récupérer le tableau "articles"
        if not JsonResponse.Get('articles', ArticlesToken) then begin
            Message('Aucun tableau "articles" trouvé dans la réponse : %1', BodyText);
            exit;
        end;

        if not ArticlesToken.IsArray then begin
            Message('Le champ "articles" n''est pas un tableau.');
            exit;
        end;

        ArticlesArray := ArticlesToken.AsArray();

        // 9) Vérifier si le tableau "articles" est vide
        if ArticlesArray.Count = 0 then begin
            Message('Aucun article trouvé pour la référence "%1".', Reference);
            exit;
        end;

        // 10) Parsing avec les objets JSON et remplissage du buffer
        Buffer.DeleteAll();
        foreach ArticleToken in ArticlesArray do begin
            ArticleObj := ArticleToken.AsObject();

            // Extraction articleNumber
            if ArticleObj.Get('articleNumber', ArticleToken) then
                ArticleNo := ArticleToken.AsValue().AsText()
            else
                ArticleNo := '';

            // Extraction mfrName
            if ArticleObj.Get('mfrName', ArticleToken) then
                Brand := ArticleToken.AsValue().AsText()
            else
                Brand := '';

            // Extraction des données imbriquées dans "genericArticles"
            // Vérifier la présence de "genericArticles" et extraire le tableau
            if ArticleObj.Get('genericArticles', ArticleToken) then begin
                Message('Le champ "genericArticles" est présent.');
                if ArticleToken.IsArray then begin
                    GenericArticlesArray := ArticleToken.AsArray();
                    // Parcourir chaque objet dans "genericArticles"
                    for j := 0 to GenericArticlesArray.Count - 1 do begin
                        GenericArticlesArray.Get(j, ArticleToken);
                        GenericArticleObj := ArticleToken.AsObject();
                        // Extraire "genericArticleDescription"
                        if GenericArticleObj.Get('genericArticleDescription', DescriptionToken) then
                            Description := DescriptionToken.AsValue().AsText()
                        else
                            Description := 'Non trouvé';
                        // Extraire "assemblyGroupName"
                        if GenericArticleObj.Get('assemblyGroupName', FamilleToken) then
                            Famille := FamilleToken.AsValue().AsText()
                        else
                            Famille := 'Non trouvé';
                        // Afficher les valeurs extraites pour vérification
                        Message('Description: %1, Famille: %2', Description, Famille);
                    end;
                end else begin
                    Message('Le champ "genericArticles" n''est pas un tableau.');
                end;
            end else begin
                Message('Le champ "genericArticles" non présent.');
            end;



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
