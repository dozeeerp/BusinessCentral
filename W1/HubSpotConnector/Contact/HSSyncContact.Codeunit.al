namespace TST.Hubspot.Contact;

using TST.Hubspot.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;

codeunit 51316 "Hubspot Sync Contacts"
{
    Access = Internal;
    trigger OnRun()
    var
        SyncStartTime: DateTime;
        HSSetup: Record "Hubspot Setup";
    begin
        HSSetup.Get();
        SyncStartTime := CurrentDateTime;
        if HSSetup."Company Import From Hubspot" = HSSetup."Company Import From Hubspot"::AllCompanies then
            ImportContactsFromHubspot();
        if HSSetup."Can Update Hubspot Companies" then
            ExportContactsToHubSpot();

        HSSetup.SetLastSyncTime(SyncStartTime);
        HSSetup.Modify()
    end;

    var
        ContactAPI: Codeunit "Hubspot Contact API";
        ContactExport: Codeunit "Hubspot Contact Export";
        ContactImport: Codeunit "Hubspot Contact Import";

    local procedure ImportContactsFromHubspot()
    var
        Contact: Record "Hubspot Contact";
        TempContact: Record "Hubspot Contact" temporary;
        ID: BigInteger;
        UpdatedAt: DateTime;
        ContactIds: Dictionary of [BigInteger, DateTime];
    begin
        ContactAPI.RetrieveHubspotContactIds(ContactIds);
        foreach ID in ContactIds.Keys do begin
            Contact.SetRange(Id, ID);
            if Contact.FindFirst() then begin
                ContactIds.Get(ID, UpdatedAt);
                if ((Contact."Updated At" = 0DT) or (Contact."Updated At" < UpdatedAt)) and (Contact."Last Updated by BC" < UpdatedAt) then begin
                    TempContact := Contact;
                    TempContact.Insert(false);
                end;
            end else begin
                Clear(TempContact);
                TempContact.Id := ID;
                TempContact.Insert(false);
            end;
        end;
        Clear(TempContact);
        if TempContact.FindSet(false) then
            repeat
                ContactImport.Run(TempContact);
            until TempContact.Next() = 0;
    end;

    local procedure ExportContactsToHubSpot()
    var
        Contact: Record Contact;
    begin
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetRange("Contact Business Relation", Contact."Contact Business Relation"::Customer);
        ContactExport.SetCreateContacts(false);
        ContactExport.Run(Contact);
    end;

}