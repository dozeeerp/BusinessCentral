codeunit 52106 "EMS API Mgt"
{
    trigger OnRun()
    begin
    end;

    var
        EMSAPISetup_gRec: Record "EMS Setup";

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
        EMSAPISetup_gRec.Get();
        IF NOT EMSAPISetup_gRec.Enabled then exit;
        EMSAPISetup_gRec.TestField("Base URL");
        EMSAPISetup_gRec.TestField("API Key");
        ParametersBody.Add('OrganizationId', Format(DeviceLinkedToLicense."Org ID"));
        ParametersBody.Add('DeviceId', DeviceLinkedToLicense."Device ID");
        ParametersBody.Add('LicenseId', DeviceLinkedToLicense."License No.");
        IF DeviceLinkedToLicense."Expiry Date" <> 0D then
            ParametersBody.Add('Expiry', CreateDateTime(DeviceLinkedToLicense."Expiry Date", 235959T))
        else
            ParametersBody.Add('Expiry', 0DT);
        ParametersBodyArray.Add(ParametersBody);
        ParametersBodyArray.WriteTo(ltext);
        // IF GuiAllowed then
        //     MESSAGE(FORMAT(ltext));
        lurl := EMSAPISetup_gRec."Base URL";
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSAPISetup_gRec."API Key");
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
        EMSAPISetup_gRec.Get();
        IF NOT EMSAPISetup_gRec.Enabled then exit;
        EMSAPISetup_gRec.TestField("Base URL");
        If Status = Status::Terminated then
            ReasonText := 'CANCELLED'
        else
            ReasonText := 'EXPIRED';
        EMSAPISetup_gRec.TestField("API Key");
        ParametersBody.Add('DeviceId', DeviceLinkedToLicense."Device ID");
        ParametersBody.Add('Reason', ReasonText);
        ParametersBodyArray.Add(ParametersBody);
        ParametersBodyArray.WriteTo(ltext);
        // IF GuiAllowed then
        //     MESSAGE(FORMAT(ltext));
        lurl := EMSAPISetup_gRec."Base URL";
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSAPISetup_gRec."API Key");
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

    procedure GetDeviceLicenseId(var DeviceLinkedToLicense: Record "Dozee Device")
    var
        lheaders: HttpHeaders;
        lurl: Text;
        gHttpClient: HttpClient;
        greqMsg: HttpRequestMessage;
        gResponseMsg: HttpResponseMessage;
        BlankGUID: Guid;
        Sequence, Prefix : Text;
        ResponseText: Text;
        DeviceIDTxt: Text;
        DeviceIdGuid: Guid;
        JArray: JsonArray;
        JValueToken, JResultToken : JsonToken;
        JValueObject: JsonObject;
        InvalidDeviceIdErr: Label 'Blank Device ID received.';
    begin
        if (DeviceLinkedToLicense."Device ID" <> BlankGUID) then exit;
        EMSAPISetup_gRec.Get();
        if not EMSAPISetup_gRec.Enabled then exit;
        Clear(lheaders);
        Clear(greqMsg);
        Clear(gResponseMsg);
        Clear(gHttpClient);
        EMSAPISetup_gRec.TestField("Base URL");
        EMSAPISetup_gRec.TestField("API Key");
        Sequence := CopyStr(DeviceLinkedToLicense."Serial No.", StrPos(DeviceLinkedToLicense."Serial No.", '-') + 1);
        Prefix := CopyStr(DeviceLinkedToLicense."Serial No.", 1, StrPos(DeviceLinkedToLicense."Serial No.", '-') - 1);
        lurl := EMSAPISetup_gRec."Base URL";
        lurl := lurl + 'sequence=' + Sequence + '&prefix=' + Prefix;
        greqMsg.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSAPISetup_gRec."API Key");
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
        if DeviceIdGuid <> BlankGUID then
            DeviceLinkedToLicense."Device ID" := DeviceIdGuid
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
        EMSAPISetup_gRec.Get();
        IF NOT EMSAPISetup_gRec.Enabled then exit;
        EMSAPISetup_gRec.TestField("API Key");
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
        lheaders.Add('x-api-key', EMSAPISetup_gRec."API Key");
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
        EMSAPISetup_gRec.Get();
        IF NOT EMSAPISetup_gRec.Enabled then exit;
        EMSAPISetup_gRec.TestField("Base URL");
        If Status = Status::Terminated then
            ReasonText := 'CANCELLED'
        else
            ReasonText := 'EXPIRED';
        EMSAPISetup_gRec.TestField("API Key");
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
        lurl := EMSAPISetup_gRec."Base URL";
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSAPISetup_gRec."API Key");
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
        lurl := EMSAPISetup_gRec."Base URL";
        gcontent.WriteFrom(ltext);
        greqMsg.SetRequestUri(lurl);
        lheaders.Clear();
        gcontent.GetHeaders(lheaders);
        lheaders.Add('x-api-key', EMSAPISetup_gRec."API Key");
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
        EMSAPISetup_gRec.Get();
        if not EMSAPISetup_gRec.Enabled then exit;
        EMSAPISetup_gRec.TestField("Base URL");
        EMSAPISetup_gRec.TestField("API Key");
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
