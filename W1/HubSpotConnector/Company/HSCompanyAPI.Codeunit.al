namespace TST.Hubspot.Company;

using TST.Hubspot.Base;
using Microsoft.Sales.Customer;
using TST.Hubspot.Setup;

codeunit 51308 "Hubspot Company API"
{
    trigger OnRun()
    begin

    end;

    var
        HSConnect: Codeunit "HubSpot Connect";
        JsonHelper: Codeunit "Hubspot Json Helper";

    internal procedure CreateCompany(HubspotCompany: Record "Hubspot Company"): Boolean
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;
        Object: Text;
    begin
        CompanyPropertyObject(PropertyObject, HubspotCompany);
        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        Object := 'companies';
        HSConnect.CreateNewRowInObject(Object, Body);
    end;

    internal procedure UpdateCompany(HubspotCompany: Record "Hubspot Company")
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;
        Object: Text;
    begin
        CompanyPropertyObject(PropertyObject, HubspotCompany);

        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        Object := 'companies/' + Format(HubspotCompany.Id);
        HSConnect.UpdateRecordOnHubSpot(Object, Body);
    end;

    local procedure CompanyPropertyObject(var PropertyObject: JsonObject; HubspotCompany: Record "Hubspot Company")
    begin
        PropertyObject.Add('name', HubspotCompany.Name);
        PropertyObject.Add('address', HubspotCompany.Address);
        PropertyObject.Add('address2', HubspotCompany."Address 2");
        PropertyObject.Add('city', HubspotCompany.City);
        PropertyObject.Add('hs_country_code', HubspotCompany."Country/Region");
        PropertyObject.Add('state', HubspotCompany.State);
        PropertyObject.Add('zip', HubspotCompany.ZIP);
        if HubspotCompany."KAM Onwer" <> 0 then
            PropertyObject.Add('kam_owner', HubspotCompany."KAM Onwer");
        PropertyObject.Add('customer_types', HubspotCompany."Customer Type");
        if HubspotCompany."Sales Onwer" <> 0 then
            PropertyObject.Add('hubspot_owner_id', HubspotCompany."Sales Onwer");
        PropertyObject.Add('phone', HubspotCompany.Phone);
        PropertyObject.Add('mobile_phone_no_', HubspotCompany."Mobile Phone No");
        if HubspotCompany."Currency Code" = '' then
            PropertyObject.Add('currency_code', 'INR')
        else
            PropertyObject.Add('currency_code', HubspotCompany."Currency Code");
        PropertyObject.Add('gst_registration_no_', HubspotCompany."GST Registration No");
        PropertyObject.Add('p_a_n__no_', HubspotCompany."P.A.N. No");
        // PropertyObject.Add('zone_of_the_hospital', '');
        // PropertyObject.Add('type', '');
        HubspotCompany.CalcFields("Customer No.");
        PropertyObject.Add('erp_customer_no_', HubspotCompany."Customer No.");
    end;

    internal procedure RetrieveHubspotCompanyIds(var CompanyIds: Dictionary of [BigInteger, DateTime])
    var
        Id: BigInteger;
        UpdatedAt: DateTime;
        JCompanies: JsonArray;
        JNode: JsonObject;
        JItem: JsonToken;
        JResponse: JsonToken;
        NextLink: Text;
        Parameters: Text;
        After: BigInteger;
        JCompany: JsonArray;
        HSSetup: Record "Hubspot Setup";
        BusinessUsnit: Boolean;
        Filters: Text;
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
            JResponse := HSConnect.GetObjectList('companies', Parameters, Filters);
            if JsonHelper.GetJsonArray(JResponse, JCompany, 'results') then begin
                foreach JItem in JCompany do begin
                    Id := JsonHelper.GetValueAsBigInteger(JItem, 'id');
                    UpdatedAt := JsonHelper.GetValueAsDateTime(JItem, 'updatedAt');
                    CompanyIds.Add(Id, UpdatedAt)
                end;
            end;
            After := JsonHelper.GetValueAsBigInteger(JResponse, 'paging.next.after');
        until After = 0
    end;

    internal procedure RetrieveHubspotCompany(var HubspotCompany: Record "Hubspot Company"): Boolean
    var
        JResponse: JsonToken;
        Object: Text;
        Property: Text;
    begin
        if HubspotCompany.Id = 0 then
            exit;
        Object := 'companies';
        Property := Format(HubspotCompany.Id) + '?properties=erp_customer_no_&properties=name&properties=address' +
                    '&properties=address2&properties=city&properties=hs_country_code&properties=state' +
                    '&properties=zip&properties=kam_owner&properties=customer_types&properties=domain' +
                    '&properties=primary_contact&properties=primary_contact_no&properties=hubspot_owner_id' +
                    '&properties=phone&properties=mobile_phone_no_&properties=currency_code&properties=gst_registration_no_' +
                    '&properties=p_a_n__no_&properties=zone_of_the_hospital&properties=type&&properties=erp_customer_no_&archived=false';
        if JResponse.ReadFrom(HSConnect.GetObjectInfo(Object, Property)) then
            exit(UpdateHubspotCompanyFields(HubspotCompany, JResponse));
    end;

    internal procedure UpdateHubspotCompanyFields(var HubspotCompany: Record "Hubspot Company"; JResponse: JsonToken) Result: Boolean
    var
        UpdatedAt: DateTime;
        Cust: Record Customer;
    begin
        UpdatedAt := JsonHelper.GetValueAsDateTime(JResponse, 'updatedAt');
        if UpdatedAt <= HubspotCompany."Updated At" then
            exit(false);
        Result := true;

        HubspotCompany."Updated At" := UpdatedAt;
        HubspotCompany."Created At" := JsonHelper.GetValueAsDateTime(JResponse, 'createdAt');
        HubspotCompany.Name := JsonHelper.GetValueAsText(JResponse, 'properties.name');
        HubspotCompany.Address := JsonHelper.GetValueAsText(JResponse, 'properties.address');
        HubspotCompany."Address 2" := JsonHelper.GetValueAsText(JResponse, 'properties.address2');
        HubspotCompany.City := JsonHelper.GetValueAsText(JResponse, 'properties.city');
        HubspotCompany."Country/Region" := JsonHelper.GetValueAsText(JResponse, 'properties.hs_country_code');
        HubspotCompany.State := JsonHelper.GetValueAsText(JResponse, 'properties.state');
        HubspotCompany.ZIP := JsonHelper.GetValueAsText(JResponse, 'properties.zip');
        if JsonHelper.GetValueAsText(JResponse, 'properties.kam_owner') <> '' then
            HubspotCompany."KAM Onwer" := JsonHelper.GetValueAsBigInteger(JResponse, 'properties.kam_owner')
        else
            HubspotCompany."KAM Onwer" := 0;
        HubspotCompany."Customer Type" := JsonHelper.GetValueAsText(JResponse, 'properties.customer_types');
        HubspotCompany.Domain := JsonHelper.GetValueAsText(JResponse, 'properties.domain');
        HubspotCompany."Primary Contact" := JsonHelper.GetValueAsText(JResponse, 'properties.primary_contact');
        HubspotCompany."Primary Contact No" := JsonHelper.GetValueAsText(JResponse, 'properties.primary_contact_no');
        HubspotCompany."Sales Onwer" := JsonHelper.GetValueAsBigInteger(JResponse, 'properties.hubspot_owner_id');
        HubspotCompany.Phone := JsonHelper.GetValueAsText(JResponse, 'properties.phone');
        HubspotCompany."Mobile Phone No" := JsonHelper.GetValueAsText(JResponse, 'properties.mobile_phone_no_');
        HubspotCompany."Currency Code" := JsonHelper.GetValueAsText(JResponse, 'properties.currency_code');
        HubspotCompany."GST Registration No" := JsonHelper.GetValueAsText(JResponse, 'properties.gst_registration_no_');
        HubspotCompany."P.A.N. No" := JsonHelper.GetValueAsText(JResponse, 'properties.p_a_n__no_');
        HubspotCompany.Zone := JsonHelper.GetValueAsText(JResponse, 'properties.zone_of_the_hospital');
        HubspotCompany.Type := JsonHelper.GetValueAsText(JResponse, 'properties.type');
        if IsNullGuid(HubspotCompany."Customer SystemId") then begin
            if Cust.Get(JsonHelper.GetValueAsText(JResponse, 'properties.erp_customer_no_')) then
                HubspotCompany."Customer SystemId" := Cust.SystemId;
        end;
        HubspotCompany.Modify();
    end;
}