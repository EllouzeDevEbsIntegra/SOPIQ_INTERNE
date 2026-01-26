page 25006980 "Transporter Shipment List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Sales Shipment Header";
    SourceTableView = sorting("No.") order(descending);
    Caption = 'Liste des Expéditions Transporteur';
    CardPageId = "Posted Sales Shipment";

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filtres';
                field(FilterShippingAgent; FilterShippingAgent)
                {
                    ApplicationArea = All;
                    Caption = 'Code Transporteur';
                    TableRelation = "Shipping Agent";
                    trigger OnValidate()
                    begin
                        SetRecFilters();
                        CurrPage.Update(false);
                    end;
                }
                field(FilterCustomerNo; FilterCustomerNo)
                {
                    ApplicationArea = All;
                    Caption = 'Code Client';
                    TableRelation = Customer;
                    trigger OnValidate()
                    var
                        Cust: Record Customer;
                    begin
                        if Cust.Get(FilterCustomerNo) then
                            FilterCustomerName := Cust.Name
                        else
                            FilterCustomerName := '';
                        SetRecFilters();
                        CurrPage.Update(false);
                    end;
                }
                field(FilterCustomerName; FilterCustomerName)
                {
                    ApplicationArea = All;
                    Caption = 'Nom Client';
                    Editable = false;
                }

            }
            repeater(Group)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.") { ApplicationArea = All; }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name") { ApplicationArea = All; }
                field("Shipping Agent Code"; Rec."Shipping Agent Code") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Ship-to City"; Rec."Ship-to City") { ApplicationArea = All; }
                field("Line Amount"; Rec."Line Amount") { ApplicationArea = All; }
                field("N° récépissé"; "N° récépissé") { ApplicationArea = All; }
                field("récépissé date"; "récépissé date") { ApplicationArea = All; }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateTransporterOrder)
            {
                ApplicationArea = All;
                Caption = 'Créer Transporter Order';
                Image = CreateDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SSH: Record "Sales Shipment Header";
                    Cust: Record Customer;
                    TransporterAPI: Codeunit "Transporter API Integration";
                    TransporterSetup: Record "Transporter Setup";
                    DialogPage: Page "Transporter Order Dialog";
                    TotalTTC: Decimal;
                    TotalColis: Integer;
                    TotalCr: Decimal;
                    TypeColisOpt: Enum "Type Colis";
                    TypeColisTxt: Text;
                    PaymentMethodOpt: Option NP,PM;
                    CommentTxt: Text;
                    ShipmentNos: Text;
                    JsonPayload: JsonObject;
                    DefaultSetupCodeTxt: Label 'DEFAULT', Locked = true;
                    CustNo: Code[20];
                    ContreRemboursement: Boolean;
                    PostCodeInt: Integer;
                    DeliveryGovernorate: Text;
                    OrderId: Code[20];
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    FileName: Text;
                    SISalesCodeUnit: Codeunit SISalesCodeUnit;
                    TempShipmentNo: Text;
                begin
                    TotalTTC := 0;

                    CurrPage.SetSelectionFilter(SSH);
                    if not SSH.FindSet() then
                        Error('Veuillez sélectionner au moins une expédition.');

                    // On prend le premier client pour référence
                    CustNo := SSH."Sell-to Customer No.";
                    Cust.Get(CustNo);

                    // Vérification de la cohérence (même client) et calculs
                    repeat
                        if SSH."Sell-to Customer No." <> CustNo then
                            Error('Toutes les expéditions sélectionnées doivent appartenir au même client (%1).', CustNo);

                        TempShipmentNo := '';
                        if ShipmentNos = '' then
                            TempShipmentNo := 'BLs : '
                        else
                            TempShipmentNo := '/';

                        if StrLen(SSH."No.") > 5 then
                            TempShipmentNo += CopyStr(SSH."No.", StrLen(SSH."No.") - 4)
                        else
                            TempShipmentNo += SSH."No.";

                        if StrLen(ShipmentNos) + StrLen(TempShipmentNo) <= 90 then
                            ShipmentNos += TempShipmentNo;

                        // Calcul du Total TTC pour ce BL
                        SSH.CalcFields("Line Amount");
                        TotalTTC += SSH."Line Amount";
                    until SSH.Next() = 0;

                    // Vérification du champ "Contre remboursement" (50001)
                    ContreRemboursement := GetContreRemboursement(Cust);

                    if not ContreRemboursement then
                        TotalTTC := 0;

                    // Ouverture du Dialog
                    DeliveryGovernorate := Cust.City;

                    DialogPage.SetData(Cust.Name, Cust.Address, Cust.City, Cust."Phone No.", Cust."E-Mail", DeliveryGovernorate, TotalTTC, ShipmentNos);

                    if DialogPage.RunModal() = Action::OK then begin
                        DialogPage.GetData(TotalColis, TotalCr, TypeColisOpt, CommentTxt, DeliveryGovernorate, PaymentMethodOpt);

                        TypeColisTxt := TypeColisOpt.Names().Get(TypeColisOpt.Ordinals().IndexOf(TypeColisOpt.AsInteger()));

                        // Préparation du JSON
                        JsonPayload.Add('deliveryName', Cust.Name);
                        JsonPayload.Add('deliveryPhone', DelChr(Cust."Phone No.", '=', ' +()'));
                        JsonPayload.Add('deliveryAddress', Cust.Address);
                        JsonPayload.Add('deliveryCity', Cust.City);

                        if Evaluate(PostCodeInt, Cust."Post Code") then
                            JsonPayload.Add('deliveryCp', PostCodeInt)
                        else
                            JsonPayload.Add('deliveryCp', 0);

                        JsonPayload.Add('deliveryGovernorat', DeliveryGovernorate);
                        JsonPayload.Add('deliveryEmail', Cust."E-Mail");
                        JsonPayload.Add('totalColis', TotalColis);
                        JsonPayload.Add('totalCr', TotalCr);
                        JsonPayload.Add('paymentMethod', Format(PaymentMethodOpt));
                        JsonPayload.Add('typeColis', TypeColisTxt);
                        JsonPayload.Add('comment', CommentTxt);

                        // Envoi API
                        if not TransporterSetup.Get(DefaultSetupCodeTxt) then
                            if not TransporterSetup.FindFirst() then
                                Error('Transporter Setup not found.');

                        OrderId := TransporterAPI.CreateOrder(JsonPayload, TransporterSetup);

                        if OrderId <> '' then begin
                            if SSH.FindSet() then
                                repeat
                                    SISalesCodeUnit.modifyTransporterOrderNo(SSH, Format(OrderId));
                                until SSH.Next() = 0;

                            TransporterAPI.GetOrderPdf(OrderId, TransporterSetup, TempBlob);
                            if TempBlob.HasValue() then begin
                                TempBlob.CreateInStream(InStr);
                                FileName := 'Order_' + Format(OrderId) + '_' + ssh."Sell-to Customer No." + '.pdf';
                                DownloadFromStream(InStr, '', '', '', FileName);
                            end;
                            Message('Transporter Order %1 créé avec succès.', OrderId);
                        end;
                    end;
                end;
            }

            action(SendEnvelope)
            {
                ApplicationArea = All;
                Caption = 'Envoyer une enveloppe';
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Cust: Record Customer;
                    TransporterAPI: Codeunit "Transporter API Integration";
                    TransporterSetup: Record "Transporter Setup";
                    DialogPage: Page "Transporter Order Dialog";
                    JsonPayload: JsonObject;
                    DefaultSetupCodeTxt: Label 'DEFAULT', Locked = true;
                    OrderId: Code[20];
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    FileName: Text;
                    TotalColis: Integer;
                    TotalCr: Decimal;
                    TypeColisOpt: Enum "Type Colis";
                    CommentTxt: Text;
                    DeliveryGovernorate: Text;
                    PaymentMethodOpt: Option NP,PM;
                    PostCodeInt: Integer;
                    JsonText: Text;
                begin
                    if FilterCustomerNo = '' then
                        Error('Veuillez sélectionner un client dans le filtre pour envoyer une enveloppe.');

                    Cust.Get(FilterCustomerNo);
                    DeliveryGovernorate := Cust.City;

                    // Initialisation du dialogue avec les données client, sans montant CR et sans BLs
                    DialogPage.SetData(Cust.Name, Cust.Address, Cust.City, Cust."Phone No.", Cust."E-Mail", DeliveryGovernorate, 0, '');
                    // Configuration spécifique pour l'enveloppe (bloque le type et met qté à 1)
                    DialogPage.SetEnvelopeMode();

                    if DialogPage.RunModal() = Action::OK then begin
                        DialogPage.GetData(TotalColis, TotalCr, TypeColisOpt, CommentTxt, DeliveryGovernorate, PaymentMethodOpt);

                        JsonPayload.Add('deliveryName', Cust.Name);
                        JsonPayload.Add('deliveryPhone', DelChr(Cust."Phone No.", '=', ' +()'));
                        JsonPayload.Add('deliveryAddress', Cust.Address);
                        JsonPayload.Add('deliveryCity', Cust.City);

                        if Evaluate(PostCodeInt, Cust."Post Code") then
                            JsonPayload.Add('deliveryCp', PostCodeInt)
                        else
                            JsonPayload.Add('deliveryCp', 0);

                        JsonPayload.Add('deliveryGovernorat', DeliveryGovernorate);
                        JsonPayload.Add('deliveryEmail', Cust."E-Mail");
                        JsonPayload.Add('totalColis', TotalColis);
                        JsonPayload.Add('totalCr', TotalCr);
                        JsonPayload.Add('paymentMethod', Format(PaymentMethodOpt));
                        JsonPayload.Add('typeColis', TypeColisOpt.Names().Get(TypeColisOpt.Ordinals().IndexOf(TypeColisOpt.AsInteger())));
                        JsonPayload.Add('comment', CommentTxt);

                        JsonPayload.WriteTo(JsonText);
                        //Message('Payload envoyé : %1', JsonText);

                        if not TransporterSetup.Get(DefaultSetupCodeTxt) then
                            if not TransporterSetup.FindFirst() then
                                Error('Transporter Setup not found.');

                        OrderId := TransporterAPI.CreateOrder(JsonPayload, TransporterSetup);

                        if OrderId <> '' then begin
                            TransporterAPI.GetOrderPdf(OrderId, TransporterSetup, TempBlob);
                            if TempBlob.HasValue() then begin
                                TempBlob.CreateInStream(InStr);
                                FileName := 'Order_' + Format(OrderId) + '_' + Cust."No." + '.pdf';
                                DownloadFromStream(InStr, '', '', '', FileName);
                            end;
                            Message('Transporter Order %1 créé avec succès.', OrderId);
                        end;
                    end;
                end;
            }
        }
    }



    local procedure GetContreRemboursement(Cust: Record Customer): Boolean
    var
        RRef: RecordRef;
        FRef: FieldRef;
    begin
        // Utilisation de RecordRef pour accéder au champ 50001 de manière dynamique
        // au cas où l'extension de table n'est pas visible directement ici.
        RRef.GetTable(Cust);
        if RRef.FieldExist(50001) then begin
            FRef := RRef.Field(50001);
            if FRef.Type = FieldType::Boolean then
                exit(FRef.Value);
        end;
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetRecFilters();
    end;

    local procedure SetRecFilters()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("N° récépissé", '');

        if FilterCustomerNo <> '' then begin
            Rec.SetRange("Sell-to Customer No.", FilterCustomerNo);
            if FilterShippingAgent <> '' then
                Rec.SetRange("Shipping Agent Code", FilterShippingAgent)
            else
                Rec.SetRange("Shipping Agent Code");
        end else begin
            // N'afficher aucune ligne si le client n'est pas sélectionné
            Rec.SetRange("Sell-to Customer No.", 'NULL_VALUE');
        end;
        Rec.FilterGroup(0);
    end;

    var
        FilterCustomerNo: Code[20];
        FilterCustomerName: Text[100];
        FilterShippingAgent: Code[10];
}