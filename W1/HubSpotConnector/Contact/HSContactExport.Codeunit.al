codeunit 51318 "Hubspot Contact Export"
{
    Access = Internal;
    TableNo = Contact;
    trigger OnRun()
    var
        Contact: Record Contact;
        HubspotContact: Record "Hubspot Contact";
    begin
        Contact.CopyFilters(Rec);
        if Contact.FindSet(false) then
            repeat
                HubspotContact.SetRange("Contact SystemId", Contact.SystemId);
                if not HubspotContact.FindFirst() then begin
                    if CreateContacts then
                        CreateHubspotContact(Contact)
                end else
                    if not CreateContacts then
                        UpdateHubspotContact(Contact, HubspotContact.Id);
                Commit();
            until Contact.Next() = 0;
    end;

    var
        ContactAPI: Codeunit "Hubspot Contact API";
        CreateContacts: Boolean;

    local procedure CreateHubspotContact(Contact: Record Contact)
    var
        HubspotContact: Record "Hubspot Contact";
    begin
        if Contact."E-Mail" = '' then
            exit;
        if FillInHubspotContact(Contact, HubspotContact) then begin
            if ContactAPI.CreateContact(HubspotContact) then begin
                HubspotContact."Contact SystemId" := Contact.SystemId;
                HubspotContact."Last Updated by BC" := CurrentDateTime();
                HubspotContact.Insert();
            end;

        end;

    end;

    internal procedure FillInHubspotContact(Contact: Record Contact; var HubspotContact: Record "Hubspot Contact"): Boolean
    var
        TempHubspotContact: Record "Hubspot Contact" temporary;
        // KAM: Record KAM;
        SalesPerson: Record "Salesperson/Purchaser";
        Country: Record "Country/Region";
    // State: Record State;
    begin
        TempHubspotContact := HubspotContact;
        HubspotContact."First Name" := Contact."First Name";
        HubspotContact."Salutation Code" := Contact."Salutation Code";
        HubspotContact."Job Title" := Contact."Job Title";
        HubspotContact."Middle Name" := Contact."Middle Name";
        HubspotContact."Last Name" := Contact.Surname;
        HubspotContact.Address := Contact.Address;
        HubspotContact."Address 2" := Contact."Address 2";
        HubspotContact.City := Contact.City;
        if Country.Get(Contact."Country/Region Code") then
            HubspotContact."Country/Region Code" := Country.Name;
        HubspotContact."Post Code" := Contact."Post Code";
        HubspotContact."Phone No." := Contact."Phone No.";
        HubspotContact."Mobile Phone No." := Contact."Mobile Phone No.";
        HubspotContact."Company No." := Contact."Company No.";
        // HubspotContact."Financial Comm" := Contact."Financial Communication";

        if HasDiff(HubspotContact, TempHubspotContact) then begin
            HubspotContact."Last Updated by BC" := CurrentDateTime;
            exit(true);
        end;
    end;

    local procedure HasDiff(RecAsVariant: Variant; xRecAsVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
        xRecordRef: RecordRef;
        Index: Integer;
    begin
        RecordRef.GetTable(RecAsVariant);
        xRecordRef.GetTable(xRecAsVariant);
        if RecordRef.Number = xRecordRef.Number then
            for Index := 1 to RecordRef.FieldCount do
                if RecordRef.FieldIndex(Index).Value <> xRecordRef.FieldIndex(Index).Value then
                    exit(true);
    end;

    local procedure UpdateHubspotContact(Contact: Record Contact; ContactId: BigInteger)
    var
        HubspotContact: Record "Hubspot Contact";
    begin
        HubspotContact.Get(ContactId);
        if HubspotContact."Contact SystemId" <> Contact.SystemId then
            exit;

        if FillInHubspotContact(Contact, HubspotContact) then begin
            ContactAPI.UpdateContact(HubspotContact);
            HubspotContact.Modify();
        end;
    end;

    internal procedure SetCreateContacts(NewContacts: Boolean)
    begin
        CreateContacts := NewContacts;
    end;
}