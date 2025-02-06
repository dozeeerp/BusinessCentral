codeunit 51315 "Hubspot Contact API"
{
    trigger OnRun()
    begin

    end;

    var
        JsonHelper: Codeunit "Hubspot Json Helper";
        HSConnect: Codeunit "HubSpot Connect";

    internal procedure CreateContact(HubSpotContact: Record "HubSpot Contact"): Boolean
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;
        Object: Text;
    begin
        ContactProperty(PropertyObject, HubSpotContact);
        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        Object := 'contacts';
        HSConnect.CreateNewRowInObject(Object, Body);
    end;

    internal procedure UpdateContact(HubSpotContact: Record "HubSpot Contact"): Boolean
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;
        Object: Text;
    begin
        ContactProperty(PropertyObject, HubSpotContact);
        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        Object := 'contacts/' + Format(HubspotContact.Id);
        HSConnect.UpdateRecordOnHubSpot(Object, Body);
    end;

    local procedure ContactProperty(PropertyObject: JsonObject; HubSpotContact: Record "HubSpot Contact")
    var
        HSSetup: Record "Hubspot Setup";
    begin
        HSSetup.Get();
        PropertyObject.Add('firstname', HubSpotContact."First Name");
        PropertyObject.Add('salutation', HubSpotContact."Salutation Code");
        PropertyObject.Add('jobtitle', HubSpotContact."Job Title");
        PropertyObject.Add('middle_name', HubSpotContact."Middle Name");
        PropertyObject.Add('lastname', HubSpotContact."Last Name");
        PropertyObject.Add('address', HubSpotContact.Address);
        PropertyObject.Add('address_2', HubSpotContact."Address 2");
        PropertyObject.Add('city', HubSpotContact.City);
        PropertyObject.Add('country', HubSpotContact."Country/Region Code");
        PropertyObject.Add('zip', HubSpotContact."Post Code");
        PropertyObject.Add('email', HubSpotContact."E-Mail");
        PropertyObject.Add('phone', HubSpotContact."Phone No.");
        PropertyObject.Add('mobilephone', HubSpotContact."Mobile Phone No.");
        PropertyObject.Add('erp_company_no', HubSpotContact."Company No.");
        PropertyObject.Add('fin__communication', HubSpotContact."Financial Comm");
        HubSpotContact.CalcFields("Contact No.");
        PropertyObject.Add('erp_contact_no_', HubSpotContact."Contact No.");
        if HSSetup."Business Unit" <> '' then
            PropertyObject.Add('hs_all_assigned_business_unit_ids', HSSetup."Business Unit");
    end;

    internal procedure RetrieveHubspotContactIds(var ContactIds: Dictionary of [BigInteger, DateTime])
    var
        JResponse: JsonToken;
        Parameters: Text;
        JContact: JsonArray;
        JItem: JsonToken;
        Id: BigInteger;
        UpdatedAt: DateTime;
        After: BigInteger;
        Filters: Text;
        HSSetup: Record "Hubspot Setup";
        BusinessUsnit: Boolean;
    begin
        Parameters := '?limit=100&archived=false';

        HSSetup.Get();
        if not (HSSetup."Business Unit" = '') then begin
            Parameters := '/search?archived=false';
            Filters := '{"filterGroups":[{"filters":[{"propertyName": "hs_all_assigned_business_unit_ids","value": "'
                + HSSetup."Business Unit"
                + '","operator": "EQ"}]}],"limit": 200}';
            BusinessUsnit := true;
        end;
        repeat
            if After <> 0 then
                if BusinessUsnit then
                    Filters := '{"filterGroups":[{"filters":[{"propertyName": "hs_all_assigned_business_unit_ids","value": "'
                            + HSSetup."Business Unit"
                            + '","operator": "EQ"}]}],"limit": 200, "after" : '
                            + Format(After)
                            + '}'
                else
                    Parameters := '?limit=100&archived=false&after=' + Format(After);
            JResponse := HSConnect.GetObjectList('contacts', Parameters, Filters);
            if JsonHelper.GetJsonArray(JResponse, JContact, 'results') then begin
                foreach JItem in JContact do begin
                    Id := JsonHelper.GetValueAsBigInteger(JItem, 'id');
                    UpdatedAt := JsonHelper.GetValueAsDateTime(JItem, 'updatedAt');
                    ContactIds.Add(Id, UpdatedAt)
                end;
            end;
            After := JsonHelper.GetValueAsBigInteger(JResponse, 'paging.next.after');
        until After = 0
    end;

    internal procedure RetrieveHubspotContacts(var HubspotContact: Record "HubSpot Contact"): Boolean
    var
        JResponse: JsonToken;
        Object: Text;
        Property: Text;
    begin
        if HubspotContact.Id = 0 then
            exit;
        Object := 'contact';
        Property := Format(HubspotContact.Id) + '?properties=erp_contact_no_&properties=firstname&properties=salutation&'
            + 'properties=jobtitle&properties=middle_name&properties=lastname&properties=address&properties=address_2&'
            + 'properties=city&properties=country&properties=zip&properties=hubspot_owner_id&properties=erp_company_no&'
            + 'properties=email&properties=phone&properties=mobilephone&properties=hs_object_id&properties=fin__communication&archived=false';
        OnAfterAddingPropertiesToContact(Property);
        if JResponse.ReadFrom(HSConnect.GetObjectInfo(Object, Property)) then
            exit(UpdateHubspotContactFields(HubspotContact, JResponse));
    end;

    local procedure UpdateHubspotContactFields(var HubspotContact: Record "HubSpot Contact"; JResponse: JsonToken) Result: Boolean
    var
        UpdatedAt: DateTime;
        Cont: Record Contact;
    begin
        UpdatedAt := JsonHelper.GetValueAsDateTime(JResponse, 'updatedAt');
        if UpdatedAt <= HubspotContact."Updated At" then
            exit(false);
        Result := true;

        HubspotContact."Updated At" := UpdatedAt;
        HubspotContact."Created At" := JsonHelper.GetValueAsDateTime(JResponse, 'createdAt');
        HubspotContact."First Name" := JsonHelper.GetValueAsText(JResponse, 'properties.firstname');
        HubspotContact."Salutation Code" := JsonHelper.GetValueAsText(JResponse, 'properties.salutation');
        HubspotContact."Job Title" := JsonHelper.GetValueAsText(JResponse, 'properties.jobtitle');
        HubspotContact."Middle Name" := JsonHelper.GetValueAsText(JResponse, 'properties.middle_name');
        HubspotContact."Last Name" := JsonHelper.GetValueAsText(JResponse, 'properties.lastname');
        HubspotContact.Address := JsonHelper.GetValueAsText(JResponse, 'properties.address');
        HubspotContact."Address 2" := JsonHelper.GetValueAsText(JResponse, 'properties.address_2');
        HubspotContact.City := JsonHelper.GetValueAsText(JResponse, 'properties.city');
        HubspotContact."Country/Region Code" := JsonHelper.GetValueAsText(JResponse, 'properties.country');
        HubspotContact."Post Code" := JsonHelper.GetValueAsText(JResponse, 'properties.zip');
        HubspotContact."E-Mail" := JsonHelper.GetValueAsText(JResponse, 'properties.email');
        HubspotContact."Phone No." := JsonHelper.GetValueAsText(JResponse, 'properties.phone');
        HubspotContact."Mobile Phone No." := JsonHelper.GetValueAsText(JResponse, 'properties.mobilephone');
        HubspotContact."Company No." := JsonHelper.GetValueAsText(JResponse, 'properties.erp_company_no');
        HubspotContact."Financial Comm" := JsonHelper.GetValueAsBoolean(JResponse, 'properties.fin__communication');

        if IsNullGuid(HubspotContact."Contact SystemId") then begin
            if Cont.Get(JsonHelper.GetValueAsText(JResponse, 'properties.erp_contact_no_')) then
                HubspotContact."Contact SystemId" := Cont.SystemId;
        end;
        OnAfterUpdateHubspotContactFields(HubspotContact, JResponse);
        HubspotContact.Modify();
    end;

    internal procedure CheckContactAssociationWithCompany(ContactId: BigInteger; var CompanyId: BigInteger): Boolean
    var
        JResponse: JsonToken;
        JArray: JsonArray;
        JItem: JsonToken;
        AssociationArray: JsonArray;
        AssociationToken: JsonToken;
    begin
        if JResponse.ReadFrom(HSConnect.GetAssociationInfo('contact', Format(ContactId), 'company')) then begin
            JsonHelper.GetJsonArray(JResponse, JArray, 'results');
            // if JArray.Count > 1 then
            //     Error('Contact must be associates with one company only.');
            // foreach JItem in JArray do begin
            //     CompanyId := JsonHelper.GetValueAsBigInteger(JItem, 'toObjectId');
            //     exit(true);
            // end;
            if JArray.Count = 1 then begin
                JArray.Get(0, JItem);
                CompanyId := JsonHelper.GetValueAsBigInteger(JItem, 'toObjectId');
                exit(true);
            end;


            foreach AssociationToken in JArray do begin
                JsonHelper.GetJsonArray(AssociationToken, AssociationArray, 'associationTypes');
                foreach JItem in AssociationArray do begin
                    if JsonHelper.GetValueAsText(JItem, 'label').ToLower() = 'primary' then begin
                        CompanyId := JsonHelper.GetValueAsBigInteger(AssociationToken, 'toObjectId');
                        exit(true);
                    end;

                    // exit(JsonHelper.GetValueAsText(AssociationToken, 'toObjectId'));
                end;
            end;
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddingPropertiesToContact(var Property: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateHubspotContactFields(var HubspotContact: Record "HubSpot Contact"; JResponse: JsonToken)
    begin
    end;
}