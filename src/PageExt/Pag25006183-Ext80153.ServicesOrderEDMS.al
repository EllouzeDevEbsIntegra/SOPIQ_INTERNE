pageextension 80153 "Services Order EDMS" extends "Service Order EDMS"//25006183
{
    layout
    {
        // Add changes to page layout here
        modify("Control Performed")
        {
            trigger OnAfterValidate()
            begin
                VehiculePretEditable := true;
                CurrPage.Update();
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
    end;


    var
        VehiculePretEditable: Boolean;
}