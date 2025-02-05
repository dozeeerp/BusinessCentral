namespace TST.Hubspot.Contact;

using Microsoft.CRM.Contact;

codeunit 51319 "Hubspot Contact Mapping"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    internal procedure DoMapping()
    begin

    end;

    internal procedure FindMapping(var HubspotContact: Record "Hubspot Contact"): Boolean
    var
        Contact: Record Contact;
    begin
        if not IsNullGuid(HubspotContact."Contact SystemId") then
            if Contact.GetBySystemId(HubspotContact."Contact SystemId") then
                exit(true)
            else begin
                Clear(HubspotContact."Contact SystemId");
                HubspotContact.Modify();
            end;
    end;
}