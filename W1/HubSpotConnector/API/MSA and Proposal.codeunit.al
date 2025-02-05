codeunit 51305 "MSA and Proposal"
{
    trigger OnRun()
    begin
    end;

    var
        HSAPIMgmt: Codeunit "Hubspot API Mgmt";
        // HSMgmt: Codeunit "Hubspot Mgmt";
        SalesHeader: Record "Sales Header";
        HSConnect: Codeunit "HubSpot Connect";
        JsonHelper: Codeunit "Hubspot Json Helper";

    procedure createQuotation(Cust: Record Customer; HSObjectID: BigInteger)
    var
        QuoteNo: Code[20];
        MSANo: Code[20];
        LineIdsResponse: Text;
        DealResponse: Text;
        JToken: JsonToken;
        JArray: JsonArray;
        JObject: JsonObject;
        ValueToken: JsonToken;
        JValue: JsonValue;
        LineItems: Text;
    begin
        //Get Deal Information
        DealResponse := HSConnect.GetObjectInfo('deal', Format(HSObjectID) +
                                                '?properties=quotation_number' +
                                                '&properties=msa_number' +
                                                '&archived=false');
        // if DealResponse = '' then
        //     Error('Deal not found.');
        JToken.ReadFrom(DealResponse);
        // JObject := JToken.AsObject();
        // if JObject.Get('properties', JToken) then
        //     JObject := JToken.AsObject();
        // if HSMgmt.GetJsonValue('quotation_number', JObject, JValue) then
        QuoteNo := JsonHelper.GetValueAsCode(JToken, 'properties.quotation_number');
        // if HSMgmt.GetJsonValue('msa_number', JObject, JValue) then
        MSANo := JsonHelper.GetValueAsCode(JToken, 'properties.msa_number');

        //Get Line Item Ids from Deal
        LineIdsResponse := HSAPIMgmt.GetLineItemsAssocitionFromDeal(HSObjectID);

        if LineIdsResponse = '' then
            Error('Lines not found for Deal id %1', HSObjectID);
        // if Cust."GST Customer Type" = cust."GST Customer Type"::" " then
        //     Error('Provide GST information for the customer or mark it as unregistered, Custtomer %1', Cust."No.");
        if QuoteNo <> '' then
            SalesHeader.Get(SalesHeader."Document Type"::Quote, QuoteNo)
        else
            InsertSalesHeader(0D, Cust, HSObjectID);

        if SalesHeader.HS_ID <> HSObjectID then begin
            SalesHeader.HS_ID := HSObjectID;
            SalesHeader.Modify(true);
        end;

        Clear(JToken);
        // Clear(JObject);

        JToken.ReadFrom(LineIdsResponse);
        // JObject := JToken.AsObject();
        JsonHelper.GetJsonArray(JToken, JArray, 'results');
        // if JObject.Get('results', JToken) then
        //     JArray := JToken.AsArray();
        foreach JToken in JArray do begin
            // JObject := JToken.AsObject();
            // if JObject.Get('toObjectId', ValueToken) then begin
            LineItems := HSAPIMgmt.GetLineItems(JsonHelper.GetValueAsText(JToken, 'toObjectId'));
            if LineItems = '' then
                Error('Line items error for lineID %1', JsonHelper.GetValueAsText(JToken, 'toObjectId'));
            InsertSalesLines(LineItems);
            // end;
        end;

        UpdateCompanyProposalTarget(Cust, false);
    end;

    procedure createMSA(Cust: Record Customer)
    begin

    end;

    local procedure InsertSalesHeader(PostDate: Date; Cust: Record Customer; HSObjectID: BigInteger)
    begin
        if PostDate = 0D then
            PostDate := WorkDate();

        Clear(SalesHeader);
        SalesHeader.Init();
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader.Insert(true);
        // DocNo := SalesHeader."No.";

        SalesHeader."Order Date" := WorkDate();
        SalesHeader."Posting Description" :=
          Format(SalesHeader."Document Type") + ' ' + SalesHeader."No.";
        SalesHeader.Validate("Sell-to Customer No.", Cust."No.");
        SalesHeader.HS_ID := HSObjectID;

        SalesHeader.Modify();
    end;

    local procedure InsertSalesLines(lineItems: Text)
    var
        SalesLine: Record "Sales Line";
        JToken: JsonToken;
        JObject: JsonObject;
        Item: Record Item;
        JValue: JsonValue;
        SalesLineNo: Integer;
    begin
        JToken.ReadFrom(lineItems);
        JObject := JToken.AsObject();
        if JObject.Get('properties', JToken) then
            JObject := JToken.AsObject();

        //InsertSalesLines
        SalesLineNo := 0;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            SalesLineNo := SalesLine."Line No.";

        SalesLineNo := SalesLineNo + 10000;

        SalesLine.Reset();
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := SalesLineNo;

        if Item.Get(JsonHelper.GetValueAsText(JToken, 'properties.hs_sku')) then begin
            // Item.Get(JValue.AsText());
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", Item."No.");
        end;
        SalesLine.Validate(Quantity, JsonHelper.GetValueAsDecimal(JToken, 'properties.quantity'));
        SalesLine.Validate("Unit Price", JsonHelper.GetValueAsDecimal(JToken, 'properties.price'));
        SalesLine.Validate("Line Discount Amount", JsonHelper.GetValueAsDecimal(JToken, 'properties.discount'));
        SalesLine.Validate("Line Discount %", JsonHelper.GetValueAsDecimal(JToken, 'properties.hs_discount_percentage'));
        SalesLine.Insert()
    end;

    local procedure UpdateQuotationNoToHubSpot(HSObjectID: BigInteger; SalesHeader2: Record "Sales Header")
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;
        Object: Text;
    begin
        PropertyObject.Add('quotation_number', SalesHeader2."No.");
        PropertyObject.Add('dealstage', '176875373');
        JObject.Add('properties', PropertyObject);
        JObject.WriteTo(Body);

        Object := 'deal/' + Format(HSObjectID);
        HSConnect.UpdateRecordOnHubSpot(Object, Body);
    end;

    // local procedure UploadSalesQuotationFileToHubSpot(HSObjectID: BigInteger; SalesHeader2: Record "Sales Header")
    // var
    //     SalesQuote: Report "Sales Quote GST";
    //     Parameter: Text;
    //     TempBlob: Codeunit "Temp Blob";
    //     OutStr: OutStream;
    //     InStr: InStream;
    //     Response: Text;

    //     JToken: JsonToken;
    //     JObject: JsonObject;
    //     Jvalue: JsonValue;
    //     PropertyObject: JsonObject;
    //     Body: Text;
    // begin
    //     // Parameter := SalesQuote.RunRequestPage();
    //     Parameter := '<?xml version="1.0" standalone="yes"?><ReportParameters name="Sales Quote GST" id="74336">' +
    //                 '<Options><Field name="NoOfCopies">0</Field><Field name="TermsAndCond_gBln">true</Field>' +
    //                 '<Field name="PrintBankDetail_gBln">true</Field></Options><DataItems><DataItem name="Sales Header">' +
    //                 'VERSION(1) SORTING(Field1,Field3) WHERE(Field1=1(0),Field3=1(' + SalesHeader2."No." + '),Field4=1(' + SalesHeader2."Sell-to Customer No." + '))</DataItem>' +
    //                 '<DataItem name="CopyLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="PageLoop">' +
    //                 'VERSION(1) SORTING(Field1)</DataItem><DataItem name="Sales Line">VERSION(1) SORTING(Field1,Field3,Field4)' +
    //                 '</DataItem><DataItem name="RoundLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DRT">' +
    //                 'VERSION(1) SORTING(Field1,Field2,Field3)</DataItem></DataItems></ReportParameters>';
    //     TempBlob.CreateOutStream(OutStr);
    //     Report.SaveAs(Report::"Sales Quote GST", Parameter, ReportFormat::Pdf, OutStr);
    //     TempBlob.CreateInStream(InStr);
    //     Response := HSConnect.UploadFiles(InStr, 'Quotation_' + SalesHeader2."No." + '.pdf', Enum::"Document Attachment File Type"::PDF);

    //     if Response = '' then
    //         Error('File not accepted by HubSpot.');

    //     JToken.ReadFrom(Response);
    //     // JObject := JToken.AsObject();
    //     // if HSMgmt.GetJsonValue('id', JObject, Jvalue) then
    //     //     PropertyObject.Add('quotation_pdf', Jvalue.AsText());
    //     PropertyObject.Add('quotation_pdf', JsonHelper.GetValueAsText(JToken, 'id'));
    //     // Clear(JObject);
    //     JObject.Add('properties', PropertyObject);
    //     JObject.WriteTo(Body);
    //     HSConnect.UpdateRecordOnHubSpot('deals/' + Format(HSObjectID), Body);
    // end;

    local procedure UpdateCompanyProposalTarget(Cust: Record Customer; Complete: Boolean)
    var
        PropertyObject: JsonObject;
        JObject: JsonObject;
        Body: Text;
        Object: Text;
        HubspotCompany: Record "Hubspot Company";
    begin
        HubspotCompany.SetRange("Customer SystemId", Cust.SystemId);
        if HubspotCompany.FindFirst() then begin
            if Complete then begin
                PropertyObject.Add('proposal_status', 'Completed');
                PropertyObject.Add('proposal_sent_date', Today());
            end else
                PropertyObject.Add('proposal_status', 'Work In Progress');
            JObject.Add('properties', PropertyObject);
            JObject.WriteTo(Body);

            Object := 'companies/' + format(HubspotCompany.Id);
            HSConnect.UpdateRecordOnHubSpot(Object, Body);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnAfterReleaseSalesDoc, '', false, false)]
    local procedure SendQuotetoHubSpot(PreviewMode: Boolean; var SalesHeader: Record "Sales Header")
    var
        Cust: Record Customer;
    begin
        if PreviewMode then
            exit;

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote then
            exit;

        UpdateQuotationNoToHubSpot(SalesHeader.HS_ID, SalesHeader);
        // UploadSalesQuotationFileToHubSpot(SalesHeader.HS_ID, SalesHeader);
        Cust.Get(SalesHeader."Sell-to Customer No.");
        UpdateCompanyProposalTarget(Cust, true);
    end;
}