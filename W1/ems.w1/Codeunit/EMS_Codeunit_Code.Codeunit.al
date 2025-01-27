codeunit 52109 EMS_Codeunit_Code
{
    local procedure FindExistingILEEntry_lFnc(var ReservationEntry_vRec: Record "Reservation Entry"; var TransHeader_vRec: Record "Transfer Header")
    var
        FindItemLedgerEntry_lRec: Record "Item Ledger Entry";
        Location_lRec: Record Location;
    begin
        FindItemLedgerEntry_lRec.Reset();
        FindItemLedgerEntry_lRec.SetRange("Item No.", ReservationEntry_vRec."Item No.");
        IF ReservationEntry_vRec."Serial No." <> '' then FindItemLedgerEntry_lRec.SetRange("Serial No.", ReservationEntry_vRec."Serial No.");
        IF ReservationEntry_vRec."Lot No." <> '' then FindItemLedgerEntry_lRec.SetRange("Lot No.", ReservationEntry_vRec."Lot No.");
        FindItemLedgerEntry_lRec.SetRange("Entry Type", FindItemLedgerEntry_lRec."Entry Type"::Transfer);
        FindItemLedgerEntry_lRec.SetRange("Document Type", FindItemLedgerEntry_lRec."Document Type"::"Transfer Receipt");
        FindItemLedgerEntry_lRec.SetRange("Demo Location", true);
        FindItemLedgerEntry_lRec.SetRange("Customer No.", TransHeader_vRec."Customer No."); //T37244-N
        IF FindItemLedgerEntry_lRec.FindLast() then begin
            Location_lRec.Get(TransHeader_vRec."Transfer-from Code");
            IF Location_lRec."Demo Location" then IF TransHeader_vRec."Customer No." <> FindItemLedgerEntry_lRec."Customer No." then Error('Serial Location_lRec."Demo Location" theno: %1 selected is not related to Customer: %2', ReservationEntry_vRec."Serial No.", TransHeader_vRec."Customer No.");
        end;
    end;

    local procedure InsertDeviceLinkedToLic_gFnc(var Rec: Record "Item Ledger Entry")
    var
        Customer_l: Record Customer;
        DevicelinkedtoLicense_lRec: record "Dozee Device";
        EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
    begin
        IF Customer_l.Get(Rec."Customer No.") Then;
        DevicelinkedtoLicense_lRec.Init();
        DevicelinkedtoLicense_lRec."Source Type" := Rec."Source Type"::Customer;
        DevicelinkedtoLicense_lRec.Validate("Source No.", Customer_l."No.");
        DevicelinkedtoLicense_lRec.Validate("Customer No.", Customer_l."No.");
        DevicelinkedtoLicense_lRec."Customer Name" := Customer_l.Name;
        DevicelinkedtoLicense_lRec."Partner No." := Customer_l."Partner ID";
        DevicelinkedtoLicense_lRec."Org ID" := Customer_l."Organization ID";
        DevicelinkedtoLicense_lRec.Validate("Item No", Rec."Item No.");
        DevicelinkedtoLicense_lRec."Item Description" := Rec.Description;
        DevicelinkedtoLicense_lRec.Variant := Rec."Variant Code";
        DevicelinkedtoLicense_lRec."Serial No." := Rec."Serial No.";
        DevicelinkedtoLicense_lRec."Item Ledger Entry No." := Rec."Entry No.";
        EMSAPIMgt_lCdu.GetDeviceLicenseId(DevicelinkedtoLicense_lRec);
        DevicelinkedtoLicense_lRec.Insert();
        EMSAPIMgt_lCdu.ExpireTerminateDeviceLicense(DevicelinkedtoLicense_lRec, 1);
        EMSAPIMgt_lCdu.SendDeviceVariant(DevicelinkedtoLicense_lRec);
        ActiveLicMgt_gCdu.InsertArchiveDeviceLedgEntry(DevicelinkedtoLicense_lRec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesLines', '', false, false)]
    local procedure C80_OnBeforePostSalesLines(var SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line")
    var
        ItemCategory_lRec: Record "Item Category";
    begin
        If NOT (TempSalesLineGlobal."Document Type" IN [TempSalesLineGlobal."Document Type"::Order, TempSalesLineGlobal."Document Type"::Invoice]) then exit;
        If TempSalesLineGlobal.Type <> TempSalesLineGlobal.Type::Item then Exit;
        ItemCategory_lRec.get(TempSalesLineGlobal."Item Category Code");
        IF ItemCategory_lRec."Used for License" then TempSalesLineGlobal.TestField(Duration);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertShipmentLine', '', false, false)]
    local procedure OnAfterInsertShipmentLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line"; PreviewMode: Boolean; xSalesLine: Record "Sales Line");
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post (Yes/No)", 'OnBeforePost', '', false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    var
        Loc: Record Location;
        ReservationEntry_lRec: Record "Reservation Entry";
    begin
        Clear(Loc);
        IF Loc.Get(TransHeader."Transfer-to Code") Then IF (Loc."Demo Location") Then TransHeader.TestField("Customer No.");
        IF Loc.Get(TransHeader."Transfer-from Code") Then IF (Loc."Demo Location") Then TransHeader.TestField("Customer No.");
        ReservationEntry_lRec.Reset();
        ReservationEntry_lRec.SetRange("Source Type", 5741);
        ReservationEntry_lRec.SetRange("Source ID", TransHeader."No.");
        ReservationEntry_lRec.SetRange("Source Subtype", 1);
        IF ReservationEntry_lRec.FindSet() then begin
            repeat
                FindExistingILEEntry_lFnc(ReservationEntry_lRec, TransHeader);
            until ReservationEntry_lRec.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterPostItemJnlLine', '', false, false)]
    local procedure OnAfterPostItemJnlLine(ItemJnlLine: Record "Item Journal Line"; var TransLine3: Record "Transfer Line"; var TransRcptHeader2: Record "Transfer Receipt Header"; var TransRcptLine2: Record "Transfer Receipt Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line");
    begin
        ItemJnlLine."Customer No." := TransRcptHeader2."Customer No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforePostItemJournalLine', '', false, false)]
    local procedure OnBeforePostItemJournalLine_(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferReceiptHeader: Record "Transfer Receipt Header"; TransferReceiptLine: Record "Transfer Receipt Line"; CommitIsSuppressed: Boolean; TransLine: Record "Transfer Line"; PostedWhseRcptHeader: Record "Posted Whse. Receipt Header")
    begin
        ItemJournalLine."Customer No." := TransferReceiptHeader."Customer No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforePostItemJournalLine', '', false, false)]
    local procedure OnBeforePostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line"; CommitIsSuppressed: Boolean)
    begin
        ItemJournalLine."Customer No." := TransferShipmentHeader."Customer No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    begin
        NewItemLedgEntry."Customer No." := ItemJournalLine."Customer No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptHeader', '', false, false)]
    local procedure OnAfterInsertTransShptHeader(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header");
    begin
        TransferShipmentHeader."Customer No." := TransferHeader."Customer No.";
        TransferShipmentHeader."Ship to Code" := TransferHeader."Ship to Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforeInsertTransShptHeader', '', false, false)]
    local procedure OnBeforeInsertTransShptHeader(var TransShptHeader: Record "Transfer Shipment Header"; TransHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean);
    begin
        TransShptHeader."Customer No." := TransHeader."Customer No.";
        TransShptHeader."Ship to Code" := TransHeader."Ship to Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', false, false)]
    local procedure OnBeforeTransRcptHeaderInsert(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header");
    begin
        TransferReceiptHeader."Customer No." := TransferHeader."Customer No.";
        TransferReceiptHeader."Ship to Code" := TransferHeader."Ship to Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyItemJnlLineFromSalesHeader', '', false, false)]
    local procedure OnAfterCopyItemJnlLineFromSalesHeader(var ItemJnlLine: Record "Item Journal Line"; SalesHeader: Record "Sales Header");
    begin
        ItemJnlLine."Customer No." := SalesHeader."Sell-to Customer No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert(var Rec: Record "Item Ledger Entry"; RunTrigger: Boolean);
    var
        DevicelinkedtoLicense: record "Dozee Device";
        Customer_l: Record Customer;
        Item_lRec: Record Item;
        FindItemLedgerEntry_lRec: Record "Item Ledger Entry";
        EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
    begin
        // IF Not Rec.IsEmpty then
        //     exit;
        IF Rec.IsTemporary then exit;
        IF NOT (Rec."Document Type" in [Rec."Document Type"::"Sales Return Receipt", Rec."Document Type"::"Transfer Receipt", Rec."Document Type"::"Sales Shipment"]) then exit;
        //If (Rec."Document Type" <> Rec."Document Type"::"Sales Shipment") Then
        //    exit;
        Clear(Item_lRec);
        if Item_lRec.Get(Rec."Item No.") then IF Not Item_lRec."Devices Item" then exit;
        If Rec."Document Type" = Rec."Document Type"::"Sales Return Receipt" then begin
            DevicelinkedtoLicense.Reset();
            DevicelinkedtoLicense.SetRange("Serial No.", Rec."Serial No.");
            IF DevicelinkedtoLicense.IsEmpty then exit;
        end;
        IF Rec.Quantity > 0 then begin
            FindItemLedgerEntry_lRec.Reset();
            FindItemLedgerEntry_lRec.SetRange("Item No.", Rec."Item No.");
            IF Rec."Item Tracking" <> Rec."Item Tracking"::None then begin
                IF Rec."Serial No." <> '' then FindItemLedgerEntry_lRec.SetRange("Serial No.", Rec."Serial No.");
                IF Rec."Lot No." <> '' then FindItemLedgerEntry_lRec.SetRange("Lot No.", Rec."Lot No.");
            end;
            FindItemLedgerEntry_lRec.SetRange("Customer No.", Rec."Customer No.");
            FindItemLedgerEntry_lRec.SetFilter("Entry No.", '<>%1', Rec."Entry No.");
            case Rec."Document Type" of
                Rec."Document Type"::"Sales Return Receipt", Rec."Document Type"::"Sales Shipment":
                    begin
                        FindItemLedgerEntry_lRec.SetRange("Entry Type", FindItemLedgerEntry_lRec."Entry Type"::Sale);
                        FindItemLedgerEntry_lRec.SetRange("Document Type", FindItemLedgerEntry_lRec."Document Type"::"Sales Shipment");
                        FindItemLedgerEntry_lRec.SetFilter(Quantity, '<%1', 0);
                    end;
                Rec."Document Type"::"Transfer Receipt":
                    begin
                        FindItemLedgerEntry_lRec.SetRange("Entry Type", FindItemLedgerEntry_lRec."Entry Type"::Transfer);
                        FindItemLedgerEntry_lRec.SetRange("Document Type", FindItemLedgerEntry_lRec."Document Type"::"Transfer Receipt");
                        FindItemLedgerEntry_lRec.SetRange("Demo Location", true);
                        FindItemLedgerEntry_lRec.SetRange("Remaining Quantity", 0);
                    end;
            end;
            IF FindItemLedgerEntry_lRec.FindLast() then begin
                DevicelinkedtoLicense.Reset();
                DevicelinkedtoLicense.SetRange("Item Ledger Entry No.", FindItemLedgerEntry_lRec."Entry No.");
                IF DevicelinkedtoLicense.FindFirst() then begin
                    IF not DevicelinkedtoLicense.Return then begin
                        DevicelinkedtoLicense.Return := true;
                        DevicelinkedtoLicense.Licensed := false;
                        DevicelinkedtoLicense.Validate("License No.", '');
                        DevicelinkedtoLicense.Modify(true);
                        ActiveLicMgt_gCdu.InsertArchiveDeviceLedgEntry(DevicelinkedtoLicense);
                        EMSAPIMgt_lCdu.ExpireTerminateDeviceLicense(DevicelinkedtoLicense, 1);
                        exit;
                    end;
                end;
            end;
        end;
        Clear(Customer_l);
        Rec.CalcFields("Demo Location");
        IF (Rec."Document Type" = Rec."Document Type"::"Transfer Receipt") then begin
            IF (Rec."Demo Location") then InsertDeviceLinkedToLic_gFnc(Rec);
        end
        else
            InsertDeviceLinkedToLic_gFnc(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Item", 'OnAfterModifyEvent', '', false, false)]
    local procedure ServItem_OnAfterModifyEvent(RunTrigger: Boolean; var Rec: Record "Service Item"; var xRec: Record "Service Item")
    var
        ItemLedgerEntry_lRec: Record "Item Ledger Entry";
        DeviceLinkedToLic_lRec: Record "Dozee Device";
    begin
        ItemLedgerEntry_lRec.Reset();
        ItemLedgerEntry_lRec.SetRange("Document No.", Rec."Sales/Serv. Shpt. Document No.");
        ItemLedgerEntry_lRec.SetRange("Document Line No.", Rec."Sales/Serv. Shpt. Line No.");
        ItemLedgerEntry_lRec.SetRange("Entry Type", ItemLedgerEntry_lRec."Entry Type"::Sale);
        ItemLedgerEntry_lRec.SetRange("Serial No.", Rec."Serial No.");
        ItemLedgerEntry_lRec.SetRange("Document Type", ItemLedgerEntry_lRec."Document Type"::"Sales Shipment");
        IF ItemLedgerEntry_lRec.FindSet() then begin
            repeat
                DeviceLinkedToLic_lRec.Reset();
                DeviceLinkedToLic_lRec.SetRange("Item Ledger Entry No.", ItemLedgerEntry_lRec."Entry No.");
                IF DeviceLinkedToLic_lRec.FindFirst() then begin
                    IF DeviceLinkedToLic_lRec."Warranty Start Date" <> Rec."Warranty Starting Date (Parts)" then DeviceLinkedToLic_lRec.Validate("Warranty Start Date", Rec."Warranty Starting Date (Parts)");
                    IF DeviceLinkedToLic_lRec."Warranty End Date" <> rec."Warranty Ending Date (Parts)" then DeviceLinkedToLic_lRec.Validate("Warranty End Date", Rec."Warranty Ending Date (Parts)");
                    IF DeviceLinkedToLic_lRec."Installation Date" <> rec."Installation Date" then DeviceLinkedToLic_lRec.Validate("Installation Date", Rec."Installation Date");
                    DeviceLinkedToLic_lRec.Modify(true);
                    ActiveLicMgt_gCdu.InsertArchiveDeviceLedgEntry(DeviceLinkedToLic_lRec);
                end;
            until ItemLedgerEntry_lRec.Next() = 0;
        end;
    end;

    var
        ActiveLicMgt_gCdu: Codeunit "Active License Mgt.";
}
