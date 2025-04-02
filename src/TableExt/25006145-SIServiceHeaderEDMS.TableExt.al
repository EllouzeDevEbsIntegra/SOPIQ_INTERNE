tableextension 80250 "Service Header EDMS" extends "Service Header EDMS" //25006145
{
    fields
    {
        modify("Control Performed")
        {
            trigger OnBeforeValidate()
            begin
                if ("Initiator Code" = '') then Error('Veuillez sélectionner l''Initiateur SVP !');
            end;
        }
        modify("Initiator Code")
        {
            trigger OnAfterValidate()
            var
                SalespersonPurchaser: Record "Salesperson/Purchaser";
            begin
                SalespersonPurchaser.Reset();
                SalespersonPurchaser.SetRange(Code, rec."Initiator Code");
                if SalespersonPurchaser.FindFirst() then rec."Initiator Name" := SalespersonPurchaser.Name;
            end;
        }
        field(80250; "Vehicule Prete"; boolean)
        {
            caption = 'Vehicule Prête';
            DataClassification = ToBeClassified;
            InitValue = false;
        }
        field(80251; "Masquer"; Boolean)
        {
            Caption = 'Masquer';
            DataClassification = ToBeClassified;
            InitValue = false;
        }
        field(80252; "Initiator Name"; TEXT[50])
        {
            DataClassification = ToBeClassified;
        }
    }
    procedure SI_InsertServPackage()
    var
        SPVersion: Record "Service Package Version";
    begin
        SPVersion.FilterGroup(2);

        SI_InsertLookupSPVersion(SPVersion);
    end;

    procedure SI_InsertLookupSPVersion(var SPVersion: Record "Service Package Version")
    var
        SPVersionSpec: Record "Service Package Version Line";
        ServLine: Record "Service Line EDMS";
        ServicePackage: Record "Service Package";
        LastLineNo: Integer;
        Text001: label 'No records to list.';
        ServicePackageVersionSelect: Page "Service Package Version-Select";
    begin
        SPVersionAssignFilter(SPVersion);
        if SPVersion.FindFirst then;
        if SPVersion.Count > 1 then begin
            ServicePackageVersionSelect.SetTableview(SPVersion);
            ServicePackageVersionSelect.LookupMode(true);
            //IF NOT (ServicePackageVersionSelect.RUNMODAL = ACTION::LookupOK) THEN
            if not (Page.RunModal(Page::"Service Package Version-Select", SPVersion) = Action::LookupOK) then
                exit;
        end;
        SI_InsertSPVersion(SPVersion);
    end;

    procedure SI_InsertSPVersion(var SPVersion: Record "Service Package Version")
    var
        SPVersionSpec: Record "Service Package Version Line";
        ServLine: Record "Service Line EDMS";
        ServicePackage: Record "Service Package";
        Text001: label 'Aucun enregistrement dans la liste';
        Text124: label 'le Service package %1 est bloqué';
        Text134: label 'Aucune version du Service Package ne corrésponde aux caractéristiques du véhicule. (%1: %2)';
        Text133: label 'Aucun Service Package corresponds aux caractéristiques du véhicule';
        ServiceMgtSetupEDMS: Record "Service Mgt. Setup EDMS";
    begin
        ServiceMgtSetupEDMS.Get();
        if SPVersion."Package No." <> '' then begin
            ServicePackage.Get(SPVersion."Package No.");
            if ServicePackage.Blocked then
                Error(StrSubstNo(Text124, SPVersion."Package No."));

            with SPVersionSpec do begin
                Reset;
                SetRange("Package No.", SPVersion."Package No.");
                SetRange("Version No.", SPVersion."Version No.");
                if FindSet then begin
                    //Line Begin
                    SPVersionSpec.CreateServLineBegin("Document Type", Rec."No.");
                    //Line Begin
                    repeat
                        SPVersionSpec.SetCurrPlanStage(SI_VehicleServicePlanStageTmp_CS);

                        SPVersionSpec.CreateServLine("Document Type", Rec."No.");

                    until Next = 0;
                    //Line End
                    SPVersionSpec.CreateServLineEnd("Document Type", Rec."No.");
                    //Line End
                end
                else begin
                    Error(Text134, SPVersion.TableCaption, SPVersion."Version No.");
                end;
            end
        end else
            Error(Text133, SPVersion.TableCaption);
    end;




    procedure SendMessage(Var SrvHeadEdms: Record "Service Header EDMS"; Message: Text)
    var
        SendSMS: Page "Sopiq Send SMS Message";
        UserSetup: Record "User Setup";
        SalespersonCode: Code[10];
        SMSManagement: Codeunit "Sopiq SMS Management";
        FillPhoneNoErr: label 'Please fill in recipient Phone No.';
        FillMessageErr: label 'Message body is empty.';
        NoSalespersonCode: label 'Please set up Salesperson code.';
        SmsQueuedMsg: label 'Message envoyé au client.';

    begin
        UserSetup.Get(UserId);
        if UserSetup."Salespers./Purch. Code" <> '' then
            SalespersonCode := UserSetup."Salespers./Purch. Code"
        else
            SalespersonCode := SrvHeadEdms."Service Advisor";


        if SrvHeadEdms."Bill-to Contact Phone No." = '' then
            Error(FillPhoneNoErr);

        if Message = '' then
            Error(FillMessageErr);

        if SalespersonCode = '' then
            Error(NoSalespersonCode);

        SMSManagement.SetContactNo(SrvHeadEdms."Sell-to Contact No.");
        SMSManagement.SetSalespersonCode(SalespersonCode);
        SMSManagement.SetDocumentNo := SrvHeadEdms."No.";
        SMSManagement.SetDocumentType := SrvHeadEdms."Document Type";
        SMSManagement.AddSMSToQueue(SrvHeadEdms."Bill-to Contact Phone No.", Message);
        Message(SmsQueuedMsg);
    end;

    VAR
        SI_VehicleServicePlanStageTmp_CS: Record "Vehicle Service Plan Stage" temporary;

    trigger OnAfterModify()
    var
        DocumentStatus: Record "Document Status";
        TextMessage: Text;
    begin
        if rec."Document Status" <> xRec."Document Status" then begin
            TextMessage := '';
            DocumentStatus.Reset();
            DocumentStatus.SetRange(Code, rec."Document Status");
            DocumentStatus.SetRange("Document Type", "Document Type"::Order);
            DocumentStatus.SetRange("Document Profile", DocumentStatus."Document Profile"::Service);
            if DocumentStatus.FindFirst() then begin
                //Message('here ! %1 - %2 - %3 - %4 - %5', rec."No.", xRec."Document Status", rec."Document Status", DocumentStatus.SendMsg, DocumentStatus.Message);
                if (DocumentStatus.SendMsg = true) then begin
                    TextMessage := DocumentStatus.Message.Replace('%MAT%', rec."Vehicle Registration No.");
                    //Message(TextMessage);
                    SendMessage(rec, TextMessage);
                end;
            end;
        end;
    end;


}
