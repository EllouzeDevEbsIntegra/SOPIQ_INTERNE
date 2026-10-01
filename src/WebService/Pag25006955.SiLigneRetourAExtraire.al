// Les lignes de reception retour que Business Central proposerait a l'extraction sur un
// avoir brouillon, pour un client donne.
//
// C'est la meme selection que la page « Extraire lignes réception retour » du bouton : les
// lignes de reception du client facture qu'il reste a facturer. Le filtre sur le reste a
// facturer est pose ici.
//
//   GET /api/sopiq/interne/v1.0/companies({id})/SiLigneRetourAExtraire
//       ?$filter=billToCustomerNo eq '41000845'
//
// Lecture seule.
page 25006955 "Si Ligne Retour A Extraire"
{
    PageType = API;
    SourceTable = "Return Receipt Line";
    APIPublisher = 'sopiq';
    APIGroup = 'interne';
    APIVersion = 'v1.0';
    EntityName = 'SiLigneRetourAExtraire';
    EntitySetName = 'SiLigneRetourAExtraire';
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Return Receipt Line" = r,
                  tabledata "Return Receipt Header" = r;

    layout
    {
        area(Content)
        {
            repeater(Lignes)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'SystemId', Locked = true;
                }
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'N° réception retour';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'N° ligne';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Date';
                }
                field(billToCustomerNo; Rec."Bill-to Customer No.")
                {
                    Caption = 'Client facturé';
                }
                field(sellToCustomerNo; Rec."Sell-to Customer No.")
                {
                    Caption = 'Client';
                }
                field(bs; EstRetourBonDeSortie)
                {
                    Caption = 'Retour de bon de sortie';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'N° article';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Désignation';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantité reçue';
                }
                field(returnQtyRcdNotInvd; Rec."Return Qty. Rcd. Not Invd.")
                {
                    Caption = 'Reste à facturer';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unité de mesure';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Prix unitaire';
                }
                field(lineDiscountPct; Rec."Line Discount %")
                {
                    Caption = 'Remise en pourcentage';
                }
                field(amount; Rec.Amount)
                {
                    Caption = 'Montant HT';
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    Caption = 'Montant TTC';
                }
            }
        }
    }

    var
        EstRetourBonDeSortie: Boolean;
        FiltreClientErr: Label 'Précisez le client, par exemple $filter=billToCustomerNo eq ''41000845''.';

    trigger OnOpenPage()
    begin
        if Rec.GetFilters() = '' then
            Error(FiltreClientErr);

        Rec.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
    end;

    trigger OnAfterGetRecord()
    var
        Reception: Record "Return Receipt Header";
    begin
        EstRetourBonDeSortie := false;
        if Reception.Get(Rec."Document No.") then
            EstRetourBonDeSortie := Reception.BS;
    end;
}
