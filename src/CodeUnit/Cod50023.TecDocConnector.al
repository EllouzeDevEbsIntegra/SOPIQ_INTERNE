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
        Buffer: Record "TecDoc Article Buffer" temporary;
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
        StartPos: Integer;
        EndPos: Integer;
        ArticleNo: Text;
        Brand: Text;
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
            Error('Erreur HTTP lors de l’appel.');
        if not Response.IsSuccessStatusCode() then
            Error('Erreur API TecDoc : %1', Response.HttpStatusCode());

        // 6) Lecture du JSON brut
        Response.Content().ReadAs(BodyText);

        // 7) Isolation du tableau "articles"
        PosArrStart := STRPOS(BodyText, '"articles":[');
        if PosArrStart = 0 then begin
            Message('Aucun tableau "articles" trouvé.');
            exit;
        end;
        OffsetStart := STRPOS(COPYSTR(BodyText, PosArrStart), '[');
        PosArrStart := PosArrStart + OffsetStart;
        OffsetEnd := STRPOS(COPYSTR(BodyText, PosArrStart), ']');
        PosArrEnd := PosArrStart + OffsetEnd - 1;
        JsonArrayPart := COPYSTR(BodyText, PosArrStart + 1, PosArrEnd - PosArrStart - 1);
        Remaining := JsonArrayPart;

        // 8) Parsing manuel et remplissage du buffer
        Buffer.DeleteAll();
        KeyArticle := '"articleNumber":"';
        KeyBrand := '"mfrName":"';
        WHILE STRLEN(Remaining) > 0 DO BEGIN
            PosObjSep := STRPOS(Remaining, '},{');
            IF PosObjSep > 0 THEN BEGIN
                ItemJson := COPYSTR(Remaining, 1, PosObjSep + 1);
                Remaining := DELSTR(Remaining, 1, PosObjSep + 3);
            END ELSE BEGIN
                ItemJson := Remaining;
                Remaining := '';
            END;

            // Extraction articleNumber
            StartPos := STRPOS(ItemJson, KeyArticle);
            IF StartPos > 0 THEN BEGIN
                StartPos := StartPos + STRLEN(KeyArticle);
                EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"') - 1;
                ArticleNo := COPYSTR(ItemJson, StartPos, EndPos);
            END ELSE
                ArticleNo := '';

            // Extraction mfrName
            StartPos := STRPOS(ItemJson, KeyBrand);
            IF StartPos > 0 THEN BEGIN
                StartPos := StartPos + STRLEN(KeyBrand);
                EndPos := STRPOS(COPYSTR(ItemJson, StartPos), '"') - 1;
                Brand := COPYSTR(ItemJson, StartPos, EndPos);
            END ELSE
                Brand := '';

            Buffer.Init();
            Buffer.Référence := ArticleNo;
            Buffer.Fabricant := Brand;
            Buffer.Insert(true);
        END;

        // 9) Afficher la liste
        PAGE.Run(Page::"TecDoc Articles", Buffer);
    end;
}
