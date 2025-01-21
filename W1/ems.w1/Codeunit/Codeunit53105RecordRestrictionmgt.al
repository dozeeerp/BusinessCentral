codeunit 52104 "EMS Record Restriction mgt"
{
    trigger OnRun()
    begin

    end;

    var
        RecordRestriction: Codeunit "Record Restriction Mgt.";

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnCheckLicenseReleaseRestrictions', '', false, false)]
    procedure SalesHeaderCheckSalesReleaseRestrictions(var Sender: Record "License Request")
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnAfterRenameEvent', '', false, false)]
    Local procedure UpdateLicenseRequestRestrictionsAfterRename(var Rec: Record "License Request"; var xRec: Record "License Request"; RunTrigger: Boolean)
    begin
        RecordRestriction.UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure RemoveLicenseRequestRestrictionsBeforeDelete(var Rec: Record "License Request")
    begin
        RecordRestriction.AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnCheckLicenseActivationRestrictions', '', false, false)]
    local procedure CustomerCheckLicenseActivationRestrictions(sender: Record "License Request")
    var
        Customer: Record Customer;
    begin
        Customer.get(sender."Customer No.");
        RecordRestriction.CheckRecordHasUsageRestrictions(Customer);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnCheckLicenseActivationRestrictions', '', false, false)]
    local procedure LicenseRequestCheckLicenseActivationRestrictions(sender: Record "License Request")
    begin
        RecordRestriction.CheckRecordHasUsageRestrictions(sender)
    end;
}