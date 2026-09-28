// Fournisseurs d'un fabricant — table « Vendor By Manufacturer » (50019, extension SOPICBC16A).
//
// POURQUOI CETTE PAGE
//   L'API Manufacturer ne rend qu'UN fournisseur : celui coché par défaut. L'écran de création
//   d'une référence équivalente (Reapro) a besoin de la LISTE des fournisseurs du fabricant, pour
//   ne proposer que ceux-là au lieu des centaines de fiches de la société.
//
//   Relevé sur SOPIQ le 2026-09-26 : 112 fabricants, dont 103 ont un fournisseur par défaut. Les
//   9 autres n'ont chacun qu'un seul fournisseur — sans cette liste, l'écran rabattrait sur tous
//   les fournisseurs de la société alors que la bonne réponse est connue.
//
//   Elle rend aussi « Vendor No Format » : le gabarit qui construit la référence fournisseur à
//   partir de la référence article ('A@' donne A000078902380). Ce format appartient au COUPLE
//   fabricant + fournisseur, pas au fabricant seul — FAB0001 le porte sur deux de ses sept
//   fournisseurs. L'écran ne peut donc le calculer qu'une fois le fournisseur choisi.
//
// LECTURE SEULE : aucun écran Reapro ne modifie ce référentiel, il se tient dans Business Central.
// Le cloisonnement par société est celui de l'appel : chaque société a sa propre table.
page 25006938 "Vendor By Manufacturer API"
{
    PageType = API;
    SourceTable = "Vendor By Manufacturer";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'vendorByManufacturer';
    EntitySetName = 'vendorByManufacturer';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    Caption = 'Vendor By Manufacturer API';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                }
                field(manufacturerCode; Rec."Manufacturer Code")
                {
                    ApplicationArea = All;
                    Caption = 'manufacturerCode';
                }
                field(vendorCode; Rec."Vendor Code")
                {
                    ApplicationArea = All;
                    Caption = 'vendorCode';
                }
                field(defaultVendor; Rec."Default Vendor")
                {
                    ApplicationArea = All;
                    Caption = 'defaultVendor';
                }
                // Gabarit de la référence fournisseur ('A@', '#########-###'…), vide le plus souvent.
                field(vendorNoFormat; Rec."Vendor No Format")
                {
                    ApplicationArea = All;
                    Caption = 'vendorNoFormat';
                }
                // Nom du fabricant : FlowField, il faut le calculer avant de le servir.
                field(manufacturerName; Rec.fabricant)
                {
                    ApplicationArea = All;
                    Caption = 'manufacturerName';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        // Sans ce calcul, le FlowField « fabricant » sort vide de l'API.
        Rec.CalcFields(fabricant);
    end;
}
