page 50130 "Liste Dossier Import"
{
    Caption = 'Liste dossier import';
    CardPageID = "Transit Folder card";

    PageType = List;
    Permissions = TableData "Purchase Header" = rimd,
                  TableData "Purchase Line" = rimd;
    SourceTable = "Transit Folder";
    SourceTableView = SORTING("No.")
                      ORDER(descending) where(Status = filter('<>Clôturé'));
    UsageCategory = Lists;
    ApplicationArea = All;
    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field("Opening Date"; "Opening Date")
                {
                    ApplicationArea = All;
                }
                field("Closing Date"; "Closing Date")
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Nom fournisseur"; "Vendor Name")
                {
                    ApplicationArea = All;
                }
                field(staStatus; Status)
                {
                    ApplicationArea = All;
                }

            }
        }
    }

    var
        TransitFolderFunctions: Codeunit TransitFolderHook;
}

