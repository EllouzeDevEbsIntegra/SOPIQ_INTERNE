codeunit 50022 SIStockCodeUnit
{
    Permissions = tabledata item = rimd,
                tabledata "Item Vendor" = rimd,
                tabledata "Item Cross Reference" = rimd;

    procedure formatVendorNo(recVendByMan: Record "Vendor By Manufacturer")
    var
        atPos, diezPos, initialLen, endLen : Integer;
        addText: Text;
        vendor: Code[20];
        recItem, recItemError : Record item;
        vendorNo, tempNo : Text[50];
        i: Integer;
        j: Integer;
        VendorByManufacturer: Record "Vendor By Manufacturer";
    begin

        if recVendByMan."Vendor No Format" <> '' then begin
            atPos := 0;
            diezPos := 0;
            addText := '';
            initialLen := 0;
            endLen := 0;

            if (Text.StrPos(recVendByMan."Vendor No Format", '@') = 0) AND (Text.StrPos(recVendByMan."Vendor No Format", '#') = 0) then begin
                //Message('Format inconnu %1 (@ ou # introuvable) !', recVendByMan."Vendor No Format");
                recItemError.Reset();
                recItemError.SetRange("Manufacturer Code", recVendByMan."Manufacturer Code");
                recItemError.SetFilter(Produit, '%1', false);
                if recItemError.FindSet() then begin
                    repeat
                        vendorNo := '';
                        vendor := '';
                        vendorNo := recItemError."No.";
                        vendor := recVendByMan."Vendor Code";
                        if recVendByMan."Default Vendor" = true then begin
                            recItemError."Vendor Item No." := vendorNo;
                            recItemError."Vendor No." := recVendByMan."Vendor Code";
                            recItemError.Modify;
                        end;
                        CreateVendorForItem(recItemError, vendorNo, vendor);
                        recItemError."Error Format Vendor No" := 'Format inconnu !';
                        recItemError.Modify();
                    until recItemError.Next() = 0;
                end;
            end
            else
                if (Text.StrPos(recVendByMan."Vendor No Format", '@') > 0) AND (Text.StrPos(recVendByMan."Vendor No Format", '#') > 0) then begin
                    // Message('Format inconnu %1 (@ et # ne peut pas être ensemble) !', recVendByMan."Vendor No Format");
                    recItemError.Reset();
                    recItemError.SetRange("Manufacturer Code", recVendByMan."Manufacturer Code");
                    recItemError.SetFilter(Produit, '%1', false);
                    if recItemError.FindSet() then begin
                        repeat
                            vendorNo := '';
                            vendor := '';
                            vendorNo := recItemError."No.";
                            vendor := recVendByMan."Vendor Code";
                            if recVendByMan."Default Vendor" = true then begin
                                recItemError."Vendor Item No." := vendorNo;
                                recItemError."Vendor No." := recVendByMan."Vendor Code";
                                recItemError.Modify;
                            end;
                            CreateVendorForItem(recItemError, vendorNo, vendor);
                            recItemError."Error Format Vendor No" := 'Format inconnu !';
                            recItemError.Modify();
                        until recItemError.Next() = 0;
                    end;
                end
                else
                    if (Text.StrPos(recVendByMan."Vendor No Format", '@') > 0) then begin
                        initialLen := Text.StrLen(recVendByMan."Vendor No Format");
                        endLen := Text.StrLen(Text.DelChr(recVendByMan."Vendor No Format", '=', '@'));
                        if (initialLen - endLen) = 1 then begin
                            recItem.Reset();
                            recItem.SetRange("Manufacturer Code", recVendByMan."Manufacturer Code");
                            recItem.SetFilter(Produit, '%1', false);
                            if recItem.FindSet() then begin
                                repeat
                                    vendorNo := '';
                                    vendor := '';
                                    vendorNo := recVendByMan."Vendor No Format".Replace('@', recItem."No.");
                                    vendor := recVendByMan."Vendor Code";
                                    if recVendByMan."Default Vendor" = true then begin
                                        recItem."Vendor Item No." := vendorNo;
                                        recItem."Vendor No." := recVendByMan."Vendor Code";
                                        recItem.Modify;
                                    end;
                                    CreateVendorForItem(recItem, vendorNo, vendor);
                                    recItem."Error Format Vendor No" := '';
                                    recItem.Modify();
                                until recItem.Next() = 0;
                            end;
                        end else begin
                            //Message('Format inconnu %1 (@ est trouvé %2 fois)!', recVendByMan."Vendor No Format", initialLen - endLen);
                            recItemError.Reset();
                            recItemError.SetRange("Manufacturer Code", recVendByMan."Manufacturer Code");
                            recItemError.SetFilter(Produit, '%1', false);
                            if recItemError.FindSet() then begin
                                repeat
                                    vendorNo := '';
                                    vendor := '';
                                    vendorNo := recItemError."No.";
                                    vendor := recVendByMan."Vendor Code";
                                    if recVendByMan."Default Vendor" = true then begin
                                        recItemError."Vendor Item No." := vendorNo;
                                        recItemError."Vendor No." := recVendByMan."Vendor Code";
                                        recItemError.Modify;
                                    end;
                                    CreateVendorForItem(recItemError, vendorNo, vendor);
                                    recItemError."Error Format Vendor No" := 'Format inconnu !';
                                    recItemError.Modify();
                                until recItemError.Next() = 0;
                            end;
                        end;
                    end
                    else begin
                        initialLen := Text.StrLen(recVendByMan."Vendor No Format");
                        endLen := Text.StrLen(Text.DelChr(recVendByMan."Vendor No Format", '=', '#'));
                        recItem.Reset();
                        recItem.SetRange("Manufacturer Code", recVendByMan."Manufacturer Code");
                        recItem.SetFilter(Produit, '%1', false);
                        if recItem.FindSet() then begin
                            repeat
                                tempNo := '';
                                vendorNo := '';
                                vendor := '';
                                if (initialLen - endLen) = Text.StrLen(recItem."No.") then begin

                                    tempNo := recItem."No.";
                                    vendor := recVendByMan."Vendor Code";
                                    j := 0;
                                    for i := 1 to initialLen do begin
                                        if recVendByMan."Vendor No Format".Substring(i, 1) = '#' then begin
                                            j := j + 1;
                                            vendorNo := vendorNo + tempNo.Substring(j, 1);
                                        end
                                        else begin
                                            vendorNo := vendorNo + recVendByMan."Vendor No Format".Substring(i, 1);
                                        end;
                                    end;
                                    if recVendByMan."Default Vendor" = true then begin
                                        recItem."Vendor Item No." := vendorNo;
                                        recItem."Vendor No." := recVendByMan."Vendor Code";
                                        recItem.Modify;
                                    end;
                                    CreateVendorForItem(recItem, vendorNo, vendor);
                                    recItem."Error Format Vendor No" := '';
                                    recItem.Modify();
                                end else begin
                                    //Message('Format inconnu %1 (Nombre de caractères du référence différent du nombre des #)!', recVendByMan."Vendor No Format", initialLen - endLen);
                                    recItemError.Reset();
                                    recItemError.SetRange("No.", recItem."No.");
                                    recItemError.SetFilter(Produit, '%1', false);
                                    if recItemError.Find() then begin
                                        Message('%1 - %2', initialLen - endLen, Text.StrLen(recItemError."No."));

                                        vendorNo := '';
                                        vendor := '';
                                        vendorNo := recItemError."No.";
                                        vendor := recVendByMan."Vendor Code";
                                        if recVendByMan."Default Vendor" = true then begin
                                            recItemError."Vendor Item No." := vendorNo;
                                            recItemError."Vendor No." := recVendByMan."Vendor Code";
                                            recItemError.Modify;
                                        end;
                                        CreateVendorForItem(recItemError, vendorNo, vendor);
                                        recItemError."Error Format Vendor No" := 'Format inconnu !';
                                        recItemError.Modify();
                                    end;
                                end;
                            until recItem.Next() = 0;
                        end;
                    end;

        end
        else begin
            recItem.Reset();
            recItem.SetRange("Manufacturer Code", recVendByMan."Manufacturer Code");
            recItem.SetFilter(Produit, '%1', false);
            if recItem.FindSet() then begin
                repeat
                    vendorNo := '';
                    vendor := '';
                    vendorNo := recItem."No.";
                    vendor := recVendByMan."Vendor Code";
                    if recVendByMan."Default Vendor" = true then begin
                        recItem."Vendor Item No." := vendorNo;
                        recItem."Vendor No." := recVendByMan."Vendor Code";
                        recItem.Modify;
                    end;
                    CreateVendorForItem(recItem, vendorNo, vendor);
                    recItem."Error Format Vendor No" := 'Format Non Défini !';
                    recItem.Modify();
                until recItem.Next() = 0;
            end;
        end;
    end;

    procedure CreateVendorForItem(var Rec: Record Item; vendorNo: code[20]; recVendor: Text)
    var
        VendorByManufacturer: Record "Vendor By Manufacturer";
        ItemVendor: Record "Item Vendor";
        Vendor: Record Vendor;
        ItemCrossReference: Record "Item Cross Reference";
    begin
        ItemVendor.Reset();
        ItemVendor.SetFilter("Item No.", Rec."No.");
        ItemVendor.SetFilter("Vendor No.", recVendor);
        ItemVendor.DeleteAll();

        ItemCrossReference.Reset();
        ItemCrossReference.SetFilter("Item No.", Rec."No.");
        ItemCrossReference.SetFilter("Cross-Reference Type No.", recVendor);
        ItemCrossReference.DeleteAll();

        ItemVendor.Init();
        ItemVendor."Item No." := Rec."No.";
        ItemVendor."Vendor No." := recVendor;
        Vendor.get(recVendor);
        ItemVendor."Lead Time Calculation" := Vendor."Lead Time Calculation"; //
        ItemVendor."Vendor Item No." := vendorNo;
        ItemVendor.Insert();


        ItemCrossReference.Init();
        ItemCrossReference."Item No." := rec."No.";
        ItemCrossReference."Cross-Reference Type" := ItemCrossReference."Cross-Reference Type"::Vendor;
        ItemCrossReference."Cross-Reference Type No." := recVendor;
        ItemCrossReference."Cross-Reference No." := vendorNo;
        ItemCrossReference."Unit of Measure" := rec."Purch. Unit of Measure";
        ItemCrossReference.Insert();

    end;

}