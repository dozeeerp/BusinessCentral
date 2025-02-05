namespace TST.Hubspot.Api;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.CRM.Contact;
using System.Environment;
// using Microsoft.Finance.TaxEngine.TaxTypeHandler;
using System.Utilities;
using Microsoft.Inventory.Item;
using TST.Hubspot.Company;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.Posting;
using TSTChanges.FA.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Tracking;
using TST.Hubspot.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.CRM.BusinessRelation;
using System.Automation;
using Microsoft.CRM.Team;

codeunit 51300 "Hubspot Mgmt"
{
    TableNo = "HubSpot Int. Log";
    Permissions = tabledata Customer = RIM,
                  tabledata Contact = RIM,
                  //   tabledata KAM = RIM,
                  tabledata "Salesperson/Purchaser" = RIM,
                  tabledata "Material Requsition Buffer" = RIMD,
                  TableData "License Type" = R,
                  //   tabledata "License type default feature" = RIMD,
                  //   tabledata "License Type default Features" = R,
                  //   TableData "Tax Entity" = R,
                  TableData "Workflow Step Instance" = R,
                  TableData Workflow = R,
                  TableData "Workflow Event" = R,
                  TableData "Workflow Step" = R;

    trigger OnRun()
    begin
        case Rec.subscriptionType of
            'ticket.propertyChange':
                GetTicketInfo(Rec);
            // 'company.propertyChange':
            //     UpdateCustomer(Rec);
            'contact.propertyChange':
                UpdateContact(Rec);
            'deal.propertyChange':
                ProcessDeal(Rec);
            else
                Error('%1 not considered in Integration.', rec.subscriptionType);
        end;
    end;

    var
        HSSetup: Record "Hubspot Setup";
        HSAPIMgmt: Codeunit "Hubspot API Mgmt";
        EnvInfo: Codeunit "Environment Information";
        MSAandProposal: Codeunit "MSA and Proposal";
        MaterialNotFoundError: Label 'Material Request should have at list 1 item in it.';
        NotPart: Label ' Not a part of integration, %1.';

    procedure GetTicketInfo(var HSIntLog: Record "HubSpot Int. Log")
    var
        IntError: Label 'HubSpot Integration';
        CustResponse: Text;
        ContResp: Text;
        Cust: Record Customer;
        ErrorMessage: Record "Error Message";
        Rental: Boolean;
        PipelineType: Option Demo,AddOn,Conversion;
    begin
        if HSIntLog.propertyName = 'hs_pipeline_stage' then
            case HSIntLog.propertyValue of
                '176793089', '209275252', '180948363', '212658552': //'176793089'Prod_Demo, '209275252'Sandbox_addon, '180948363'Sandbox_con, '212658552'prod_addon
                    begin
                        GetOrCreateCustomer(HSAPIMgmt.GetCustomerIDFromTicket(Format(HSIntLog.objectId)), Cust);
                        HSIntLog.Message := StrSubstNo('Customer: %1', Cust."No.");
                        ContResp := HSAPIMgmt.GetContactIDFromTicket(Format(HSIntLog.objectId), Cust);
                        HSAPIMgmt.CheckHSTicketPipeline(Format(HSIntLog.objectId), PipelineType);
                        if PipelineType = PipelineType::Conversion then
                            Rental := true;
                        if PipelineType = PipelineType::AddOn then
                            HSAPIMgmt.checkHSAddOnTicketisConversion(Format(HSIntLog.objectId), Rental);
                        CreateTransferOrder(HSIntLog.objectId, Cust, Rental);
                        HSIntLog.Message := HSIntLog.Message + ', ' + ContResp;
                        exit;
                    end;
                '176793093', '209275257', '180948368', '232930615':
                    begin
                        GetOrCreateCustomer(HSAPIMgmt.GetCustomerIDFromTicket(Format(HSIntLog.objectId)), Cust);
                        HSIntLog.Message := CreateLicenseFromTicket(HSIntLog.objectId, Cust, HSIntLog.propertyValue);
                        exit;
                    end;
            end;
        if (HSIntLog.propertyName = 'demo_extension_approved') then begin
            GetOrCreateCustomer(HSAPIMgmt.GetCustomerIDFromTicket(Format(HSIntLog.objectId)), Cust);
            if Cust."No." <> '' then
                HSIntLog.Message := CreateLicenseFromTicket(HSIntLog.objectId, Cust, HSIntLog.propertyValue)
            else
                HSIntLog.Message := CustResponse;
            exit;
        end;
        if HSIntLog.propertyName = 'submit_device_return_request' then begin
            GetOrCreateCustomer(HSAPIMgmt.GetCustomerIDFromTicket(Format(HSIntLog.objectId)), Cust);
            HSAPIMgmt.CheckHSTicketPipeline(Format(HSIntLog.objectId), PipelineType);
            if PipelineType = PipelineType::Conversion then
                Rental := true;
            if PipelineType = PipelineType::AddOn then
                HSAPIMgmt.checkHSAddOnTicketisConversion(Format(HSIntLog.objectId), Rental);
            ProcessReturn(HSIntLog, Cust, Rental);
            exit;
        end;
        Error('Not considered in Integration.');
    end;

    local procedure ProcessDeal(var HSIntLog: Record "HubSpot Int. Log")
    var
        Cust: Record Customer;
    begin
        if HSIntLog.propertyName = 'dealstage' then
            if HSIntLog.propertyValue = 'contractsent' then begin
                if HSIntLog."Customer No." <> '' then
                    Cust.Get(HSIntLog."Customer No.")
                else begin
                    GetOrCreateCustomer(HSAPIMgmt.GetCustomerIDFromDeal(Format(HSIntLog.objectId)), Cust);
                    HSIntLog."Customer No." := Cust."No.";
                end;
                MSAandProposal.createQuotation(Cust, HSIntLog.objectId);
                MSAandProposal.createMSA(Cust);
                exit;
            end;
        Error(NotPart, HSIntLog.propertyName);
    end;

    local procedure GetOrCreateCustomer(HSCustID: Text; var Cust: Record Customer)
    var
        HubspotCompany: Record "Hubspot Company";
        UpdateCustomer: Codeunit "Hubspot Update Customer";
    begin
        if HSCustID = '' then
            Error('Customer ID should not be null check association.');
        if HubspotCompany.Get(HSCustID) then begin
            if isnullguid(HubspotCompany."Customer SystemId") then
                UpdateCustomer.CreateCustomerFromCompany(HubspotCompany);
            Cust.GetBySystemId(HubspotCompany."Customer SystemId");
        end;
    end;

    procedure InsertOrUpdateContact(Response: Text; Cust: Record Customer; Primary: Boolean): Text
    var
        Jtoken: JsonToken;
        JObject: JsonObject;
        ValueToken: JsonToken;
        Jvalue: JsonValue;

        Contact: Record Contact;
        Contact2: Record Contact;
        Modify: Boolean;
        Id: Text;
        ContactBusinessRelation: Record "Contact Business Relation";

        Cust2: Record Customer;
        Msg: Text;
    begin
        if Response = '' then
            Error('Missing Contact');
        // get fileds from response
        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();
        JObject.Get('id', ValueToken);
        Id := ValueToken.AsValue().AsText();

        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();
        if GetJsonValue('erp_contact_no_', JObject, Jvalue) then begin
            if Contact2.Get(Jvalue.AsText()) then begin
                Contact := Contact2;
                Modify := true;
            end;
        end else begin
            Contact2.Reset();
            Contact2.SetFilter("HS Contact ID", Id);
            if Contact2.FindFirst() then begin
                Contact := Contact2;
                Modify := true;
            end;
        end;

        if not Modify then begin
            Contact.Init();
        end;

        // Process mapping
        Contact."HS Contact ID" := Id;
        Contact.Type := Contact.Type::Person;
        Contact."Contact Business Relation" := Contact."Contact Business Relation"::Customer;

        if GetJsonValue('firstname', JObject, Jvalue) then
            Contact.Validate("First Name", Jvalue.AsText());
        if GetJsonValue('salutation', JObject, Jvalue) then
            Contact."Salutation Code" := Jvalue.AsText();
        if GetJsonValue('jobtitle', JObject, Jvalue) then
            Contact."Job Title" := Jvalue.AsText();
        if GetJsonValue('middle_name', JObject, Jvalue) then
            Contact.Validate("Middle Name", Jvalue.AsText());
        if GetJsonValue('lastname', JObject, Jvalue) then
            Contact.Validate(Surname, Jvalue.AsText());
        if GetJsonValue('address', JObject, Jvalue) then
            Contact.Address := Jvalue.AsText();
        if GetJsonValue('address_2', JObject, Jvalue) then
            Contact."Address 2" := Jvalue.AsText();
        if GetJsonValue('city', JObject, Jvalue) then
            Contact.City := Jvalue.AsText();
        if GetJsonValue('ip_country_code', JObject, Jvalue) then
            Contact.Validate("Country/Region Code", Jvalue.AsText());
        if GetJsonValue('zip', JObject, Jvalue) then
            Contact."Post Code" := Jvalue.AsText();
        if JObject.Get('hubspot_owner_id', ValueToken) then begin
            Jvalue := ValueToken.AsValue();
            //write handling for hubspot_owner_id
        end;
        if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Cust."No.") then
            Contact.Validate("Company No.", ContactBusinessRelation."Contact No.");
        if GetJsonValue('email', JObject, Jvalue) then
            Contact."E-Mail" := Jvalue.AsText();
        if GetJsonValue('phone', JObject, Jvalue) then
            Contact."Phone No." := Jvalue.AsText();
        if GetJsonValue('mobilephone', JObject, Jvalue) then
            Contact."Mobile Phone No." := Jvalue.AsText();

        if Modify then begin
            Contact.Modify(true);
            Msg := HSAPIMgmt.UpdateContactNoToHS(Contact);
        end else begin
            Contact.Insert(true);
            Msg := HSAPIMgmt.UpdateContactNoToHS(Contact);
        end;

        if Primary then begin
            Cust2.Get(Cust."No.");
            Cust2.Validate("Primary Contact No.", Contact."No.");
            Cust2.Modify(true);
        end;
        exit(Msg)
    end;

    local procedure CreateLicenseFromTicket(ObjectId: BigInteger; Cust: Record Customer; PropertyValue: Text): Text
    var
        Response: Text;
        Properties: Text;
        Jtoken: JsonToken;
        JObject: JsonObject;
        ValueToken: JsonToken;
        Jvalue: JsonValue;

        LicReq: Record "License Request";
        LicReq2: Record "License Request";
        Modify: Boolean;
        HSConnect: Codeunit "HubSpot Connect";
        AssociatedTicketID: BigInteger;
        OriginalLic: Record "License Request";
        OldLicNo: Code[20];
        SalesSetup: Record "EMS Setup";
    begin
        case PropertyValue of
            '176793093': //Demo Pipeline
                begin
                    Properties := 'properties=license_code&properties=license_qty_&properties=duration&properties=document_type';
                    Response := HSAPIMgmt.GetTicket(ObjectId, Properties);

                    if Response = '' then
                        exit('license info missing');

                    Jtoken.ReadFrom(Response);
                    JObject := Jtoken.AsObject();

                    LicReq2.Reset();
                    LicReq2.SetFilter(HS_ID, '%1', ObjectId);
                    if LicReq2.FindFirst() then begin
                        if LicReq2.Status in [LicReq2.Status::Active, LicReq2.Status::Expired, LicReq2.Status::Terminated] then
                            Error('Requested license request status is %1', LicReq2.Status);
                        LicReq := LicReq2;
                        Modify := true;
                    end else
                        LicReq.Init();

                    if not Modify then begin
                        LicReq.Validate("Customer No.", Cust."No.");
                        LicReq.Validate("Contact No.");
                    end;

                    if JObject.Get('properties', Jtoken) then
                        JObject := Jtoken.AsObject();
                    if GetJsonValue('license_code', JObject, Jvalue) then
                        LicReq.validate("License Code", Jvalue.AsText());
                    if GetJsonValue('license_qty_', JObject, Jvalue) then
                        LicReq."License Qty." := Jvalue.AsInteger();
                    if GetJsonValue('duration', JObject, Jvalue) then
                        LicReq.Validate(Duration, Jvalue.AsText() + 'D');

                    LicReq."Document Type" := LicReq."Document Type"::New;

                    LicReq.HS_ID := ObjectId;
                    LicReq.Status := LicReq.Status::Released;

                    if not Modify then
                        LicReq.Insert(true)
                    else
                        LicReq.Modify(true);
                end;
            '209275257':  //Add On pipeline
                begin
                    //Get old license number
                    GetOldLicenseNumber(ObjectId, OldLicNo, true);

                    SalesSetup.GET;
                    SalesSetup.TESTFIELD("License Request Nos.");

                    OriginalLic.Reset();
                    OriginalLic.SetRange("License No.", OldLicNo);
                    if OriginalLic.FindFirst() then begin
                        OriginalLic.TestField(Terminated, false);
                        OriginalLic.TestField(Renewed, false);
                        OriginalLic.TestField(Extended, false);
                        OriginalLic.TestField(Status, OriginalLic.Status::Active);

                        LicReq2.Reset();
                        LicReq2.SetFilter(HS_ID, '%1', ObjectId);
                        if LicReq2.FindFirst() then begin
                            if LicReq2.Status in [LicReq2.Status::Active, LicReq2.Status::Expired, LicReq2.Status::Terminated] then
                                Error('Requested license request status is %1', LicReq2.Status);
                            LicReq := LicReq2;
                            // Modify := true;
                        end else begin
                            LicReq.Init();
                            LicReq.TransferFields(OriginalLic);
                            LicReq."No. Series" := SalesSetup."License Request Nos.";
                            LicReq."No." := '';
                            LicReq."License No." := '';
                            LicReq.Insert(true);
                        end;
                        LicReq."Document Type" := LicReq."Document Type"::"Add on";
                        LicReq.Status := LicReq.Status::Released;
                        LicReq."Parent Add on Of" := OriginalLic."License No.";
                        IF OriginalLic."Original Add on Of" <> '' then
                            LicReq."Original Add on Of" := OriginalLic."Original Add on Of"
                        else
                            LicReq."Original Add on Of" := OriginalLic."License No.";
                        LicReq.Validate("License Type", OriginalLic."License Type");
                        LicReq.validate("Activation Date", WorkDate());
                        LicReq."Expiry Date" := OriginalLic."Expiry Date";
                        LicReq."Requested Activation Date" := 0D;
                        // LicenseRequest.Dunning := false;
                        // LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";

                        //get properties form add on ticket
                        Clear(Properties);
                        Clear(Response);
                        Clear(Jtoken);

                        Properties := 'properties=license_code&properties=license_qty_&properties=duration';
                        Response := HSAPIMgmt.GetTicket(ObjectId, Properties);
                        if Response = '' then
                            exit('License info missing');

                        Jtoken.ReadFrom(Response);
                        JObject := Jtoken.AsObject();

                        if JObject.Get('properties', Jtoken) then
                            JObject := Jtoken.AsObject();
                        if GetJsonValue('license_qty_', JObject, Jvalue) then
                            LicReq."License Qty." := Jvalue.AsInteger();

                        LicReq.HS_ID := ObjectId;

                        LicReq.Modify(true);
                    end;
                end;
            'true':  //Extension license
                begin
                    GetOldLicenseNumber(ObjectId, OldLicNo, false);

                    SalesSetup.GET;
                    SalesSetup.TESTFIELD("License Request Nos.");

                    OriginalLic.Reset();
                    OriginalLic.SetRange("License No.", OldLicNo);
                    OriginalLic.SetRange(Status, OriginalLic.Status::Active);
                    if OriginalLic.FindFirst() then begin
                        OriginalLic.TestField(Terminated, false);
                        OriginalLic.TestField(Renewed, false);
                        OriginalLic.TestField(Extended, false);

                        // LicReq2.Reset();
                        // LicReq2.SetFilter(HS_ID, '%1', ObjectId);
                        // if LicReq2.FindFirst() then begin
                        //     if LicReq2.Status in [LicReq2.Status::Active, LicReq2.Status::Expired, LicReq2.Status::Terminated] then
                        //         Error('Requested license request status is %1', LicReq2.Status);
                        //     LicReq := LicReq2;
                        // end else begin
                        LicReq.Init();
                        LicReq.TransferFields(OriginalLic);
                        LicReq."No. Series" := SalesSetup."License Request Nos.";
                        LicReq."No." := '';
                        LicReq."License No." := '';
                        LicReq.Insert(true);
                        // end;
                        LicReq."Document Type" := LicReq."Document Type"::Extension;
                        LicReq.Status := LicReq.Status::Released;
                        LicReq."Parent Extension Of" := OriginalLic."License No.";
                        IF OriginalLic."Original Extension Of" <> '' then
                            LicReq."Original Extension Of" := OriginalLic."Original Extension Of"
                        else
                            LicReq."Original Extension Of" := OriginalLic."License No.";
                        LicReq.Validate("License Type", OriginalLic."License Type");
                        LicReq.validate("Activation Date", WorkDate());
                        LicReq."Requested Activation Date" := 0D;
                        // LicenseRequest.Dunning := false;
                        // LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";

                        //get properties form add on ticket
                        Clear(Properties);
                        Clear(Response);
                        Clear(Jtoken);

                        Properties := 'properties=demo_extension_requested__days_';
                        Response := HSAPIMgmt.GetTicket(ObjectId, Properties);
                        if Response = '' then
                            Error('License info missing');

                        Jtoken.ReadFrom(Response);
                        JObject := Jtoken.AsObject();

                        if JObject.Get('properties', Jtoken) then
                            JObject := Jtoken.AsObject();
                        if GetJsonValue('demo_extension_requested__days_', JObject, Jvalue) then
                            LicReq.Validate(Duration, Jvalue.AsText() + 'D');

                        LicReq.HS_ID := ObjectId;

                        LicReq.Modify(true);
                    end else begin
                        Properties := 'properties=license_code&properties=license_qty_&properties=demo_extension_requested__days_&properties=document_type';
                        Response := HSAPIMgmt.GetTicket(ObjectId, Properties);

                        if Response = '' then
                            exit('license info missing');

                        Jtoken.ReadFrom(Response);
                        JObject := Jtoken.AsObject();

                        LicReq.Init();
                        LicReq.Validate("Customer No.", Cust."No.");
                        LicReq.Validate("Contact No.");
                        if JObject.Get('properties', Jtoken) then
                            JObject := Jtoken.AsObject();
                        if GetJsonValue('license_code', JObject, Jvalue) then
                            LicReq.validate("License Code", Jvalue.AsText());
                        if GetJsonValue('license_qty_', JObject, Jvalue) then
                            LicReq."License Qty." := Jvalue.AsInteger();
                        if GetJsonValue('demo_extension_requested__days_', JObject, Jvalue) then
                            LicReq.Validate(Duration, Jvalue.AsText() + 'D');

                        LicReq."Document Type" := LicReq."Document Type"::New;

                        LicReq.HS_ID := ObjectId;
                        LicReq.Status := LicReq.Status::Released;

                        LicReq.Insert(true);
                    end;
                end;
            '180948368': //Conversion Grace
                begin
                    Properties := 'properties=license_code&properties=license_qty_&properties=grace_period&properties=document_type';
                    Response := HSAPIMgmt.GetTicket(ObjectId, Properties);

                    if Response = '' then
                        exit('license info missing');

                    Jtoken.ReadFrom(Response);
                    JObject := Jtoken.AsObject();

                    // LicReq2.Reset();
                    // LicReq2.SetFilter(HS_ID, '%1', ObjectId);
                    // if LicReq2.FindFirst() then begin
                    //     if LicReq2.Status in [LicReq2.Status::Active, LicReq2.Status::Expired, LicReq2.Status::Terminated] then
                    //         Error('Requested license request status is %1', LicReq2.Status);
                    //     LicReq := LicReq2;
                    //     Modify := true;
                    // end else
                    LicReq.Init();

                    if not Modify then begin
                        LicReq.Validate("Customer No.", Cust."No.");
                        LicReq.Validate("Contact No.");
                    end;

                    if JObject.Get('properties', Jtoken) then
                        JObject := Jtoken.AsObject();
                    if GetJsonValue('license_code', JObject, Jvalue) then
                        LicReq.validate("License Code", Jvalue.AsText());
                    if GetJsonValue('license_qty_', JObject, Jvalue) then
                        LicReq."License Qty." := Jvalue.AsInteger();
                    if GetJsonValue('grace_period', JObject, Jvalue) then
                        LicReq.Validate(Duration, Jvalue.AsText() + 'D');

                    LicReq."Document Type" := LicReq."Document Type"::New;

                    LicReq.HS_ID := ObjectId;
                    LicReq.Status := LicReq.Status::Released;

                    if not Modify then
                        LicReq.Insert(true)
                    else
                        LicReq.Modify(true);
                end;
            '232930615': //Conversion Pipeline
                begin
                    Properties := 'properties=license_code&properties=license_qty_&properties=duration&properties=document_type';
                    Response := HSAPIMgmt.GetTicket(ObjectId, Properties);

                    if Response = '' then
                        exit('license info missing');

                    Jtoken.ReadFrom(Response);
                    JObject := Jtoken.AsObject();

                    // LicReq2.Reset();
                    // LicReq2.SetFilter(HS_ID, '%1', ObjectId);
                    // if LicReq2.FindFirst() then begin
                    //     if LicReq2.Status in [LicReq2.Status::Active, LicReq2.Status::Expired, LicReq2.Status::Terminated] then
                    //         Error('Requested license request status is %1', LicReq2.Status);
                    //     LicReq := LicReq2;
                    //     Modify := true;
                    // end else
                    LicReq.Init();

                    if not Modify then begin
                        LicReq.Validate("Customer No.", Cust."No.");
                        LicReq.Validate("Contact No.");
                    end;

                    if JObject.Get('properties', Jtoken) then
                        JObject := Jtoken.AsObject();
                    if GetJsonValue('license_code', JObject, Jvalue) then
                        LicReq.validate("License Code", Jvalue.AsText());
                    if GetJsonValue('license_qty_', JObject, Jvalue) then
                        LicReq."License Qty." := Jvalue.AsInteger();
                    if GetJsonValue('duration', JObject, Jvalue) then
                        LicReq.Validate(Duration, Jvalue.AsText() + 'D');

                    LicReq."Document Type" := LicReq."Document Type"::New;

                    LicReq.HS_ID := ObjectId;
                    LicReq.Status := LicReq.Status::Released;

                    if not Modify then
                        LicReq.Insert(true)
                    else
                        LicReq.Modify(true);
                end;
            else
                Error('Property value %1 is not considered in license', PropertyValue);
        end;
        exit(StrSubstNo('License Created %1', LicReq."No."));
    end;

    local procedure GetOldLicenseNumber(ObjectId: BigInteger; var OldLicNo: Code[20]; AddOn: Boolean)
    var
        AssociatedTicketID: BigInteger;
        Properties: Text;
        Response: Text;
        Jtoken: JsonToken;
        JObject: JsonObject;
        Jvalue: JsonValue;
    begin
        if AddOn then
            Evaluate(AssociatedTicketID, HSAPIMgmt.GetAssociatedTicketID(ObjectId))
        else
            AssociatedTicketID := ObjectId;
        Properties := 'properties=license_request_no_';
        Response := HSAPIMgmt.GetTicket(AssociatedTicketID, Properties);
        if Response = '' then
            Error('License info missing');

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();

        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();
        if GetJsonValue('license_request_no_', JObject, Jvalue) then
            OldLicNo := Jvalue.AsText();

        if OldLicNo = '' then
            Error('Add on license is only posible on active License');
    end;

    procedure GetJsonValue(Parameter: Text; JObject: JsonObject; var Jvalue: JsonValue): Boolean
    var
        Jtoken: JsonToken;
    begin
        if JObject.Get(Parameter, Jtoken) then begin
            Jvalue := Jtoken.AsValue();
            exit(not Jvalue.IsNull);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", OnAfterValidateEvent, Status, false, false)]
    procedure UpdateLicenseActivatedOnHS(var Rec: Record "License Request"; var xRec: Record "License Request")
    var
        JObject: JsonObject;
        HSIntLog: Record "HubSpot Int. Log";
    begin
        if (Rec.Status = rec.Status::Active) and (rec.HS_ID <> 0) then begin
            HSIntLog.Reset();
            HSIntLog.SetRange(objectId, Rec.HS_ID);
            if HSIntLog.FindLast() then begin
                if HSIntLog.propertyName = 'hs_pipeline_stage' then
                    case HSIntLog.propertyValue of
                        '176793093': //Demo
                            begin
                                JObject.Add('no_of_devices_to_activate', Rec."License Qty.");
                                JObject.Add('license_activation', true);
                                JObject.Add('hs_pipeline_stage', '176793094');
                                JObject.Add('license_request_no_', rec."License No.");
                                JObject.Add('date_of_license_activation', rec."Activation Date");
                                JObject.Add('license_expiration_date', rec."Expiry Date");
                                HSAPIMgmt.UpdateTicketOnHS(Rec.HS_ID, JObject);
                            end;
                        '209275257': //Addon
                            begin
                                JObject.Add('no_of_devices_to_activate', Rec."License Qty.");
                                JObject.Add('license_activation', true);
                                JObject.Add('license_request_no_', rec."License No.");
                                JObject.Add('date_of_license_activation', rec."Activation Date");
                                JObject.Add('license_expiration_date', rec."Expiry Date");
                                HSAPIMgmt.UpdateTicketOnHS(Rec.HS_ID, JObject);
                            end;
                        '180948368': // Conversion Grace
                            begin
                                JObject.Add('no_of_devices_to_activate', Rec."License Qty.");
                                JObject.Add('license_activation', true);
                                JObject.Add('hs_pipeline_stage', '232930614');
                                JObject.Add('license_request_no_', rec."License No.");
                                JObject.Add('license_activation_date__grace_', rec."Activation Date");
                                JObject.Add('license_expiration_date__grace_', rec."Expiry Date");
                                HSAPIMgmt.UpdateTicketOnHS(Rec.HS_ID, JObject);
                            end;
                        '232930615': // Conversion Commercial
                            begin
                                JObject.Add('no_of_devices_to_activate', Rec."License Qty.");
                                JObject.Add('license_activation', true);
                                JObject.Add('hs_pipeline_stage', '232930616');
                                JObject.Add('license_request_no_', rec."License No.");
                                JObject.Add('date_of_license_activation', rec."Activation Date");
                                JObject.Add('license_expiration_date', rec."Expiry Date");
                                HSAPIMgmt.UpdateTicketOnHS(Rec.HS_ID, JObject);
                            end;
                    end;
                if HSIntLog.propertyName = 'demo_extension_approved' then
                    if HSIntLog.propertyValue = 'true' then begin
                        JObject.Add('no_of_devices_to_activate', Rec."License Qty.");
                        JObject.Add('license_activation', true);
                        JObject.Add('license_request_no_', rec."License No.");
                        JObject.Add('license_expiration_date', rec."Expiry Date");
                        JObject.Add('demo_extension_requested__days_', '');
                        HSAPIMgmt.UpdateTicketOnHS(Rec.HS_ID, JObject);
                    end;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnAfterTransferOrderPostShipment, '', false, false)]
    procedure UpdateDeviceShippedOnHS(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        JObject: JsonObject;
        HSIntLog: Record "HubSpot Int. Log";
        HSSetup: Record "Hubspot Setup";
        ILE: Record "Item Ledger Entry";
        ILE2: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        InputsObject: JsonObject;
        PropertyObject: JsonObject;
        InputsArray: JsonArray;
        Body: Text;
        Object: Text;
        HSConnect: Codeunit "HubSpot Connect";
    begin
        if TransferHeader.HS_ID = 0 then
            exit;
        TransferShipmentHeader.HS_ID := TransferHeader.HS_ID;
        TransferShipmentHeader.Modify(true);
        HSSetup.Get();
        if (HSSetup."Demo Location" = TransferHeader."Transfer-to Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-to Code") then begin
            HSIntLog.Reset();
            HSIntLog.SetRange(objectId, TransferHeader.HS_ID);
            if HSIntLog.FindLast() then begin
                if HSIntLog.propertyName = 'hs_pipeline_stage' then begin
                    case HSIntLog.propertyValue of
                        '176793089':    //Demo Pipeline
                            JObject.Add('hs_pipeline_stage', '176793090');
                        '180948363':    //Conversion
                            JObject.Add('hs_pipeline_stage', '180948364');
                        '209275252':    //Add On Material Sandbox
                            JObject.Add('hs_pipeline_stage', '209275253');
                        '212658552':    //Add On Material Production
                            JObject.Add('hs_pipeline_stage', '212658553');
                    end;
                    HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
                end;
            end;
        end;
        if (HSSetup."Demo Location" = TransferHeader."Transfer-from Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-from Code") then begin
            Object := 'device';
            ILE.Reset();
            ILE.SetRange("Document No.", TransferShipmentHeader."No.");
            ILE.SetRange(Positive, false);
            ILE.SetRange("Posting Date", TransferShipmentHeader."Posting Date");
            if ILE.FindSet() then
                repeat
                    ItemApplnEntry.Reset();
                    ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
                    ItemApplnEntry.SetRange("Outbound Item Entry No.", ILE."Entry No.");
                    ItemApplnEntry.SetRange("Item Ledger Entry No.", ILE."Entry No.");
                    IF ItemApplnEntry.Find('-') then
                        repeat
                            Clear(InputsObject);
                            Clear(PropertyObject);
                            ILE2.Get(ItemApplnEntry."Inbound Item Entry No.");
                            InputsObject.Add('idProperty', 'entry_no_');
                            if EnvInfo.IsSandbox() then
                                InputsObject.Add('id', Format(ILE2."Entry No."))
                            else
                                InputsObject.Add('id', 'I' + Format(ILE2."Entry No."));
                            PropertyObject.Add('customer_no_', ILE."Customer No.");
                            PropertyObject.Add('lot_no_', ILE."Lot No.");
                            PropertyObject.Add('serial_no_', ILE."Serial No.");
                            PropertyObject.Add('item_no_', ILE."Item No.");
                            PropertyObject.Add('item_description', ILE.Description);
                            PropertyObject.Add('variant', ILE."Variant Code");
                            PropertyObject.Add('posting_received_date', ILE."Posting Date");
                            PropertyObject.Add('quantity', ILE.Quantity);
                            PropertyObject.Add('returned', 'true');
                            InputsObject.Add('properties', PropertyObject);
                            InputsArray.Add(InputsObject);
                        until ItemApplnEntry.Next() = 0;
                until ILE.Next() = 0;
            JObject.Add('inputs', InputsArray);
            JObject.WriteTo(Body);
            HSConnect.BatchUpsert(Object, Body);

            Clear(JObject);
            ILE.Reset();
            ILE.SetFilter("Remaining Quantity", '<>%1', 0);
            ILE.SetFilter("Customer No.", TransferHeader."Customer No.");
            if HSSetup."Rental Location" = TransferHeader."Transfer-from Code" then begin
                ILE.SetFilter("Location Code", HSSetup."Rental Location");
                if not ILE.FindSet() then begin
                    JObject.Add('hs_pipeline_stage', '180948369');
                    HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
                end;
            end else begin
                ILE.SetFilter("Location Code", HSSetup."Demo Location");
                if not ILE.FindSet() then begin
                    JObject.Add('hs_pipeline_stage', '176793097');
                    HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
                end else begin
                    JObject.Add('current_status', 'Partial Device Return in Progress');
                    HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
                end;
            end;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FATransferOrder-Post Shipment", OnAfterTransferOrderPostShipment, '', false, false)]
    local procedure UpdateFAShippedOnHS(var TransferHeader: Record "FA Transfer Header"; var TransferShipmentHeader: Record "FA Transfer Shipment Header"; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean)
    var
        JObject: JsonObject;
        HSIntLog: Record "HubSpot Int. Log";
        HSSetup: Record "Hubspot Setup";
        ILE: Record "FA Item Ledger Entry";
        ILE2: Record "FA Item Ledger Entry";
        ItemApplnEntry: Record "FA Item Application Entry";
        InputsObject: JsonObject;
        PropertyObject: JsonObject;
        InputsArray: JsonArray;
        Body: Text;
        Object: Text;
        HSConnect: Codeunit "HubSpot Connect";
    begin
        if TransferHeader.HS_ID = 0 then
            exit;
        HSSetup.Get();
        if (HSSetup."Demo Location" = TransferHeader."Transfer-to Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-to Code") then begin
            HSIntLog.Reset();
            HSIntLog.SetRange(objectId, TransferHeader.HS_ID);
            if HSIntLog.FindLast() then begin
                if HSIntLog.propertyName = 'hs_pipeline_stage' then begin
                    case HSIntLog.propertyValue of
                        '176793089':    //Demo Pipeline
                            JObject.Add('hs_pipeline_stage', '176793090');
                        '180948363':    //Conversion
                            JObject.Add('hs_pipeline_stage', '180948364');
                        '209275252':    //Add On Material Sandbox
                            JObject.Add('hs_pipeline_stage', '209275253');
                        '212658552':    //Add On Material Production
                            JObject.Add('hs_pipeline_stage', '212658553');
                    end;
                    HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
                end;
            end;
        end;
        if (HSSetup."Demo Location" = TransferHeader."Transfer-from Code") or (HSSetup."Rental Location" = TransferHeader."Transfer-from Code") then begin
            Object := 'device';
            ILE.Reset();
            ILE.SetRange("Document No.", TransferShipmentHeader."No.");
            ILE.SetRange(Positive, false);
            ILE.SetRange("Posting Date", TransferShipmentHeader."Posting Date");
            if ILE.FindSet() then
                repeat
                    ItemApplnEntry.Reset();
                    ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
                    ItemApplnEntry.SetRange("Outbound Item Entry No.", ILE."Entry No.");
                    ItemApplnEntry.SetRange("Item Ledger Entry No.", ILE."Entry No.");
                    IF ItemApplnEntry.Find('-') then
                        repeat
                            Clear(InputsObject);
                            Clear(PropertyObject);
                            ILE2.Get(ItemApplnEntry."Inbound Item Entry No.");
                            InputsObject.Add('idProperty', 'entry_no_');
                            if EnvInfo.IsSandbox() then
                                InputsObject.Add('id', Format(ILE2."Entry No."))
                            else
                                InputsObject.Add('id', 'A' + Format(ILE2."Entry No."));
                            PropertyObject.Add('customer_no_', ILE."Customer No.");
                            PropertyObject.Add('lot_no_', ILE."Lot No.");
                            PropertyObject.Add('serial_no_', ILE."Serial No.");
                            PropertyObject.Add('item_no_', ILE."FA Item No.");
                            PropertyObject.Add('item_description', ILE.Description);
                            PropertyObject.Add('variant', ILE."Variant Code");
                            PropertyObject.Add('posting_received_date', ILE."Posting Date");
                            PropertyObject.Add('quantity', ILE.Quantity);
                            PropertyObject.Add('returned', 'true');
                            InputsObject.Add('properties', PropertyObject);
                            InputsArray.Add(InputsObject);
                        until ItemApplnEntry.Next() = 0;
                until ILE.Next() = 0;
            JObject.Add('inputs', InputsArray);
            JObject.WriteTo(Body);
            HSConnect.BatchUpsert(Object, Body);

            Clear(JObject);
            ILE.Reset();
            ILE.SetFilter("Remaining Quantity", '<>%1', 0);
            ILE.SetFilter("Customer No.", TransferHeader."Transfer-from Customer");
            ILE.SetFilter("Location Code", HSSetup."Demo Location");
            if not ILE.FindSet() then begin
                JObject.Add('hs_pipeline_stage', '176793097');
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end else begin
                JObject.Add('current_status', 'Partial Device Return in Progress');
                HSAPIMgmt.UpdateTicketOnHS(TransferHeader.HS_ID, JObject);
            end;
        end;
    end;

    local procedure CreateTransferOrder(ObjectId: BigInteger; Cust: Record Customer; Rental: Boolean)
    var
        Response: Text;
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        ValueToken: JsonToken;
        JValue: JsonValue;
        Output: Text;

        MaterialReqBuffer: Record "Material Requsition Buffer";
        WareTranOrdNo: Code[20];
        EmpTranOrdNo: Code[20];

        AddSameAsBilling: Boolean;
        ShipToAddress: array[8] of Text;
    begin
        if not MaterialReqBuffer.IsEmpty then
            MaterialReqBuffer.DeleteAll();

        Response := HSAPIMgmt.GetMaetrialIDFromTicket(ObjectId);
        if Response = '' then
            Error('Marital Request not found on HubSpot.');
        JToken.ReadFrom(Response);
        JObject := JToken.AsObject();
        if JObject.Get('results', JToken) then
            JArray := JToken.AsArray();

        if JArray.Count = 0 then
            Error(MaterialNotFoundError);

        foreach Jtoken in Jarray do begin
            Jobject := JToken.AsObject();
            if GetJsonValue('toObjectId', JObject, JValue) then
                PrepareMaterialReqBuffer(JValue.AsText(), Cust."No.", MaterialReqBuffer);
        end;
        MaterialReqBuffer.Reset();
        MaterialReqBuffer.CalcSums(Warehouse);
        if MaterialReqBuffer.Warehouse <> 0 then
            CreateTOfromWarehouse(MaterialReqBuffer, Cust, Rental, ObjectId, WareTranOrdNo);

        MaterialReqBuffer.Reset();
        MaterialReqBuffer.CalcSums(Self);
        if MaterialReqBuffer.Self <> 0 then
            CreateTOfromEmployee(MaterialReqBuffer, Cust, Rental, ObjectId, EmpTranOrdNo);

        MaterialReqBuffer.DeleteAll();
        HSAPIMgmt.GetShippingAddressFromTicket(Format(ObjectId), AddSameAsBilling, ShipToAddress);
        if not AddSameAsBilling then begin
            if WareTranOrdNo <> '' then
                UpdateShipToAddrsOnTransferOrder(WareTranOrdNo, ShipToAddress);
            if EmpTranOrdNo <> '' then
                UpdateShipToAddrsOnTransferOrder(EmpTranOrdNo, ShipToAddress);
        end;
    end;

    local procedure CreateTOfromWarehouse(var MaterialReqBuffer: Record "Material Requsition Buffer"; Cust: Record Customer; Rental: Boolean;
        HS_ID: BigInteger; var TransHeaderNo: Code[20])
    var
        // TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Item: Record Item;
        LineNo: Integer;
    begin
        HSSetup.Get();
        HSSetup.TestField("Default Warehouse");
        HSSetup.TestField("Demo Location");
        if not Rental then
            TransHeaderNo := InsertTransferHeader(HSSetup."Default Warehouse", HSSetup."Demo Location", Cust."No.", '', HS_ID)
        else begin
            HSSetup.TestField("Rental Location");
            TransHeaderNo := InsertTransferHeader(HSSetup."Default Warehouse", HSSetup."Rental Location", Cust."No.", '', HS_ID)
        end;

        LineNo := 0;

        if MaterialReqBuffer.FindSet() then
            repeat
                if MaterialReqBuffer.Warehouse <> 0 then begin
                    TransLine.Init();
                    TransLine."Document No." := TransHeaderNo;
                    TransLine."Line No." := LineNo + 10000;
                    TransLine.SuspendStatusCheck(true);
                    TransLine.Validate("Item No.", MaterialReqBuffer."No.");
                    TransLine.Validate(Quantity, MaterialReqBuffer.Warehouse);
                    TransLine.Insert(true);
                end;
            until MaterialReqBuffer.Next() = 0;
    end;

    local procedure CreateTOfromEmployee(var MaterialReqBuffer: Record "Material Requsition Buffer"; Cust: Record Customer; Rental: Boolean;
        HS_ID: BigInteger; var TransHeaderNo: Code[20])
    var
        // TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        Item: Record Item;
        LineNo: Integer;
    begin
        HSSetup.Get();
        HSSetup.TestField("Employee Location");
        HSSetup.TestField("Demo Location");
        if not Rental then
            TransHeaderNo := InsertTransferHeader(HSSetup."Employee Location", HSSetup."Demo Location", Cust."No.", '', HS_ID)
        else begin
            HSSetup.TestField("Rental Location");
            TransHeaderNo := InsertTransferHeader(HSSetup."Employee Location", HSSetup."Rental Location", Cust."No.", '', HS_ID)
        end;

        LineNo := 0;

        if MaterialReqBuffer.FindSet() then
            repeat
                if MaterialReqBuffer.self <> 0 then begin
                    if not Item.Get(MaterialReqBuffer."No.") then
                        Error('Item dose not exist in ERP %1', MaterialReqBuffer."No.");
                    TransLine.Init();
                    TransLine."Document No." := TransHeaderNo;
                    TransLine."Line No." := LineNo + 10000;
                    TransLine.SuspendStatusCheck(true);
                    TransLine.Validate("Item No.", MaterialReqBuffer."No.");
                    TransLine.Validate(Quantity, MaterialReqBuffer.Self);
                    TransLine.Insert(true);
                end;
            until MaterialReqBuffer.Next() = 0;
    end;

    local procedure PrepareMaterialReqBuffer(MaterialReqID: Text; CustNo: Code[20]; var MaterialReqBuffer: Record "Material Requsition Buffer")
    var
        Response: Text;
        Jtoken: JsonToken;
        JObject: JsonObject;
        Jvalue: JsonValue;
    begin
        Response := HSAPIMgmt.GetMaterialReq(MaterialReqID);
        if Response = '' then
            exit;

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();
        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();

        MaterialReqBuffer.Init();
        MaterialReqBuffer."Entry No." := MaterialReqBuffer.GetLastEntryNo() + 1;
        MaterialReqBuffer."Customer No." := CustNo;

        if GetJsonValue('description', JObject, Jvalue) then
            MaterialReqBuffer."No." := Jvalue.AsText();
        if GetJsonValue('self_quantity', JObject, Jvalue) then
            if Jvalue.AsText() <> '' then
                MaterialReqBuffer.Self := Jvalue.AsDecimal();
        if GetJsonValue('warehouse_quantity', JObject, Jvalue) then
            if Jvalue.AsText() <> '' then
                MaterialReqBuffer.Warehouse := Jvalue.AsDecimal();

        MaterialReqBuffer.Insert();
    end;

    // local procedure UpdateCustomer(var HSIntLog: Record "HubSpot Int. Log")
    // var
    //     Cust: Record Customer;
    //     Response: Text;

    //     Jtoken: JsonToken;
    //     JObject: JsonObject;
    //     ValueToken: JsonToken;
    //     Jvalue: JsonValue;
    // begin
    //     if HSIntLog.changeSource in ['CRM_UI', 'DEALS', 'MOBILE_ANDROID', 'MOBILE_IOS', 'AUTOMATION_PLATFORM'] then begin
    //         Cust.Reset();
    //         Cust.SetFilter("HS Customer ID", '%1', Format(HSIntLog.objectId));
    //         if Cust.FindSet() then
    //             if Cust.Count() = 1 then begin
    //                 if Cust.FindFirst() then begin
    //                     UpdateCustomerProperties(HSIntLog, Cust);
    //                     Cust.Modify(true);
    //                 end;
    //             end else
    //                 Error('Customer not found or more than 1, cust count - %1', Cust.Count);
    //         if not Cust.FindSet() then begin
    //             Response := HSAPIMgmt.GetCustomerFromHS(Format(HSIntLog.objectId));
    //             if Response <> '' then begin
    //                 Jtoken.ReadFrom(Response);
    //                 JObject := Jtoken.AsObject();

    //                 if JObject.Get('properties', Jtoken) then
    //                     JObject := Jtoken.AsObject();
    //                 if GetJsonValue('erp_customer_no_', JObject, Jvalue) then begin
    //                     if Cust.get(Jvalue.AsCode()) then begin
    //                         UpdateCustomerProperties(HSIntLog, Cust);
    //                         if Cust."HS Customer ID" = '' then
    //                             Cust."HS Customer ID" := Format(HSIntLog.objectId);
    //                         Cust.Modify(true);
    //                     end;
    //                 end else begin
    //                     if GetJsonValue('name', JObject, Jvalue) then
    //                         Error('Customer %1 not yet in ERP.', Jvalue.AsText());
    //                 end;
    //             end;
    //         end;
    //     end else
    //         Error('Source %1 is not a part of Integration.', HSIntLog.changeSource);
    // end;

    // local procedure UpdateCustomerProperties(var HSIntLog: Record "HubSpot Int. Log"; var Cust: Record Customer)
    // var
    //     BigInteger: BigInteger;
    // begin
    //     case HSIntLog.propertyName of
    //         'name':
    //             Cust.Validate(Name, HSIntLog.propertyValue);
    //         'address':
    //             Cust.Validate(Address, HSIntLog.propertyValue);
    //         'address2':
    //             Cust.Validate("Address 2", HSIntLog.propertyValue);
    //         'zip':
    //             Cust.Validate("Post Code", HSIntLog.propertyValue);
    //         'city':
    //             Cust.Validate(City, HSIntLog.propertyValue);
    //         'state':
    //             Cust.Validate("State Code", GetStateCode(HSIntLog.propertyValue));
    //         'country':
    //             Cust.Validate("Country/Region Code", GetCountryCode(HSIntLog.propertyValue));
    //         'currency_code':
    //             if HSIntLog.propertyValue = 'INR' then
    //                 Cust.Validate("Currency Code", '')
    //             else
    //                 Cust.Validate("Currency Code", HSIntLog.propertyValue);
    //         'p_a_n__no_':
    //             begin
    //                 if Cust."P.A.N. No." <> HSIntLog.propertyValue then
    //                     Cust.Validate("P.A.N. No.", HSIntLog.propertyValue);
    //             end;
    //         'gst_registration_no_':
    //             begin
    //                 if Cust."P.A.N. No." <> CopyStr(HSIntLog.propertyValue, 3, 10) then
    //                     Cust.Validate("P.A.N. No.", CopyStr(HSIntLog.propertyValue, 3, 10));
    //                 Cust.Validate("GST Registration No.", HSIntLog.propertyValue);
    //             end;
    //         'kam_owner':
    //             begin
    //                 Evaluate(BigInteger, HSIntLog.propertyValue);
    //                 Cust.Validate("KAM Code", GetKam(BigInteger));
    //             end;
    //         'zone_of_the_hospital':
    //             UpdateDimensionOnCustomer('REGION', HSIntLog.propertyValue, Cust."No.");
    //         'customer_types':
    //             UpdatePostingGroupOnCustomer(Cust, HSIntLog.propertyValue);
    //         else
    //             Error('Yet to add this property in customer update process.');
    //     end;
    //     HSIntLog.Message := StrSubstNo('%1 changed to %2 on Customer %3', HSIntLog.propertyName, HSIntLog.propertyValue, Cust."No.");
    // end;

    // local procedure GetStateCode(StateText: Text): Code[10]
    // var
    //     State: Record State;
    // begin
    //     State.Reset();
    //     if State.Get(CopyStr(StateText, 1, MaxStrLen(State.Code))) then
    //         exit(State.Code);

    //     State.SetFilter(Description, StateText);
    //     if State.FindFirst() then
    //         exit(State.Code);

    //     Error('State not valid %1', StateText);
    // end;

    // local procedure GetCountryCode(StateText: Text): Code[10]
    // var
    //     Country: Record "Country/Region";
    // begin
    //     Country.Reset();
    //     if Country.Get(CopyStr(StateText, 1, MaxStrLen(Country.Code))) then
    //         exit(Country.Code);

    //     Country.SetFilter(Name, StateText);
    //     if Country.FindFirst() then
    //         exit(Country.Code);

    //     Error('Country not valid %1', StateText);
    // end;

    // local procedure UpdatePostingGroupOnCustomer(var Cust: Record customer; CustGroupValue: Text)
    // var
    //     CustomerType: Text;
    // begin
    //     CustomerType := UpperCase(CustGroupValue);
    //     Case CustomerType of
    //         'DOMESTIC':
    //             begin
    //                 Cust."Gen. Bus. Posting Group" := CustomerType;
    //                 Cust."Customer Posting Group" := CustomerType;
    //             end;
    //         'FOREIGN':
    //             begin
    //                 Cust."Gen. Bus. Posting Group" := CustomerType;
    //                 Cust."Customer Posting Group" := CustomerType;
    //             end;
    //         'B2C':
    //             begin
    //                 Cust."Gen. Bus. Posting Group" := 'DOMESTIC';
    //                 Cust."Customer Posting Group" := CustomerType;
    //             end;
    //         'DISTRIBUTOR':
    //             begin
    //                 Cust."Gen. Bus. Posting Group" := 'DOMESTIC';
    //                 Cust."Customer Posting Group" := CustomerType;
    //             end;
    //         else
    //             Error('Customer Type should not be: %1', CustomerType);
    //     end;
    // end;

    // local procedure UpdateDimensionOnCustomer(DimCode: Code[20]; DimValue: Code[20]; CustNo: code[20])
    // var
    //     DefDim: Record "Default Dimension";
    // begin
    //     DefDim.Reset();
    //     if DefDim.Get(Database::Customer, CustNo, DimCode) then begin
    //         if Defdim."Dimension Value Code" <> DimValue then begin
    //             DefDim.Validate("Dimension Value Code", DimValue);
    //             DefDim.Modify(true);
    //         end;
    //     end else begin
    //         DefDim.Init();
    //         DefDim.Validate("Table ID", Database::Customer);
    //         DefDim.Validate("No.", CustNo);
    //         DefDim.Validate("Dimension Code", DimCode);
    //         DefDim.Validate("Dimension Value Code", DimValue);
    //         DefDim.Validate("Parent Type", DefDim."Parent Type"::Customer);
    //         DefDim.Insert(true);
    //     end;
    // end;

    local procedure UpdateContact(var HSIntLog: Record "HubSpot Int. Log")
    var
        Cont: Record Contact;
    begin
        if HSIntLog.changeSource in ['CRM_UI', 'DEALS', 'MOBILE_ANDROID', 'MOBILE_IOS', 'AUTOMATION_PLATFORM'] then begin
            Cont.Reset();
            Cont.SetFilter("HS Contact ID", '%1', Format(HSIntLog.objectId));
            if Cont.FindSet() then
                if Cont.Count() = 1 then begin
                    if Cont.FindFirst() then begin
                        UpdateContactProperties(HSIntLog, Cont);
                        Cont.Modify(true);
                    end;
                end else
                    Error('Customer not found or more than 1, cust count - %1', Cont.Count);
            if not Cont.FindSet() then begin
                Error('Contact Not yet in ERP.');
            end;
        end else
            Error('Source %1 is not a part of Integration.', HSIntLog.changeSource);
    end;

    local procedure UpdateContactProperties(var HSIntLog: Record "HubSpot Int. Log"; var Cont: Record Contact)
    begin
        case HSIntLog.propertyName of
            'firstname':
                Cont.Validate("First Name", HSIntLog.propertyValue);
            'middle_name':
                Cont.Validate("Middle Name", HSIntLog.propertyValue);
            'lastname':
                Cont.Validate(Surname, HSIntLog.propertyValue);
            'city':
                Cont.Validate(City, HSIntLog.propertyValue);
            'salutation':
                Cont.Validate("Salutation Code", HSIntLog.propertyValue);
            'jobtitle':
                Cont.Validate("Job Title", HSIntLog.propertyValue);
            'address':
                Cont.Validate(Address, HSIntLog.propertyValue);
            'address_2':
                Cont.Validate("Address 2", HSIntLog.propertyValue);
            'zip':
                Cont.Validate("Post Code", HSIntLog.propertyValue);
            'email':
                Cont.Validate("E-Mail", HSIntLog.propertyValue);
            'phone':
                Cont.Validate("Phone No.", HSIntLog.propertyValue);
            else
                Error('Yet to add %1 property in Contact update process.', HSIntLog.propertyName);
        end;
        HSIntLog.Message := StrSubstNo('%1 changed to %2 on Contact %3', HSIntLog.propertyName, HSIntLog.propertyValue, Cont."No.");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Dozee Devices", OnAfterActionEvent, "Attach License to Device", false, false)]
    local procedure UpdateLicenseInfoOnDevice(var Rec: Record "Dozee Device")
    begin
        HSAPIMgmt.UpdateDeviceInfo(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Dozee devices", OnAfterActionEvent, "Detach License from Device", false, false)]
    local procedure UpdateExpireOrTerminateInfoOnDevice(var Rec: Record "Dozee Device")
    begin
        HSAPIMgmt.UpdateDeviceInfo(Rec);
    end;

    [EventSubscriber(ObjectType::Report, Report::"License Expiry BatchJob", OnAfterReassignLicenseofDevice, '', false, false)]
    local procedure UpdateDeviceInfoOnLicBatchJob(var DozeeDevice: Record "Dozee Device")
    begin
        HSAPIMgmt.UpdateDeviceInfo(DozeeDevice);
    end;

    local procedure ProcessReturn(var HsIntLog: Record "HubSpot Int. Log"; cust: Record Customer; Rental: Boolean)
    var
        Response: Text;
        HSConnt: Codeunit "HubSpot Connect";
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        JValue: JsonValue;
        DeviceBuffer: Record "Device Buffer";
        TransHeader: Record "Transfer Header";
        TransHeader2: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        LineNo: Integer;
        Quantity: Decimal;
        ItemNo: Text;
        Variant: Text;
        TOrdNoWarehouse: Code[20];
        TOrdNoEmp: Code[20];
    begin
        HSSetup.Get();

        Response := HSConnt.GetObjectInfo('ticket', Format(HsIntLog.objectId) + '/associations/device?limit=500');

        if Response = '' then
            Error('Nothing to return.');
        JToken.ReadFrom(Response);
        JObject := JToken.AsObject();
        if JObject.Get('results', JToken) then
            JArray := JToken.AsArray();

        if JArray.Count = 0 then
            Error('Return Request should have atleast 1 item in it.');

        foreach Jtoken in Jarray do begin
            Jobject := JToken.AsObject();
            if GetJsonValue('id', JObject, JValue) then
                PrepareDeviceBuffer(JValue.AsText(), DeviceBuffer);
        end;

        if DeviceBuffer.Count() = 0 then
            exit;
        LineNo := 0;

        DeviceBuffer.SetRange("To Location", '');
        if DeviceBuffer.FindSet() then begin
            Error('To Location must have values on device');
        end;

        DeviceBuffer.SetCurrentKey("Item No.", "Variant Code");
        DeviceBuffer.SetFilter("To Location", '%1', 'Warehouse');
        DeviceBuffer.SetAscending("Item No.", true);
        if DeviceBuffer.FindSet() then begin
            HSSetup.TestField("Demo Location");
            HSSetup.TestField("Rental Location");
            HSSetup.TestField("Default Warehouse");
            if not Rental then
                TOrdNoWarehouse := InsertTransferHeader(HSSetup."Demo Location", HSSetup."Default Warehouse", cust."No.", '', HsIntLog.objectId)
            else
                TOrdNoWarehouse := InsertTransferHeader(HSSetup."Rental Location", HSSetup."Default Warehouse", cust."No.", '', HsIntLog.objectId);
            repeat
                InsertTransferReturnLines(DeviceBuffer, TOrdNoWarehouse, LineNo, ItemNo, Variant);
            until DeviceBuffer.Next() = 0;
        end;
        DeviceBuffer.SetFilter("To Location", '%1', 'Self');
        if DeviceBuffer.FindSet() then begin
            HSSetup.TestField("Demo Location");
            HSSetup.TestField("Rental Location");
            HSSetup.TestField("Employee Location");
            if not Rental then
                TOrdNoEmp := InsertTransferHeader(HSSetup."Demo Location", HSSetup."Employee Location", cust."No.", '', HsIntLog.objectId)
            else
                TOrdNoEmp := InsertTransferHeader(HSSetup."Rental Location", HSSetup."Employee Location", cust."No.", '', HsIntLog.objectId);
            repeat
                InsertTransferReturnLines(DeviceBuffer, TOrdNoEmp, LineNo, ItemNo, Variant);
            until DeviceBuffer.Next() = 0;
        end;
        HsIntLog.Message := StrSubstNo('T.Order: %1, %2', TOrdNoWarehouse, TOrdNoEmp);
    end;

    local procedure PrepareDeviceBuffer(DeviceID: Text; var DeviceBuffer: Record "Device Buffer")
    var
        Response: Text;
        HSConnect: Codeunit "HubSpot Connect";
        Properties: Text;

        JToken: JsonToken;
        JObject: JsonObject;
        JValue: JsonValue;
    begin
        Properties := DeviceID + '?properties=customer_no_&properties=lot_no_&properties=serial_no_&properties=item_no_&properties=variant&properties=quantity&properties=return_request&properties=return_device_to_self_warehouse_&properties=returned&archived=false';
        Response := HSConnect.GetObjectInfo('device', Properties);
        if Response = '' then
            exit;

        Jtoken.ReadFrom(Response);
        JObject := Jtoken.AsObject();
        if JObject.Get('properties', Jtoken) then
            JObject := Jtoken.AsObject();

        if GetJsonValue('returned', JObject, JValue) then begin
            if (JValue.AsText() in ['yes', 'true']) then
                exit; //exit when device is alredy returned
        end;

        if GetJsonValue('return_request', JObject, JValue) then begin
            if not (JValue.AsText() in ['yes', 'true']) then
                exit; //exit when return_request is not true
        end else
            exit; //exit when return_request is null

        DeviceBuffer.Init();
        DeviceBuffer."Entry No." := DeviceBuffer.GetLastEntryNo() + 1;
        if GetJsonValue('customer_no_', JObject, JValue) then
            DeviceBuffer."Customer No." := JValue.AsText();
        if GetJsonValue('item_no_', JObject, JValue) then
            DeviceBuffer."Item No." := JValue.AsText();
        if GetJsonValue('variant', JObject, JValue) then
            DeviceBuffer."Variant Code" := JValue.AsText();
        if GetJsonValue('lot_no_', JObject, JValue) then
            DeviceBuffer."Lot No." := JValue.AsText();
        if GetJsonValue('serial_no_', JObject, JValue) then
            DeviceBuffer."Serial No." := JValue.AsText();
        if GetJsonValue('quantity', JObject, JValue) then
            DeviceBuffer.Quantity := JValue.AsDecimal();
        if GetJsonValue('return_device_to_self_warehouse_', JObject, JValue) then
            DeviceBuffer."To Location" := JValue.AsText();
        DeviceBuffer.Insert();
    end;

    local procedure InsertTransferHeader(var FromLocation: Code[20]; ToLocation: Code[20]; CustNo: Code[20]; EmpNo: Code[20]; HSID: BigInteger): Code[20]
    var
        TransHeader: Record "Transfer Header";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        TransHeader.Init();
        TransHeader.Validate("Transfer-from Code", FromLocation);
        TransHeader.Validate("Transfer-to Code", ToLocation);
        TransHeader.Validate("In-Transit Code", 'IN TRANSIT');
        TransHeader.Validate("Customer No.", CustNo);
        TransHeader.HS_ID := HSID;
        TransHeader.Insert(true);
        TransHeader.Validate(Status, TransHeader.Status::Released);
        TransHeader.Validate(Status1, TransHeader.Status1::Released);
        WhseTransferRelease.Release(TransHeader);
        TransHeader.Modify(true);
        exit(TransHeader."No.")
    end;

    local procedure UpdateShipToAddrsOnTransferOrder(TranOrdNumber: Code[20]; ShipToAddress: array[8] of Text);
    var
        TransHeader: Record "Transfer Header";
    begin
        TransHeader.Get(TranOrdNumber);
        TransHeader."Transfer-to Address" := ShipToAddress[0];
        TransHeader."Transfer-to Address 2" := ShipToAddress[1];
        TransHeader."Transfer-to City" := ShipToAddress[2] + ShipToAddress[4];
        TransHeader."Transfer-to Post Code" := ShipToAddress[5];
        TransHeader."Trsf.-to Country/Region Code" := ShipToAddress[3];
        TransHeader.Modify(true);
    end;

    local procedure InsertFATransferHeader(FromLocation: Code[20];
        ToLocation: Code[20]; CustNo: Code[20]; EmpNo: Code[20]; HSID: BigInteger): Code[20]
    var
        FATransHeader: Record "FA Transfer Header";
        location: Record Location;
    begin
        FATransHeader.Init();
        FATransHeader.Validate("Transfer-from Code", FromLocation);
        FATransHeader.Validate("Transfer-to Code", ToLocation);
        FATransHeader.Validate("In-Transit Code", 'IN TRANSIT');
        location.Get(FromLocation);
        if location."Demo Location" then
            FATransHeader.Validate("Transfer-from Customer", CustNo)
        else
            FATransHeader.Validate("Transfer-to Customer", CustNo);
        FATransHeader.HS_ID := HSID;
        FATransHeader.Status := FATransHeader.Status::Released;
        FATransHeader.Insert(true);
        exit(FATransHeader."No.")
    end;

    local procedure InsertTransferReturnLines(DeviceBuffer: Record "Device Buffer"; TransHeaderNo: Code[20];
        var LineNo: Integer; var ItemNo: Text; var Variant: Text)
    var
        TransLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        if (ItemNo = DeviceBuffer."Item No.") and (Variant = DeviceBuffer."Variant Code") then begin
            TransLine.Get(TransHeaderNo, LineNo);
            TransLine.SuspendStatusCheck(true);
            Quantity := TransLine.Quantity + DeviceBuffer.Quantity;
            TransLine.Validate(Quantity, Quantity);
            TransLine.Modify(true);
            AddItemTrackingtoTransferLine(TransLine, Enum::"Transfer Direction"::Outbound, DeviceBuffer."Serial No.", DeviceBuffer."Lot No.", DeviceBuffer.Quantity);
        end else begin
            TransLine.Init();
            TransLine."Document No." := TransHeaderNo;
            TransLine."Line No." := LineNo + 10000;
            TransLine.SuspendStatusCheck(true);
            TransLine.Validate("Item No.", DeviceBuffer."Item No.");
            if DeviceBuffer."Variant Code" <> '' then
                TransLine.Validate("Variant Code", DeviceBuffer."Variant Code");
            TransLine.Validate(Quantity, DeviceBuffer.Quantity);
            TransLine.Insert(true);
            AddItemTrackingtoTransferLine(TransLine, Enum::"Transfer Direction"::Outbound, DeviceBuffer."Serial No.", DeviceBuffer."Lot No.", DeviceBuffer.Quantity);
        end;
        ItemNo := DeviceBuffer."Item No.";
        Variant := DeviceBuffer."Variant Code";
        LineNo := TransLine."Line No.";
    end;

    local procedure AddItemTrackingtoTransferLine(TransLine: Record "Transfer Line"; TransDirection: Enum "Transfer Direction";
                                    SerialNo: Code[50]; LotNo: Code[50]; Quantity: Decimal)
    var
        TrackingSpecification: Record "Tracking Specification";
        AvalabilityDate: Date;
        ItemTrackingLineMgt: Codeunit "Item Tracking Lines Mgt";
        TransLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        TransLineReserve.InitFromTransLine(TrackingSpecification, TransLine, AvalabilityDate, TransDirection);
        // TrackingSpecification.InitFromTransLine(TransLine, AvalabilityDate, TransDirection);
        ItemTrackingLineMgt.SetSourceSpec(TrackingSpecification, AvalabilityDate);
        ItemTrackingLineMgt.SetInbound(TransLine.IsInbound());
        ItemTrackingLineMgt.SetBlockCommit(false);
        ItemTrackingLineMgt.InsertItemTracking(SerialNo, LotNo, Quantity);
    end;
}