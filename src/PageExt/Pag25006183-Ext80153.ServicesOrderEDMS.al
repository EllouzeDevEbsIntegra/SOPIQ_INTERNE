pageextension 80153 "Services Order EDMS" extends "Service Order EDMS"//25006183
{
    layout
    {
        // Add changes to page layout here
        modify("Control Performed")
        {
            trigger OnAfterValidate()
            var
                parService: Record "Service Mgt. Setup EDMS";
            begin
                parService.get();
                if parService."Global Ress. Mondata" then begin
                    verifyGlobalQtyFini(rec);
                    VehiculePretEditable := true;
                    CurrPage.Update();
                end;

            end;
        }



        addafter("Control Performed")
        {

            field("Vehicule Prêt"; "Vehicule Prete")
            {
                Editable = VehiculePretEditable;
                trigger OnValidate()
                var
                    ServiceMgtSetupEDMS: Record "Service Mgt. Setup EDMS";
                begin
                    ServiceMgtSetupEDMS.Get();
                    if ServiceMgtSetupEDMS."Statut Vehicule Pret" <> '' then begin
                        if ("Vehicule Prete" = true) then begin
                            //Message('Bravo ! - %1', ServiceMgtSetupEDMS."Statut Vehicule Pret");
                            rec.Validate("Document Status", ServiceMgtSetupEDMS."Statut Vehicule Pret");
                            VehiculePretEditable := false;
                            CurrPage.Update();
                        end;
                    end
                    else begin
                        Error('Code statut vehicule prête dans paramètres services doit avoir une valeur, valeur actuelle est '' ');
                    end;

                end;
            }
            field(Masquer; Masquer)
            {
                ApplicationArea = All;
                Caption = 'Masquer';
            }


        }
        addafter(InitiatorCode)
        {
            field("Initiator Name"; "Initiator Name")
            {
                Caption = 'Nom Initiateur';
                ApplicationArea = all;
            }
        }

        addafter(Advanced)
        {
            group(Constat)
            {
                Caption = 'Constat Ordre Réparation';
                field("Type Lavage"; "Type Lavage")
                {
                    ApplicationArea = All;
                    Caption = 'Type Lavage';
                    ToolTip = 'Type de lavage';
                }
                field("Carte Grise"; "Carte Grise")
                {
                    ApplicationArea = All;
                    Caption = 'Carte Grise';
                }
                field("Assurance"; "Assurance")
                {
                    ApplicationArea = All;
                    Caption = 'Assurance';
                }
                field("Accessoire Tel"; "Accessoire Tel")
                {
                    ApplicationArea = All;
                    Caption = 'Accessoire Téléphone';
                }

                field("Tapis"; "Tapis")
                {
                    ApplicationArea = All;
                    Caption = 'Tapis de sol';
                }
                field(Roue; Roue)
                {
                    ApplicationArea = All;
                    Caption = 'Roue de secours';
                }
                field("Cle Roue"; "Cle Roue")
                {
                    ApplicationArea = All;
                    Caption = 'Clé de roue sécurité';
                }
                field("Compresseur"; "Compresseur")
                {
                    ApplicationArea = All;
                    Caption = 'Compresseur';
                }
                field("Triange Panne"; "Triange Panne")
                {
                    ApplicationArea = All;
                    Caption = 'Triangle de panne';
                }
                field(Objet; Objet)
                {
                    ApplicationArea = All;
                    Caption = 'Objet';
                }
                field(Observation; Observation)
                {
                    ApplicationArea = All;
                    Caption = 'Observation';
                    ToolTip = 'Observation';
                }

            }
        }

    }

    actions
    {
        modify(Action1101904032)
        {
            Visible = false;
        }

        addafter(Action1101904032)
        {
            action("Print OR")
            {
                ApplicationArea = Basic;
                Caption = 'Imprimer';
                Image = ServiceAgreement;
                Promoted = true;
                PromotedCategory = Category6;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ServLine: Record "Service Line EDMS";
                    DocMgt: Codeunit DocumentManagementDMS;
                    DocReport: Record "Document Report";
                    ServiceMgtSetupEDMS: Record "Service Mgt. Setup EDMS";
                begin
                    ServLine.Reset;
                    DocMgt.PrintCurrentDoc(3, 3, 1, DocReport);
                    DocMgt.SelectServDocReport(DocReport, Rec, ServLine, false);
                    // Modify document Statut
                    if ("No. Printed" = 0) then begin
                        message('Test Here !');
                        ServiceMgtSetupEDMS.Get();
                        if ServiceMgtSetupEDMS."Statut Vehicule Receptionne" <> '' then begin
                            if ("Document Status" = ServiceMgtSetupEDMS."Statut creation OR") then begin
                                //Message('Bravo ! - %1', ServiceMgtSetupEDMS."Statut Vehicule Receptionne");
                                rec.Validate("Document Status", ServiceMgtSetupEDMS."Statut Vehicule Receptionne");
                                CurrPage.Update();
                            end;
                        end
                        else begin
                            Error('Code statut vehicule réceptionné dans paramètres services doit avoir une valeur, valeur actuelle est '' ');
                        end;
                    end;

                    "No. Printed" := "No. Printed" + 1;



                end;
            }
        }
        modify("Imprimer Picking list")
        {
            Visible = true;
        }
        // Add changes to page actions here
        modify(InsertServicePackage)
        {
            Visible = false;
            Promoted = false;
        }
        addafter(InsertServicePackage)
        {
            action(SI_InsertServicePackage)
            {
                ApplicationArea = Basic;
                Caption = 'Inserer Service Package';
                Image = CopyFromTask;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SI_InsertServPackage
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        if ("Vehicule Prete" = false) then VehiculePretEditable := rec."Control Performed" else VehiculePretEditable := false;

        // if VIN <> '' then Validate(VIN);
        // if "Sell-to Customer No." <> '' then Validate("Sell-to Customer No.");
    end;

    procedure verifyGlobalQtyFini(ServiceHeaderEDMS: Record "Service Header EDMS")
    var
        ServiceLineEDMS: Record "Service Line EDMS";
        ServLaborAlloc: Record "Serv. Labor Alloc. Application";
        SumQty: Decimal;
        Text001: label 'Quantité finie ne doit pas être égale à 0';

    begin
        ServiceLineEDMS.SetRange("Document No.", ServiceHeaderEDMS."No.");
        ServiceLineEDMS.SetRange(Type, ServiceLineEDMS.Type::Labor);
        if ServiceLineEDMS.Count > 0 then begin
            ServLaborAlloc.Reset();
            ServLaborAlloc.SetRange("Document No.", ServiceHeaderEDMS."No.");
            ServLaborAlloc.SetRange("Document Type", ServLaborAlloc."Document Type"::Order);
            ServLaborAlloc.SetRange("Document Line No.", 0);
            ServLaborAlloc.CalcSums("Finished Quantity (Hours)");
            if ServLaborAlloc."Finished Quantity (Hours)" = 0 then
                Error(Text001);
        end;
    end;

    var
        VehiculePretEditable: Boolean;
}