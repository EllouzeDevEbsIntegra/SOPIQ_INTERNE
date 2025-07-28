pageextension 80150 "Service Mgt. Setup EDMS" extends "Service Mgt. Setup EDMS" //25006150
{
    layout
    {
        addafter("Quantity Labor Mandatory")
        {
            field("Global Ress. Mondata"; "Global Ress. Mondata")
            {
                ApplicationArea = all;
                trigger OnValidate()
                begin
                    if xrec."Global Ress. Mondata" = false
                    then begin
                        "Quantity Labor Mandatory" := false;
                    end;
                end;
            }
        }
        modify("Quantity Labor Mandatory")
        {
            trigger OnAfterValidate()
            begin
                if xrec."Quantity Labor Mandatory" = false
                then begin
                    "Global Ress. Mondata" := false;
                end;
            end;
        }

        addafter(ControlMechanicTimeEntry)
        {
            field("Begin Pack"; "Begin Pack")
            {
                ApplicationArea = All;
            }
            field("End Pack"; "End Pack")
            {
                ApplicationArea = All;
            }
        }

        addafter("Statut Waiting Invoicing")
        {
            field("Statut Vehicule Pret"; "Statut Vehicule Pret")
            {
                ApplicationArea = All;
            }

            field("Statut Vehicule Receptionne"; "Statut Vehicule Receptionne")
            {
                ApplicationArea = all;
            }
        }
        addafter(LaborNos)
        {
            field("Service Task Nos"; "Service Task Nos")
            {
                Caption = 'N° Tâche Service';
                ApplicationArea = All;
            }
        }
    }
}
