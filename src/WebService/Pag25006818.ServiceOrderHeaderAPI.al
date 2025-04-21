page 25006818 "Service Order Header API"
{
    PageType = API;
    Caption = 'Commande Service';
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'ServOrderHeader';
    EntitySetName = 'ServOrderHeader';
    SourceTable = "Service Header EDMS";
    DelayedInsert = true;
    ModifyAllowed = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(OrderDate; "Order Date")
                {
                    Caption = 'Date Commande';
                }
                field(DealType; "Deal Type")
                {
                    Caption = 'Type Affaire';
                }
                field(DocumentType; "Document Type")
                {
                    Caption = 'Type Document';
                }
                field(DocumentNo; "No.")
                {
                    Caption = 'Document N°';
                }
                field("TypeSrv"; "Type Booking")
                {
                    Caption = 'Type Prestation';
                }
                field("WorkDescription"; workDescription)
                {
                    Caption = 'Description Travail';
                    Editable = true;
                }
                // field("Customer"; "Sell-to Customer No.")
                // {
                //     Caption = 'Client';
                // }

                field("Customer"; "Bill-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(CustomerName; "Sell-to Customer Name")
                {
                    Caption = 'Nom Client';
                }

                field(PhoneNo; "Mobile Phone No.")
                {
                    Caption = 'Téléphone Mobile';
                }
                field(Vsn; "Vehicle Serial No.")
                {
                    Caption = 'Numéro de série du véhicule';

                }
                field(VIN; VIN)
                {
                    Caption = 'VIN';
                }

                field(VehicleRegistNo; "Vehicle Registration No.")
                {
                    Caption = 'Immatriculation';

                }
                field("Make"; "Make Code")
                {
                    Caption = 'Marque';
                }
                field("Model"; "Model Code")
                {
                    Caption = 'Modèle';
                }
                field(DocumentStatusCode; "Document Status")
                {
                    Caption = 'Code Statut Document';
                }
                field(DocStatus; "Doc. Statut Desc.")
                {
                    Caption = 'Description Statut Document';
                }
                field(CodeStatus; "Status")
                {
                    Caption = 'Statut';
                }
                field("ServiceAdvisor"; "Service Advisor")
                {
                    Caption = 'Conseiller';
                }
                field(km; "Variable Field Run 1")
                {
                    Caption = 'Kilométrage';
                }
                field(fuel; fuel)
                {
                    Caption = 'Carburant';
                }
                field(Location; "Location Code")
                {
                    Caption = 'Code Magasin';
                }

                field(Lavage; "Type Lavage")
                {
                    Caption = 'Lavage';
                }
                field(CarteGrise; "Carte Grise")
                {
                    Caption = 'Carte Grise';
                }
                field(Assurance; "Assurance")
                {
                    Caption = 'Assurance';
                }
                field(AccessoireTel; "Accessoire Tel")
                {
                    Caption = 'Accessoire Téléphone';
                }

                field(Tapis; "Tapis")
                {
                    Caption = 'Tapis de sol';
                }
                field(Roue; Roue)
                {
                    Caption = 'Roue de secours';
                }
                field(CleRoue; "Cle Roue")
                {
                    Caption = 'Clé de roue sécurité';
                }
                field(Compresseur; "Compresseur")
                {
                    Caption = 'Compresseur';
                }
                field(TriangePanne; "Triange Panne")
                {
                    Caption = 'Triangle de panne';
                }
                field(Objet; Objet)
                {
                    Caption = 'Objet laissé';
                }
                field(Observation; Observation)
                {
                    Caption = 'Observation';
                }



            }
        }

    }
    var
        workDescription: Text[250];

    trigger OnModifyRecord(): Boolean
    begin
        if workDescription <> '' then begin
            rec.SetWorkDescription(workDescription);
        end
    end;
}