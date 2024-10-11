pageextension 80120 "Product To Be Compared card" extends "Product To Be Compared card" //50014
{
    layout
    {

        addafter("Comparateur")
        {
            part("Produit"; 50021)
            {
                UpdatePropagation = SubPart;
                ApplicationArea = All;
                SubPageLink = "Compare Quote No." = field("Compare Quote No."),
                    "Reference Origine Lié" = field("No.");
            }

            part("Equivalent"; "Item Equivalent")
            {
                UpdatePropagation = SubPart;
                ApplicationArea = All;
            }

            part("Kit"; "Item Kit")
            {
                UpdatePropagation = SubPart;
                ApplicationArea = All;
            }
        }
        modify("Quote Lines")
        {
            Visible = false;
        }

        modify("Produit équivalent Comparateur")
        {
            Visible = false;
        }

        modify("Kit Comparateur")
        {
            Visible = false;
        }
        // moveafter(" "; "Produit équivalent Comparateur")

        // moveafter("Produit équivalent Comparateur"; "Kit Comparateur")

    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnAfterGetCurrRecord()

    VAR
        recIsKit, recIsComponent : Record "BOM Component";
        recitem: Record item;
        recPurchLine: Record "Purchase Line";
        iscomponent, EntredOnce : Boolean;
        comparedNo: TEXT;

    begin
        EntredOnce := false;
        comparedNo := '';
        recPurchLine.Reset();
        recPurchLine.SetRange("Compare Quote No.", "Compare Quote No.");
        recPurchLine.SetRange("Reference Origine Lié", "No.");
        if recPurchLine.FindSet() then begin
            repeat
                // Message('EntredOnce : %1 - ComapredNo : %2', EntredOnce, comparedNo);
                if EntredOnce then comparedNo := comparedNo + '|';
                comparedNo := comparedNo + recPurchLine."No.";
                EntredOnce := true;
            until recPurchLine.next = 0;
        end;
        if EntredOnce then begin
            // Message(comparedNo);
            CurrPage."Equivalent".Page.SetItemNo(comparedNo);

            //Vérifier si c'est un parent, composant ou rien
            recIsKit.Reset();
            recIsKit.SetRange("Parent Item No.", comparedNo);

            iscomponent := false;
            recitem.Reset();
            recitem.SetRange("Reference Origine Lié", "No.");
            if recitem.FindSet() then begin
                repeat
                    recIsComponent.Reset();
                    recIsComponent.SetRange("No.", recitem."No.");
                    if recIsComponent.FindFirst() then iscomponent := true;
                until recitem.next = 0;
            end;

            if (recIsKit.IsEmpty = true AND iscomponent = false) then begin
                CurrPage.Kit.Page.SetNothing();
            end
            else
                if recIsKit.FindFirst() then
                    CurrPage."kit".Page.SetKit(comparedNo)
                else
                    CurrPage.Kit.Page.SetComponent(comparedNo);
        end



    end;


    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        bool: Boolean;
    begin
        bool := Confirm('Voulez vous vraiment quitter ?', true);
        if bool = false then exit(bool);

    end;

}