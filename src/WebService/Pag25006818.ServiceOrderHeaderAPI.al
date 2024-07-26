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
                field("WorkDescription"; GetWorkDescription())
                {
                    Caption = 'Description Travail';
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
                field(DocStatus; "Doc. Statut Desc.")
                {
                    Caption = 'Statut Document';
                }

            }
        }

    }

}