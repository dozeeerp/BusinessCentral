namespace TST.Hubspot.Api;

using TST.hubspot.setup;
using Microsoft.Inventory.Item;
using TST.Hubspot.Base;
using TSTChanges.FA.Ledger;
using Microsoft.Inventory.Ledger;
using System.Environment;
using Microsoft.Sales.Customer;
using Microsoft.CRM.Contact;

codeunit 51301 "Hubspot API Mgmt"
{
    trigger OnRun()
    begin

    end;

    var
        HSMgmt: Codeunit "Hubspot Mgmt";
        HSSetup: Record "Hubspot Setup";
        EnvInfo: Codeunit "Environment Information";
        HSConnect: Codeunit "HubSpot Connect";
        JsonHelper: Codeunit "Hubspot Json Helper";

    Procedure GetContactFromHS(ContactID: Text): Text
    var
        Response: Text;
        Object: Text;
        Properties: Text;
    Begin
        Object := 'contacts';
        Properties := ContactId + '?properties=erp_contact_no_&properties=firstname&properties=salutation&properties=jobtitle&properties=middle_name&properties=lastname&properties=address&properties=address_2&properties=city&properties=ip_country_code&properties=zip&properties=hubspot_owner_id&properties=erp_company_no&properties=email&properties=phone&properties=mobilephone&properties=hs_object_id&archived=false';
        Response := HSConnect.GetObjectInfo(Object, Properties);
        exit(Response);
    End;

    procedure UpdateContactNoToHS(Contact: Record Contact): Text
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Url: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        Content: HttpContent;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
        Body: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
    begin
        HSSetup.Get();
        HSSetup.TestField("Access Token");
        PropertyObject.Add('erp_contact_no_', Contact."No.");
        PropertyObject.Add('erp_company_no', Contact."Company No.");

        JObject.Add('properties', PropertyObject);
        Clear(Body);
        JObject.WriteTo(Body);

        Url := HSSetup."Base Url" + 'crm/v3/objects/contacts/' + Contact."HS Contact ID";
        Content.WriteFrom(Body);
        ReqMsg.SetRequestUri(Url);
        Header.Clear();
        Content.GetHeaders(Header);
        Header.Remove('Content-Type');
        Header.Add('Content-Type', 'application/json');
        ReqMsg.Method := 'PATCH';
        ReqMsg.Content(Content);
        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', 'Bearer ' + HSSetup."Access Token");

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        ResponseMsg.Content.ReadAs(Response);

        if not ResponseMsg.IsSuccessStatusCode then begin
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('message', RJToken) then begin
                RJValue := RJToken.AsValue();
                if not RJValue.IsNull then
                    exit(RJValue.AsText())
                else
                    exit('Error while updating Contact No to HubSpot, Please check with HubSpot for further information');
            end;
        end else
            exit(Contact."No.");
    end;

    Procedure GetTicket(ObjectID: BigInteger; Properties: Text): Text
    var
        url: Text;
        AccessToken: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
    begin
        HSSetup.Get();
        URL := HSSetup."Base Url" + 'crm/v3/objects/tickets/' + format(ObjectID) + '?' + Properties + '&archived=false';
        AccessToken := 'Bearer ' + HSSetup."Access Token";

        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', AccessToken);
        ReqMsg.Method := 'GET';
        ReqMsg.SetRequestUri(url);

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        if not ResponseMsg.IsSuccessStatusCode then
            Error('Invalid Status Code: %1 received.', ResponseMsg.HttpStatusCode);

        ResponseMsg.Content.ReadAs(Response);
        exit(Response);
    end;

    procedure GetShippingAddressFromTicket(ObjectID: Text; var SameAsBilling: Boolean; var ShipToAddress: array[8] of Text)
    var
        Properties: Text;
        Response: Text;

        Jtoken: JsonToken;
        JObject: JsonObject;
        Jvalue: JsonValue;
    begin
        Properties := ObjectID + '?' + 'properties=dispatch_address_same_as_billing_address_&properties=dispatch_address&properties=address_2&properties=city&properties=country_code&properties=state_code1&properties=post_code';
        Properties := Properties + '&archived=false';
        Response := HSConnect.GetObjectInfo('ticket', Properties);

        If Response = '' then
            Error('Ticekt information not found.');

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();

        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();
        if HSMgmt.GetJsonValue('dispatch_address_same_as_billing_address_', JObject, Jvalue) then begin
            if Jvalue.AsText() = '' then
                Error('Dispatch adrress same as billing address - can not be bank.');
            SameAsBilling := Jvalue.AsText() in ['Yes', 'yes', 'true'];
        end else
            SameAsBilling := true;

        if not SameAsBilling then begin
            if HSMgmt.GetJsonValue('dispatch_address', JObject, Jvalue) then
                ShipToAddress[0] := Jvalue.AsText();
            if HSMgmt.GetJsonValue('address_2', JObject, Jvalue) then
                ShipToAddress[1] := Jvalue.AsText();
            if HSMgmt.GetJsonValue('city', JObject, Jvalue) then
                ShipToAddress[2] := Jvalue.AsText();
            if HSMgmt.GetJsonValue('country_code', JObject, Jvalue) then
                ShipToAddress[3] := Jvalue.AsText();
            if HSMgmt.GetJsonValue('state_code1', JObject, Jvalue) then
                ShipToAddress[4] := Jvalue.AsText();
            if HSMgmt.GetJsonValue('post_code', JObject, Jvalue) then
                ShipToAddress[5] := Jvalue.AsText();
        end;
    end;

    procedure CheckHSTicketPipeline(ObjectID: Text; Var PipelineType: Option Demo,AddOn,Conversion)
    var
        Properties: Text;
        Response: Text;

        Jtoken: JsonToken;
        JObject: JsonObject;
        Jvalue: JsonValue;
    begin
        Properties := ObjectID + '?' + 'properties=hs_pipeline&archived=false';
        Response := HSConnect.GetObjectInfo('ticket', Properties);

        If Response = '' then
            Error('Ticekt information not found.');

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();

        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();
        if HSMgmt.GetJsonValue('hs_pipeline', JObject, Jvalue) then
            case Jvalue.AsInteger() of
                99064422:
                    PipelineType := PipelineType::Conversion;
                0:
                    PipelineType := PipelineType::Demo;
                120572679,  //Production HubSpot
                115884692:  //Sandbox HubSpot
                    PipelineType := PipelineType::AddOn;
                else
                    Error('The Pipeline Type %1 is not part of integration', Jvalue.AsInteger());
            end;
    end;

    procedure checkHSAddOnTicketisConversion(ObjectID: Text; Var Rental: Boolean)
    var
        Properties: Text;
        Response: Text;
        Jtoken: JsonToken;
        JObject: JsonObject;
        Jvalue: JsonValue;
    begin
        Properties := ObjectID + '?' + 'properties=type_of_add_on&archived=false';
        Response := HSConnect.GetObjectInfo('ticket', Properties);

        If Response = '' then
            Error('Ticekt information not found.');

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();

        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();
        if HSMgmt.GetJsonValue('type_of_add_on', JObject, Jvalue) then
            if Jvalue.AsText() = 'Conversion' then
                Rental := true;
    end;

    procedure CheckHSTicketLastStatus(ObjectID: Text; Var TicketStage: BigInteger)
    var
        Properties: Text;
        Response: Text;

        Jtoken: JsonToken;
        JObject: JsonObject;
        Jvalue: JsonValue;
    begin
        Properties := ObjectID + '?' + 'properties=hs_pipeline_stage&archived=false';
        Response := HSConnect.GetObjectInfo('ticket', Properties);

        If Response = '' then
            Error('Ticekt information not found.');

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();

        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();
        if HSMgmt.GetJsonValue('hs_pipeline_stage', JObject, Jvalue) then
            TicketStage := Jvalue.AsBigInteger();
    end;

    procedure GetCustomerIDFromTicket(HSObjectId: Text): Text
    var
        Response: Text;
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        ValueToken: JsonToken;
        AssociationArray: JsonArray;
        AssociationToken: JsonToken;
    begin
        Response := HSConnect.GetAssociationInfo('ticket', HSObjectId, 'company');

        JToken.ReadFrom(Response);
        if JsonHelper.GetJsonArray(JToken, JArray, 'results') then
            if JArray.Count = 1 then begin
                JArray.Get(0, ValueToken);
                exit(JsonHelper.GetValueAsText(ValueToken, 'toObjectId'));
            end;

        foreach AssociationToken in JArray do begin
            JsonHelper.GetJsonArray(AssociationToken, AssociationArray, 'associationTypes');
            foreach ValueToken in AssociationArray do begin
                if JsonHelper.GetValueAsText(ValueToken, 'label').ToLower() = 'primary' then
                    exit(JsonHelper.GetValueAsText(AssociationToken, 'toObjectId'));
            end;
        end;
    end;

    procedure GetCustomerIDFromDeal(HSObjectId: Text): Text
    var
        Response: Text;

        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        ValueToken: JsonToken;
    begin
        Response := HSConnect.GetAssociationInfo('deal', HSObjectId, 'company');

        //Get Customer Object ID
        JToken.ReadFrom(Response);
        JObject := JToken.AsObject();
        if JObject.Get('results', JToken) then
            JArray := JToken.AsArray();

        foreach Jtoken in Jarray do begin
            Jobject := JToken.AsObject();
            if JObject.Get('toObjectId', ValueToken) then
                exit(ValueToken.AsValue().AsText())
        end;
    end;

    procedure GetContactIDFromTicket(HSObjectId: Text; cust: Record Customer): Text
    var
        Response: Text;

        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        ValueToken: JsonToken;
        Output: Text;

        AssoArray: JsonArray;
        AssoObject: JsonObject;
        AssoToken: JsonToken;
        Primary: Boolean;
    begin
        Response := HSConnect.GetAssociationInfo('ticket', HSObjectId, 'contact');

        //Get Contact Object ID
        JToken.ReadFrom(Response);
        JObject := JToken.AsObject();
        if JObject.Get('results', JToken) then
            JArray := JToken.AsArray();

        if JArray.Count = 1 then
            Primary := true;


        foreach Jtoken in Jarray do begin
            Jobject := JToken.AsObject();

            if not Primary then
                if JObject.Get('associationTypes', ValueToken) then begin
                    AssoArray := ValueToken.AsArray();
                    foreach AssoToken in AssoArray do begin
                        AssoObject := AssoToken.AsObject();
                        if AssoObject.Get('typeId', ValueToken) then
                            if ValueToken.AsValue().AsInteger() = 26 then
                                Primary := true;
                    end;
                end;

            if JObject.Get('toObjectId', ValueToken) then begin
                if Output = '' then
                    Output := 'Contact:';
                Output := Output + ' ' + HSMgmt.InsertOrUpdateContact(GetContactFromHS(ValueToken.AsValue().AsText()), cust, Primary);
            end;
        end;
        exit(Output);
    end;

    procedure GetCustomerFromHS(CustId: Text): Text
    var
        Response: Text;
        Object: Text;
        Property: Text;
    begin
        Object := 'companies';
        Property := CustId + '?properties=erp_customer_no_&properties=name&properties=address' +
                    '&properties=address2&properties=city&properties=hs_country_code&properties=state' +
                    '&properties=zip&properties=kam_owner&properties=customer_types&properties=domain' +
                    '&properties=primary_contact&properties=primary_contact_no&properties=sales_owner' +
                    '&properties=phone&properties=mobile_phone_no_&properties=currency_code&properties=gst_registration_no_' +
                    '&properties=p_a_n__no_&properties=zone_of_the_hospital&properties=type&archived=false';
        Response := HSConnect.GetObjectInfo(Object, Property);
        exit(Response);
    end;

    procedure UpdateERPCustomerNumberToHS(Cust: Record Customer)
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;


        Object: Text;
    begin
        PropertyObject.Add('erp_customer_no_', Cust."No.");

        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        Object := 'companies/' + Cust."HS Customer ID";
        HSConnect.UpdateRecordOnHubSpot(Object, Body);
    end;

    procedure UpdateItemToHubSpot(var Item: Record Item)
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Url: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        Content: HttpContent;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
        Body: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
        Modify: Boolean;
    begin
        HSSetup.Get();
        HSSetup.TestField("Access Token");
        PropertyObject.Add('price', '1.0');
        PropertyObject.Add('name', Item.Description);
        PropertyObject.Add('hs_sku', item."No.");
        PropertyObject.Add('hs_product_type', LowerCase(Format(Item.Type)));

        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        if Item.HS_Item_Id <> 0 then
            Modify := true;

        if not Modify then
            Url := HSSetup."Base Url" + 'crm/v3/objects/products'
        else
            Url := HSSetup."Base Url" + 'crm/v3/objects/products/' + Format(Item.HS_Item_Id);

        Content.WriteFrom(Body);
        ReqMsg.SetRequestUri(Url);
        Header.Clear();
        Content.GetHeaders(Header);
        Header.Remove('Content-Type');
        Header.Add('Content-Type', 'application/json');
        if not Modify then
            ReqMsg.Method := 'POST'
        else
            ReqMsg.Method := 'PATCH';
        ReqMsg.Content(Content);
        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', 'Bearer ' + HSSetup."Access Token");

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        ResponseMsg.Content.ReadAs(Response);
        if not ResponseMsg.IsSuccessStatusCode then begin
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('message', RJToken) then begin
                RJValue := RJToken.AsValue();
                if not RJValue.IsNull then
                    Error(RJValue.AsText())
                else
                    Error('Error while updating Customer No to HubSpot, Please check with HubSpot for further information');
            end;

        end else begin
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('properties', RJToken) then
                RJObject := RJToken.AsObject();
            if RJObject.Get('hs_object_id', RJToken) then
                RJValue := RJToken.AsValue();
            if not RJValue.IsNull then
                Item.HS_Item_Id := RJValue.AsBigInteger();
        end;
        if not Modify then
            Item.Modify(true);

        UpdateMaterialReqProperties(Item);
    end;

    procedure GetUserInfoFromHS(UserID: Text): Text
    var
        url: Text;
        AccessToken: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
        Modify: Boolean;
    begin
        HSSetup.Get();
        URL := HSSetup."Base Url" + 'crm/v3/owners/' + UserID + '?idProperty=id&archived=false';
        AccessToken := 'Bearer ' + HSSetup."Access Token";

        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', AccessToken);
        ReqMsg.Method := 'GET';
        ReqMsg.SetRequestUri(url);

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        ResponseMsg.Content.ReadAs(Response);
        if not ResponseMsg.IsSuccessStatusCode then begin
            Error('Error getting Owner: %1, %2', Format(ResponseMsg.HttpStatusCode), ResponseMsg.ReasonPhrase);
        end else begin
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('email', RJToken) then
                RJValue := RJToken.AsValue();
            if not RJValue.IsNull then
                exit(RJValue.AsText())
        end;
    end;

    procedure UpdateTicketOnHS(TicketID: BigInteger; Properties: JsonObject)
    var
        url: Text;
        AccessToken: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
        Jobject: JsonObject;
        Content: HttpContent;
        Body: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
        Modify: Boolean;
    begin
        HSSetup.Get();
        JObject.Add('properties', Properties);
        JObject.WriteTo(Body);
        URL := HSSetup."Base Url" + 'crm/v3/objects/tickets/' + Format(TicketID);
        Content.WriteFrom(Body);
        ReqMsg.SetRequestUri(Url);
        Header.Clear();
        Content.GetHeaders(Header);
        Header.Remove('Content-Type');
        Header.Add('Content-Type', 'application/json');
        ReqMsg.Method := 'PATCH';
        ReqMsg.Content(Content);
        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', 'Bearer ' + HSSetup."Access Token");

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        ResponseMsg.Content.ReadAs(Response);
        if not ResponseMsg.IsSuccessStatusCode then begin
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('message', RJToken) then begin
                RJValue := RJToken.AsValue();
                if not RJValue.IsNull then
                    Error(RJValue.AsText());
            end;
        end;
    end;

    procedure GetMaetrialIDFromTicket(HSObjectId: BigInteger): Text
    var
        url: Text;
        AccessToken: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
        Material: Text;
    begin
        HSSetup.Get();
        if EnvInfo.IsProduction() then
            Material := 'p44671231_material_requisition'
        else
            Material := 'p46231690_material_requisition';
        URL := HSSetup."Base Url" + 'crm/v4/objects/ticket/' + Format(HSObjectId) + '/associations/' + Material + '?limit=500';
        AccessToken := 'Bearer ' + HSSetup."Access Token";

        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', AccessToken);
        ReqMsg.Method := 'GET';
        ReqMsg.SetRequestUri(url);

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        if not ResponseMsg.IsSuccessStatusCode then
            Error('Invalid Status Code: %1 received.', ResponseMsg.HttpStatusCode);

        ResponseMsg.Content.ReadAs(Response);
        exit(Response);
    end;

    procedure GetLineItemsAssocitionFromDeal(HsObjectId: BigInteger): Text
    var
        Response: Text;
    begin
        Response := HSConnect.GetAssociationInfo('deal', Format(HsObjectId), 'line_items');
        if Response <> '' then
            exit(Response);
    end;

    procedure GetLineItems(LineID: Text): Text
    var
        Properties: Text;
        Response: Text;
    begin
        Properties := LineID + '?properties=hs_sku' +
                    '&properties=price&properties=amount&properties=recurringbillingfrequency' +
                    '&properties=hs_term_in_months&properties=discount&properties=quantity' +
                    '&properties=hs_discount_percentage&archived=false';

        Response := HSConnect.GetObjectInfo('line_items', Properties);
        if Response <> '' then
            exit(Response);
    end;

    procedure GetMaterialReq(MaterialID: text): Text
    var
        Objects: Text;
        Properties: Text;
    begin
        if EnvInfo.IsProduction() then
            Objects := 'p44671231_material_requisition'
        else
            Objects := 'p46231690_material_requisition';

        Properties := MaterialID + '?properties=description&properties=warehouse_quantity' +
                '&properties=self_quantity&properties=total_quantity&properties=url&archived=false';
        exit(HSConnect.GetObjectInfo(Objects, Properties));
    end;

    local procedure GetMetrialReqDescription(): Text
    var
        url: Text;
        AccessToken: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
        Material: Text;
    begin
        HSSetup.Get();
        if EnvInfo.IsProduction() then
            Material := 'p44671231_material_requisition'
        else
            Material := 'p46231690_material_requisition';
        URL := HSSetup."Base Url" + 'crm/v3/properties/' + Material + '/description';
        AccessToken := 'Bearer ' + HSSetup."Access Token";

        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', AccessToken);
        ReqMsg.Method := 'GET';
        ReqMsg.SetRequestUri(url);

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        if not ResponseMsg.IsSuccessStatusCode then
            Error('Invalid Status Code: %1 received.', ResponseMsg.HttpStatusCode);

        ResponseMsg.Content.ReadAs(Response);
        exit(Response);
    end;

    procedure UpdateMaterialReqProperties(Item: Record Item)
    var
        OldMaterialReq: Text;
        Jtoken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        NewJArray: JsonArray;
        NewJobject: JsonObject;
        DisplayOrder: Integer;
    begin
        OldMaterialReq := GetMetrialReqDescription();
        if OldMaterialReq = '' then
            exit;

        Jtoken.ReadFrom(OldMaterialReq);
        JObject := Jtoken.AsObject();
        if JObject.Get('options', Jtoken) then
            JArray := Jtoken.AsArray();

        DisplayOrder := 0;
        DisplayOrder := JArray.Count;

        foreach JToken in JArray do begin
            NewJArray.Add(Jtoken.AsObject());
        end;

        NewJobject.Add('label', Item.Description);
        NewJobject.Add('value', Item."No.");
        NewJobject.Add('hidden', false);
        NewJobject.Add('description', '');
        NewJobject.Add('displayOrder', DisplayOrder + 1);
        NewJArray.Add(NewJobject);

        PatchMaterialReqDescription(NewJArray);
    end;

    local procedure PatchMaterialReqDescription(Properties: JsonArray)
    var
        url: Text;
        AccessToken: Text;
        HttpClient: HttpClient;
        Header: HttpHeaders;
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Response: Text;
        Jobject: JsonObject;
        Content: HttpContent;
        Body: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
        // Modify: Boolean;
        Material: Text;
    begin
        HSSetup.Get();
        JObject.Add('options', Properties);
        JObject.WriteTo(Body);
        if EnvInfo.IsProduction() then
            Material := 'p44671231_material_requisition'
        else
            Material := 'p46231690_material_requisition';
        URL := HSSetup."Base Url" + 'crm/v3/properties/' + Material + '/description';
        Content.WriteFrom(Body);
        ReqMsg.SetRequestUri(Url);
        Header.Clear();
        Content.GetHeaders(Header);
        Header.Remove('Content-Type');
        Header.Add('Content-Type', 'application/json');
        ReqMsg.Method := 'PATCH';
        ReqMsg.Content(Content);
        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', 'Bearer ' + HSSetup."Access Token");

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        ResponseMsg.Content.ReadAs(Response);
        if not ResponseMsg.IsSuccessStatusCode then begin
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('message', RJToken) then begin
                RJValue := RJToken.AsValue();
                if not RJValue.IsNull then
                    Error(RJValue.AsText());
            end;
        end;
    end;

    procedure InsertDeviceInHS(RecRef: RecordRef; HSObjectID: BigInteger; PipelineType: Option Demo,AddOn,Conversion);
    var
        Object: Text;
        Body: Text;
        JObject: JsonObject;
        AObject: JsonObject;
        PJObject: JsonObject;
        JObjectOut: JsonObject;
        JArray: JsonArray;
        AJArray: JsonArray;
        ILE: Record "Item Ledger Entry";
        FAILE: Record "FA Item ledger Entry";

        Response: Text;
        RJObject: JsonObject;
        RJArray: JsonArray;
        RJToken: JsonToken;
    begin
        HSSetup.Get();
        HSSetup.TestField("AssociationID Ticket to Device");

        Object := 'device';
        JObject.Add('associationCategory', 'USER_DEFINED');
        JObject.Add('associationTypeId', HSSetup."AssociationID Ticket to Device");
        JArray.add(JObject);
        Clear(JObject);
        JObject.Add('id', HSObjectID);
        AObject.Add('types', JArray);
        AObject.Add('to', JObject);
        clear(JArray);
        Clear(JObject);
        AJArray.Add(AObject);
        Clear(AObject);

        if PipelineType = PipelineType::AddOn then begin
            // Response := HSConnect.GetObjectInfo('ticket', Format(HSObjectId) + '/associations/ticket?limit=500');
            // if Response = '' then
            //     Error('Demo ticket not found.');
            // RJToken.ReadFrom(Response);
            // RJObject := RJToken.AsObject();
            // if RJObject.Get('results', RJToken) then begin
            //     RJArray := RJToken.AsArray();

            //     foreach RJToken in RJArray do begin
            //         RJObject := RJToken.AsObject();
            //         if RJObject.Get('id', RJToken) then 
            // begin
            JObject.Add('associationCategory', 'USER_DEFINED');
            JObject.Add('associationTypeId', HSSetup."AssociationID Ticket to Device");
            JArray.add(JObject);
            Clear(JObject);
            JObject.Add('id', GetAssociatedTicketID(HSObjectId));
            AObject.Add('types', JArray);
            AObject.Add('to', JObject);
            Clear(JObject);
            AJArray.Add(AObject);
            // end;
        end;
        // end;
        // end;

        case RecRef.Number of
            Database::"Item Ledger Entry":
                begin
                    Recref.SetTable(ILE);
                    if EnvInfo.IsProduction() then
                        PJObject.Add('entry_no_', 'I' + Format(ILE."Entry No.") + '-' + ILE."Serial No.")
                    else
                        PJObject.Add('entry_no_', Format(ILE."Entry No.") + '-' + ILE."Serial No.");
                    PJObject.Add('customer_no_', ILE."Customer No.");
                    PJObject.Add('lot_no_', ILE."Lot No.");
                    PJObject.Add('serial_no_', ILE."Serial No.");
                    PJObject.Add('item_no_', ILE."Item No.");
                    PJObject.Add('item_description', ILE.Description);
                    PJObject.Add('variant', ILE."Variant Code");
                    PJObject.Add('posting_received_date', ILE."Posting Date");
                    PJObject.Add('quantity', ILE.Quantity);
                end;
            Database::"FA Item ledger Entry":
                begin
                    RecRef.SetTable(FAILE);
                    if EnvInfo.IsProduction() then
                        PJObject.Add('entry_no_', 'A' + Format(FAILE."Entry No.") + '-' + FAILE."Serial No.")
                    else
                        PJObject.Add('entry_no_', Format(FAILE."Entry No.") + '-' + FAILE."Serial No.");
                    PJObject.Add('customer_no_', FAILE."Customer No.");
                    PJObject.Add('lot_no_', FAILE."Lot No.");
                    PJObject.Add('serial_no_', FAILE."Serial No.");
                    PJObject.Add('item_no_', FAILE."FA Item No.");
                    PJObject.Add('item_description', FAILE.Description);
                    PJObject.Add('variant', FAILE."Variant Code");
                    PJObject.Add('posting_received_date', FAILE."Posting Date");
                    PJObject.Add('quantity', FAILE.Quantity);
                end;
        end;

        JObjectout.Add('associations', AJArray);
        JObjectOut.Add('properties', PJObject);
        Body := '';
        JObjectOut.WriteTo(Body);
        HSConnect.CreateNewRowInObject(Object, Body);
    end;

    procedure GetAssociatedTicketID(HSObjectId: BigInteger): Text
    var
        Object: Text;
        // Properties: Text;
        Response: Text;
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
    begin
        Object := 'ticket';
        // Properties := Format(HSObjectId) + '/associations/ticket?limit=500';
        // Response := HSConnect.GetObjectInfo(Object, Properties);
        Response := HSConnect.GetAssociationInfo(Object, Format(HSObjectId), 'ticket');
        if Response = '' then
            Error('Demo ticket not found.');
        JToken.ReadFrom(Response);
        JObject := JToken.AsObject();
        if JObject.Get('results', JToken) then begin
            JArray := JToken.AsArray();

            foreach JToken in JArray do begin
                JObject := JToken.AsObject();
                if JObject.Get('toObjectId', JToken) then begin
                    exit(JToken.AsValue().AsText());
                end;
            end;
        end;
    end;

    procedure UpdateDeviceInfo(DozeeDevice: Record "Dozee Device")
    var
        InputArray: JsonArray;
        JsonObject: JsonObject;
        Body: Text;
        Object: Text;
        ICount: Integer;
        DozeeDevice1: Record "Dozee Device";
    begin
        Object := 'device';
        ICount := 0;

        DozeeDevice1.Reset();
        DozeeDevice1.SetRange("Customer No.", DozeeDevice."Customer No.");
        DozeeDevice1.SetFilter(SystemModifiedAt, '%1..%2', CreateDateTime(Today(), 0T), CurrentDateTime());//We need to have proper trigger to catch selected devices
        if DozeeDevice1.FindSet() then begin
            repeat
                Preparedevicebody(DozeeDevice1, InputArray);
                ICount += 1;
                if ICount = 99 then begin
                    JsonObject.Add('inputs', InputArray);
                    JsonObject.WriteTo(Body);
                    HSConnect.BatchUpsert(Object, Body);

                    Clear(InputArray);
                    Clear(JsonObject);
                    Clear(Body);
                    ICount := 0;
                end;
            until DozeeDevice1.Next() = 0;

            JsonObject.Add('inputs', InputArray);
            JsonObject.WriteTo(Body);
            HSConnect.BatchUpsert(Object, Body);
        end;
    end;

    procedure Preparedevicebody(DozeeDevice: Record "Dozee Device"; var InputsArray: JsonArray)
    var
        InputsObject: JsonObject;
        PropertyObject: JsonObject;
        ILE: Record "Item Ledger Entry";
        FAILE: Record "FA Item ledger Entry";
    begin
        PropertyObject.Add('license_activated', DozeeDevice.Licensed);
        PropertyObject.Add('license_no', DozeeDevice."License No.");
        if DozeeDevice."Activation Date" <> 0D then
            PropertyObject.Add('license_activation_date', DozeeDevice."Activation Date");
        if DozeeDevice."Expiry Date" <> 0D then
            PropertyObject.Add('expiry_date', DozeeDevice."Expiry Date");
        PropertyObject.Add('expired', DozeeDevice.Expired);

        InputsObject.Add('idProperty', 'entry_no_');
        if EnvInfo.IsProduction() then begin
            if DozeeDevice.Type = DozeeDevice.Type::Asset then begin
                if FAILE.Get(DozeeDevice."Item Ledger Entry No.") then begin
                    InputsObject.Add('id', 'A' + Format(DozeeDevice."Item Ledger Entry No.") + '-' + FAILE."Serial No.");
                    PropertyObject.Add('customer_no_', FAILE."Customer No.");
                    PropertyObject.Add('lot_no_', FAILE."Lot No.");
                    PropertyObject.Add('serial_no_', FAILE."Serial No.");
                    PropertyObject.Add('item_no_', FAILE."FA Item No.");
                    PropertyObject.Add('item_description', FAILE.Description);
                    PropertyObject.Add('variant', FAILE."Variant Code");
                    PropertyObject.Add('posting_received_date', FAILE."Posting Date");
                    PropertyObject.Add('quantity', FAILE.Quantity);
                end;
            end else begin
                if ILE.Get(DozeeDevice."Item Ledger Entry No.") then begin
                    InputsObject.Add('id', 'I' + Format(DozeeDevice."Item Ledger Entry No.") + '-' + ILE."Serial No.");
                    PropertyObject.Add('customer_no_', ILE."Customer No.");
                    PropertyObject.Add('lot_no_', ILE."Lot No.");
                    PropertyObject.Add('serial_no_', ILE."Serial No.");
                    PropertyObject.Add('item_no_', ILE."Item No.");
                    PropertyObject.Add('item_description', ILE.Description);
                    PropertyObject.Add('variant', ILE."Variant Code");
                    PropertyObject.Add('posting_received_date', ILE."Posting Date");
                    PropertyObject.Add('quantity', ILE.Quantity);
                end;
            end;

        end else begin
            if ILE.Get(DozeeDevice."Item Ledger Entry No.") then begin
                InputsObject.Add('id', Format(DozeeDevice."Item Ledger Entry No.") + '-' + ILE."Serial No.");
                PropertyObject.Add('customer_no_', ILE."Customer No.");
                PropertyObject.Add('lot_no_', ILE."Lot No.");
                PropertyObject.Add('serial_no_', ILE."Serial No.");
                PropertyObject.Add('item_no_', ILE."Item No.");
                PropertyObject.Add('item_description', ILE.Description);
                PropertyObject.Add('variant', ILE."Variant Code");
                PropertyObject.Add('posting_received_date', ILE."Posting Date");
                PropertyObject.Add('quantity', ILE.Quantity);
            end;
        end;

        InputsObject.Add('properties', PropertyObject);
        InputsArray.Add(InputsObject);
    end;
}