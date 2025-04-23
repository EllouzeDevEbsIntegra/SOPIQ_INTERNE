codeunit 50023 "TecDoc Connector"
{
    procedure RechercherArticleTecdoc(Reference: Text)
    var
        JsonResponse: JsonObject;
        SearchType: Integer;
        Pays: Text;
        FournisseurID: Integer;
        Langue: Text;
        APIKey: Text;
        BodyText: Text;
    begin
        if not ValiderReference(Reference, SearchType) then
            exit;

        Pays := 'TN';
        FournisseurID := 24879;
        Langue := 'en';
        APIKey := '2BeBXg6QH1oQtitZABFPjuLczwZ2Z6xPazrcg69tHKnTkAEsv7Y3';

        BodyText := ConstruireJSONBody(Pays, FournisseurID, Langue, Reference, SearchType);

        if not EffectuerAppelHTTP(APIKey, BodyText, JsonResponse) then
            exit;

        ParserResponse(JsonResponse, Reference);
    end;


    local procedure ValiderReference(var Reference: Text; var SearchType: Integer) Result: Boolean
    var
        recItem: Record Item;
    begin
        recItem.Reset();
        recItem.SetRange("No.", Reference);
        if recItem.FindFirst() then begin
            if recItem."Item Class" = recItem."Item Class"::Original then begin
                Reference := recItem."Vendor Item No.";
                SearchType := 1;
            end else
                SearchType := 0;
            exit(true);
        end else begin
            Message('La référence "%1" n''existe pas dans la base de données.', Reference);
            exit(false);
        end;
    end;


    local procedure ConstruireJSONBody(Pays: Text; FournisseurID: Integer; Langue: Text; Reference: Text; SearchType: Integer) Result: Text
    begin
        exit(
          '{' +
            '"getArticles":{' +
              '"articleCountry":"' + Pays + '",' +
              '"provider":' + Format(FournisseurID) + ',' +
              '"searchQuery":"' + Reference + '",' +
              '"searchType":"' + Format(SearchType) + '",' +
              '"lang":"' + Langue + '",' +
              '"includeAll": true' +
            '}' +
          '}'
        );
    end;


    local procedure EffectuerAppelHTTP(APIKey: Text; BodyText: Text; var JsonResponse: JsonObject) Result: Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        BodyResponse: Text;
        URL: Text;
        ErrorToken: JsonToken;
        StatusToken: JsonToken;
    begin
        URL := 'https://webservice.tecalliance.services/pegasus-3-0/services/TecdocToCatDLB.jsonEndpoint?api_key=' + APIKey;
        Content.WriteFrom(BodyText);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        if not Client.Post(URL, Content, Response) then begin
            Error('Erreur HTTP lors de l''appel à l''API TecDoc.');
            exit(false);
        end;
        if not Response.IsSuccessStatusCode() then begin
            Error('Erreur API TecDoc : %1', Response.HttpStatusCode());
            exit(false);
        end;

        Response.Content().ReadAs(BodyResponse);
        if not JsonResponse.ReadFrom(BodyResponse) then begin
            Message('La réponse JSON est invalide ou mal formée : %1', BodyResponse);
            exit(false);
        end;

        if JsonResponse.Get('error', ErrorToken) then begin
            Message('Erreur renvoyée par l''API TecDoc : %1', ErrorToken.AsValue().AsText());
            exit(false);
        end;

        if JsonResponse.Get('status', StatusToken) then begin
            if StatusToken.AsValue().AsInteger() <> 200 then begin
                Message('La requête a échoué avec le statut : %1', StatusToken.AsValue().AsInteger());
                exit(false);
            end;
        end;

        exit(true);
    end;


    local procedure ParserResponse(JsonResponse: JsonObject; OriginalReference: Text)
    var
        ArticlesToken: JsonToken;
        ArticlesArray: JsonArray;
        Buffer: Record "TecDoc Article Buffer";
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
        OemNumbersArray: JsonArray;
        OemNumberToken: JsonToken;
        CriteriaArray: JsonArray;
        CriteriaToken: JsonToken;
        LocalCritObj: JsonObject;
        CritDesc: Text;
        FormattedValue: Text;
        ImagesArray: JsonArray;
        ImageURL: Text;
        ImgToken: JsonToken;
        ImageCount: Integer;
        OEMNum: Text[50];
        OEMBrand: Text;
        OEMObj: JsonObject;
        OEMToken: JsonToken;
    begin
        if not JsonResponse.Get('articles', ArticlesToken) then begin
            Message('Aucun tableau "articles" trouvé dans la réponse.');
            exit;
        end;
        if not ArticlesToken.IsArray() then begin
            Message('Le champ "articles" n''est pas un tableau.');
            exit;
        end;

        ArticlesArray := ArticlesToken.AsArray();
        if ArticlesArray.Count = 0 then begin
            Message('Aucun article trouvé pour la référence "%1".', OriginalReference);
            exit;
        end;

        Buffer.DeleteAll();
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
                Buffer.Init();
                Buffer.Référence := ArticleNo;
                Buffer.Fabricant := Brand;
                Buffer.Description := DescriptionValue;
                Buffer.Famille := Famille;
                Buffer.Insert(true);

                if ArticleObj.Get('oemNumbers', ArticleToken) and ArticleToken.IsArray() then begin
                    OemNumbersArray := ArticleToken.AsArray();
                    foreach OemNumberToken in OemNumbersArray do begin
                        OEMObj := OemNumberToken.AsObject();
                        if OEMObj.Get('articleNumber', OEMToken) then begin
                            OEMNum := OEMToken.AsValue().AsText();
                            if OEMObj.Get('mfrName', OEMToken) then
                                OEMBrand := OEMToken.AsValue().AsText()
                            else
                                OEMBrand := Brand;
                            if not OEMRec.Get(ArticleNo, OEMNum) then begin
                                OEMRec.Init();
                                OEMRec.ParentReference := ArticleNo;
                                OEMRec.OEMNumber := OEMNum;
                                OEMRec.Marque := OEMBrand;
                                OEMRec.Insert();
                            end;
                        end;
                    end;
                end;

                if ArticleObj.Get('articleCriteria', ArticleToken) and ArticleToken.IsArray() then begin
                    CriteriaArray := ArticleToken.AsArray();
                    foreach CriteriaToken in CriteriaArray do begin
                        LocalCritObj := CriteriaToken.AsObject();
                        if LocalCritObj.Get('criteriaDescription', ArticleToken) then
                            CritDesc := ArticleToken.AsValue().AsText()
                        else
                            CritDesc := '';
                        if LocalCritObj.Get('formattedValue', ArticleToken) then
                            FormattedValue := ArticleToken.AsValue().AsText()
                        else
                            FormattedValue := '';
                        if (CritDesc <> '') and (FormattedValue <> '') then begin
                            if not CriteriaRec.Get(ArticleNo, CritDesc) then begin
                                CriteriaRec.Init();
                                CriteriaRec.ParentReference := ArticleNo;
                                CriteriaRec.Nom := CritDesc;
                                CriteriaRec.Valeur := FormattedValue;
                                CriteriaRec.Insert();
                            end;
                        end;
                    end;
                end;

                // 2ème partie : Traitement des images et comptage
                if ArticleObj.Get('images', ArticleToken) and ArticleToken.IsArray() then begin
                    ImagesArray := ArticleToken.AsArray();
                    ImageCount := 0;
                    foreach ImgToken in ImagesArray do begin
                        if ImgToken.AsObject().Get('imageURL3200', ArticleToken) then begin
                            ImageURL := ArticleToken.AsValue().AsText();
                            ImagesRec.Init();
                            ImagesRec.ParentReference := ArticleNo;
                            ImagesRec.ImageID := GetNextImageID(ArticleNo);
                            if DownloadImage(ImageURL, ImagesRec) then begin
                                ImagesRec.Insert();
                                ImageCount += 1;
                            end;
                        end;
                    end;
                    // Mise à jour du champ nbPicture dans l'article
                    Buffer.SetRange("Référence", ArticleNo);
                    if Buffer.FindFirst() then begin
                        Buffer.nbPicture := ImageCount;
                        Buffer.Modify();
                    end;
                end;
            end;
        end;

        if Buffer.IsEmpty then
            Message('Aucun article trouvé pour la référence "%1".', OriginalReference)
        else
            PAGE.Run(page::"TecDoc Articles List", Buffer);
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
        // Import du flux dans le champ MediaSet
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
