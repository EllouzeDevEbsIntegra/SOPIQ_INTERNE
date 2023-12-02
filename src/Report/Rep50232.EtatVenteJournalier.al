report 50232 "Etat Vente Journalier"
{

    DefaultLayout = RDLC;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Etat de vente Journalier';
    RDLCLayout = './src/report/RDLC/etatVenteJournalier.rdl';


    dataset
    {

        dataitem(RecItem; "Item Ledger Entry")
        {
            DataItemTableView = SORTING("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code")
             ORDER(Ascending)
             WHERE("Entry Type" = CONST(Sale));
            RequestFilterFields = "Item No.", "posting Date", "Location Code";
            column(varlocatinfilter; varlocatinfilter)
            {

            }
            column(DateFilter; DateFilter)
            {

            }
            column(Vendor; GItem."Vendor Item No.")
            {

            }
            column(Fabricant; GItem."Manufacturer Name")
            {

            }
            column(CodeFabricant; GItem."Manufacturer Code")
            {

            }
            column(Int; Int)
            {

            }
            column(Picture; RecCompany.Picture)
            {

            }
            column(LocationFilter; LocationFilter)
            {

            }

            column(ItemNo; "Item No.")
            {

            }
            column(ItemName; GItem.Description)
            {

            }
            column(Magasin; "Location Code")
            {

            }
            column(CodeEmplacement; CodeEmplacement)
            {

            }
            column(fabName; fab.Name)
            {

            }
            column(Stockdebut; Stockdebut)
            {

            }
            column(QteVendu; QteVendu)
            {

            }
            column(QteFinal; GItem.Inventory)
            {

            }
            trigger OnAfterGetRecord()
            var
                myInt: Integer;

            begin
                IF ("Item No." = oldItem) and ("Location Code" = OldLocation) THEN
                    CurrReport.SKIP else
                    if GItem.get("Item No.") THEN;
                GItem.SetFilter("Location Filter", LocationFilter);
                GItem.CalcFields(Inventory);
                QteVendu := 0;
                GetStockVendu(GItem, "Location Code", GETFILTER("Posting Date"));
                Stockdebut := GItem.Inventory + QteVendu;
                // if QteVendu <> 0 THEN begin
                //     Int += 1;
                // end else begin
                //     CurrReport.SKIP;
                // end;
                Int += 1;

                oldItem := "Item No.";
                OldLocation := "Location Code";
                // end ELSE begin
                //     CurrReport.SKIP;
                //end;
                fab.Reset();
                fab.SetRange(fab.Code, GItem."Manufacturer Code");
                if fab.FindFirst() then;
                // WarehouseEntry.SetRange(WarehouseEntry."Reference No.", "Document No.");
                // WarehouseEntry.SetRange(WarehouseEntry."Whse. Document Line No.", "Order Line No.");
                // WarehouseEntry.SetRange(WarehouseEntry."Item No.", "Item No.");

                // WarehouseEntry.SetRange(WarehouseEntry."Location Code", "Location Code");
                // if WarehouseEntry.FindSet then
                //     repeat
                //         CodeEmplacement := WarehouseEntry."Bin Code";


                //     until WarehouseEntry.Next = 0
                CodeEmplacement := '';
                BinCOntent.Reset();
                BinCOntent.SetRange("Location Code", "Location Code");
                BinCOntent.SetRange("Item No.", "Item No.");
                BinCOntent.SetRange(Default, true);
                if BinCOntent.FindFirst() then
                    CodeEmplacement := BinCOntent."Bin Code"
                else begin
                    BinCOntent1.Reset();
                    BinCOntent1.SetRange("Location Code", "Location Code");
                    BinCOntent1.SetRange("Item No.", "Item No.");
                    BinCOntent1.SetFilter(Quantity, '>0');
                    if BinCOntent1.FindFirst() then
                        CodeEmplacement := BinCOntent1."Bin Code";
                end;

            END;

            trigger OnPreDataItem()
            var
                myInt: Integer;
            begin
                LocationFilter := GETFILTER("Location code");
                if LocationFilter = '' then
                    varlocatinfilter := 'Dépôt : Tous les dépôts' else
                    varlocatinfilter := 'Dépôt :' + ' ' + LocationFilter;
                DateFilter := GETFILTER("Posting date");
                if DateFilter = '' then error(DatFilterError);
                //message('%1 %2', varlocatinfilter, DateFilter);
            end;


        }
    }

    requestpage
    {
        // layout
        // {
        //     area(Content)
        //     {
        //         group(Filter)
        //         {
        //             field(From; DatFilter)
        //             {
        //                 ApplicationArea = All;
        //                 Caption = 'De :';

        //             }
        //             field(To; DatFilter1)
        //             {
        //                 ApplicationArea = All;
        //                 Caption = 'A :';

        //             }
        //         }
        //     }
        // }

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
    // local procedure GetStockInitial(Var Rec: Record item; LocationFilter: Text[250])

    // var
    //     myInt: Integer;
    //     lItem: Record Item;
    // begin

    //     WITH lItem DO BEGIN
    //         setrange("No.", Rec."No.");
    //         SETFILTER("Location Filter", LocationFilter);
    //         SETFILTER("Date Filter", format(0D) + '..' + format(DatFilter - 1));
    //         IF FINDSET THEN
    //             CalcFields(Inventory2);
    //         Stockdebut := Inventory2;
    //         //message('%1 %2 ', LocationFilter, Stockdebut);
    //     end;
    // end;

    local procedure GetStockVendu(Var Rec: Record item; LocationFilters: Text[250]; DateFilters: text[20])

    var
        myInt: Integer;
        lItem: Record Item;
    begin
        WITH lItem DO BEGIN
            setrange("No.", Rec."No.");
            SETFILTER("Location Filter", LocationFilters);
            SETFILTER("Date Filter", DateFilters);
            if FINDSET THEN
                CalcFields("Qte Vendu");
            QteVendu := -"Qte Vendu";
            //message('%1 %2 %3', Rec."No.", LocationFilters, QteVendu);
        end;
    end;

    trigger OnInitReport()
    begin
        CLEAR(RecCompany);
        RecCompany.GET;
        RecCompany.CALCFIELDS(Picture);
        RecCompany.CALCFIELDS(RecCompany."Invoice Header Picture");
        RecCompany.CALCFIELDS(RecCompany."Invoice Footer Picture");

    end;

    var

        oldItem: code[20];
        OldLocation: code[10];
        GItem: Record Item;
        myInt: Integer;
        DatFilter: date;
        DatFilter1: date;
        CodeEmplacement: Code[10];
        Stockdebut: Decimal;
        WarehouseEntry: Record 7312;
        DatFilterError: label 'Merci de renseigner la date de filtre';
        QteVendu: Decimal;
        LocationFilter: text[250];
        DateFilter: text[20];
        Int: Integer;
        varlocatinfilter: text[250];
        fab: Record Manufacturer;
        RecCompany: record "Company Information";
        BinCOntent, BinCOntent1 : Record "Bin Content";
}