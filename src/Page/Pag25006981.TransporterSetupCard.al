page 25006981 "Transporter Setup Card"
{
    ApplicationArea = All;
    Caption = 'Transporter Setup';
    PageType = Card;
    SourceTable = "Transporter Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for the transporter setup.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the transporter setup.';
                }
                field("API URL"; Rec."API URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for the transporter API.';
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API key for authentication with the transporter API.';
                    ExtendedDatatype = Masked;
                }
                field("Last Fetched DateTime"; Rec."Last Fetched DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time when orders were last fetched from the API.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Fetch Orders Now")
            {
                ApplicationArea = All;
                Caption = 'Fetch Orders Now';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TransporterAPI: Codeunit "Transporter API Integration";
                begin
                    Rec.TestField(Code);
                    TransporterAPI.GetOrders(Rec);
                end;
            }
            action("View Orders")
            {
                ApplicationArea = All;
                Caption = 'View Fetched Orders';
                Image = View;
                Promoted = true;
                PromotedCategory = Category4;

                trigger OnAction()
                var
                    TransporterOrderList: Page "Transporter Orders List";
                begin
                    TransporterOrderList.Run();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        DefaultSetupCodeTxt: Label 'DEFAULT', Comment = 'The default code for the transporter setup record', Locked = true;
    begin
        // This logic ensures the page always opens the single setup record.
        // If the record doesn't exist, it creates it.
        if Rec.Get(DefaultSetupCodeTxt) then
            exit;

        Rec.Init();
        Rec.Code := DefaultSetupCodeTxt;
        Rec.Insert();
    end;
}