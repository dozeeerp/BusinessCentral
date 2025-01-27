codeunit 52106 "EMS API Mgt"
{
    trigger OnRun()
    begin
    end;

    var
        EMSSetup: Record "EMS Setup";

    local procedure GetEmsSetup()
    begin
        EMSSetup.Get();
        if not EMSSetup.Enabled then
            exit;
        EMSSetup.TestField("Base URL");
        EMSSetup.TestField("API Key");
    end;

    procedure SendDeviceLicenseStatus(var DeviceLinkedToLicense: Record "Dozee Device")
    var
        ltext: Text;
        lheaders: HttpHeaders;
        lurl: Text;
        gcontent: HttpContent;
        gHttpClient: HttpClient;
        greqMsg: HttpRequestMessage;
        gResponseMsg: HttpResponseMessage;
        JSONResponse: Text;
        ParametersBody: JsonObject;
        ParametersBodyArray: JsonArray;
    begin
        Clear(ParametersBody);
        Clear(ParametersBodyArray);
        ltext := '';
        GetEmsSetup();
        IF NOT EMSSetup.Enabled then
            exit;
        ParametersBody.Add('OrganizationId', Format(DeviceLinkedToLicense."Org ID"));
        ParametersBody.Add('DeviceId', DeviceLinkedToLicense."Device ID");
        ParametersBody.Add('LicenseId', DeviceLinkedToLicense."License No.");
        IF DeviceLinkedToLicense."Expiry Date" <> 0D then
            ParametersBody.Add('Expiry', CreateDateTime(DeviceLinkedToLicense."Expiry Date", 235959T))
        else
            ParametersBody.Add('Expiry', 0DT);
        ParametersBodyArray.Add(ParametersBody);
        ParametersBodyArray.WriteTo(ltext);
        lurl := EMSSetup."Base URL" + '/activate';
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSSetup."API Key");
        lheaders.Remove('Content-Type');
        lheaders.Add('Content-Type', 'application/json');
        gcontent.GetHeaders(lheaders);
        greqMsg.Content(gcontent);
        greqMsg.GetHeaders(lheaders);
        greqMsg.Method := 'POST';
        if not gHttpClient.Send(greqMsg, gResponseMsg) then Error('API Authorization token request failed...');
        JSONResponse := '';
        gResponseMsg.Content().ReadAs(JSONResponse);
        //Message(JSONResponse);
        //if not JObject.ReadFrom(JSONResponse) then
        //    Error('Invalid response, expected a JSON object');
        IF gResponseMsg.HttpStatusCode <> 201 then Error('Invalid Status Code: %1 received.', gResponseMsg.HttpStatusCode);
    end;

    procedure ExpireTerminateDeviceLicense(var DeviceLinkedToLicense: Record "Dozee Device"; Status: Option Terminated,Expired)
    var
        ltext: Text;
        lheaders: HttpHeaders;
        lurl: Text;
        gcontent: HttpContent;
        gHttpClient: HttpClient;
        greqMsg: HttpRequestMessage;
        gResponseMsg: HttpResponseMessage;
        JSONResponse: Text;
        ReasonText: Text;
        ParametersBody: JsonObject;
        ParametersBodyArray: JsonArray;
    begin
        Clear(ParametersBody);
        Clear(ParametersBodyArray);
        Clear(ReasonText);
        Clear(ltext);
        GetEmsSetup();
        IF NOT EMSSetup.Enabled then
            exit;
        If Status = Status::Terminated then
            ReasonText := 'CANCELLED'
        else
            ReasonText := 'EXPIRED';
        ParametersBody.Add('DeviceId', DeviceLinkedToLicense."Device ID");
        ParametersBody.Add('Reason', ReasonText);
        ParametersBodyArray.Add(ParametersBody);
        ParametersBodyArray.WriteTo(ltext);
        lurl := EMSSetup."Base URL" + '/deactivate';
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSSetup."API Key");
        lheaders.Remove('Content-Type');
        lheaders.Add('Content-Type', 'application/json');
        gcontent.GetHeaders(lheaders);
        greqMsg.Content(gcontent);
        greqMsg.GetHeaders(lheaders);
        greqMsg.Method := 'POST';
        if not gHttpClient.Send(greqMsg, gResponseMsg) then Error('API Authorization token request failed...');
        JSONResponse := '';
        gResponseMsg.Content().ReadAs(JSONResponse);
        //Message(JSONResponse);
        // if not JObject.ReadFrom(JSONResponse) then
        //     Error('Invalid response, expected a JSON object');
        IF gResponseMsg.HttpStatusCode <> 201 then Error('Invalid Status Code: %1 received.', gResponseMsg.HttpStatusCode);
    end;

    procedure GetDeviceLicenseId(var DozeeDevice: Record "Dozee Device")
    var
        lheaders: HttpHeaders;
        lurl: Text;
        gHttpClient: HttpClient;
        greqMsg: HttpRequestMessage;
        gResponseMsg: HttpResponseMessage;
        // BlankGUID: Guid;
        Sequence, Prefix : Text;
        ResponseText: Text;
        DeviceIDTxt: Text;
        DeviceIdGuid: Guid;
        JArray: JsonArray;
        JValueToken, JResultToken : JsonToken;
        JValueObject: JsonObject;
        InvalidDeviceIdErr: Label 'Blank Device ID received.';
    begin
        if not IsNullGuid(DozeeDevice."Device ID") then
            exit;
        GetEmsSetup();
        if not EMSSetup.Enabled then
            exit;
        Clear(lheaders);
        Clear(greqMsg);
        Clear(gResponseMsg);
        Clear(gHttpClient);
        Sequence := CopyStr(DozeeDevice."Serial No.", StrPos(DozeeDevice."Serial No.", '-') + 1);
        Prefix := CopyStr(DozeeDevice."Serial No.", 1, StrPos(DozeeDevice."Serial No.", '-') - 1);
        lurl := EMSSetup."Base URL" + '/forerp/get?';
        lurl := lurl + 'sequence=' + Sequence + '&prefix=' + Prefix;
        greqMsg.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSSetup."API Key");
        greqMsg.Method := 'GET';
        greqMsg.SetRequestUri(lurl);
        if not gHttpClient.Send(greqMsg, gResponseMsg) then Error('API Authorization token request failed...');
        IF gResponseMsg.HttpStatusCode <> 200 then Error('Invalid Status Code: %1 received.', gResponseMsg.HttpStatusCode);
        gResponseMsg.Content.ReadAs(ResponseText);
        JArray.ReadFrom(ResponseText);
        JArray.Get(0, JValueToken);
        JValueObject := JValueToken.AsObject();
        JValueObject.Get('RecorderId', JResultToken);
        DeviceIDTxt := JResultToken.AsValue().AsText();
        Evaluate(DeviceIdGuid, DeviceIDTxt);
        if not IsNullGuid(DeviceIdGuid) then
            DozeeDevice."Device ID" := DeviceIdGuid
        else
            Error(InvalidDeviceIdErr);
    end;

    procedure SendDeviceVariant(var DeviceLinkedToLicense: Record "Dozee Device")
    var
        // DevicewithModel_lRec: Record "Device with Model Name";
        ltext: Text;
        lheaders: HttpHeaders;
        lurl: Text;
        gcontent: HttpContent;
        gHttpClient: HttpClient;
        greqMsg: HttpRequestMessage;
        gResponseMsg: HttpResponseMessage;
        ParametersBody: JsonObject;
        ParametersBodyArray: JsonArray;
        DeviceIdTxt: Text;
    begin
        //exit;  //Do not remove....
        Clear(ParametersBody);
        Clear(ParametersBodyArray);
        Clear(lheaders);
        ltext := '';
        GetEmsSetup();
        IF NOT EMSSetup.Enabled then
            exit;
        // IF DevicewithModel_lRec.Get(DeviceLinkedToLicense."Item No") then
        //     ParametersBody.Add('Model', DevicewithModel_lRec."Model Name")
        // else
        ParametersBody.Add('Model', DeviceLinkedToLicense."Item Description");
        ParametersBody.Add('Sku', DeviceLinkedToLicense.Variant);
        ParametersBody.WriteTo(ltext);
        DeviceIdTxt := Format(DeviceLinkedToLicense."Device ID");
        DeviceIdTxt := DelChr(DeviceIdTxt, '=', '{}');
        lurl := 'https://devices.senslabs.io/api/recorders/' + DeviceIdTxt + '/properties/forerp/update';
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSSetup."API Key");
        lheaders.Remove('Content-Type');
        lheaders.Add('Content-Type', 'application/json');
        greqMsg.Content(gcontent);
        greqMsg.Method := 'POST';
        if not gHttpClient.Send(greqMsg, gResponseMsg) then Error('API Authorization token request failed...');
        IF gResponseMsg.HttpStatusCode <> 201 then Error('Invalid Status Code: %1 received.', gResponseMsg.HttpStatusCode);
    end;

    procedure ExpireTerminateDeviceLicenseBody(DeviceLinkedToLicense: Record "Dozee Device"; var ParametersBodyArray: JsonArray; Status: Option Terminated,Expired)
    var
        ParametersBody: JsonObject;
        ReasonText: Text;
        ltext: Text;
    begin
        Clear(ParametersBody);
        Clear(ReasonText);
        Clear(ltext);
        GetEmsSetup();
        IF NOT EMSSetup.Enabled then
            exit;
        If Status = Status::Terminated then
            ReasonText := 'CANCELLED'
        else
            ReasonText := 'EXPIRED';
        ParametersBody.Add('DeviceId', DeviceLinkedToLicense."Device ID");
        ParametersBody.Add('Reason', ReasonText);
        ParametersBodyArray.Add(ParametersBody);
    end;

    procedure ExpireTerminateDeviceLicenseReq(var ParametersBodyArray: JsonArray)
    var
        ltext: Text;
        lurl: Text;
        gContent: HttpContent;
        greqMsg: HttpRequestMessage;
        lheaders: HttpHeaders;
        gHttpClient: HttpClient;
        gResponseMsg: HttpResponseMessage;
        JSONResponse: Text;
        DeviceDetachMsg: Label 'The selected devices are detacheded from license, the devices license is set to expired';
    begin
        ParametersBodyArray.WriteTo(ltext);
        lurl := EMSSetup."Base URL" + '/deactivate';
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSSetup."API Key");
        lheaders.Remove('Content-Type');
        lheaders.Add('Content-Type', 'application/json');
        gcontent.GetHeaders(lheaders);
        greqMsg.Content(gcontent);
        greqMsg.GetHeaders(lheaders);
        greqMsg.Method := 'POST';
        if not gHttpClient.Send(greqMsg, gResponseMsg) then Error('API Authorization token request failed...');
        JSONResponse := '';
        gResponseMsg.Content().ReadAs(JSONResponse);
        if gResponseMsg.HttpStatusCode <> 201 then
            Error('Invalid Status Code: %1 received.', gResponseMsg.HttpStatusCode)
        else
            Message(DeviceDetachMsg);
    end;

    procedure SendDeviceLicenseStatusReq(var ParametersBodyArray: JsonArray)
    var
        ltext: Text;
        lurl: Text;
        gContent: HttpContent;
        greqMsg: HttpRequestMessage;
        lheaders: HttpHeaders;
        gHttpClient: HttpClient;
        gResponseMsg: HttpResponseMessage;
        JSONResponse: Text;
        DeviceAttachMsg: Label 'The selected devices are attached with license, the devices license is set to activated.';
    begin
        ParametersBodyArray.WriteTo(ltext);
        lurl := EMSSetup."Base URL" + '/activate';
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSSetup."API Key");
        lheaders.Remove('Content-Type');
        lheaders.Add('Content-Type', 'application/json');
        gcontent.GetHeaders(lheaders);
        greqMsg.Content(gcontent);
        greqMsg.GetHeaders(lheaders);
        greqMsg.Method := 'POST';
        if not gHttpClient.Send(greqMsg, gResponseMsg) then Error('API Authorization token request failed...');
        JSONResponse := '';
        gResponseMsg.Content().ReadAs(JSONResponse);
        IF gResponseMsg.HttpStatusCode <> 201 then
            Error('Invalid Status Code: %1 received.', gResponseMsg.HttpStatusCode)
        else
            Message(DeviceAttachMsg);
    end;

    procedure SendDeviceLicenseStatusBody(var ParametersBodyArray: JsonArray; DeviceLinkedToLicense: Record "Dozee Device")
    var
        ParametersBody: JsonObject;
        ltext: Text;
    begin
        Clear(ParametersBody);
        ltext := '';
        GetEmsSetup();
        if not EMSSetup.Enabled then
            exit;
        ParametersBody.Add('OrganizationId', Format(DeviceLinkedToLicense."Org ID"));
        ParametersBody.Add('DeviceId', DeviceLinkedToLicense."Device ID");
        ParametersBody.Add('LicenseId', DeviceLinkedToLicense."License No.");
        IF DeviceLinkedToLicense."Expiry Date" <> 0D then
            ParametersBody.Add('Expiry', CreateDateTime(DeviceLinkedToLicense."Expiry Date", 235959T))
        else
            ParametersBody.Add('Expiry', 0DT);
        ParametersBodyArray.Add(ParametersBody);
    end;
}
