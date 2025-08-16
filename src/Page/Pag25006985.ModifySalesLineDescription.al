page 25006985 "Modify Sales Line Description"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Sales Invoice Line";
    ModifyAllowed = true;
    Editable = true;

    layout
    {
        area(Content)
        {

            group(General)
            {
                Caption = 'Lignes';
                field(newdescription; newdescription)
                {
                    ApplicationArea = All;
                    Caption = 'Nouvelle Description';
                    ToolTip = 'Saisissez la nouvelle description pour les lignes de facture sélectionnées.';
                    Editable = true;
                }
            }
            repeater(Lines)
            {
                field("Document No."; "Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    Editable = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    Editable = false;
                }
                field("Description"; "Description")
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Modifier Designation")
            {
                ApplicationArea = All;
                Caption = 'Modifier Designation';
                Image = Edit;

                trigger OnAction()
                var
                    SISalesCodeUnit: Codeunit SISalesCodeUnit;
                begin
                    SISalesCodeUnit.modifySalesLineDescription(Rec, newdescription);
                end;
            }
        }
    }
    var
        newdescription: Text[250];
}