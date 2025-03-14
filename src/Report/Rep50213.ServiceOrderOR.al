report 50213 "Service Order OR"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/RDLC/ServiceOrderOR.rdl';
    Caption = 'Ordre de réparatio';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Service Header EDMS"; "Service Header EDMS")
        {
            RequestFilterFields = "No.";
            column("Kilométrage"; "Service Header EDMS"."Variable Field Run 1")
            {
            }
            column(ImagePDI; ServiceMgtSetupEDMS."Picture PDI")
            {
            }
            column(LWorkDescription; LWorkDescription)
            {
            }
            column(captionCheckNo; captionCheckNo)
            {
            }
            column(CaptionFinalCheck; CaptionFinalCheck)
            {
            }
            column(caption1; caption1)
            {
            }
            column(Service_Advisor; "Service Advisor")
            {
            }

            column(Arrival_Date; "Arrival Date")
            {
            }
            column(Requested_Finishing_Date; "Requested Finishing Date")
            {
            }


            column(caption2; caption2)
            {
            }
            column(caption3; caption3)
            {
            }
            column(caption4; caption4)
            {
            }
            column(caption5; caption5)
            {
            }
            column(caption6; caption6)
            {
            }
            column(caption7; caption7)
            {
            }
            column(Vehicle_Status_Code; "Vehicle Status Code")
            {
            }
            column(caption8; caption8)
            {
            }
            column(caption9; caption9)
            {
            }
            column(captionKPSN; captionKPSN)
            {
            }
            column(CaptionKeepParts; CaptionKeepParts)
            {
            }
            column(CaptionYesNo; CaptionYesNo)
            {
            }
            column(CAptionActualDElTime; CAptionActualDElTime)
            {
            }
            column(CaptionEstJobTime; CaptionEstJobTime)
            {
            }
            column(CaptionTimeReq; CaptionTimeReq)
            {
            }
            column(CaptionLatestStartTime; CaptionLatestStartTime)
            {
            }
            column(CaptionRevisedTime; CaptionRevisedTime)
            {
            }
            column(DocNo; "Service Header EDMS"."No.")
            {
            }
            column(CaptionTime; CaptionTime)
            {
            }
            column(CaptionJCQC; CaptionJCQC)
            {
            }
            column(CaptionIssueDate; CaptionIssueDate)
            {
            }
            column(CapRegNo; CapRegNo)
            {
            }
            column(CaptionModel; CaptionModel)
            {
            }
            column(CaptionFirstRegDate; CaptionFirstRegDate)
            {
            }
            column(CaptionEstmate; CaptionEstmate)
            {
            }
            column(CaptionRevEstimate; CaptionRevEstimate)
            {
            }
            column(CaptionAuthoBy; CaptionAuthoBy)
            {
            }
            column(CaptionComment; CaptionComment)
            {
            }
            column(CaptionEngineN; CaptionEngineN)
            {
            }
            column(CaptionKm; CaptionKm)
            {
            }
            column(CaptionCustSIgn; CaptionCustSIgn)
            {
            }
            column(CaptionSubCond; CaptionSubCond)
            {
            }
            column(CaptionAddItems; CaptionAddItems)
            {
            }
            column(CaptionSquare1; CaptionSquare1)
            {
            }
            column(CaptionSquareCheckN; CaptionSquareCheckN)
            {
            }
            column(CaptionSquareFCheck; CaptionSquareFCheck)
            {
            }
            column(CaptionInspected; CaptionInspected)
            {
            }
            column(CaptionOther; CaptionOther)
            {
            }
            column(CaptionWAC1; CaptionWAC1)
            {
            }
            column(CaptionWAC2; CaptionWAC2)
            {
            }
            column(CaptionWAC3; CaptionWAC3)
            {
            }
            column(CaptionWAC4; CaptionWAC4)
            {
            }
            column(CaptionWAC5; CaptionWAC5)
            {
            }
            column(CaptionWAC6; CaptionWAC6)
            {
            }
            column(CaptionWAC7; CaptionWAC7)
            {
            }
            column(CaptionPaymentMethod; CaptionPaymentMethod)
            {
            }
            column(CaptionCK1; CaptionCK1)
            {
            }
            column(CaptionCK2; CaptionCK2)
            {
            }
            column(CaptionCK3; CaptionCK3)
            {
            }
            column(CaptionCK4; CaptionCK4)
            {
            }
            column(CaptionFMC1; CaptionFMC1)
            {
            }
            column(CaptionFMC2; CaptionFMC2)
            {
            }
            column(CaptionFMC3; CaptionFMC3)
            {
            }
            column(CaptionFMC4; CaptionFMC4)
            {
            }
            column(Caption_CustInfo; Caption_CustInfo)
            {
            }
            column(Caption_Name; Caption_Name)
            {
            }
            column(Caption_adr; Caption_adr)
            {
            }
            column(Caption_tel; Caption_tel)
            {
            }
            column(Caption_CustrRq; Caption_CustrRq)
            {
            }
            column(Caption_PIIR; Caption_PIIR)
            {
            }
            column(Caption_techRep; Caption_techRep)
            {
            }
            column(CaptionCheck1; CaptionCheck1)
            {
            }
            column(CaptionCheck2; CaptionCheck2)
            {
            }
            column(CaptionCheck3; CaptionCheck3)
            {
            }
            column(CaptionCheck4; CaptionCheck4)
            {
            }

            column(DLT_Fuel; "Fuel")
            {
            }
            column(CaptionCheck6; CaptionCheck6)
            {
            }
            column(CaptionCheck7; CaptionCheck7)
            {
            }
            column(CaptionCheck8; CaptionCheck8)
            {
            }
            column(Caption_SAname; Caption_SAname)
            {
            }
            column(Caption_ROno; Caption_ROno)
            {
            }
            column(DLT_Type_Booking; "Type Booking")
            {
            }

            column(Caption_Reception_Time; Caption_ReceptionTime)
            {
            }
            column(Caption_DelivTime; Caption_DelivTime)
            {
            }
            column(Caption_residence; Caption_residence)
            {
            }
            column(CompName; CompanyInformation.Name)
            {
            }
            column(Logo; CompanyInformation."Invoice Header Picture")
            {
            }
            column(Footer; CompanyInformation."Invoice Footer Picture")
            {
            }
            column(AdresseCompagny; CompanyInformation.Address)
            {
            }
            column(NomReceptionnaire; NomReceptionnaire)
            {
            }
            column(TimeRequired; "Service Header EDMS"."Total Work (Hours)")
            {
            }
            column(DocumentType_ServiceHeaderEDMS; "Service Header EDMS"."Document Type")
            {
            }
            column(SelltoCustomerNo_ServiceHeaderEDMS; "Service Header EDMS"."Sell-to Customer No.")
            {
            }
            column(No_ServiceHeaderEDMS; "Service Header EDMS"."No.")
            {
            }
            column(BilltoCustomerNo_ServiceHeaderEDMS; "Service Header EDMS"."Bill-to Customer No.")
            {
            }
            column(BilltoName_ServiceHeaderEDMS; "Service Header EDMS"."Bill-to Name")
            {
            }
            column(BilltoName2_ServiceHeaderEDMS; "Service Header EDMS"."Bill-to Name 2")
            {
            }
            column(Address_Customer; "Service Header EDMS"."Bill-to Address")
            {
            }
            column(BilltoAddress2_ServiceHeaderEDMS; "Service Header EDMS"."Bill-to Address 2")
            {
            }
            column(BilltoCity_ServiceHeaderEDMS; "Service Header EDMS"."Bill-to City")
            {
            }
            column(BilltoContact_ServiceHeaderEDMS; "Service Header EDMS"."Bill-to Contact")
            {
            }
            column(YourReference_ServiceHeaderEDMS; "Service Header EDMS"."Your Reference")
            {
            }
            column(OrderDate_ServiceHeaderEDMS; "Service Header EDMS"."Order Date")
            {
            }
            column(PostingDate_ServiceHeaderEDMS; "Service Header EDMS"."Posting Date")
            {
            }
            column(ShipmentDate_ServiceHeaderEDMS; "Service Header EDMS"."Shipment Date")
            {
            }
            column(PostingDescription_ServiceHeaderEDMS; "Service Header EDMS"."Posting Description")
            {
            }
            column(PaymentTermsCode_ServiceHeaderEDMS; "Service Header EDMS"."Payment Terms Code")
            {
            }
            column(RequestedStartingDate_ServiceHeaderEDMS; "Service Header EDMS"."Requested Starting Date")
            {
            }
            column(RequestedStartingTime_ServiceHeaderEDMS; "Service Header EDMS"."Requested Starting Time")
            {
            }
            column(RequestedFinishingDate_ServiceHeaderEDMS; "Service Header EDMS"."Requested Finishing Date")
            {
            }
            column(RequestedFinishingTime_ServiceHeaderEDMS; "Service Header EDMS"."Requested Finishing Time")
            {
            }
            column(DueDate_ServiceHeaderEDMS; "Service Header EDMS"."Due Date")
            {
            }
            column(PaymentDiscount_ServiceHeaderEDMS; "Service Header EDMS"."Payment Discount %")
            {
            }
            column(LocationCode_ServiceHeaderEDMS; "Service Header EDMS"."Location Code")
            {
            }
            column(DocumentDate_ServiceHeaderEDMS; "Service Header EDMS"."Document Date")
            {
            }
            column(SerialNo_Vehicle; Vehicle."Serial No.")
            {
            }
            column(VIN_Vehicle; Vehicle.VIN)
            {
            }
            column(MakeCode_Vehicle; Vehicle."Make Code")
            {
            }
            column(ModelCode_Vehicle; Vehicle."Model Code")
            {
            }
            column(ModelVersionNo_Vehicle; Vehicle."Model Version No.")
            {
            }
            column(ModelCommercialName_Vehicle; Vehicle."Model Commercial Name")
            {
            }
            column(Comment_Vehicle; Vehicle.Comment)
            {
            }
            column(ProductionYear_Vehicle; Vehicle."Production Year")
            {
            }
            column(RegistrationNo_Vehicle; Vehicle."Registration No.")
            {
            }
            column(firstregDateVeh; Vehicle."First Registration Date")
            {
            }
            //  column(EngineNum_Vehicle; Vehicle."Engine Num")
            // {
            // }
            column(Name_Customer; Customer.Name)
            {
            }
            column(Address_Customerc; Customer.Address)
            {
            }
            column(City_Customer; Customer.City)
            {
            }
            column(PhoneNo_Customer; Customer."Phone No.")
            {
            }
            column(TelexNo_Customer; Customer."Telex No.")
            {
            }
            column(EMail_Customer; Customer."E-Mail")
            {
            }
            column(Ville; "Service Header EDMS"."Bill-to City")
            {
            }
            column(afficherPiedsPage; afficherPiedsPage)
            {
            }

            trigger OnAfterGetRecord()
            var

            begin
                IF "Service Header EDMS"."Service Advisor" <> '' THEN BEGIN
                    IF SalespersonPurchaser.GET("Service Header EDMS"."Service Advisor") THEN
                        NomReceptionnaire := SalespersonPurchaser.Name;
                END;
                IF Vehicle.GET("Vehicle Serial No.") THEN;
                IF Customer.GET("Sell-to Customer No.") THEN;

                //read blob
                CALCFIELDS("Work Description");
                "Work Description".CREATEINSTREAM(CommentStream);
                CommentStream.READTEXT(CommentText);
                LWorkDescription := "Service Header EDMS".GetWorkDescription;
            end;

            trigger OnPreDataItem()
            begin

            end;
        }
    }


    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {

                field(afficherPiedsPage; afficherPiedsPage)
                {
                    ApplicationArea = all;
                    Caption = 'Afficher entête et pied de page';
                }
            }
        }

        actions
        {
        }
    }








    labels
    {
    }

    trigger OnInitReport()
    begin

    end;

    trigger OnPreReport()
    begin
        CompanyInformation.GET;
        CompanyInformation.CALCFIELDS(CompanyInformation.Picture, CompanyInformation."Invoice Footer Picture");
        CompanyInformation.CALCFIELDS(CompanyInformation."Invoice Header Picture");
        ServiceMgtSetupEDMS.GET;
        ServiceMgtSetupEDMS.CALCFIELDS(ServiceMgtSetupEDMS."Picture PDI");
        afficherPiedsPage := true;
    end;

    var
        CompanyInformation: Record 79;
        Caption_CustInfo: Label 'Customer Information';
        Caption_Name: Label 'Name';
        Caption_adr: Label 'Address';
        Caption_tel: Label 'Tel No';
        Caption_CustrRq: Label 'Customer''s Request';
        Caption_PIIR: Label '(Prime item if required)';
        Caption_techRep: Label 'Technician''s report';
        language: Record 8;
        [InDataSet]
        UseCustomerLanguage: Boolean;
        lCustomer: Record 18;
        DisplayLanguage: Code[10];
        CaptionCheck1: Label 'Repeat Visit';
        CaptionCheck2: Label 'While you Wait';
        CaptionCheck3: Label 'Internal';
        CaptionCheck4: Label 'Walk-In';
        CaptionCheck5: Label 'Maintenance';
        CaptionCheck6: Label 'Repair';
        CaptionCheck7: Label 'Warranty';
        CaptionCheck8: Label 'Appointment';
        Caption_SAname: Label 'S.A. Name';
        Caption_ROno: Label 'R/O No';
        Caption_ReceptionTime: Label 'Reception Time';
        Caption_DelivTime: Label 'Delivery Time';
        Caption_residence: Label 'Residence';
        CaptionPaymentMethod: Label 'Payment Method';
        CaptionCK1: Label 'Credit Card VISA';
        CaptionCK2: Label 'Cash';
        CaptionCK3: Label 'Account';
        CaptionCK4: Label 'Others';
        CaptionWAC1: Label 'Spare Wheel';
        CaptionWAC2: Label 'Jack & Handle';
        CaptionWAC3: Label 'Tools';
        CaptionWAC4: Label 'Spot Light';
        CaptionWAC5: Label 'Mats';
        CaptionWAC6: Label 'Keys';
        CaptionWAC7: Label 'Radio & Cassette';
        CaptionFMC1: Label 'Good';
        CaptionFMC2: Label 'Non-Geninue';
        CaptionFMC3: Label 'No Good';
        CaptionFMC4: Label 'Double Mats';
        CaptionOther: Label 'Other';
        CaptionCustSIgn: Label 'Customer''s Signature';
        CaptionSubCond: Label 'subject to conditions';
        CaptionAddItems: Label 'Additional Items found during the Work';
        CaptionSquare1: Label 'Job Card Quality Check';
        CaptionSquareCheckN: Label 'Check No.';
        CaptionSquareFCheck: Label 'Final Check';
        CaptionInspected: Label 'Inspected By';
        CaptionEstmate: Label 'Estimate';
        CaptionRevEstimate: Label 'Revised Estimate';
        CaptionAuthoBy: Label 'Authorized By';
        CaptionComment: Label 'Comment';
        CaptionEngineN: Label 'Engine Number';
        CaptionKm: Label 'Mileage (Kms)';
        CaptionFirstRegDate: Label 'First Registration Date';
        CaptionModel: Label 'Model Code';
        CapRegNo: Label 'Registration Number';
        CaptionIssueDate: Label 'R/O Issue Date';
        CaptionJCQC: Label 'Job Card Quality Check';
        CaptionTime: Label 'Time';
        Customer: Record 18;
        Vehicle: Record 25006005;
        CaptionRevisedTime: Label 'Revised Deliver Time';
        CaptionTimeReq: Label 'Time Required';
        CaptionEstJobTime: Label 'Estimated Job Time';
        CaptionLatestStartTime: Label 'Latest Start Time';
        NomReceptionnaire: Text;
        SalespersonPurchaser: Record 13;
        CAptionActualDElTime: Label 'Actual Delivery Time';
        CaptionYesNo: Label 'Yes / No';
        CaptionKeepParts: Label 'Kepp Parts';
        captionKPSN: Label 'Key/Parking Stall Number';
        caption1: Label 'Diagnosis';
        caption2: Label 'Start Time';
        caption3: Label 'Finish Date';
        caption4: Label 'Nom Dig./Tec.';
        caption5: Label 'Dig./Report No';
        caption6: Label 'Pre-Delivery';
        caption8: Label 'Post-Service Follow - up Preferense';
        caption7: Label 'Final Inspection Done BY';
        caption9: Label 'Job Resl. Expl.Done BY';
        captionCheckNo: Label 'Check No';
        CaptionFinalCheck: Label ' Final Check';
        LWorkDescription: Text;
        CommentStream: InStream;
        CommentText: Text;
        Item1: Record 27;
        ServiceMgtSetupEDMS: Record 25006120;
        afficherPiedsPage: Boolean;
}

