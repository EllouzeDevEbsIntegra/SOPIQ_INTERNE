page 25006836 "Recu Caisse Document API"
{
    PageType = API;
    SourceTable = "Recu Caisse Document";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'recuCaisseDocumentAPI';
    EntitySetName = 'recuCaisseDocumentAPI';
    DelayedInsert = true;
    ODataKeyFields = "No Recu", "Line No";

    layout
    {
        area(Content)
        {
            group("Document")
            {
                field(NoRecu; "No Recu") { Caption = 'N° Reçu'; }
                field(LineNo; "Line No") { Caption = 'N° Ligne'; }
                field(type; type) { Caption = 'Type Document'; }
                field(CustomerNo; "Customer No") { Caption = 'Client'; }
                field(DocumentNo; "Document No") { Caption = 'N° Document'; }
                field(Libelle; Libelle) { Caption = 'Libellé'; }
                field(TotalTTC; "Total TTC") { Caption = 'Total TTC'; }
                field(MntReg; "Montant Reglement") { Caption = 'Montant Règlement'; }
            }
        }
    }
}
