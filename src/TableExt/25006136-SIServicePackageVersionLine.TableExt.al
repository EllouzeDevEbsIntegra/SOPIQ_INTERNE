tableextension 80252 "Service Package Version Line" extends "Service Package Version Line"//25006136
{

    procedure CreateServLineBegin(DocType: Option Quote,"Order","Return Order"; DocNo: Code[20])
    var
        ServLine: Record "Service Line EDMS";
        ServicePackage: Record "Service Package";
        servicePackageVersion: record "Service Package Version";
        LineNo: Integer;
        ServiceMgtSetupEDMS: Record "Service Mgt. Setup EDMS";
    begin
        ServiceMgtSetupEDMS.Get();
        ServiceMgtSetupEDMS.TestField("Begin Pack");

        ServLine.Reset;
        ServLine.SetRange("Document Type", DocType);
        ServLine.SetRange("Document No.", DocNo);
        if ServLine.FindLast then
            LineNo := ServLine."Line No." + 10000
        else
            LineNo := 10000;

        ServLine.Init;
        ServLine."Line No." := LineNo;
        ServLine.Validate("Document Type", DocType);
        ServLine.Validate("Document No.", DocNo);
        ServLine.Insert;

        ServLine.Validate(Type, ServLine.Type::Comment);

        //18.03.2008. EDMS P2 moved up this code>>
        ServLine."Package No." := "Package No.";
        ServLine."Package Version No." := "Version No.";
        ServLine."Package Version Spec. Line No." := "Line No.";
        //18.03.2008. EDMS P2 moved up this code<<

        ServLine.Validate("No.", ServiceMgtSetupEDMS."Begin Pack");
        //IF Type = Type::" " THEN

        servicePackageVersion.Get("Package No.", "Version No.");
        ServLine.Description := 'Pack ' + servicePackageVersion.Description + '-----';


        //29.01.2010 EDMS P2 >>
        if ServicePackage.Get("Package No.") then
            ServLine."Campaign No." := ServicePackage."Campaign No.";
        //29.01.2010 EDMS P2 <<

        ServLine.Modify;
    end;

    procedure CreateServLineEnd(DocType: Option Quote,"Order","Return Order"; DocNo: Code[20])
    var
        ServLine: Record "Service Line EDMS";
        ServicePackage: Record "Service Package";
        servicePackageVersion: record "Service Package Version";
        LineNo: Integer;
        ServiceMgtSetupEDMS: Record "Service Mgt. Setup EDMS";
    begin
        ServiceMgtSetupEDMS.Get();
        ServiceMgtSetupEDMS.TestField("End Pack");

        ServLine.Reset;
        ServLine.SetRange("Document Type", DocType);
        ServLine.SetRange("Document No.", DocNo);
        if ServLine.FindLast then
            LineNo := ServLine."Line No." + 10000
        else
            LineNo := 10000;

        ServLine.Init;
        ServLine."Line No." := LineNo;
        ServLine.Validate("Document Type", DocType);
        ServLine.Validate("Document No.", DocNo);
        ServLine.Insert;

        ServLine.Validate(Type, ServLine.Type::Comment);

        //18.03.2008. EDMS P2 moved up this code>>
        ServLine."Package No." := "Package No.";
        ServLine."Package Version No." := "Version No.";
        ServLine."Package Version Spec. Line No." := "Line No.";
        //18.03.2008. EDMS P2 moved up this code<<

        ServLine.Validate("No.", ServiceMgtSetupEDMS."End Pack");
        //IF Type = Type::" " THEN

        servicePackageVersion.Get("Package No.", "Version No.");


        //29.01.2010 EDMS P2 >>
        if ServicePackage.Get("Package No.") then
            ServLine."Campaign No." := ServicePackage."Campaign No.";
        //29.01.2010 EDMS P2 <<

        ServLine.Modify;
    end;


}
