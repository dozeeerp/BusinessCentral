namespace TSTChanges.EMS;

using TSTChanges.FA.Ledger;
using TSTChanges.FA.FAItem;
using Microsoft.Sales.Customer;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Inventory.Location;

codeunit 51241 "EMS Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CustomerNoEmptyError: Label 'Customer No. can not be empty when transfring the devices to %1';
        ISPL_ActiveLicMgt: Codeunit "Active License Mgt.";
        EMSAPIMgt: Codeunit "EMS API Mgt";
        PreviewPosting: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"FA Item ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertFAILEInsertDozeeDeviceList(var Rec: Record "FA Item ledger Entry")
    var
        FAItem: Record "FA Item";
        Location: Record Location;
    begin
        if Rec.IsTemporary then
            exit;

        if not FAItem.IsDozeeDevice(rec."FA Item No.") then
            exit;

        if Location.IsInTransit(rec."Location Code") then
            exit;

        Location.Get(rec."Location Code");

        if not Location."Demo Location" then
            exit;

        if Rec."Customer No." = '' then
            Error(CustomerNoEmptyError, rec."Location Code");

        if Rec.Quantity >= 1 then
            InsertDozeeDeviceList(Rec)
        else
            MarkDozeeDeviceReturn(Rec);
    end;

    Local procedure InsertDozeeDeviceList(FAILE: Record "FA Item ledger Entry")
    var
        DozeeDevice: Record "Dozee Device";
        Cust: Record Customer;

        lastNo: Integer;
    begin
        lastNo := 0;
        DozeeDevice.Reset();
        if DozeeDevice.FindLast() then
            lastNo := DozeeDevice."Entry No.";

        DozeeDevice.Init();
        DozeeDevice."Entry No." := lastNo + 1;
        DozeeDevice."Document No." := FAILE."Document No.";
        DozeeDevice."Posting Date" := FAILE."Posting Date";
        DozeeDevice."Item No" := FAILE."FA Item No.";
        DozeeDevice.Variant := FAILE."Variant Code";
        DozeeDevice."Item Description" := FAILE.Description;
        DozeeDevice."Customer No." := FAILE."Customer No.";
        DozeeDevice."Serial No." := FAILE."Serial No.";
        DozeeDevice."Source Type" := DozeeDevice."Source Type"::Customer;
        DozeeDevice."Source No." := FAILE."Customer No.";
        Cust.Get(FAILE."Customer No.");
        DozeeDevice."Customer Name" := Cust.Name;
        if Cust."Is Partner" then
            DozeeDevice."Partner No." := Cust."No.";
        if Cust."Partner ID" <> '' then
            DozeeDevice."Partner No." := Cust."Partner ID";
        DozeeDevice."Org ID" := Cust."Organization ID";
        DozeeDevice.Type := DozeeDevice.Type::Asset;
        DozeeDevice."Item Ledger Entry No." := FAILE."Entry No.";
        if not PreviewPosting then begin
            EMSAPIMgt.GetDeviceLicenseId(DozeeDevice);
            EMSAPIMgt.ExpireTerminateDeviceLicense(DozeeDevice, 1);
            EMSAPIMgt.SendDeviceVariant(DozeeDevice);
        end;
        ISPL_ActiveLicMgt.InsertArchiveDeviceLedgEntry(DozeeDevice);

        DozeeDevice.Insert(true);
    end;

    local procedure MarkDozeeDeviceReturn(FAILE: Record "FA Item ledger Entry")
    var
        FAItemApplnEntry: Record "FA Item Application Entry";
        DozeeDevice: Record "Dozee Device";
    begin
        FAItemApplnEntry.Reset();
        FAItemApplnEntry.SetRange("Item Ledger Entry No.", FAILE."Entry No.");
        if FAItemApplnEntry.FindSet() then begin
            DozeeDevice.Reset();
            DozeeDevice.SetRange(Return, false);
            DozeeDevice.SetRange("Item Ledger Entry No.", FAItemApplnEntry."Inbound Item Entry No.");
            if DozeeDevice.FindSet() then
                repeat
                    DozeeDevice.Return := true;
                    DozeeDevice.Modify(true);
                    if not PreviewPosting then
                        EMSAPIMgt.ExpireTerminateDeviceLicense(DozeeDevice, 1);
                    ISPL_ActiveLicMgt.InsertArchiveDeviceLedgEntry(DozeeDevice);
                until DozeeDevice.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterBindSubscription', '', false, false)]
    local procedure OnAfterBindSubscription()
    begin
        PreviewPosting := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterUnBindSubscription', '', false, false)]
    local procedure OnAfterUnBindSubscription()
    begin
        PreviewPosting := false;
    end;
}