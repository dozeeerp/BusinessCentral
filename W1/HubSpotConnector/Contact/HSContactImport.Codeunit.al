codeunit 51317 "Hubspot Contact Import"
{
    Access = Internal;
    TableNo = "Hubspot Contact";

    trigger OnRun()
    begin
        HSSetup.Get();
        if Rec.Id = 0 then
            exit;
        SetContact(rec.Id);

        if not ContactAPI.RetrieveHubspotContacts(HubspotContact) then begin
            HubspotContact.Delete();
            exit;
        end;

        Commit();
        if ContactMapping.FindMapping(HubspotContact) then begin
            UpdateContact.UpdateContactFromContact(HubspotContact);
        end
        else
            if UpdateContact.GetAssociatedCustomer(HubspotContact.Id) then begin
                UpdateContact.CreateContactFromContact(HubspotContact);
            end
            else
                if HSSetup."Create Cutomer" = HSSetup."Create Cutomer"::AllCompanies then
                    UpdateContact.CreateContactFromContact(HubspotContact);
    end;

    var
        HubspotContact: Record "Hubspot Contact";
        ContactAPI: Codeunit "Hubspot Contact API";
        ContactMapping: Codeunit "Hubspot Contact Mapping";
        UpdateContact: Codeunit "Hubspot Update Contact";
        HSSetup: Record "Hubspot Setup";

    local procedure SetContact(Id: BigInteger)
    begin
        if Id <> 0 then begin
            Clear(HubspotContact);
            HubspotContact.SetRange(Id, Id);
            if not HubspotContact.FindFirst() then begin
                HubspotContact.Id := Id;
                HubspotContact.Insert(false);
            end;
        end;
    end;
}