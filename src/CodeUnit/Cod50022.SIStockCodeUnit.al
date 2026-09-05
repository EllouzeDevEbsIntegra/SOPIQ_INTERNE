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
        ItemVendor: Record "Item Vendor";
        Vendor: Record Vendor;
        ItemCrossReference: Record "Item Cross Reference";
        ItemUoM: Record "Item Unit of Measure";
        VendCode: Code[20];
        UoMCode: Code[10];
    begin
        // ---- Garde-fous : on n'ecrit rien sur des donnees incoherentes
        if Rec."No." = '' then
            exit;

        VendCode := CopyStr(recVendor, 1, MaxStrLen(VendCode));
        if VendCode = '' then
            exit;
        if not Vendor.Get(VendCode) then
            exit;

        // ---- Purge ciblee : SetRange (valeur) et non SetFilter (expression)
        ItemVendor.Reset();
        ItemVendor.SetRange("Item No.", Rec."No.");
        ItemVendor.SetRange("Vendor No.", VendCode);
        ItemVendor.DeleteAll(true);

        ItemCrossReference.Reset();
        ItemCrossReference.SetRange("Item No.", Rec."No.");
        ItemCrossReference.SetRange("Cross-Reference Type",
                                    ItemCrossReference."Cross-Reference Type"::Vendor);
        ItemCrossReference.SetRange("Cross-Reference Type No.", VendCode);
        ItemCrossReference.DeleteAll(true);

        // ---- Rien a recreer si la reference fournisseur est vide
        if vendorNo = '' then
            exit;

        // ---- Unite de mesure : verifiee sur l'article, avec repli
        UoMCode := Rec."Purch. Unit of Measure";
        if (UoMCode = '') or (not ItemUoM.Get(Rec."No.", UoMCode)) then
            UoMCode := Rec."Base Unit of Measure";
        if (UoMCode <> '') and (not ItemUoM.Get(Rec."No.", UoMCode)) then
            UoMCode := '';

        // ---- Fiche fournisseur article
        ItemVendor.Init();
        ItemVendor.Validate("Item No.", Rec."No.");
        ItemVendor.Validate("Vendor No.", VendCode);
        ItemVendor.Validate("Variant Code", '');
        ItemVendor.Validate("Vendor Item No.", vendorNo);
        ItemVendor.Validate("Lead Time Calculation", Vendor."Lead Time Calculation");
        // Idempotent : le trigger standard a pu deja creer la ligne
        if not ItemVendor.Insert(true) then
            ItemVendor.Modify(true);

        // ---- Reference externe
        ItemCrossReference.Init();
        ItemCrossReference.Validate("Item No.", Rec."No.");
        ItemCrossReference.Validate("Variant Code", '');
        ItemCrossReference.Validate("Unit of Measure", UoMCode);
        ItemCrossReference.Validate("Cross-Reference Type",
                                    ItemCrossReference."Cross-Reference Type"::Vendor);
        ItemCrossReference.Validate("Cross-Reference Type No.", VendCode);
        ItemCrossReference.Validate("Cross-Reference No.", vendorNo);
        // Idempotent : Item Vendor.Insert(true) cree deja la reference
        // externe correspondante via le trigger standard.
        if not ItemCrossReference.Insert(true) then
            ItemCrossReference.Modify(true);
    end;

}