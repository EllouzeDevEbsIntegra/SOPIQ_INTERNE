report 50222 "ModifyBillToCustomer"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;
    Permissions = TableData 17 = rimd,
                  TableData 32 = rimd,
                  TableData 5802 = rimd,
                  TableData 110 = rimd,
                  TableData 111 = rimd;
    dataset
    {
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
            DataItemTableView = sorting("No.")
            ORDER(Ascending) WHERE(BS = CONST(FALSE));

            trigger OnAfterGetRecord()
            begin

                if (BlNo <> "No.") then BlNo := "No.";
                if Customer.get(CustNo) then;
                SalesSetup.get;
                UserSetup.get(UserId);
                //@@@@@@@@@@ BL
                SalesSetup.TestField("Posted Shipment Nos.");
                if "Bill-to Customer No." <> Customer."No." then begin
                    "Bill-to Customer No." := Customer."No.";
                    "Bill-to Name" := Customer.Name;
                    "Bill-to Name 2" := Customer."Name 2";
                    "Bill-to Address" := Customer.Address;
                    "Bill-to Address 2" := Customer."Address 2";
                    "Bill-to City" := Customer.City;
                    "Bill-to Post Code" := Customer."Post Code";
                    "Bill-to County" := Customer.County;
                    "Bill-to Country/Region Code" := Customer."Country/Region Code";
                    "Gen. Bus. Posting Group" := Customer."Gen. Bus. Posting Group";
                    "VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
                    "Tax Area Code" := Customer."Tax Area Code";
                    "Tax Liable" := Customer."Tax Liable";
                    "VAT Registration No." := Customer."VAT Registration No.";
                    Modify(true);
                end;


                recSalesShpLine.Reset();
                recSalesShpLine.SetRange("Document No.", "No.");
                if recSalesShpLine.FindSet() then begin
                    repeat

                        //@@@@@ ECRITURE ARTICLE
                        ItemkledgEntry.RESET;
                        ItemkledgEntry.setrange("Entry No.", recSalesShpLine."Item Shpt. Entry No.");
                        IF ItemkledgEntry.FINDSET THEN begin
                            ItemkledgEntry."Source No." := Customer."No.";
                            ItemkledgEntry.MODIFY;

                            //@@@@@ ECRITURE VALEUR
                            ValueEntry.RESET;
                            ValueEntry.setrange("Item Ledger Entry No.", ItemkledgEntry."Entry No.");
                            IF ValueEntry.FINDSET THEN begin
                                ValueEntry."Source No." := Customer."No.";
                                ValueEntry.MODIFY;
                            end;
                        end;

                        //@@@@LIGNE BL


                        recSalesShpLine."Bill-to Customer No." := "Sales Shipment Header"."Bill-to Customer No.";
                        recSalesShpLine."Currency Code" := "Sales Shipment Header"."Currency Code";
                        recSalesShpLine."Gen. Bus. Posting Group" := "Sales Shipment Header"."Gen. Bus. Posting Group";
                        recSalesShpLine."VAT Bus. Posting Group" := "Sales Shipment Header"."VAT Bus. Posting Group";
                        recSalesShpLine."VAT %" := GetVat(recSalesShpLine."VAT Bus. Posting Group", recSalesShpLine."VAT Prod. Posting Group");
                        recSalesShpLine.MODIFY(true);


                        //@@@@ MODIFICATION CLIENT FACTURE ET DONNEUR D ORDRE
                        salesline.RESET;
                        salesline.SETRANGE("Document Type", salesline."Document Type"::Order);
                        salesline.SETRANGE("Document No.", "Order No.");
                        salesline.SETRANGE("Line No.", recSalesShpLine."Order Line No.");
                        IF salesline.FINDSET THEN begin
                            salesline."Bill-to Customer No." := "Sales Shipment Header"."Bill-to Customer No.";
                            salesline."Gen. Bus. Posting Group" := "Sales Shipment Header"."Gen. Bus. Posting Group";
                            salesline."VAT Bus. Posting Group" := "Sales Shipment Header"."VAT Bus. Posting Group";
                            salesline."Gen. Bus. Posting Group" := "Sales Shipment Header"."Gen. Bus. Posting Group";
                            salesline."VAT Bus. Posting Group" := "Sales Shipment Header"."VAT Bus. Posting Group";
                            salesline."VAT %" := GetVat(salesline."VAT Bus. Posting Group", salesline."VAT Prod. Posting Group");
                            salesline.modify;
                        end;



                    until recSalesShpLine.next = 0;
                end;


            END;

            trigger OnPreDataItem()
            begin
                if CustNo = '' THEN ERROR(CustAbsence);


            end;

            trigger OnPostDataItem()
            var
                myInt: Integer;
            begin
                message(BlGenerated, BlNo, CustNo, Custname);
                BlNo := '';
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Choisir client")
                {
                    field("Client"; CustNo)
                    {
                        ApplicationArea = All;
                        TableRelation = Customer;
                        trigger OnLookup(var text: text): Boolean
                        var
                            myInt: Integer;
                            ReclCustomer: Record Customer;
                            custmerlist: page "Customer List";
                        begin

                            IF PAGE.RUNMODAL(22, ReclCustomer) = ACTION::LookupOK THEN BEGIN
                                CustNo := ReclCustomer."No.";
                                Custname := ReclCustomer.name;
                            end;
                            if CustNo = '' then Custname := '';
                        END;
                    }
                    field(Nom; Custname)
                    {
                        ApplicationArea = All;
                        Editable = false;
                    }
                }
            }
        }

        actions
        {
            area(processing)
            {
                action(ActionName)
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    var
        myInt: Integer;
        CustNo: Code[20];
        Custname: text[80];
        Window: Dialog;
        BlNo: code[20];
        NoSeriesMgt: Codeunit 396;
        SalesSetup: Record 311;
        confirmation: label 'Modifier le bon de livraison';
        confirmationcanceled: label 'Génération annulé';
        CustAbsence: label 'Merci de spécifier le code client';
        SalesOrder: Record 36;
        SalesShipHead: array[2] of Record "Sales Shipment Header";
        SalesShipline: array[2] of Record "Sales Shipment Line";
        Customer: Record Customer;
        ItemkledgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        OLdDocNo: code[20];
        dialogWindow: Label 'Modification du bon de livrasion';
        BlGenerated: label 'Bon de livraison No %1 modifié pour le client No %2 - %3';
        LineNo: Integer;
        salesline: Record "Sales Line";
        UserSetup: Record "User Setup";
        ligneArchiveBS: Record "Ligne archive BS";
        OldlineNo: Integer;
        recSalesShpLine, recSalesShpLine2 : Record "Sales Shipment Line";

    procedure GetVat(VatBus: code[10]; VatProd: code[10]): Decimal

    var
        VatPostGrp: Record "VAT Posting Setup";
    Begin
        VatPostGrp.RESET;
        VatPostGrp.SetRange("VAT Bus. Posting Group", VatBus);
        VatPostGrp.SetRange("VAT Prod. Posting Group", VatProd);
        IF VatPostGrp.FindSet then begin
            exit(VatPostGrp."VAT %");
        end;
    End;

}