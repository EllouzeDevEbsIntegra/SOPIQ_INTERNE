// Prix des lignes de bon de sortie a la validation.
//
// Probleme corrige : la codeunit "SalesSubscribers" de l'extension SOPICBC16A calcule
// le prix d'un BS a partir du COUT de la ligne :
//     "Prix Vente 1" := "Unit Cost" * (1 + % marge);
//     "Prix Vente 2" := "Prix Vente 1" * (1 - % remise);
// Elle ignore le parametre "Garder prix initial" (champ "Same Price Order/BS" des
// parametres ventes), et surtout, quand le cout de la ligne vaut zero, elle produit un
// prix de vente nul. Ces lignes deviennent ensuite des BL a zero lors du transfert
// BS vers BL (report 50003), et le document sort faux.
//
// Mesure sur STE COPIM en septembre 2026 : 1 293 lignes de BS a prix nul, toutes avec
// un cout nul, sans exception.
//
// Pourquoi ici et pas dans un abonne a l'insertion de la ligne : SOPICBC16A s'abonne
// deja a "Sales Shipment Line" OnAfterInsertEvent. Deux abonnes sur le meme evenement
// s'executent dans un ordre non garanti et ecrivent les memes champs, le resultat
// depend de qui passe en dernier. On intervient donc apres la validation complete du
// document, une seule fois, sans Commit, dans la meme transaction que la validation.
//
// Regle appliquee, celle voulue par le metier :
//   si "Garder prix initial" est vrai OU si le cout de la ligne est nul
//       -> on reprend le prix et la remise d'origine, deja portes par la ligne
//          d'expedition ("Unit Price" et "% Discount")
//   sinon
//       -> on ne touche a rien, le calcul depuis le cout reste en place
codeunit 50033 "Prix BS Validation"
{
    Permissions = tabledata "Sales Shipment Line" = rm;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure ReprendrePrixOrigineSurBS(var SalesHeader: Record "Sales Header"; SalesShptHdrNo: Code[20])
    begin
        if SalesShptHdrNo = '' then
            exit;

        TraiterExpedition(SalesShptHdrNo);
    end;

    procedure TraiterExpedition(NoExpedition: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesSetup: Record "Sales & Receivables Setup";
        GarderPrixInitial: Boolean;
    begin
        if not SalesShipmentHeader.Get(NoExpedition) then
            exit;

        // Seuls les bons de sortie sont concernes, pas les bons de livraison.
        if not SalesShipmentHeader.BS then
            exit;

        SalesSetup.Get();
        GarderPrixInitial := SalesSetup."Same Price Order/BS";

        SalesShipmentLine.SetRange("Document No.", NoExpedition);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetFilter(Quantity, '<>%1', 0);
        if not SalesShipmentLine.FindSet(true) then
            exit;

        repeat
            if GarderPrixInitial or (SalesShipmentLine."Unit Cost" = 0) then
                ReprendrePrixOrigine(SalesShipmentLine);
        until SalesShipmentLine.Next() = 0;
    end;

    local procedure ReprendrePrixOrigine(var SalesShipmentLine: Record "Sales Shipment Line")
    var
        PrixRemise: Decimal;
    begin
        PrixRemise := SalesShipmentLine."Unit Price" * (1 - (SalesShipmentLine."% Discount" / 100));

        SalesShipmentLine."Prix Vente 1" := SalesShipmentLine."Unit Price";
        SalesShipmentLine."Prix Vente 2" := PrixRemise;
        SalesShipmentLine."Line Discount %" := SalesShipmentLine."% Discount";
        SalesShipmentLine."Montant ligne HT BS" := PrixRemise * SalesShipmentLine.Quantity;
        SalesShipmentLine."Montant ligne TTC BS" :=
            SalesShipmentLine."Montant ligne HT BS" * (1 + (SalesShipmentLine."VAT %" / 100));

        SalesShipmentLine.Modify();
    end;
}
