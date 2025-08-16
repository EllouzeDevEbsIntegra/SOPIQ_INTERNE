page 25006998 "Article Tecdoc Details"
{
    PageType = Card;
    SourceTable = "TecDoc Article Buffer";
    Caption = 'Détails Article Tecdoc';
    layout
    {
        area(content)
        {
            group("Informations Générales")
            {
                field(Référence; Référence) { ApplicationArea = All; Editable = false; }
                field(Description; Description) { ApplicationArea = All; Editable = false; }
                field(Fabricant; Fabricant) { ApplicationArea = All; Editable = false; }
                field(Famille; Famille) { ApplicationArea = All; Editable = false; }
                field(LastUpdated; LastUpdated) { ApplicationArea = All; Editable = false; Caption = 'Dernière mise à jour'; }
            }
            group("Liste des OEM")
            {
                part(OEMPart; "TecDoc OEM Part")
                {
                    Editable = false;
                    SubPageLink = ParentReference = FIELD("Référence");
                }
            }
            group("Critères")
            {
                part(CriteriaPart; "TecDoc Criteria Part")
                {
                    Editable = false;
                    SubPageLink = ParentReference = FIELD("Référence");
                }
            }
            group("Images")
            {
                part(ImageDetail1; "TecDoc Image Detail 1")
                {
                    Editable = false;
                    Visible = visiblePicture1;
                    SubPageLink = ParentReference = FIELD("Référence"), ImageID = filter(1);
                }
                part(ImageDetail2; "TecDoc Image Detail 2")
                {
                    Editable = false;
                    Visible = visiblePicture2;
                    SubPageLink = ParentReference = FIELD("Référence"), ImageID = filter(2);
                }
                part(ImageDetail3; "TecDoc Image Detail 3")
                {
                    Editable = false;
                    Visible = visiblePicture3;
                    SubPageLink = ParentReference = FIELD("Référence"), ImageID = filter(3);
                }
            }
        }
    }
    var

        visiblePicture1, visiblePicture2, visiblePicture3 : Boolean;
    trigger OnOpenPage()
    begin
        // Initialiser les variables pour contrôler la visibilité des images
        visiblePicture1 := false;
        visiblePicture2 := false;
        visiblePicture3 := false;

        // Vérifier si l'image 1 est présente
        if nbPicture = 0 then begin
            visiblePicture1 := false;
            visiblePicture2 := false;
            visiblePicture3 := false;
        end;

        // Vérifier si l'image 2 est présente
        if nbPicture = 1 then begin
            visiblePicture1 := true;
            visiblePicture2 := false;
            visiblePicture3 := false;
        end;
        if nbPicture = 2 then begin
            visiblePicture1 := true;
            visiblePicture2 := true;
            visiblePicture3 := false;
        end;
        if nbPicture > 2 then begin
            visiblePicture1 := true;
            visiblePicture2 := true;
            visiblePicture3 := true;
        end;
    end;

}
