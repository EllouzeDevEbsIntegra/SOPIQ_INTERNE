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
                field(TypeColis; TypeColis) { ApplicationArea = All; Caption = 'Type de Colis'; Editable = IsTypeColisEditable; }
                field(TotalCr; TotalCr) { ApplicationArea = All; Caption = 'Total Contre Remboursement'; }
                field(PaymentMethod; PaymentMethod)
                {
                    ApplicationArea = All;
                    Caption = 'Méthode de paiement';
                    OptionCaption = 'Non payé,Paiement Mensuel';
                }
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
        PaymentMethod: Option NP,PM;
        Comment: Text;
        IsTypeColisEditable: Boolean;

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
        PaymentMethod := PaymentMethod::NP;
        IsTypeColisEditable := true;
    end;

    procedure SetEnvelopeMode()
    begin
        TotalColis := 1;
        TypeColis := TypeColis::Envelope;
        IsTypeColisEditable := false;
    end;

    procedure GetData(var TColis: Integer; var TCr: Decimal; var TyColis: Enum "Type Colis"; var Cmt: Text; var Governorate: Text; var PMethod: Option NP,PM)
    begin
        TColis := TotalColis;
        TCr := TotalCr;
        TyColis := TypeColis;
        Cmt := Comment;
        Governorate := DeliveryGovernorate;
        PMethod := PaymentMethod;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            if TotalColis <= 0 then
                Error('Le nombre de colis doit être strictement supérieur à 0.');
    end;
}