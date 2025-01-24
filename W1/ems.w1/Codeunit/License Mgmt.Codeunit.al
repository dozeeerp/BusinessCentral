codeunit 52110 "License Mgmt."
{
    TableNo = "License Request";
    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    var
        ActiveLicMgt: Codeunit "Active License Mgt.";
        EMSSetup: Record "EMS Setup";
        NoSeries: Codeunit "No. Series";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        LiEmailSend_lCdu: Codeunit "License Email Sending";
        OriginalLicense_gRec: Record "License Request";
        ActivateConfirmQst: Label 'Do you want to activat the license';

    local procedure RunWithCheck(var LicenseRequest2: Record "License Request")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        LicenseReq: Record "License Request";
    begin
        if not ConfirmManagement.GetResponseOrDefault(ActivateConfirmQst, true) then
            exit;
        GetEmsSetup();
        if LicenseRequest2."License No." = '' then
            LicenseRequest2."License No." := NoSeries.GetNextNo(EMSSetup."License Nos.");
        LicenseRequest2.ValidateActivationAndExpiryDate();
        LicenseRequest2.CheckMandateFields();
        LicenseRequest2.MandatoryInvoiceNo();

        If LicenseRequest2."Document Type" <> LicenseRequest2."Document Type"::New then begin
            //get parent license
            LicenseReq.Reset();
            LicenseReq.SetCurrentKey("License No.");
            case LicenseRequest2."Document Type" of
                "Document Type"::Renewal:
                    LicenseReq.SetRange("License No.", LicenseRequest2."Parent Renewal Of");
                "Document Type"::Extension:
                    LicenseReq.SetRange("License No.", LicenseRequest2."Parent Extension Of");
                "Document Type"::"Add on":
                    LicenseReq.SetRange("License No.", LicenseRequest2."Parent Add on Of");
            end;
            if LicenseReq.FindFirst() then begin
                LicenseReq."Renewal/Ext Lic No." := LicenseRequest2."License No.";
                LicenseReq.Modify();

                //expire parent license if its in dunning and active
                if LicenseReq.Dunning and LicenseReq.Renewed and (LicenseReq."Renewal/Ext Lic No." <> '') and (LicenseReq.Status = LicenseReq.Status::Active) then
                    ExpireDunningLicenseOnRenewal(LicenseReq, LicenseRequest2);
            end;
        end;

        LicenseRequest2.Validate(Status, LicenseRequest2.Status::Active);
        LicenseRequest2.Modify(true);

        ApprovalsMgmt.PostApprovalEntries(LicenseRequest2.RecordId, LicenseRequest2.RecordId, LicenseRequest2."License No.");
        ApprovalsMgmt.DeleteApprovalEntries(LicenseRequest2.RecordId);

        if EMSSetup."Email Notofication" then begin
            Clear(LiEmailSend_lCdu);
            LiEmailSend_lCdu.SendActivationEmail_gFnc(LicenseRequest2, TRUE);
        end;
        commit;
    end;

    local procedure GetEmsSetup()
    begin
        EMSSetup.Get();
        EMSSetup.TestField("License Nos.");
    end;

    procedure ExpireDunningLicenseOnRenewal(Var XLicReq: Record "License Request"; LicReq: Record "License Request")
    begin
        //Set parent license to expire
        XLicReq.Status := XLicReq.Status::Expired;
        XLicReq."Expiry Date" := Today;

        if LicReq."License Qty." >= XLicReq."License Qty." then begin
            DeviceLicenseMgmt(true, LicReq, XLicReq."License No.");
        end;
        XLicReq.Modify();
    end;

    procedure DeviceLicenseMgmt(Reassign: Boolean; NewLicReq: Record "License Request"; OldLicNo: Code[20])
    var
        DeviceLinked: Record "Dozee Device";
        ParametersBodyArray: JsonArray;
        EMSAPIMgt: Codeunit "EMS API Mgt";
        BlankGUID: Guid;
    begin
        Clear(ParametersBodyArray);
        GetEmsSetup();
        if Reassign then begin
            DeviceLinked.Reset();
            DeviceLinked.SetRange("License No.", OldLicNo);
            DeviceLinked.SetRange(Licensed, true);
            if DeviceLinked.Findset() then begin
                repeat
                    IF DeviceLinked."Org ID" = BlankGUID then
                        DeviceLinked."Org ID" := NewLicReq."Organization ID";
                    EMSAPIMgt.GetDeviceLicenseId(DeviceLinked);
                    DeviceLinked."License No." := NewLicReq."License No.";
                    DeviceLinked."Activation Date" := NewLicReq."Activation Date";
                    DeviceLinked."Expiry Date" := NewLicReq."Expiry Date";
                    DeviceLinked.Dunning := NewLicReq.Dunning;
                    DeviceLinked."Dunning Type" := NewLicReq."Dunning Type";
                    DeviceLinked.Modify();
                    ActiveLicMgt.InsertArchiveDeviceLedgEntry(DeviceLinked);
                    EMSAPIMgt.SendDeviceLicenseStatusBody(ParametersBodyArray, DeviceLinked);
                until DeviceLinked.Next() = 0;
                if EMSSetup.Enabled then
                    EMSAPIMgt.SendDeviceLicenseStatusReq(ParametersBodyArray);
                exit;
            end;
        end;

        DeviceLinked.Reset();
        DeviceLinked.SetRange(Licensed, true);
        DeviceLinked.SetRange("License No.", OldLicNo);
        if DeviceLinked.Findset() then begin
            repeat
                DeviceLinked.Expired := true;
                DeviceLinked.Licensed := false;
                DeviceLinked."License No." := '';
                DeviceLinked.Modify();
                ActiveLicMgt.InsertArchiveDeviceLedgEntry(DeviceLinked);
                if DeviceLinked.Terminated then
                    EMSAPIMgt.ExpireTerminateDeviceLicenseBody(DeviceLinked, ParametersBodyArray, 0)
                else
                    EMSAPIMgt.ExpireTerminateDeviceLicenseBody(DeviceLinked, ParametersBodyArray, 1);
            until DeviceLinked.Next() = 0;
            if EMSSetup.Enabled then
                EMSAPIMgt.ExpireTerminateDeviceLicenseReq(ParametersBodyArray);
        end;
    end;

    // procedure CreateLicenseRequest(var OriginalLicense_iCod: Code[20]; Action_iOpt: Option "Issue Extension","Issue Renewal","Issue Add On","Convert to Commercial")
    // begin
    //     case Action_iOpt of
    //         // Action_iOpt::"Issue Extension":
    //         //     IssueExtension_lFnc(OriginalLicense_iCod);
    //         Action_iOpt::"Issue Renewal":
    //             IssueRenewal_lFnc(OriginalLicense_iCod);
    //         Action_iOpt::"Issue Add On":
    //             IssueAddOn_lFnc(OriginalLicense_iCod);
    //     // Action_iOpt::"Convert to Commercial":
    //     //     ConvertToCommercial(OriginalLicense_iCod);
    //     // Action_iOpt::"Issue Notice":
    //     //     IssueNotice(OriginalLicense_iCod);
    //     end;
    // end;

    // local procedure IssueRenewal_lFnc(OriginalLicense_iCod: Code[20])
    // var
    //     LicenseRequest: Record "License Request";
    //     SalesSetupRec: Record "Sales & Receivables Setup";
    //     LicensRequestCard: Page "License Request";
    //     NewLicCod_lCod: Code[20];
    // begin
    //     SalesSetupRec.GET;
    //     SalesSetupRec.TESTFIELD("License Request No.");
    //     GetOriginalLicense(OriginalLicense_iCod);
    //     IF NOT (OriginalLicense_gRec."License Type" in [OriginalLicense_gRec."License Type"::Commercial, OriginalLicense_gRec."License Type"::MillionICU]) then
    //         exit;

    //     OriginalLicense_gRec.Testfield(Renewed, false);
    //     LicenseRequest.Reset();
    //     LicenseRequest.SetRange("Parent Renewal Of", OriginalLicense_gRec."License No.");
    //     IF NOT LicenseRequest.FindFirst() then begin
    //         IF not Confirm('Do you want to Issue Renewal for Active License: %1?', true, OriginalLicense_gRec."License No.") then
    //             exit;
    //         OriginalLicense_gRec.TestField(Terminated, false);
    //         OriginalLicense_gRec.TestField(Renewed, false);
    //         OriginalLicense_gRec.TestField(Extended, false);
    //         OriginalLicense_gRec.TestField("Converted from Notice", false);

    //         LicenseRequest.Init();
    //         LicenseRequest.TransferFields(OriginalLicense_gRec);
    //         LicenseRequest."No. Series" := SalesSetupRec."License Request No.";
    //         LicenseRequest."No." := '';
    //         LicenseRequest."License No." := '';
    //         LicenseRequest.Insert(true);
    //         LicenseRequest."Document Type" := OriginalLicense_gRec."Document Type"::Renewal;
    //         LicenseRequest."Parent Renewal Of" := OriginalLicense_gRec."License No.";
    //         IF OriginalLicense_gRec."Original Renewal Of" <> '' then
    //             LicenseRequest."Original Renewal Of" := OriginalLicense_gRec."Original Renewal Of"
    //         else
    //             LicenseRequest."Original Renewal Of" := OriginalLicense_gRec."License No.";
    //         LicenseRequest.Validate("License Type", OriginalLicense_gRec."License Type");
    //         // LicenseRequest."Activation Date" := CALCDATE('1D', OriginalLicense_gRec."Expiry Date");
    //         // LicenseRequest."Expiry Date" := CalcDate(LicenseRequest.Duration, LicenseRequest."Activation Date");
    //         LicenseRequest.ValidateActivationAndExpiryDate();
    //         // LicenseRequest."Old Expiry Date" := LicenseRequest."Expiry Date";
    //         LicenseRequest."Requested Activation Date" := 0D;
    //         LicenseRequest.Status := LicenseRequest.Status::Open;
    //         LicenseRequest.Dunning := false;
    //         LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";
    //         LicenseRequest.Modify(true);
    //         NewLicCod_lCod := LicenseRequest."No.";

    //         OriginalLicense_gRec.Renewed := true;
    //         // If OrignalLicense_gRec.Dunning then begin
    //         //     OrignalLicense_gRec.Status := OrignalLicense_gRec.Status::Expired;
    //         //     OrignalLicense_gRec."Expiry Date" := CalcDate('-1D', Today);
    //         //     OrignalLicense_gRec.Dunning := false;
    //         //     OrignalLicense_gRec."Dunning Type" := OrignalLicense_gRec."Dunning Type"::" ";
    //         // end;

    //         OriginalLicense_gRec.Modify(true);
    //         Commit();
    //         LicenseRequest.Reset();
    //         LicenseRequest.SetRange("No.", NewLicCod_lCod);
    //         Clear(LicensRequestCard);
    //         LicensRequestCard.SetTableView(LicenseRequest);
    //         LicensRequestCard.RunModal();
    //     end else
    //         Error('Renewal already generated for License No: %1.', OriginalLicense_gRec."License No.");
    // end;

    // local procedure IssueAddOn_lFnc(OriginalLicense_iCod: Code[20])
    // var
    //     LicenseRequest: Record "License Request";
    //     SalesSetupRec: Record "Sales & Receivables Setup";
    //     LicensRequestCard: Page "License Request";
    //     NewLicCod_lCod: Code[20];
    // begin
    //     GetOriginalLicense(OriginalLicense_iCod);
    //     SalesSetupRec.GET;
    //     SalesSetupRec.TESTFIELD("License Request No.");
    //     GetOriginalLicense(OriginalLicense_iCod);
    //     IF NOT (OriginalLicense_gRec."License Type" in [OriginalLicense_gRec."License Type"::Commercial, OriginalLicense_gRec."License Type"::MillionICU]) then
    //         exit;
    //     LicenseRequest.Reset();
    //     LicenseRequest.SetRange("Parent Add on Of", OriginalLicense_gRec."License No.");
    //     IF NOT LicenseRequest.FindFirst() then begin
    //         IF not Confirm('Do you want to Issue Add On for Active License: %1?', true, OriginalLicense_gRec."License No.") then
    //             exit;
    //         OriginalLicense_gRec.TestField(Terminated, false);
    //         OriginalLicense_gRec.TestField(Renewed, false);
    //         OriginalLicense_gRec.TestField(Extended, false);
    //         OriginalLicense_gRec.TestField("Converted from Notice", false);
    //         LicenseRequest.Init();
    //         LicenseRequest.TransferFields(OriginalLicense_gRec);
    //         LicenseRequest."No. Series" := SalesSetupRec."License Request No.";
    //         LicenseRequest."No." := '';
    //         LicenseRequest."License No." := '';
    //         LicenseRequest.Insert(true);
    //         LicenseRequest."Document Type" := OriginalLicense_gRec."Document Type"::"Add on";
    //         LicenseRequest.Status := LicenseRequest.Status::Open;
    //         LicenseRequest."Parent Add on Of" := OriginalLicense_gRec."License No.";
    //         IF OriginalLicense_gRec."Original Add on Of" <> '' then
    //             LicenseRequest."Original Add on Of" := OriginalLicense_gRec."Original Add on Of"
    //         else
    //             LicenseRequest."Original Add on Of" := OriginalLicense_gRec."License No.";
    //         LicenseRequest.Validate("License Type", OriginalLicense_gRec."License Type");
    //         LicenseRequest.validate("Activation Date", WorkDate());
    //         //LicenseRequest."Expiry Date" := OrignalLicense_gRec."Expiry Date";
    //         LicenseRequest."Requested Activation Date" := 0D;
    //         // LicenseRequest.Dunning := false;
    //         // LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";

    //         LicenseRequest.Modify(true);
    //         NewLicCod_lCod := LicenseRequest."No.";
    //         Commit();
    //         LicenseRequest.Reset();
    //         LicenseRequest.SetRange("No.", NewLicCod_lCod);
    //     end;
    //     Clear(LicensRequestCard);
    //     LicensRequestCard.SetTableView(LicenseRequest);
    //     LicensRequestCard.RunModal();
    // end;

    // local procedure GetOriginalLicense(var OriginalLicense_iCod: Code[20])
    // var
    // begin
    //     IF OriginalLicense_iCod = '' then
    //         exit;
    //     Clear(OriginalLicense_gRec);
    //     OriginalLicense_gRec.get(OriginalLicense_iCod);
    //     OriginalLicense_gRec.TestField(Status, OriginalLicense_gRec.Status::Active);
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"License Email Sending", 'OnBeforeCreateEmailMessage', '', false, false)]
    // local procedure abc(var LicReq_iRec: Record "License Request"; var BCCListNew_iTxt: Text[1024]; var CCListNew_iTxt: Text[1024]; var RecipientsListNew_iTxt: Text[1024])
    // var
    //     KAM: Record KAM;
    // begin
    //     if KAM.Get(LicReq_iRec."KAM Code") then begin
    //         if KAM."E-Mail" <> '' then
    //             CCListNew_iTxt := KAM."E-Mail";

    //         if KAM."E-Mail 2" <> '' then
    //             if CCListNew_iTxt <> '' then
    //                 CCListNew_iTxt := BCCListNew_iTxt + ';' + KAM."E-Mail 2"
    //             else
    //                 CCListNew_iTxt := kam."E-Mail 2";
    //     end;
    // end;

    // [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterValidateEvent, "Org ID", false, false)]
    // local procedure UpdateDeviceNameOnOrgIDChange(var Rec: Record Customer; var xRec: Record Customer)
    // var
    //     Devlist: Record "Device linked to License";
    // begin
    //     if rec."Org ID" <> xRec."Org ID" then
    //         UpdateDeviceList(Rec);
    // end;

    // [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterValidateEvent, Name, false, false)]
    // local procedure UpdateDeviceNameOnNameChange(var Rec: Record Customer; var xRec: Record Customer)
    // var
    //     Devlist: Record "Device linked to License";
    // begin
    //     if Rec.Name <> xRec.Name then
    //         UpdateDeviceList(Rec);
    // end;

    // local procedure UpdateDeviceList(Cust: Record Customer)
    // var
    //     Devlist: Record "Device linked to License";
    // begin
    //     Devlist.Reset();
    //     Devlist.SetRange("Customer No.", Cust."No.");
    //     Devlist.SetRange("Customer Name", Cust.Name);
    //     if Devlist.FindSet() then begin
    //         Devlist.ModifyAll("Customer Name", Cust.Name);
    //         Devlist.ModifyAll("Org ID", Cust."Org ID");
    //     end;
    // end;
}