codeunit 50023 "TecDoc Connector"
{
    procedure RechercherArticleTecdoc(Reference: Text; var Mrfid: Text)
    var
        JsonResponse: JsonObject;
        SearchType: Integer;
        ResponseText: Text;
        RequestCache: Record "TecDoc Request Cache";
        ArticleBuffer: Record "TecDoc Article Buffer";
        RequestID: Integer;
        Pays: Text;
        ProviderID: Integer;
        Langue: Text;
        APIKey: Text;
        TotalArticles: Integer;
        Token: JsonToken;
    begin
        Pays := 'TN';
        ProviderID := 24879;
        Langue := 'fr';
        APIKey := '2BeBXg6QH1oQtitZABFPjuLczwZ2Z6xPazrcg69tHKnTkAEsv7Y3';

        if not ValiderReference(Reference, SearchType, Mrfid) then
            exit;

        RequestCache.Reset();
        RequestCache.SetRange(SearchQuery, Reference);
        RequestCache.SetRange(SearchType, SearchType);
        RequestCache.SetRange(IncludeAll, true);
        RequestCache.SetRange(Mrfid, Mrfid);

        if RequestCache.FindFirst() then begin
            if IsCacheExpired(RequestCache.LastUpdated) then begin
                DeleteAllByRequestID(RequestCache.RequestID);
                ResponseText := EffectuerAppelHTTP(Pays, ProviderID, Langue, Reference, SearchType, Mrfid, APIKey);
                if ResponseText = '' then exit;

                RequestID := GetNextRequestID();
                RequestCache.Init();
                RequestCache.SearchQuery := Reference;
                RequestCache.SearchType := SearchType;
                RequestCache.IncludeAll := true;
                RequestCache.Mrfid := Mrfid;
                RequestCache.LastUpdated := CurrentDateTime();
                RequestCache.RequestID := RequestID;
                RequestCache.Insert();

                if not JsonResponse.ReadFrom(ResponseText) then
                    Error('Erreur lors du parsing JSON après appel API.');
                ParserResponse(JsonResponse, Reference, RequestID);
                lastUpdatedTime := RequestCache.LastUpdated;
            end else begin
                RequestID := RequestCache.RequestID;
                lastUpdatedTime := RequestCache.LastUpdated;
                // ✅ Pas de lecture JSON, on lit directement les buffers
            end;
        end else begin
            ResponseText := EffectuerAppelHTTP(Pays, ProviderID, Langue, Reference, SearchType, Mrfid, APIKey);
            if not JsonResponse.ReadFrom(ResponseText) then
                Error('Erreur lors du parsing JSON après appel API.');

            // Récupérer la valeur du champ "totalMatchingArticles"
            if JsonResponse.Get('totalMatchingArticles', Token) then begin
                if not Token.AsValue().IsNull then
                    TotalArticles := Token.AsValue().AsInteger();

                if TotalArticles = 0 then
                    Error('Aucun article trouvé pour la référence %1', Reference);
            end;

            RequestID := GetNextRequestID();
            RequestCache.Init();
            RequestCache.SearchQuery := Reference;
            RequestCache.SearchType := SearchType;
            RequestCache.IncludeAll := true;
            RequestCache.Mrfid := Mrfid;
            RequestCache.LastUpdated := CurrentDateTime();
            RequestCache.RequestID := RequestID;
            RequestCache.Insert();

            if not JsonResponse.ReadFrom(ResponseText) then
                Error('Erreur lors du parsing JSON après appel API.');
            ParserResponse(JsonResponse, Reference, RequestID);
            lastUpdatedTime := RequestCache.LastUpdated;
        end;

        ArticleBuffer.Reset();
        ArticleBuffer.SetRange(RequestID, RequestID);
        if ArticleBuffer.FindFirst() then
            PAGE.RUN(page::"TecDoc Articles List", ArticleBuffer)
        else
            Message('Aucun article trouvé pour "%1".', Reference);
    end;

    local procedure ValiderReference(var Reference: Text; var SearchType: Integer; var Mrfid: Text): Boolean
    var
        recItem: Record Item;
    begin
        recItem.Reset();
        recItem.SetRange("No.", Reference);
        if recItem.FindFirst() then begin
            recItem.CALCFIELDS(mrfID);
            if recItem."Item Class" = recItem."Item Class"::Original then begin
                Reference := recItem."Vendor Item No.";
                SearchType := 1;
                Mrfid := '';
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

    local procedure GetNextRequestID(): Integer
    var
        Cache: Record "TecDoc Request Cache";
        MaxID: Integer;
    begin
        Cache.Reset();
        if Cache.FindLast() then
            MaxID := Cache.RequestID;
        exit(MaxID + 1);
    end;

    local procedure IsCacheExpired(CacheDateTime: DateTime): Boolean
    var
        OneMonthAgo: Date;
    begin
        OneMonthAgo := CalcDate('-1M', DT2Date(CurrentDateTime()));
        exit(DT2Date(CacheDateTime) < OneMonthAgo);
    end;

    local procedure EffectuerAppelHTTP(Pays: Text; ProviderID: Integer; Langue: Text; Reference: Text; SearchType: Integer; Mrfid: Text; APIKey: Text): Text
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        URL: Text;
        ResponseText: Text;
    begin
        URL := 'https://webservice.tecalliance.services/pegasus-3-0/services/TecdocToCatDLB.jsonEndpoint?api_key=' + APIKey;
        Content.WriteFrom(ConstruireJSONBody(Pays, ProviderID, Langue, Reference, SearchType, Mrfid));
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        if not Client.Post(URL, Content, Response) then exit('');
        if not Response.IsSuccessStatusCode() then exit('');
        Response.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    local procedure ConstruireJSONBody(Pays: Text; ProviderID: Integer; Langue: Text; Reference: Text; SearchType: Integer; Mrfid: Text): Text
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

    local procedure DeleteAllByRequestID(RequestID: Integer)
    var
        ArticleBuffer: Record "TecDoc Article Buffer";
        OEMBuffer: Record "TecDoc OEM Buffer";
        CriteriaBuffer: Record "TecDoc Criteria Buffer";
        ImagesBuffer: Record "TecDoc Images Buffer";
        RequestCache: Record "TecDoc Request Cache";
    begin
        ArticleBuffer.SetRange(RequestID, RequestID);
        ArticleBuffer.DeleteAll();

        OEMBuffer.SetRange(RequestID, RequestID);
        OEMBuffer.DeleteAll();

        CriteriaBuffer.SetRange(RequestID, RequestID);
        CriteriaBuffer.DeleteAll();

        ImagesBuffer.SetRange(RequestID, RequestID);
        ImagesBuffer.DeleteAll();

        RequestCache.SetRange(RequestID, RequestID);
        RequestCache.DeleteAll();
    end;

    procedure ParserResponse(JsonResponse: JsonObject; OriginalReference: Text; RequestID: Integer)
    var
        ArticlesToken: JsonToken;
        ArticlesArray: JsonArray;
        ArticleBuffer: Record "TecDoc Article Buffer";
        ArticleToken: JsonToken;
        ArticleObj: JsonObject;
        ArticleNo: Text;
        Brand: Text;
        BrandID: Code[20];
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

        foreach ArticleToken in ArticlesArray do begin
            ArticleObj := ArticleToken.AsObject();

            if ArticleObj.Get('articleNumber', ArticleToken) then
                ArticleNo := CopyStr(ArticleToken.AsValue().AsText(), 1, 20)
            else
                ArticleNo := '';

            if ArticleObj.Get('dataSupplierId', ArticleToken) then
                BrandID := ArticleToken.AsValue().AsText()
            else
                BrandID := '';
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
                ArticleBuffer.dataSupplierId := BrandID;
                ArticleBuffer.Fabricant := Brand;
                ArticleBuffer.Description := DescriptionValue;
                ArticleBuffer.Famille := Famille;
                ArticleBuffer.LastUpdated := lastUpdatedTime;
                ArticleBuffer.RequestID := RequestID;
                ArticleBuffer.Insert(true);

                if ArticleObj.Get('oemNumbers', ArticleToken) and ArticleToken.IsArray() then begin
                    OEMNumbersArray := ArticleToken.AsArray();
                    foreach OEMToken in OEMNumbersArray do begin
                        GenericArticleObj := OEMToken.AsObject();

                        OEMRec.Init();
                        OEMRec.ParentReference := ArticleNo;
                        OEMRec.dataSupplierId := BrandID;
                        OEMRec.RequestID := RequestID;

                        if GenericArticleObj.Get('articleNumber', TempToken) then
                            OEMRec.OEMNumber := CopyStr(TempToken.AsValue().AsText(), 1, 50)
                        else
                            OEMRec.OEMNumber := '';

                        if GenericArticleObj.Get('mfrName', TempToken) then
                            OEMRec.Marque := CopyStr(TempToken.AsValue().AsText(), 1, 100)
                        else
                            OEMRec.Marque := CopyStr(Brand, 1, 100);

                        if (OEMRec.OEMNumber <> '') and
                           (not OEMRec.Get(OEMRec.ParentReference, OEMRec.dataSupplierId, OEMRec.OEMNumber, OEMRec.Marque)) then
                            OEMRec.Insert();
                    end;
                end;

                if ArticleObj.Get('articleCriteria', ArticleToken) and ArticleToken.IsArray() then begin
                    CriteriaArray := ArticleToken.AsArray();
                    foreach CriteriaToken in CriteriaArray do begin
                        CriteriaRec.Init();
                        CriteriaRec.ParentReference := ArticleNo;
                        CriteriaRec.dataSupplierId := BrandID;
                        CriteriaRec.RequestID := RequestID;

                        if CriteriaToken.AsObject().Get('criteriaDescription', TempToken) then
                            CriteriaRec.Nom := TempToken.AsValue().AsText();
                        if CriteriaToken.AsObject().Get('formattedValue', TempToken) then
                            CriteriaRec.Valeur := TempToken.AsValue().AsText()
                        else
                            CriteriaRec.Valeur := '';

                        if not CriteriaRec.Get(CriteriaRec.ParentReference, CriteriaRec.dataSupplierId, CriteriaRec.Nom) then
                            CriteriaRec.Insert()
                        else
                            CriteriaRec.Modify();
                    end;
                end;

                if ArticleObj.Get('images', ArticleToken) and ArticleToken.IsArray() then begin
                    ImagesArray := ArticleToken.AsArray();
                    ImageCount := 0;
                    foreach ImgToken in ImagesArray do begin
                        if ImgToken.AsObject().Get('imageURL3200', TempToken) then begin
                            ImageURL := TempToken.AsValue().AsText();
                            if ImageURL <> '' then begin
                                ImagesRec.Init();
                                ImagesRec.ParentReference := ArticleNo;
                                ImagesRec.dataSupplierId := BrandID;
                                ImagesRec.ImageID := GetNextImageID(ArticleNo);
                                ImagesRec.RequestID := RequestID;
                                if DownloadImage(ImageURL, ImagesRec) then begin
                                    ImagesRec.Insert();
                                    ImageCount += 1;
                                end;
                            end;
                        end;
                    end;
                    ArticleBuffer.SetRange("Référence", ArticleNo);
                    ArticleBuffer.SetRange(dataSupplierId, BrandID);
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

    var
        lastUpdatedTime: DateTime;
}
