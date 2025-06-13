pageextension 80210 "Company Information" extends "Company Information" // 1
{
    layout
    {
        // Add changes to page layout here
        addafter(Picture)
        {
            field(Company; Company)
            {
                ApplicationArea = Basic;
                Caption = 'Société';

            }
            field("Base Company"; "Base Company")
            {
                ApplicationArea = Basic;
                Caption = 'Société de base';
            }
            field(BS; BS)
            {
                ApplicationArea = Basic;
                Caption = 'Gestion BS';
            }


        }

        addafter(Communication)
        {
            group(Commission)
            {
                Caption = 'Commission';
                field("Com VN"; "Com VN")
                {
                    Caption = 'Commission VN';
                    ApplicationArea = all;
                }
                field("Com PDR"; "Com PDR")
                {
                    Caption = 'Commission PDR';
                    ApplicationArea = all;
                }
                field(Other; Other)
                {
                    Caption = 'Autre';
                    ApplicationArea = all;
                }
            }

        }

        addafter(Commission)
        {
            group("Inter Society")
            {
                Caption = 'Inter Société';
                field("Inter Society 1"; "Inter Society 1")
                {
                    Caption = 'Société 1';
                    ApplicationArea = all;
                }
                field("Inter Society 2"; "Inter Society 2")
                {
                    Caption = 'Société 2';
                    ApplicationArea = all;
                }
            }
        }


    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;


}