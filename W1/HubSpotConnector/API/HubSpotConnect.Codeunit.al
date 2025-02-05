codeunit 51302 "HubSpot Connect"
{
    // trigger OnRun()
    // begin
    // end;

    var
        HSSetup: Record "Hubspot Setup";
        ErrorOnHubspotErr: Label 'Error(s) on Hubspot:\\%1';
        NoJsonError: Label 'The response from Hubpot Caontaines no Json.\Requested %1 \Response %2';
        JsonHelper: Codeunit "Hubspot Json Helper";

    /// <summary>
    /// These procedure gets infromation from hubspot by passing object and properties params.
    /// </summary>
    /// <param name="Objects"></param>
    /// <param name="Properties"></param>
    /// <returns></returns>
    procedure GetObjectInfo(Objects: Text; Properties: Text): Text
    var
        Url: Text;
        ReceivedData: Text;
        ResponseHeaders: HttpHeaders;
        JResponse: JsonToken;
    begin
        GetHSSetup();
        Url := CreateWebRequestUrl(Objects, 'v3');
        if Properties <> '' then
            Url += '/' + Properties;
        ReceivedData := ExecuteWebRequest(Url, 'GET', '', ResponseHeaders, 3);
        if JResponse.ReadFrom(ReceivedData) then begin
            if JResponse.AsObject().Contains('message') then
                Error(ErrorOnHubspotErr, Format(JsonHelper.GetJsonToken(JResponse, 'message')));
        end else
            Error(NoJsonError, Objects, ReceivedData);
        exit(ReceivedData);
    end;


    /// <summary>
    /// These procedure creates CRM Object with given properties
    /// </summary>
    /// <param name="Objects"></param>
    /// <param name="Body"></param>
    /// <returns></returns>
    procedure CreateNewRowInObject(Objects: Text; Body: Text): Text
    var
        Url: Text;
        ReceivedData: Text;
        ResponseHeaders: HttpHeaders;
        JResponse: JsonToken;
    begin
        GetHSSetup();
        Url := CreateWebRequestUrl(Objects, 'v3');
        ReceivedData := ExecuteWebRequest(Url, 'POST', Body, ResponseHeaders, 3);
        if JResponse.ReadFrom(ReceivedData) then begin
            if JResponse.AsObject().Contains('message') then
                Error(ErrorOnHubspotErr, Format(JsonHelper.GetJsonToken(JResponse, 'message')));
        end else
            Error(NoJsonError, Objects, ReceivedData);
        exit(ReceivedData);
    end;

    /// <summary>
    /// This Procedute updates record on hubspot.
    /// </summary>
    /// <param name="Objects">This is the object name on hubspot like, contacts, company, deal etc..</param>
    /// <param name="Body">This parameter is the json format of the body.</param>
    /// <returns></returns>
    procedure UpdateRecordOnHubSpot(Objects: Text; Body: Text) JResponse: JsonToken
    var
        Url: Text;
        ReceivedData: Text;
        ResponseHeaders: HttpHeaders;
    begin
        GetHSSetup();

        Url := CreateWebRequestUrl(Objects, 'v3');
        ReceivedData := ExecuteWebRequest(Url, 'PATCH', Body, ResponseHeaders, 3);
        if JResponse.ReadFrom(ReceivedData) then begin
            if JResponse.AsObject().Contains('message') then
                Error(ErrorOnHubspotErr, Format(JsonHelper.GetJsonToken(JResponse, 'message')));
        end else
            Error(NoJsonError, Objects, ReceivedData);
    end;

    Procedure BatchUpsert(Object: Text; Body: Text): Text
    var
        Url: Text;
        Content: HttpContent;
        ReqMsg: HttpRequestMessage;
        Header: HttpHeaders;
        HttpClient: HttpClient;
        ResponseMsg: HttpResponseMessage;
        Response: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
    begin
        GetHSSetup();
        Url := HSSetup."Base Url" + 'crm/v3/objects/' + Object + '/batch/upsert';

        Content.WriteFrom(Body);
        ReqMsg.SetRequestUri(Url);
        Header.Clear();
        Content.GetHeaders(Header);
        Header.Remove('Content-Type');
        Header.Add('Content-Type', 'application/json');
        ReqMsg.Method := 'POST';
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
                    Error('Error while creating record to HubSpot, Please check with HubSpot for further information');
            end;

        end else begin
            exit(Response);
        end;
    end;

    procedure GetAssociationInfo(Object: Text; ObjectID: Text; Acc_Object: Text): Text
    var
        URL: text;
        AccessToken: Text;
        ReqMsg: HttpRequestMessage;
        Header: HttpHeaders;
        HttpClient: HttpClient;
        ResponseMsg: HttpResponseMessage;
        Response: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
    begin
        GetHSSetup();
        URL := HSSetup."Base Url" + 'crm/v4/objects/' + Object + '/' + ObjectId + '/associations/' + Acc_Object + '?limit=500';
        AccessToken := 'Bearer ' + HSSetup."Access Token";

        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', AccessToken);
        ReqMsg.Method := 'GET';
        ReqMsg.SetRequestUri(url);

        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('Error %1', ResponseMsg.ReasonPhrase);

        ResponseMsg.Content.ReadAs(Response);
        if not ResponseMsg.IsSuccessStatusCode then begin
            Error('Error: %1, %2', Format(ResponseMsg.HttpStatusCode), ResponseMsg.ReasonPhrase);
        end else begin
            exit(Response);
        end;
    end;

    local procedure GetHSSetup()
    begin
        HSSetup.Get();
        HSSetup.TestField("Access Token");
        HSSetup.TestField("Base Url");
    end;

    procedure UploadFiles(InStr: InStream; FileName: Text; DocumentType: Enum "Document Attachment File Type"): Text
    var
        ReqMsg: HttpRequestMessage;
        ResponseMsg: HttpResponseMessage;
        Header: HttpHeaders;
        ContentHeader: HttpHeaders;
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        URL: Text;
        Response: Text;
        Boundary: Text[50];
        JsonOptions: Text;
        FolderId: Text;

        RJToken: JsonToken;
        RJObject: JsonObject;
        RJValue: JsonValue;
        MultiPartBody: TextBuilder;
        MultiPartBodyOutStream: OutStream;
        MultiPartBodyInStream: InStream;
        TempBlob: Codeunit "Temp Blob";
    begin
        GetHSSetup();
        URL := 'https://api.hubapi.com/files/v3/files';

        FolderId := '182709373325';
        Boundary := DelChr(CreateGuid(), '=', '{}');

        // Prepare JSON options part for form-data
        JsonOptions := '{"access": "PUBLIC_NOT_INDEXABLE"}';

        // Start building multipart form-data content with boundaries
        TempBlob.CreateOutStream(MultiPartBodyOutStream);

        MultiPartBody.AppendLine('--' + Boundary);
        MultiPartBody.AppendLine('Content-Disposition: form-data; name="file"; filename="' + FileName + '"');
        case DocumentType of
            DocumentType::PDF:
                MultiPartBody.AppendLine('Content-Type: application/pdf');
            DocumentType::Word:
                MultiPartBody.AppendLine('Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document');
        end;
        MultiPartBody.AppendLine();
        MultiPartBodyOutStream.WriteText(MultiPartBody.ToText());

        CopyStream(MultiPartBodyOutStream, InStr);

        // Append JSON options part
        MultiPartBody.Clear();
        MultiPartBody.AppendLine();
        MultiPartBody.AppendLine('--' + Boundary);
        MultiPartBody.AppendLine('Content-Disposition: form-data; name="options"');
        MultiPartBody.AppendLine('Content-Type: application/json');
        MultiPartBody.AppendLine();
        MultiPartBody.AppendLine(JsonOptions);

        // Append FolderId part
        MultiPartBody.AppendLine('--' + Boundary);
        MultiPartBody.AppendLine('Content-Disposition: form-data; name="folderId"');
        MultiPartBody.AppendLine();
        MultiPartBody.AppendLine(FolderId);

        // Append FileName part
        MultiPartBody.AppendLine('--' + Boundary);
        MultiPartBody.AppendLine('Content-Disposition: form-data; name="fileName"');
        MultiPartBody.AppendLine();
        MultiPartBody.AppendLine(FileName);

        // End the multipart form-data with closing boundary
        MultiPartBody.AppendLine('--' + Boundary + '--');

        MultiPartBodyOutStream.WriteText(MultiPartBody.ToText());
        TempBlob.CreateInStream(MultiPartBodyInStream);

        // Write the remaining parts to HttpContent
        HttpContent.WriteFrom(MultiPartBodyInStream);

        ReqMsg.SetRequestUri(URL);
        Header.Clear();
        HttpContent.GetHeaders(Header);
        if Header.Contains('Content-Type') then
            Header.Remove('Content-Type');
        // Header.Add('Content-Type', 'application/json');
        Header.Add('Content-Type', 'multipart/form-data; boundary=' + Boundary);
        ReqMsg.Method := 'POST';
        ReqMsg.Content(HttpContent);
        ReqMsg.GetHeaders(Header);
        Header.Add('authorization', 'Bearer ' + HSSetup."Access Token");
        Header.Add('Accept', 'application/json');
        if not HttpClient.Send(ReqMsg, ResponseMsg) then
            Error('API Authorization token request failed...');

        ResponseMsg.Content.ReadAs(Response);
        if not ResponseMsg.IsSuccessStatusCode then begin
            if Response = '' then
                Error('%1, %2', ResponseMsg.HttpStatusCode, ResponseMsg.ReasonPhrase);
            RJToken.ReadFrom(Response);
            RJObject := RJToken.AsObject();
            if RJObject.Get('message', RJToken) then begin
                RJValue := RJToken.AsValue();
                if not RJValue.IsNull then
                    Error(RJValue.AsText())
                else
                    Error('Error while creating record to HubSpot, Please check with HubSpot for further information');
            end;

        end else begin
            exit(Response);
        end;
    end;

    procedure GetObjectList(URLPath: Text; Parameter: Text; Request: Text) JResponse: JsonToken
    var
        URL: Text;
        ReceivedData: Text;
        ResponseHeaders: HttpHeaders;
        Method: Text;
    begin
        GetHSSetup();
        URL := CreateWebRequestUrl(URLPath, 'v3') + Parameter;
        if Request = '' then
            Method := 'GET'
        else
            Method := 'POST';
        ReceivedData := ExecuteWebRequest(URL, Method, Request, ResponseHeaders, 3);
        if JResponse.ReadFrom(ReceivedData) then begin
            if JResponse.AsObject().Contains('message') then
                Error(ErrorOnHubspotErr, Format(JsonHelper.GetJsonToken(JResponse, 'message')));
        end else
            Error(NoJsonError, URLPath, ReceivedData);
    end;

    local procedure CreateWebRequestUrl(UrlPath: Text; ApiVersion: Text): Text
    begin
        if HSSetup."Base Url".EndsWith('/') then
            exit(HSSetup."Base Url" + 'crm/' + ApiVersion + '/objects/' + UrlPath)
        else
            exit(HSSetup."Base Url" + '/crm/' + ApiVersion + '/objects/' + UrlPath)
    end;

    local procedure CreateHttpRequestMessage(Url: Text; Method: Text; Request: Text; Var HttpRequestMsg: HttpRequestMessage)
    var
        HttpContent: HttpContent;
        ContentHttpHeaders: HttpHeaders;
        HttpHeaders: HttpHeaders;
        AccessToken: SecretText;
    begin
        HttpRequestMsg.SetRequestUri(Url);
        HttpRequestMsg.GetHeaders(HttpHeaders);

        AccessToken := 'Bearer ' + HSSetup."Access Token";
        HttpHeaders.Add('authorization', AccessToken);
        HttpRequestMsg.Method := Method;

        if Method in ['POST', 'PUT', 'PATCH'] then begin
            HttpContent.WriteFrom(Request);
            HttpContent.GetHeaders(ContentHttpHeaders);
            if ContentHttpHeaders.Contains('Content-Type') then
                ContentHttpHeaders.Remove('Content-Type');
            ContentHttpHeaders.Add('Content-Type', 'application/json');
            HttpRequestMsg.Content(HttpContent);
        end;
    end;

    internal procedure ExecuteWebRequest(Url: Text; Method: Text; Request: Text; Var ResponseHeaders: HttpHeaders; MaxRetires: Integer) Response: Text
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        RetryCounter: Integer;
    begin
        CreateHttpRequestMessage(Url, Method, Request, HttpRequestMessage);

        if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            Clear(RetryCounter);
            while (not HttpResponseMessage.IsBlockedByEnvironment) and (EvaluateResponse(HttpResponseMessage)) and (RetryCounter < MaxRetires) do begin
                RetryCounter += 1;
                Sleep(100);
                Clear(HttpClient);
                Clear(HttpRequestMessage);
                Clear(HttpResponseMessage);
                CreateHttpRequestMessage(Url, Method, Request, HttpRequestMessage);
                HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
            end;
        end;
        if GetContent(HttpResponseMessage, Response) then;
        ResponseHeaders := HttpResponseMessage.Headers();
    end;

    Local procedure EvaluateResponse(HttpResponseMessage: HttpResponseMessage) Retry: Boolean
    var
        Status: Integer;
        Values: array[10] of Text;
        RemainingCalls: Integer;
        WaitTime: Duration;
    begin
        Status := HttpResponseMessage.HttpStatusCode();
        case Status of
            429:
                begin
                    Sleep(200);
                    Retry := true;
                end;
            500 .. 599:
                begin
                    Sleep(10000);
                    Retry := true;
                end;
            else
                if HttpResponseMessage.Headers().GetValues('x-hubspot-ratelimit-daily-remaining', Values) then
                    if Evaluate(RemainingCalls, Values[1]) then
                        if RemainingCalls = 0 then
                            WaitTime := 235959T - Time();
        end;
    end;

    [NonDebuggable]
    internal procedure Post(var Client: HttpClient; Url: Text; Content: HttpContent; var Response: HttpResponseMessage)
    begin
        // if IsTestInProgress then
        //     CommunicationEvents.OnClientPost(Url, Content, Response)
        // else
        Client.Post(Url, Content, Response);
    end;

    [NonDebuggable]
    internal procedure Get(var Client: HttpClient; Url: Text; var Response: HttpResponseMessage)
    begin
        Client.Get(Url, Response);
    end;

    [TryFunction]
    local procedure GetContent(HttpResponseMsg: HttpResponseMessage; var Response: Text)
    begin
        // if IsTestInProgress then
        //     CommunicationEvents.OnGetContent(HttpResponseMsg, Response)
        // else
        HttpResponseMsg.Content.ReadAs(Response);
    end;
}