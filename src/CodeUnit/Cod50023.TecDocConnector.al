codeunit 50023 "TecDoc Connector"
{
    procedure RechercherArticleTecdoc(Reference: Text; var Mrfid: Text)
    var
        JsonResponse: JsonObject;
        SearchType: Integer;
        ResponseText: Text;
        RequestCache: Record "TecDoc Request Cache";
        ArticleBuffer: Record "TecDoc Article Buffer";
        // Paramètres fixes pour l'API TecDoc
        Pays: Text;
        ProviderID: Integer;
        Langue: Text;
        APIKey: Text;
    begin
        // Paramètres fixes
        Pays := 'TN';
        ProviderID := 24879;
        Langue := 'en';
        APIKey := '2BeBXg6QH1oQtitZABFPjuLczwZ2Z6xPazrcg69tHKnTkAEsv7Y3';

        // Validation de la référence, calcul et récupération du FlowField mrfID
        if not ValiderReference(Reference, SearchType, Mrfid) then
            exit;

        // Vérification dans le cache (filtré sur SearchQuery, SearchType, IncludeAll et Mrfid)
        RequestCache.Reset();
        RequestCache.SetRange(SearchQuery, Reference);
        RequestCache.SetRange(SearchType, SearchType);
        RequestCache.SetRange(IncludeAll, true);
        RequestCache.SetRange(Mrfid, Mrfid);

        if RequestCache.FindFirst() then begin
            // Cache trouvé, vérification de son expiration
            if IsCacheExpired(RequestCache.LastUpdated) then begin
                // Cache expiré → suppression des enregistrements associés
                DeleteCacheDataAndRelatedRecords(Reference);
                // Appel API
                ResponseText := EffectuerAppelHTTP(Pays, ProviderID, Langue, Reference, SearchType, Mrfid, APIKey);
                if ResponseText = '' then
                    exit; // Échec lors de l'appel API

                RequestCache.Init();
                RequestCache.SearchQuery := Reference;
                RequestCache.SearchType := SearchType;
                RequestCache.IncludeAll := true;
                RequestCache.Mrfid := Mrfid;
                RequestCache.LastUpdated := CurrentDateTime();
                StoreResponseInCache(RequestCache, ResponseText);
                RequestCache.Insert();

                if not JsonResponse.ReadFrom(ResponseText) then
                    Error('Erreur lors du parsing JSON après appel API.');
                ParserResponse(JsonResponse, Reference);
            end else begin
                // Cache non expiré : relecture du record depuis la base pour obtenir le BLOB actualisé
                if not RequestCache.Get(RequestCache.SearchQuery, RequestCache.SearchType, RequestCache.IncludeAll, RequestCache.Mrfid) then
                    Error('Le record cache est introuvable lors de la lecture.');

                // Affichage du contenu pour débogage
                ResponseText := GetResponseFromCache(RequestCache);
                Message('Contenu du cache lu : ' + ResponseText); // Message de débogage
                if not JsonResponse.ReadFrom(ResponseText) then
                    Error('Erreur lors de la lecture du cache.');
                ParserResponse(JsonResponse, Reference);
            end;
        end else begin
            // Aucun cache → appel API
            ResponseText := EffectuerAppelHTTP(Pays, ProviderID, Langue, Reference, SearchType, Mrfid, APIKey);
            if ResponseText = '' then
                exit; // Échec lors de l'appel API

            RequestCache.Init();
            RequestCache.SearchQuery := Reference;
            RequestCache.SearchType := SearchType;
            RequestCache.IncludeAll := true;
            RequestCache.Mrfid := Mrfid;
            RequestCache.LastUpdated := CurrentDateTime();
            StoreResponseInCache(RequestCache, ResponseText);
            RequestCache.Insert();

            if not JsonResponse.ReadFrom(ResponseText) then
                Error('Erreur lors du parsing JSON après appel API.');
            ParserResponse(JsonResponse, Reference);
        end;

        // Affichage de la page "TecDoc Articles List" avec le contenu du buffer Article
        ArticleBuffer.Reset();
        ArticleBuffer.SetRange("Référence", Reference);
        if ArticleBuffer.FindFirst() then
            PAGE.RUN(page::"TecDoc Articles List", ArticleBuffer)
        else
            Message('Aucun article trouvé pour "%1".', Reference);
    end;

    local procedure ValiderReference(var Reference: Text; var SearchType: Integer; var Mrfid: Text) Result: Boolean
    var
        recItem: Record Item;
    begin
        recItem.Reset();
        recItem.SetRange("No.", Reference);
        if recItem.FindFirst() then begin
            recItem.CALCFIELDS(mrfID); // Calcul du FlowField mrfID
            if recItem."Item Class" = recItem."Item Class"::Original then begin
                Reference := recItem."Vendor Item No.";
                SearchType := 1;
                Mrfid := ''; // Aucun mrfid pour un article original
            end else begin
                SearchType := 0;
                Mrfid := recItem.mrfID;
            end;
            exit(true);
        end else begin
            Message('La référence "%1" n''existe pas.', Reference);
            exit(false);
        end;
    end;

    local procedure EffectuerAppelHTTP(Pays: Text; ProviderID: Integer; Langue: Text; Reference: Text; SearchType: Integer; Mrfid: Text; APIKey: Text) ResponseText: Text
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        URL: Text;
    begin
        URL := 'https://webservice.tecalliance.services/pegasus-3-0/services/TecdocToCatDLB.jsonEndpoint?api_key=' + APIKey;
        Content.WriteFrom(ConstruireJSONBody(Pays, ProviderID, Langue, Reference, SearchType, Mrfid));
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type'); // Évite les doublons d'en-tête
        Headers.Add('Content-Type', 'application/json');
        if not Client.Post(URL, Content, Response) then
            exit('');
        if not Response.IsSuccessStatusCode() then
            exit('');
        Response.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    local procedure ConstruireJSONBody(Pays: Text; ProviderID: Integer; Langue: Text; Reference: Text; SearchType: Integer; Mrfid: Text) Result: Text
    begin
        exit(
          '{' +
            '"getArticles":{' +
              '"articleCountry":"' + Pays + '",' +
              '"provider":' + Format(ProviderID) + ',' +
              '"searchQuery":"' + Reference + '",' +
              '"searchType":"' + Format(SearchType) + '",' +
              '"lang":"' + Langue + '",' +
              '"includeAll": true,' +
              '"mrfid":"' + Mrfid + '"' +
            '}' +
          '}'
        );
    end;

    // Stockage dans le cache via le champ BLOB (aucun appel à Modify() car le record est nouveau)
    local procedure StoreResponseInCache(var RequestCache: Record "TecDoc Request Cache"; ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        RequestCache.ResponseData.CreateOutStream(OutStream);
        OutStream.WriteText(ResponseText);
    end;

    local procedure GetResponseFromCache(var RequestCache: Record "TecDoc Request Cache") ResponseText: Text
    var
        InStream: InStream;
    begin
        ResponseText := '';
        if RequestCache.ResponseData.HasValue() then begin
            RequestCache.ResponseData.CreateInStream(InStream);
            InStream.ReadText(ResponseText);
        end;
        // Message de débogage pour vérifier le contenu du BLOB
        Message('Contenu du cache lu : ' + ResponseText);
        exit(ResponseText);
    end;

    local procedure IsCacheExpired(CacheDateTime: DateTime) Result: Boolean
    var
        OneMonthAgo: DateTime;
    begin
        // Logique d'expiration (à adapter si nécessaire)
        OneMonthAgo := CurrentDateTime() - 1000000;
        exit(CacheDateTime < OneMonthAgo);
    end;

    local procedure DeleteCacheDataAndRelatedRecords(SearchQuery: Text)
    var
        RequestCache: Record "TecDoc Request Cache";
        ArticleBuffer: Record "TecDoc Article Buffer";
        OEMBuffer: Record "TecDoc OEM Buffer";
        CriteriaBuffer: Record "TecDoc Criteria Buffer";
        ImagesBuffer: Record "TecDoc Images Buffer";
    begin
        RequestCache.Reset();
        RequestCache.SetRange(SearchQuery, SearchQuery);
        RequestCache.DeleteAll();

        ArticleBuffer.Reset();
        ArticleBuffer.SetRange("Référence", SearchQuery);
        ArticleBuffer.DeleteAll();

        OEMBuffer.Reset();
        OEMBuffer.SetRange("ParentReference", SearchQuery);
        OEMBuffer.DeleteAll();

        CriteriaBuffer.Reset();
        CriteriaBuffer.SetRange("ParentReference", SearchQuery);
        CriteriaBuffer.DeleteAll();

        ImagesBuffer.Reset();
        ImagesBuffer.SetRange("ParentReference", SearchQuery);
        ImagesBuffer.DeleteAll();
    end;

    local procedure ParserResponse(JsonResponse: JsonObject; OriginalReference: Text)
    var
        ArticlesToken: JsonToken;
        ArticlesArray: JsonArray;
        ArticleBuffer: Record "TecDoc Article Buffer";
        ArticleToken: JsonToken;
        ArticleObj: JsonObject;
        ArticleNo: Text;
        Brand: Text;
        DescriptionValue: Text;
        Famille: Text;
        GenericArticlesToken: JsonToken;
        GenericArticlesArray: JsonArray;
        GenericArticleObj: JsonObject;
        OEMRec: Record "TecDoc OEM Buffer";
        CriteriaRec: Record "TecDoc Criteria Buffer";
        ImagesRec: Record "TecDoc Images Buffer";
        OEMNumbersArray: JsonArray;
        OEMToken: JsonToken;
        CriteriaArray: JsonArray;
        CriteriaToken: JsonToken;
        ImagesArray: JsonArray;
        ImgToken: JsonToken;
        ImageURL: Text;
        ImageCount: Integer;
        TempToken: JsonToken;
    begin
        if not JsonResponse.Get('articles', ArticlesToken) then begin
            Message('Aucun article trouvé pour "%1".', OriginalReference);
            exit;
        end;
        if not ArticlesToken.IsArray() then begin
            Message('Le champ "articles" n''est pas un tableau.');
            exit;
        end;
        ArticlesArray := ArticlesToken.AsArray();

        // Suppression des anciens enregistrements dans les buffers
        ArticleBuffer.DeleteAll();
        OEMRec.DeleteAll();
        CriteriaRec.DeleteAll();
        ImagesRec.DeleteAll();

        foreach ArticleToken in ArticlesArray do begin
            ArticleObj := ArticleToken.AsObject();

            if ArticleObj.Get('articleNumber', ArticleToken) then
                ArticleNo := CopyStr(ArticleToken.AsValue().AsText(), 1, 20)
            else
                ArticleNo := '';

            if ArticleObj.Get('mfrName', ArticleToken) then
                Brand := ArticleToken.AsValue().AsText()
            else
                Brand := '';

            DescriptionValue := '';
            Famille := '';
            if ArticleObj.Get('genericArticles', GenericArticlesToken) and GenericArticlesToken.IsArray() then begin
                GenericArticlesArray := GenericArticlesToken.AsArray();
                if GenericArticlesArray.Count > 0 then begin
                    GenericArticlesArray.Get(0, ArticleToken);
                    GenericArticleObj := ArticleToken.AsObject();
                    if GenericArticleObj.Get('genericArticleDescription', ArticleToken) then
                        DescriptionValue := ArticleToken.AsValue().AsText()
                    else
                        DescriptionValue := 'Non trouvé';
                    if GenericArticleObj.Get('assemblyGroupName', ArticleToken) then
                        Famille := ArticleToken.AsValue().AsText()
                    else
                        Famille := 'Non trouvé';
                end;
            end;

            if ArticleNo <> '' then begin
                ArticleBuffer.Init();
                ArticleBuffer."Référence" := ArticleNo;
                ArticleBuffer.Fabricant := Brand;
                ArticleBuffer.Description := DescriptionValue;
                ArticleBuffer.Famille := Famille;
                ArticleBuffer.Insert(true);

                // Traitement des OEM – éviter les doublons sur ParentReference et OEMNumber
                if ArticleObj.Get('oemNumbers', ArticleToken) and ArticleToken.IsArray() then begin
                    OEMNumbersArray := ArticleToken.AsArray();
                    foreach OEMToken in OEMNumbersArray do begin
                        if OEMToken.AsObject().Get('articleNumber', OEMToken) then begin
                            if not OEMRec.Get(ArticleNo, OEMToken.AsValue().AsText()) then begin
                                OEMRec.Init();
                                OEMRec.ParentReference := ArticleNo;
                                OEMRec.OEMNumber := OEMToken.AsValue().AsText();
                                if ArticleObj.Get('mfrName', OEMToken) then
                                    OEMRec.Marque := OEMToken.AsValue().AsText()
                                else
                                    OEMRec.Marque := Brand;
                                OEMRec.Insert();
                            end;
                        end;
                    end;
                end;

                // Traitement des critères
                if ArticleObj.Get('articleCriteria', ArticleToken) and ArticleToken.IsArray() then begin
                    CriteriaArray := ArticleToken.AsArray();
                    foreach CriteriaToken in CriteriaArray do begin
                        CriteriaRec.Init();
                        CriteriaRec.ParentReference := ArticleNo;
                        if CriteriaToken.AsObject().Get('criteriaDescription', TempToken) then
                            CriteriaRec.Nom := TempToken.AsValue().AsText();
                        if CriteriaToken.AsObject().Get('formattedValue', TempToken) then
                            CriteriaRec.Valeur := TempToken.AsValue().AsText()
                        else
                            CriteriaRec.Valeur := '';
                        // Évite le doublon en vérifiant l'existence
                        if not CriteriaRec.Get(CriteriaRec.ParentReference, CriteriaRec.Nom) then
                            CriteriaRec.Insert()
                        else
                            CriteriaRec.Modify();
                    end;
                end;

                // Traitement des images
                if ArticleObj.Get('images', ArticleToken) and ArticleToken.IsArray() then begin
                    ImagesArray := ArticleToken.AsArray();
                    ImageCount := 0;
                    foreach ImgToken in ImagesArray do begin
                        if ImgToken.AsObject().Get('imageURL3200', TempToken) then begin
                            ImageURL := TempToken.AsValue().AsText();
                            if ImageURL <> '' then begin
                                ImagesRec.Init();
                                ImagesRec.ParentReference := ArticleNo;
                                ImagesRec.ImageID := GetNextImageID(ArticleNo);
                                if DownloadImage(ImageURL, ImagesRec) then begin
                                    ImagesRec.Insert();
                                    ImageCount += 1;
                                end;
                            end;
                        end;
                    end;
                    ArticleBuffer.SetRange("Référence", ArticleNo);
                    if ArticleBuffer.FindFirst() then begin
                        ArticleBuffer.nbPicture := ImageCount;
                        ArticleBuffer.Modify();
                    end;
                end;
            end;
        end;
    end;

    local procedure DownloadImage(ImageURL: Text; var ImgRec: Record "TecDoc Images Buffer") Result: Boolean
    var
        ImgClient: HttpClient;
        ImgResponse: HttpResponseMessage;
        ImgStream: InStream;
    begin
        if not ImgClient.Get(ImageURL, ImgResponse) then
            exit(false);
        if not ImgResponse.IsSuccessStatusCode() then
            exit(false);
        ImgResponse.Content().ReadAs(ImgStream);
        ImgRec.Image.ImportStream(ImgStream, 'PNG');
        exit(true);
    end;

    local procedure GetNextImageID(ParentReference: Text) Result: Integer
    var
        ImgBufferRec: Record "TecDoc Images Buffer";
        MaxID: Integer;
    begin
        MaxID := 0;
        ImgBufferRec.SetRange("ParentReference", ParentReference);
        if ImgBufferRec.FindSet() then
            repeat
                if ImgBufferRec.ImageID > MaxID then
                    MaxID := ImgBufferRec.ImageID;
            until ImgBufferRec.Next() = 0;
        exit(MaxID + 1);
    end;
}
