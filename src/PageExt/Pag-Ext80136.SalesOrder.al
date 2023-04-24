pageextension 80136 "Sales Order" extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        modify(Valider)
        {
            Visible = false;
        }
        addafter(Valider)
        {
            action("Valider 2")
            {
                ApplicationArea = All;
                Caption = 'Valider', comment = 'NLB="Valider"';
                Ellipsis = true;
                Image = PostOrder;
                Promoted = true;
                PromotedCategory = Category6;
                ToolTip = 'Validation aprés vérification des encours autorisés';
                trigger OnAction()
                var
                    myInt: Integer;
                    SalesPost: Codeunit "Sales-Post";
                    NoSeriesMgt: Codeunit 396;
                    SalesSetup: Record 311;
                    confirmation: label 'Générer un bon de sortie ?';
                    confirmation1: label 'Générer une expédition ?';
                    TypeextVide: label 'Type expédition doit être mentionner ?';
                    confirmationcanceled: label 'Validation annulée';
                    SalesOrder: Record 36;
                    options: Text[50];//'(Livrer/ Bon de sortie),Facturer';
                    TypeExped: text[20];
                    Choix: label 'Générer :';
                    ShipmenCard: Page "Posted Sales Shipment";
                    SalesShipmentHead: Record "Sales Shipment Header";
                    SalesOrder2: Record "Sales Header";
                    FacturerQst: Text[9];
                    UserSetup: Record "User Setup";
                    recCustomer: Record Customer;
                    CustomerEncour, CreditAutorise : Decimal;
                    nbFactureNPautorise: Integer;
                    Verified: Boolean;
                    Error: Text;
                begin
                    // Initialisation
                    recCustomer.Reset();
                    CreditAutorise := 0;
                    CustomerEncour := 0;
                    Verified := false;
                    Error := 'Client bloqué : \';



                    if (Status = Status::Open) then
                        Error('Statut doit être égal à %1 dans En-tête vente: Type document= %2, N°=%3. La valeur actuelle est %4', Status::Released, rec."Document Type", rec."No.", rec.Status::Open) else begin
                        recCustomer.SetRange("No.", "Sell-to Customer No.");
                        if recCustomer.FindFirst() then begin
                            recCustomer.CalcFields("Opened Invoice", "Shipped Not Invoiced BL", "Return Receipts Not Invoiced");

                            // Message('%1', rec."Old Amount Including VAT");
                            // Message('No. : %1 - Sell-to Customer No. : %2', recCustomer."No.", "Sell-to Customer No.");
                            nbFactureNPautorise := recCustomer."Nb Facture NP";
                            CreditAutorise := recCustomer."Credit Limit (LCY)";
                            CustomerEncour := recCustomer."Opened Invoice" + recCustomer."Shipped Not Invoiced BL" + rec."Old Amount Including VAT" + recCustomer."Return Receipts Not Invoiced";

                            if (CustomerEncour < CreditAutorise) then
                                Verified := true else
                                Error := Error + '* Crédit autorisé du client est dépassé ! \';

                            if ("Nbr factures impayées" > "nbFactureNPautorise") THEN begin
                                Verified := false;
                                Error := Error + '* Nombre de factures non réglées du client est dépassé ! \';
                            end;



                        end;


                        if (Verified) then begin
                            FacturerQst := 'Facturer';
                            UserSetup.Get(UserId);
                            TestField(Status, Status::Released);
                            TypeExped := format("Expédition type");
                            if UserSetup."Allow Invoice Option" then
                                options := TypeExped + ',' + FacturerQst
                            else
                                options := TypeExped;
                            CASE STRMENU(Options, ExpeditionOrInvoice(Rec), Choix) OF
                                1:
                                    begin

                                        case "Expédition type" of
                                            "Expédition type"::" ":
                                                begin
                                                    error(TypeextVide);
                                                end;

                                            "Expédition type"::"Bon de sortie":
                                                begin
                                                    //  If Confirm(confirmation, True, False) then begin
                                                    SalesOrder := rec;
                                                    SalesSetup.get;
                                                    SalesSetup.TestField("Posted BC");
                                                    // ShipNo := NoSeriesMgt.GetNextNo(SalesSetup."Posted BC", SalesOrder."Posting Date", true);
                                                    // SalesOrder."Shipping No." := ShipNo;
                                                    SalesOrder.BS := true;
                                                    SalesOrder.Ship := true;
                                                    SalesOrder.MODIFY;
                                                    CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesOrder);
                                                    // ArchiveBS(SalesOrder."Shipping No.");
                                                    SalesOrder.bs := false;
                                                    SalesOrder.Ship := false;
                                                    SalesOrder.MODIFY;
                                                    SalesShipmentHead.Reset();
                                                    SalesShipmentHead.SetRange("Order No.", SalesOrder."No.");
                                                    IF SalesShipmentHead.FindLast() then begin
                                                        page.Run(130, SalesShipmentHead);
                                                        SalesOrder."Statut B2B" := SalesOrder."Statut B2B"::"Livré";
                                                        SalesOrder.Modify();
                                                    end;
                                                    // end else begin
                                                    //     message(confirmationcanceled);
                                                    // end;
                                                end;
                                            "Expédition type"::"Expédition":
                                                begin
                                                    // If Confirm(confirmation1, True, False) then begin
                                                    SalesOrder := rec;
                                                    SalesSetup.get;
                                                    // ShipNo := NoSeriesMgt.GetNextNo(SalesSetup."Posted Shipment Nos.", SalesOrder."Posting Date", true);
                                                    // SalesOrder."Shipping No." := ShipNo;
                                                    SalesOrder.Ship := true;
                                                    SalesOrder.MODIFY;
                                                    CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesOrder);
                                                    SalesOrder.Ship := false;
                                                    SalesOrder.MODIFY;
                                                    SalesShipmentHead.Reset();
                                                    SalesShipmentHead.SetRange("Order No.", SalesOrder."No.");
                                                    IF SalesShipmentHead.FindLast() then begin
                                                        page.Run(130, SalesShipmentHead);
                                                        SalesOrder."Statut B2B" := SalesOrder2."Statut B2B"::"Livré";
                                                        SalesOrder.Modify();
                                                    end;
                                                    // end else begin
                                                    //     message(confirmationcanceled);
                                                    // end;
                                                end;
                                        end;
                                    end;///livraion/facture
                                2:
                                    begin
                                        SalesOrder := rec;
                                        SalesOrder.Invoice := true;
                                        SalesOrder.MODIFY;
                                        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesOrder);
                                    end;
                            end;
                        end
                        else begin
                            Message(Error);
                        end;
                    end;


                end;
            }

        }
    }

    var
        myInt: Integer;

    local procedure ExpeditionOrInvoice(var SalesOrder: record "Sales Header"): Integer
    var
        lsalesline: Record "Sales Line";
    begin
        lsalesline.reset;
        lsalesline.setrange("Document Type", SalesOrder."Document Type");
        lsalesline.setrange("Document No.", SalesOrder."No.");
        lsalesline.SetFilter("Quantity Shipped", '>%1', 0);
        if lsalesline.FindFirst then
            exit(2) else
            exit(1);

    end;
}