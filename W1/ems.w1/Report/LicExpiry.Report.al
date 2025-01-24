report 52103 "License Expiry BatchJob"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;
    dataset
    {
        dataitem("License Request"; "License Request")
        {
            trigger OnPreDataItem()
            begin
                SetFilter(Status, '<>%1', Status::Expired);
                SetFilter("Expiry Date", '%1..%2', CalcDate('<-2M>', Today), Today - 1);
                // SetFilter("Expiry Date", '>%1', CalcDate('<-2M>', Today));

                if GuiAllowed then begin
                    Window.Open('Total Record : #1#########\' + 'Current Record : #2##########\');
                    Window.Update(1, Count);
                end;
            end;

            trigger OnAfterGetRecord()
            var
                LicReq: Record "License Request";
            begin
                if GuiAllowed then begin
                    CurrentRec += 1;
                    Window.Update(2, CurrentRec);
                end;

                if Status in [Status::Open, Status::"Pending Approval", Status::Released] then
                    CurrReport.Skip();

                IF "Expiry Date" = 0D then
                    CurrReport.skip;

                // if Terminated and ("Expiry Date" < Today - 3) then
                //     CurrReport.Skip();

                if "Expiry Date" < Today then begin
                    if (Renewed or Extended) and ("Renewal/Ext Lic No." <> '') then begin
                        LicReq.Reset();
                        LicReq.SetCurrentKey("License No.");
                        LicReq.SetRange("License No.", "Renewal/Ext Lic No.");
                        if LicReq.FindFirst() then begin
                            if LicReq."License Qty." = "License Qty." then
                                licenseMgmt.DeviceLicenseMgmt(true, LicReq, "License Request"."License No.")
                            else
                                licenseMgmt.DeviceLicenseMgmt(false, "License Request", '');
                            Expirelicense(false);
                        end else begin
                            licenseMgmt.DeviceLicenseMgmt(false, "License Request", '');
                            Expirelicense(true);
                        end;
                        CurrReport.Skip();
                    end;
                    if Renewed then begin
                        LicReq.SetRange("Parent Renewal Of", "License No.");
                        LicReq.SetRange(Status, Status::Active);
                        LicReq.SetRange("Document Type", "Document Type"::Renewal);
                        if LicReq.Find('-') then begin
                            if LicReq."License Qty." = "License Request"."License Qty." then
                                DeviceManage(true, LicReq."No.")
                            else
                                DeviceManage(false, '');
                            Expirelicense(false);
                        end else begin
                            DeviceManage(false, '');
                            Expirelicense(true);
                        end;
                        CurrReport.Skip();
                    end;

                    if Extended then begin
                        LicReq.SetRange("Parent Extension Of", "License No.");
                        LicReq.SetRange(Status, Status::Active);
                        LicReq.SetRange("Document Type", "Document Type"::Extension);
                        if LicReq.Find('-') then begin
                            if LicReq."License Qty." = "License Request"."License Qty." then
                                DeviceManage(true, LicReq."No.")
                            else
                                DeviceManage(false, '');
                            Expirelicense(false);
                        end else begin
                            DeviceManage(false, '');
                            Expirelicense(true);
                        end;
                        CurrReport.Skip();
                    end;

                    if Status = Status::Terminated then begin
                        CalcFields("No of devices assigned");
                        if "No of devices assigned" > 0 then begin
                            DeviceManage(false, '');
                        end;
                        if "Expiry Date" = Today - 1 then
                            Expirelicense(true);
                        CurrReport.Skip();
                    end;

                    // For all other licenses.
                    DeviceManage(false, '');
                    if "Expiry Date" <= Today - 1 then
                        Expirelicense(true);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then
                    Window.Close();
            end;
        }
    }
    var
        Window: Dialog;
        CurrentRec: Integer;
        ActiveLicMgt: Codeunit "Active License Mgt.";
        EMSSetup: Record "EMS Setup";
        licenseMgmt: Codeunit "License Mgmt.";

    /// <summary>
    /// This procedure will expire the license. 
    /// </summary>
    /// <param name="SendEmail"></param>
    local procedure Expirelicense(SendEmail: Boolean)
    var
        LicReq2: Record "License Request";
        LicEmailSend: codeunit "License Email Sending";
    begin
        LicReq2.get("License Request"."No.");
        if LicReq2.Terminated then
            LicReq2.Status := LicReq2.Status::Terminated
        else
            LicReq2.Status := LicReq2.Status::Expired;

        LicReq2.Modify();

        if SendEmail then begin
            Clear(LicEmailSend);
            LicEmailSend.SendExpiredEmail_gFnc(LicReq2, false);
        end;
    end;

    /// <summary>
    /// This procedure will manage device license deactivation and or reassignment.
    /// </summary>
    /// <param name="Reassign"></param>
    /// <param name="NewLicNo"></param>
    local procedure DeviceManage(Reassign: Boolean; NewLicNo: Code[20])
    var
        DeviceLinked: Record "Dozee Device";
        ParametersBodyArray: JsonArray;
        EMSAPIMgt: Codeunit "EMS API Mgt";
        LicReq3: Record "License Request";
        BlankGUID: Guid;
    begin
        Clear(ParametersBodyArray);
        EMSSetup.Get();
        if Reassign then begin
            LicReq3.get(NewLicNo);
            if "License Request".Renewed or "License Request".Extended then begin
                DeviceLinked.Reset();
                DeviceLinked.SetRange("License No.", "License Request"."License No.");
                DeviceLinked.SetRange(Licensed, true);
                if DeviceLinked.Findset() then begin
                    repeat
                        IF DeviceLinked."Org ID" = BlankGUID then
                            DeviceLinked."Org ID" := LicReq3."Organization ID";
                        EMSAPIMgt.GetDeviceLicenseId(DeviceLinked);
                        DeviceLinked."License No." := LicReq3."License No.";
                        DeviceLinked."Activation Date" := LicReq3."Activation Date";
                        DeviceLinked."Expiry Date" := LicReq3."Expiry Date";
                        DeviceLinked.Dunning := LicReq3.Dunning;
                        DeviceLinked."Dunning Type" := LicReq3."Dunning Type";
                        DeviceLinked.Modify();
                        ActiveLicMgt.InsertArchiveDeviceLedgEntry(DeviceLinked);
                        EMSAPIMgt.SendDeviceLicenseStatusBody(ParametersBodyArray, DeviceLinked);
                    until DeviceLinked.Next() = 0;
                    if EMSSetup.Enabled then
                        EMSAPIMgt.SendDeviceLicenseStatusReq(ParametersBodyArray);
                    exit;
                end;
            end;
        end;

        DeviceLinked.Reset();
        DeviceLinked.SetRange(Licensed, true);
        DeviceLinked.SetRange("License No.", "License Request"."License No.");
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

        OnAfterReassignLicenseofDevice(DeviceLinked);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReassignLicenseofDevice(var DozeeDevice: Record "Dozee Device")
    begin
    end;
}