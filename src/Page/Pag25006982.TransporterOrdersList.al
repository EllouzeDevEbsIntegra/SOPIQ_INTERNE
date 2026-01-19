page 25006982 "Transporter Orders List"
{
    ApplicationArea = All;
    Caption = 'Transporter Orders';
    PageType = List;
    SourceTable = "Transporter Order Buffer";
    SourceTableView = SORTING("Order ID") ORDER(Descending);
    UsageCategory = Lists;
    Editable = false;


    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field("Order ID"; Rec."Order ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Order ID field.';
                }
                field("Delivery Name"; Rec."Delivery Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Name field.';
                }
                field("Delivery Address"; Rec."Delivery Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Address field.';
                }
                field("Delivery City"; Rec."Delivery City")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery City field.';
                }
                field("Delivery Post Code"; Rec."Delivery Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Post Code field.';
                }
                field("Delivery Governorate"; Rec."Delivery Governorate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Governorate field.';
                }
                field("Delivery Phone"; Rec."Delivery Phone")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Phone field.';
                }
                field("Delivery Email"; Rec."Delivery Email")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Email field.';
                }
                field("Total Colis"; Rec."Total Colis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Total Colis field.';
                }
                field("Type Colis"; Rec."Type Colis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Type Colis field.';
                }
                field("Total CR"; Rec."Total CR")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Total CR field.';
                }
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Payment Method field.';
                }
                field("Delivery Status"; Rec."Delivery Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Status field.';
                }
                field("Payment Status"; Rec."Payment Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Payment Status field.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Created At field.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Comment field.';
                }
                field("Fetched DateTime"; Rec."Fetched DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time when the order was fetched from the API.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Fetch Orders")
            {
                ApplicationArea = All;
                Caption = 'Fetch Orders from Transporter';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                begin
                    FetchAndRefresh();
                end;
            }
            action("Print Order")
            {
                ApplicationArea = All;
                Caption = 'Imprimer';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TransporterAPI: Codeunit "Transporter API Integration";
                    TransporterSetup: Record "Transporter Setup";
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    FileName: Text;
                    DefaultSetupCodeTxt: Label 'DEFAULT', Locked = true;
                    SalesShipmentHeader: Record "Sales Shipment Header";
                    custNo: Code[20];
                begin
                    SalesShipmentHeader.Reset();
                    custNo := '';

                    if not TransporterSetup.Get(DefaultSetupCodeTxt) then
                        if not TransporterSetup.FindFirst() then
                            Error('Transporter Setup not found.');

                    SalesShipmentHeader.SetRange("N° récépissé", Rec."Order ID");
                    if SalesShipmentHeader.FindFirst() then begin
                        custNo := SalesShipmentHeader."Sell-to Customer No.";
                    end;

                    TransporterAPI.GetOrderPdf(Rec."Order ID", TransporterSetup, TempBlob);

                    if not TempBlob.HasValue() then
                        Error('Aucune donnée PDF reçue.');

                    TempBlob.CreateInStream(InStr);

                    FileName := 'Order_' + Format(Rec."Order ID") + '_' + custNo + '.pdf';
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        FetchAndRefresh();
    end;

    local procedure FetchAndRefresh()
    var
        TransporterAPI: Codeunit "Transporter API Integration";
        TransporterSetup: Record "Transporter Setup";
        DefaultSetupCodeTxt: Label 'DEFAULT', Comment = 'The default code for the transporter setup record', Locked = true;
        SetupNotFoundErr: Label 'Transporter Setup with code ''%1'' not found. Please configure the API.', Comment = '%1 = Setup Code';
    begin
        if not TransporterSetup.Get(DefaultSetupCodeTxt) then
            Error(SetupNotFoundErr, DefaultSetupCodeTxt);

        TransporterAPI.GetOrders(TransporterSetup);
        CurrPage.Update(false);
    end;
}