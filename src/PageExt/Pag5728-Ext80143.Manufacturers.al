pageextension 80143 "Manufacturers" extends "Manufacturers"//5728
{
    layout
    {
        addafter("ID TechDOC")
        {
            field(Actif; Actif)
            {
                ApplicationArea = All;
                Caption = 'Actif';
            }

            field(IsSpecific; IsSpecific)
            {
                ApplicationArea = All;
                Caption = 'Fabricant Spécifique';
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