namespace TSTChanges.Automation;

using System.Automation;
using Microsoft.Inventory.Transfer;
using TSTChanges.FA.Conversion;
using Microsoft.Sales.Customer;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.Journal;
using TSTChanges.FA.FAItem;

codeunit 51238 "TST Record Restriction Mgt"
{
    trigger OnRun()
    begin

    end;

    var
        RecordRestriction: Codeunit "Record Restriction Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Transfer Document", 'OnRunOnBeforeSetStatusReleased', '', false, false)]
    local procedure OnRunOnBeforeSetStatusReleased(var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.CheckTransferReleaseRestrictions();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnCheckTransferReleaseRestrictions', '', false, false)]
    local procedure TransferHeaderCheckTransferReleaseRestrictions(var Sender: Record "Transfer Header")
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion Header", OnCheckConversionReleaseRestrictions, '', false, false)]
    Local procedure ConversionHeaderCheckConversionReleaseRestrictions(sender: Record "FA Conversion Header")
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Transfer Header", OnCheckFATransferReleaseRestrictions, '', false, false)]
    local procedure FATransferHeaderCheckReleaseRestrictions(sender: Record "FA Transfer Header")
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateTransferHeaderRestrictionsAfterRename(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; RunTrigger: Boolean)
    begin
        RecordRestriction.UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion Header", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateConversionHeaderRestrictionsAfterRename(var Rec: Record "FA Conversion Header"; var xRec: Record "FA Conversion Header"; RunTrigger: Boolean)
    begin
        RecordRestriction.UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Transfer Header", OnAfterRenameEvent, '', false, false)]
    procedure UpdateFATransferHeaderRestrictionAfterRename(var Rec: Record "FA Transfer Header"; var xRec: Record "FA Transfer Header")
    begin
        RecordRestriction.UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveTransferHeaderRestrictionsBeforeDelete(var Rec: Record "Transfer Header"; RunTrigger: Boolean)
    begin
        RecordRestriction.AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Conversion Header", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveConversionHeaderRestrictionsBeforeDelete(var Rec: Record "FA Conversion Header"; RunTrigger: Boolean)
    begin
        RecordRestriction.AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Transfer Header", OnBeforeDeleteEvent, '', false, false)]
    Procedure RemoveFATransferRestrictionsBeforeDelete(var Rec: Record "FA Transfer Header")
    begin
        RecordRestriction.AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnCheckTransferPostRestrictions', '', false, false)]
    procedure TransferHeaderCheckTransferPostRestrictions(sender: Record "Transfer Header")
    var
        Customer: Record Customer;
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(sender);
        if sender."Customer No." <> '' then begin
            Customer.Get(sender."Customer No.");
            RecordRestriction.CheckRecordHasUsageRestrictions(Customer);
        end;
    end;

    [EventSubscriber(ObjectType::Table, database::"FA Conversion Header", OnCheckConversionPostRestrictions, '', false, false)]
    local procedure ConversionHeaderCheckPostRestrictions(sender: Record "FA Conversion Header")
    var
        FAItem: Record "FA Item";
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(sender);
        FAItem.Get(sender."FA Item No.");
        RecordRestriction.CheckRecordHasUsageRestrictions(FAItem);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Transfer Header", OnCheckFATransferPostRestrictions, '', false, false)]
    local procedure FATransferHeaderCheckPostRestrictions(sender: Record "FA Transfer Header")
    var
        Customer: Record Customer;
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(sender);
        if sender."Transfer-from Customer" <> '' then begin
            Customer.Get(sender."Transfer-from Customer");
            RecordRestriction.CheckRecordHasUsageRestrictions(Customer)
        end;
        if sender."Transfer-to Customer" <> '' then begin
            Customer.Get(sender."Transfer-to Customer");
            RecordRestriction.CheckRecordHasUsageRestrictions(Customer)
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post (Yes/No)", 'OnCodeOnBeforePostTransferOrder', '', false, false)]
    local procedure TransferOrderCheckPostTransferRestrictions(var TransHeader: Record "Transfer Header")
    begin
        TransHeader.CheckTransferPostRestrictions();
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Item", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveItemRestrictionsBeforeDelete(var Rec: Record "FA Item"; RunTrigger: Boolean)
    begin
        RecordRestriction.AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Item Journal Line", 'OnCheckItemJournalLinePostRestrictions', '', false, false)]
    local procedure ItemJournalLineCheckItemPostRestrictions(var Sender: Record "FA Item Journal Line")
    var
        FAItem: Record "FA Item";
        IsHandled: Boolean;
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(Sender);
        FAItem.Get(Sender."FA Item No.");
        RecordRestriction.CheckRecordHasUsageRestrictions(FAItem);
    end;
}