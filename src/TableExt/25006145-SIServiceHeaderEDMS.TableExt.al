tableextension 80250 "Service Header EDMS" extends "Service Header EDMS" //25006145
{
    fields
    {

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



    VAR
        SI_VehicleServicePlanStageTmp_CS: Record "Vehicle Service Plan Stage" temporary;
}
