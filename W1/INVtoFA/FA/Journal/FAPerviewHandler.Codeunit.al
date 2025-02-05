namespace TSTChanges.FA.Journal;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.Posting;
using TSTChanges.FA.History;
using Microsoft.Finance.GST.Base;
using TSTChanges.FA.Ledger;

codeunit 51213 "FA Preview Handler"
{
    SingleInstance = true;

    var
        TempFAItemLedgerEntry: Record "FA Item ledger Entry" temporary;
        TempDozeeDevice: Record "Device linked to License" temporary;
        TempDozeeDeviceArchive: Record "Archive Device Led. Entry" temporary;
        DocumentNoTxt: Label '***', Locked = true;
        PreviewPosting: Boolean;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnGetEntries, '', false, false)]
    local procedure OnGetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
        Case TableNo of
            Database::"FA Item ledger Entry":
                RecRef.GETTABLE(TempFAItemLedgerEntry);
            Database::"Device linked to License":
                RecRef.GetTable(TempDozeeDevice);
            Database::"Archive Device Led. Entry":
                RecRef.GetTable(TempDozeeDeviceArchive);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterShowEntries, '', false, false)]
    local procedure OnAfterShowEntries(TableNo: Integer)
    begin
        case TableNo of
            Database::"FA Item ledger Entry":
                Page.Run(PAGE::"FA Item Ledger Entries", TempFAItemLedgerEntry);
            Database::"Device linked to License":
                Page.Run(Page::"Device linked to License list", TempDozeeDevice);
            Database::"Archive Device Led. Entry":
                Page.Run(Page::"Archive Device Ledger Entry", TempDozeeDeviceArchive);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Item ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure SavePreviewFAItemLedEntry(var Rec: Record "FA Item ledger Entry"; RunTrigger: Boolean)
    begin
        if not PreviewPosting then
            exit;

        if Rec.IsTemporary() then
            exit;

        TempFAItemLedgerEntry := Rec;
        TempFAItemLedgerEntry."Document No." := DocumentNoTxt;
        TempFAItemLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Device linked to License", OnAfterInsertEvent, '', false, false)]
    local procedure SavePreviewDozeeDeviceEntry(var Rec: Record "Device linked to License"; RunTrigger: Boolean)
    begin
        if not PreviewPosting then
            exit;

        if Rec.IsTemporary() then
            exit;

        TempDozeeDevice := Rec;
        TempDozeeDevice."Document No." := DocumentNoTxt;
        TempDozeeDevice.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Archive Device Led. Entry", OnAfterInsertEvent, '', false, false)]
    local procedure SacePreviewDozeeDeviceArchiveEntry(var Rec: Record "Archive Device Led. Entry")
    begin
        if not PreviewPosting then
            exit;
        if Rec.IsTemporary then
            exit;

        TempDozeeDeviceArchive := Rec;
        TempDozeeDeviceArchive.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterFillDocumentEntry, '', false, false)]
    local procedure OnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry" temporary)
    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
    begin
        PostingPreviewEventHandler.InsertDocumentEntry(TempFAItemLedgerEntry, DocumentEntry);
        PostingPreviewEventHandler.InsertDocumentEntry(TempDozeeDevice, DocumentEntry);
        PostingPreviewEventHandler.InsertDocumentEntry(TempDozeeDeviceArchive, DocumentEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Conversion-Post", OnBeforeOnRun, '', false, false)]
    local procedure OnBeforePostConversionDoc()
    begin
        DeleteTempFAItemLedEntry();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FATransferOrder-Post Shipment", OnBeforeOnRun, '', false, false)]
    local procedure OnBeforePostFATransferShipment()
    begin
        DeleteTempFAItemLedEntry();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FATransferOrder-Post Receipt", OnBeforeOnRun, '', false, false)]
    local procedure OnBeforePostFATransferReceipt()
    begin
        DeleteTempFAItemLedEntry();
    end;

    local procedure DeleteTempFAItemLedEntry()
    begin
        TempFAItemLedgerEntry.Reset();
        if not TempFAItemLedgerEntry.IsEmpty() then
            TempFAItemLedgerEntry.DeleteAll();

        TempDozeeDevice.Reset();
        if not TempDozeeDevice.IsEmpty then
            TempDozeeDevice.DeleteAll();

        TempDozeeDeviceArchive.Reset();
        if not TempDozeeDeviceArchive.IsEmpty then
            TempDozeeDeviceArchive.DeleteAll();
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

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure ShowEntries(DocNoFilter: Text; PostingDateFilter: Text; var TempDocumentEntry: Record "Document Entry"; var IsHandled: Boolean)
    var
        FAItemLedgEntry: Record "FA Item ledger Entry";
        PostedConHeader: Record "Posted Conversion Header";
        FATranShipHdr: Record "FA Transfer Shipment Header";
    begin
        case TempDocumentEntry."Table ID" of
            Database::"FA Item ledger Entry":
                begin
                    FAItemLedgEntry.Reset();
                    FAItemLedgEntry.SetRange("Document No.", DocNoFilter);
                    FAItemLedgEntry.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, FAItemLedgEntry);
                end;
            Database::"Posted Conversion Header":
                begin
                    PostedConHeader.Reset();
                    PostedConHeader.SetFilter("No.", DocNoFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        Page.Run(Page::"Posted Conversion Order", PostedConHeader)
                    else
                        Page.Run(0, PostedConHeader);
                end;
            Database::"FA Transfer Shipment Header":
                begin
                    FATranShipHdr.Reset();
                    FATranShipHdr.SetFilter("No.", DocNoFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        Page.Run(Page::"Posted FA Transfer Shipment", FATranShipHdr)
                    else
                        Page.Run(0, FATranShipHdr);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure FindFAEntries(sender: Page Navigate; DocNoFilter: Text; var DocumentEntry: Record "Document Entry" temporary; PostingDateFilter: Text)
    var
        PostedConversionHeader: Record "Posted Conversion Header";
        FAItemLedgEntry: Record "FA Item ledger Entry";
        FATransferShipHeader: Record "FA Transfer Shipment Header";
        FATransRecHdr: Record "FA Transfer Receipt Header";
        PostedConversionOrderTxt: Label 'Posted Assembly Order';
    begin
        if PostedConversionHeader.ReadPermission() then begin
            PostedConversionHeader.Reset();
            PostedConversionHeader.SetFilter("No.", DocNoFilter);
            // sender.InsertIntoDocEntry(DocumentEntry, Database::"Posted Conversion Header", PostedConversionOrderTxt, PostedConversionHeader.Count);
            DocumentEntry.InsertIntoDocEntry(Database::"Posted Conversion Header", PostedConversionOrderTxt, PostedConversionHeader.Count);
        end;

        if FATransferShipHeader.ReadPermission() then begin
            FATransferShipHeader.Reset();
            FATransferShipHeader.SetFilter("No.", DocNoFilter);
            // sender.InsertIntoDocEntry(DocumentEntry, Database::"FA Transfer Shipment Header", FATransferShipHeader.TableCaption, FATransferShipHeader.Count);
            DocumentEntry.InsertIntoDocEntry(Database::"FA Transfer Shipment Header", FATransferShipHeader.TableCaption, FATransferShipHeader.Count);
        end;

        if FATransRecHdr.ReadPermission() then begin
            FATransRecHdr.Reset();
            FATransRecHdr.SetFilter("No.", DocNoFilter);
            // sender.InsertIntoDocEntry(DocumentEntry, Database::"FA Transfer Receipt Header", FATransRecHdr.TableCaption, FATransRecHdr.Count);
            DocumentEntry.InsertIntoDocEntry(Database::"FA Transfer Receipt Header", FATransRecHdr.TableCaption, FATransRecHdr.Count);
        end;

        if FAItemLedgEntry.ReadPermission() then begin
            FAItemLedgEntry.Reset();
            FAItemLedgEntry.SetCurrentKey("Document No.");
            FAItemLedgEntry.SetFilter("Document No.", DocNoFilter);
            FAItemLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            // sender.InsertIntoDocEntry(DocumentEntry, Database::"FA Item Ledger Entry", FAItemLedgEntry.TableCaption(), FAItemLedgEntry.Count);
            DocumentEntry.InsertIntoDocEntry(Database::"FA Item Ledger Entry", FAItemLedgEntry.TableCaption(), FAItemLedgEntry.Count);
        end;
    end;
}