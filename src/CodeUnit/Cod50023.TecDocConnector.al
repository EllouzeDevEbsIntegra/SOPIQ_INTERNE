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
        KeyOemNumbers: Text;
        KeyArticleCriteria: Text;
        KeyImage: Text;
        StartPos: Integer;
        EndPos: Integer;
        ArticleNo: Text;
        Brand: Text;
        Description: Text;
        Famille: Text;
        OemNumbers: Text;
        ArticleCriteria: Text;
        ImageURL: Text;
        JsonResponse: JsonObject;
        StatusToken: JsonToken;
        ErrorToken: JsonToken;
        TotalMatchingToken: JsonToken;
        TempText: Text;
        IsFirst: Boolean;
        recItem: Record Item;
        searchType: Integer;
    begin
        // 0) Verification de la référence Origine ou non
        searchType := 0;
        recItem.Reset();
        recItem.SetRange("No.", Reference);
        if recItem.FindFirst() then begin
            // La référence est un article
            if recItem."Item Class" = recItem."Item Class"::Original then begin
                // La référence est un article d'origine
                Reference := recItem."Vendor Item No.";
                searchType := 1;
            end else begin
                // La référence est un article TecDoc
                Reference := recItem."No.";
                searchType := 2;
            end;
        end else begin
            // La référence n'est pas un article
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

        // Vérifier si "totalMatchingArticles" existe pour confirmer la structure attendue
        if not JsonResponse.Get('totalMatchingArticles', TotalMatchingToken) then begin
            Message('La réponse JSON ne contient pas le champ "totalMatchingArticles". Réponse : %1', BodyText);
            exit;
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
        KeyOemNumbers := '"oemNumbers": [';
        KeyArticleCriteria := '"articleCriteria": [';
        KeyImage := '"images": [';

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

            // Extraction genericArticleDescription (Description)
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

            // Extraction oemNumbers
            // StartPos := STRPOS(ItemJson, KeyOemNumbers);
            // if StartPos > 0 then begin
            //     StartPos := StartPos + STRLEN(KeyOemNumbers);
            //     EndPos := STRPOS(COPYSTR(ItemJson, StartPos), ']');
            //     if EndPos > 0 then begin
            //         TempText := COPYSTR(ItemJson, StartPos, EndPos - 1);
            //         OemNumbers := '';
            //         IsFirst := true;
            //         while STRLEN(TempText) > 0 do begin
            //             PosObjSep := STRPOS(TempText, '},{');
            //             if PosObjSep > 0 then begin
            //                 ItemJson := COPYSTR(TempText, 1, PosObjSep + 1);
            //                 TempText := DELSTR(TempText, 1, PosObjSep + 3);
            //             end else begin
            //                 ItemJson := TempText;
            //                 TempText := '';
            //             end;

            //             StartPos := STRPOS(ItemJson, '"articleNumber": "');
            //             if StartPos > 0 then begin
            //                 StartPos := StartPos + STRLEN('"articleNumber": "');
            //                 EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
            //                 if EndPos > 0 then begin
            //                     EndPos := EndPos - 1;
            //                     if EndPos >= 0 then begin
            //                         if IsFirst then
            //                             OemNumbers := COPYSTR(ItemJson, StartPos, EndPos)
            //                         else
            //                             OemNumbers := OemNumbers + ', ' + COPYSTR(ItemJson, StartPos, EndPos);
            //                         IsFirst := false;
            //                     end;
            //                 end;
            //             end;
            //         end;
            //     end else
            //         OemNumbers := '';
            // end else
            //     OemNumbers := '';

            // Extraction articleCriteria
            // StartPos := STRPOS(ItemJson, KeyArticleCriteria);
            // if StartPos > 0 then begin
            //     StartPos := StartPos + STRLEN(KeyArticleCriteria);
            //     EndPos := STRPOS(COPYSTR(ItemJson, StartPos), ']');
            //     if EndPos > 0 then begin
            //         TempText := COPYSTR(ItemJson, StartPos, EndPos - 1);
            //         ArticleCriteria := '';
            //         IsFirst := true;
            //         while STRLEN(TempText) > 0 do begin
            //             PosObjSep := STRPOS(TempText, '},{');
            //             if PosObjSep > 0 then begin
            //                 ItemJson := COPYSTR(TempText, 1, PosObjSep + 1);
            //                 TempText := DELSTR(TempText, 1, PosObjSep + 3);
            //             end else begin
            //                 ItemJson := TempText;
            //                 TempText := '';
            //             end;

            //             StartPos := STRPOS(ItemJson, '"criteriaDescription": "');
            //             if StartPos > 0 then begin
            //                 StartPos := StartPos + STRLEN('"criteriaDescription": "');
            //                 EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
            //                 if EndPos > 0 then begin
            //                     EndPos := EndPos - 1;
            //                     if EndPos >= 0 then begin
            //                         TempText := COPYSTR(ItemJson, StartPos, EndPos);
            //                         StartPos := STRPOS(ItemJson, '"formattedValue": "');
            //                         if StartPos > 0 then begin
            //                             StartPos := StartPos + STRLEN('"formattedValue": "');
            //                             EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
            //                             if EndPos > 0 then begin
            //                                 EndPos := EndPos - 1;
            //                                 if EndPos >= 0 then begin
            //                                     if COPYSTR(ItemJson, StartPos, EndPos) <> '' then begin
            //                                         if IsFirst then
            //                                             ArticleCriteria := TempText + ': ' + COPYSTR(ItemJson, StartPos, EndPos)
            //                                         else
            //                                             ArticleCriteria := ArticleCriteria + ', ' + TempText + ': ' + COPYSTR(ItemJson, StartPos, EndPos);
            //                                         IsFirst := false;
            //                                     end;
            //                                 end;
            //                             end;
            //                         end;
            //                     end;
            //                 end;
            //             end;
            //         end;
            //     end else
            //         ArticleCriteria := '';
            // end else
            //     ArticleCriteria := '';

            // Extraction imageURL3200 (Images)
            // StartPos := STRPOS(ItemJson, KeyImage);
            // if StartPos > 0 then begin
            //     StartPos := StartPos + STRLEN(KeyImage);
            //     EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"');
            //     if EndPos > 0 then begin
            //         EndPos := EndPos - 1;
            //         if EndPos >= 0 then
            //             ImageURL := COPYSTR(ItemJson, StartPos, EndPos)
            //         else
            //             ImageURL := '';
            //     end else
            //         ImageURL := '';
            // end else
            //     ImageURL := '';

            // Insérer dans le buffer si au moins une référence est trouvée
            if ArticleNo <> '' then begin
                Buffer.Init();
                Buffer.Référence := CopyStr(ArticleNo, 1, 20); // Limiter à la longueur du champ
                Buffer.Fabricant := Brand;
                Buffer.Description := Description;
                Buffer.Famille := Famille;
                // Buffer.OemNumbers := CopyStr(OemNumbers, 1, 250); // Limiter à la longueur du champ
                // Buffer.ArticleCriteria := CopyStr(ArticleCriteria, 1, 250); // Limiter à la longueur du champ
                // Buffer.ImageURL := CopyStr(ImageURL, 1, 250); // Limiter à la longueur du champ
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
