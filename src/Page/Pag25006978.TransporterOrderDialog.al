page 25006978 "Transporter Order Dialog"
{
    PageType = StandardDialog;
    Caption = 'Créer Transporter Order';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Informations Livraison';
                field(DeliveryName; DeliveryName) { ApplicationArea = All; Caption = 'Nom Destinataire'; Editable = false; }
                field(DeliveryAddress; DeliveryAddress) { ApplicationArea = All; Caption = 'Adresse'; Editable = false; }
                field(DeliveryCity; DeliveryCity) { ApplicationArea = All; Caption = 'Ville'; Editable = false; }
                field(DeliveryPhone; DeliveryPhone) { ApplicationArea = All; Caption = 'Téléphone'; Editable = false; }
                field(DeliveryEmail; DeliveryEmail) { ApplicationArea = All; Caption = 'Email'; Editable = false; }
                field(DeliveryGovernorate; DeliveryGovernorate) { ApplicationArea = All; Caption = 'Gouvernorat'; }
            }
            group(Details)
            {
                Caption = 'Détails Expédition';
                field(TotalColis; TotalColis) { ApplicationArea = All; Caption = 'Nombre de Colis'; }
                field(TypeColis; TypeColis) { ApplicationArea = All; Caption = 'Type de Colis'; }
                field(TotalCr; TotalCr) { ApplicationArea = All; Caption = 'Total Contre Remboursement'; }
                field(Comment; Comment) { ApplicationArea = All; Caption = 'Commentaire'; MultiLine = true; }
            }
        }
    }

    var
        DeliveryName: Text;
        DeliveryAddress: Text;
        DeliveryCity: Text;
        DeliveryPhone: Text;
        DeliveryEmail: Text;
        DeliveryGovernorate: Text;
        TotalColis: Integer;
        TotalCr: Decimal;
        TypeColis: Enum "Type Colis";
        Comment: Text;

    procedure SetData(Name: Text; Address: Text; City: Text; Phone: Text; Email: Text; Governorate: Text; CrAmount: Decimal; Cmt: Text)
    begin
        DeliveryName := Name;
        DeliveryAddress := Address;
        DeliveryCity := City;
        DeliveryPhone := Phone;
        DeliveryEmail := Email;
        DeliveryGovernorate := Governorate;
        TotalCr := CrAmount;
        Comment := Cmt;
        TypeColis := TypeColis::Colis; // Valeur par défaut
    end;

    procedure GetData(var TColis: Integer; var TCr: Decimal; var TyColis: Enum "Type Colis"; var Cmt: Text; var Governorate: Text)
    begin
        TColis := TotalColis;
        TCr := TotalCr;
        TyColis := TypeColis;
        Cmt := Comment;
        Governorate := DeliveryGovernorate;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            if TotalColis <= 0 then
                Error('Le nombre de colis doit être strictement supérieur à 0.');
    end;
}