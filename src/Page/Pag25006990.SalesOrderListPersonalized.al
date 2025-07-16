page 25006990 "Sales Order List Personalized"
{
    ApplicationArea = Basic, Suite, Assembly;
    Caption = 'Sales Orders';
    CardPageID = "Sales Order";
    DataCaptionFields = "Sell-to Customer No.";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Request Approval,Order,Release,Posting,Print/Send,Navigate';
    QueryCategory = 'Sales Order List';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    UsageCategory = Lists;
    SourceTableView = sorting("No.") order(descending) WHERE("Document Type" = CONST(Order));
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // Champs standard
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    // Lookup = true;
                    // LookupPageId = "Sales Order";
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }

                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the sales order was posted.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which the sales order was created.';
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the sales order.';
                }
                field("Statut B2B"; "Statut B2B")
                {
                    ApplicationArea = All;
                }
                field("Shipping Agent Code SI"; "Shipping Agent Code SI")
                {
                    Caption = 'Code Transporteur SI';
                    ApplicationArea = All;
                }

                field("Completely Shipped"; "Completely Shipped")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the sales order has been completely shipped.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of the sales order excluding VAT.';
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = All;
                }

                field(custNameImprime; custNameImprime)
                {
                    ApplicationArea = All;
                }
                field(custAdresseImprime; custAdresseImprime)
                {
                    ApplicationArea = All;
                }
                field(custMFImprime; custMFImprime)
                {
                    ApplicationArea = All;
                }
                field(custVINImprime; custVINImprime)
                {
                    ApplicationArea = All;
                }
            }
        }
    }



    actions
    {
        area(processing)
        {
            group(Posting)
            {
                Caption = 'Posting';

                // Toutes les actions standard d'origine (Release, Reopen, Make Invoice, etc.)
                // Ici je place un exemple, à compléter par vos besoins :
                action("Release")
                {
                    Caption = 'Release';
                    ApplicationArea = Basic;
                    Image = ReleaseDoc;

                    trigger OnAction()
                    begin
                        // Code standard Release ici
                    end;
                }

                // Votre action personnalisée "Changer statut B2B"
                action("Changer statut B2B")
                {
                    ApplicationArea = Basic, Suite;
                    Image = ReleaseDoc;
                    Caption = 'Changer statut B2B';
                    Promoted = true;
                    PromotedIsBig = true;
                    PromotedCategory = Category7;

                    trigger OnAction()
                    var
                        options: label 'Préparé,En cours de pointage,En attente de livraison,Livré,Annulée';
                        Choix: label 'Changement statut B2B:';
                        int: Code[2];
                        VarInt: Integer;
                    begin
                        int := Format("Statut B2B", 0, 2);
                        Evaluate(VarInt, int);
                        Rec.Get("Document Type", "No.");
                        if Rec."Statut B2B" in ["Statut B2B"::"En cours de préparation", "Statut B2B"::"Préparé", "Statut B2B"::"En cours de pointage",
                            "Statut B2B"::"En attente de livraison", "Statut B2B"::"Livré", "Statut B2B"::"Annulée"] then begin
                            case StrMenu(Options, VarInt - 1, Choix) of
                                1:
                                    Rec."Statut B2B" := "Statut B2B"::"Préparé";
                                2:
                                    Rec."Statut B2B" := "Statut B2B"::"En cours de pointage";
                                3:
                                    Rec."Statut B2B" := "Statut B2B"::"En attente de livraison";
                                4:
                                    Rec."Statut B2B" := "Statut B2B"::"Livré";
                                5:
                                    Validate("Statut B2B", "Statut B2B"::"Annulée");
                            end;
                            Modify();
                        end;
                    end;
                }
            }

            group(Comments)
            {
                Caption = 'Comments';

                // Action personnalisée "Delete Canceled Ship"
                action("Delete Canceled Ship")
                {
                    Caption = 'Supprimer tous les lignes avec expédition annulée';
                    Image = DeleteAllBreakpoints;
                    Promoted = true;
                    PromotedCategory = Category5;

                    trigger OnAction()
                    var
                        SalesLine: Record "Sales Line";
                    begin
                        SalesLine.Reset();
                        SalesLine.SetRange("Is Ship Canceled", true);
                        SalesLine.DeleteAll();
                        Message('Tous les lignes avec expédition annulllée sont supprimées avec succès !');
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Acopmpte);
        // Ajoutez ici votre logique OnAfterGetRecord complète
    end;

    // Ajoutez autres triggers OnInit, OnOpenPage, etc. avec logique originale + votre logique

    var
        // Variables nécessaires
        myInt: Integer;

}
