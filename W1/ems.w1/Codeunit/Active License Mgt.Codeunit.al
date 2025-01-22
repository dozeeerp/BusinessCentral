codeunit 52108 "Active License Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        EMSSetup: Record "EMS Setup";

    local procedure GetEMSSetup()
    begin
        EMSSetup.Get();
        EMSSetup.TestField("License Request Nos.");
        EMSSetup.TestField("License Nos.");
    end;

    procedure CreateActiveLicenseCard(var OriginalLicense_iCod: Code[20]; Action_iOpt: Option "Issue Extension","Issue Renewal","Issue Add On","Convert to Commercial","Issue Notice")
    var
    begin
        case Action_iOpt of
            Action_iOpt::"Issue Extension":
                IssueExtension_lFnc(OriginalLicense_iCod);
            Action_iOpt::"Issue Renewal":
                IssueRenewal_lFnc(OriginalLicense_iCod);
            Action_iOpt::"Issue Add On":
                IssueAddOn_lFnc(OriginalLicense_iCod);
            Action_iOpt::"Convert to Commercial":
                ConvertToCommercial(OriginalLicense_iCod);
            Action_iOpt::"Issue Notice":
                IssueNotice(OriginalLicense_iCod);
        end;
    end;

    local procedure IssueExtension_lFnc(OriginalLicense_iCod: Code[20])
    var
        LicenseRequest: Record "License Request";
        LicensRequestCard: Page "License Request";
        NewLicCod_lCod: Code[20];
    begin
        GetEMSSetup();
        GetOriginalLicense(OriginalLicense_iCod);
        IF NOT (OrignalLicense_gRec."License Type" in [OrignalLicense_gRec."License Type"::Demo]) then exit;
        OrignalLicense_gRec.Testfield(Extended, false);
        LicenseRequest.Reset();
        LicenseRequest.SetRange("Parent Extension Of", OrignalLicense_gRec."License No.");
        IF NOT LicenseRequest.FindFirst() then begin
            IF not Confirm('Do you want to Issue Extension for  Active License: %1?', true, OrignalLicense_gRec."License No.") then exit;
            OrignalLicense_gRec.TestField(Terminated, false);
            OrignalLicense_gRec.TestField(Renewed, false);
            OrignalLicense_gRec.TestField(Extended, false);
            OrignalLicense_gRec.TestField("Converted from Notice", false);
            LicenseRequest.Init();
            LicenseRequest.TransferFields(OrignalLicense_gRec);
            LicenseRequest."No. Series" := EMSSetup."License Request Nos.";
            LicenseRequest."No." := '';
            LicenseRequest."License No." := '';
            LicenseRequest.Insert(true);
            LicenseRequest."Document Type" := OrignalLicense_gRec."Document Type"::Extension;
            LicenseRequest."Parent Extension Of" := OrignalLicense_gRec."License No.";
            LicenseRequest.Status := LicenseRequest.Status::Open;
            LicenseRequest.Validate("License Type", OrignalLicense_gRec."License Type");
            IF OrignalLicense_gRec."Original Extension Of" <> '' then
                LicenseRequest."Original Extension Of" := OrignalLicense_gRec."Original Extension Of"
            else
                LicenseRequest."Original Extension Of" := OrignalLicense_gRec."License No.";
            LicenseRequest."Activation Date" := CALCDATE('1D', OrignalLicense_gRec."Expiry Date");
            LicenseRequest."Expiry Date" := CalcDate(LicenseRequest.Duration, LicenseRequest."Activation Date");
            LicenseRequest."Old Expiry Date" := LicenseRequest."Expiry Date";
            LicenseRequest."Requested Activation Date" := 0D;
            LicenseRequest.Dunning := false;
            LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";
            LicenseRequest.Modify(true);
            NewLicCod_lCod := LicenseRequest."No.";
            OrignalLicense_gRec.Extended := true;
            OrignalLicense_gRec.Modify(true);
            Commit();
            LicenseRequest.Reset();
            LicenseRequest.SetRange("No.", NewLicCod_lCod);
            Clear(LicensRequestCard);
            LicensRequestCard.SetTableView(LicenseRequest);
            LicensRequestCard.RunModal();
        end
        else
            Error('Extension already generated for License No: %1.', OrignalLicense_gRec."License No.");
    end;

    local procedure IssueRenewal_lFnc(OriginalLicense_iCod: Code[20])
    var
        LicenseRequest: Record "License Request";
        LicensRequestCard: Page "License Request";
        NewLicCod_lCod: Code[20];
    begin
        GetOriginalLicense(OriginalLicense_iCod);
        GetEMSSetup();
        GetOriginalLicense(OriginalLicense_iCod);
        IF NOT (OrignalLicense_gRec."License Type" in [OrignalLicense_gRec."License Type"::Commercial]) then exit;
        OrignalLicense_gRec.Testfield(Renewed, false);
        LicenseRequest.Reset();
        LicenseRequest.SetRange("Parent Renewal Of", OrignalLicense_gRec."License No.");
        IF NOT LicenseRequest.FindFirst() then begin
            IF not Confirm('Do you want to Issue Renewal for Active License: %1?', true, OrignalLicense_gRec."License No.") then exit;
            OrignalLicense_gRec.TestField(Terminated, false);
            OrignalLicense_gRec.TestField(Renewed, false);
            OrignalLicense_gRec.TestField(Extended, false);
            OrignalLicense_gRec.TestField("Converted from Notice", false);
            LicenseRequest.Init();
            LicenseRequest.TransferFields(OrignalLicense_gRec);
            LicenseRequest."No. Series" := EMSSetup."License Request Nos.";
            LicenseRequest."No." := '';
            LicenseRequest."License No." := '';
            LicenseRequest.Insert(true);
            LicenseRequest."Document Type" := OrignalLicense_gRec."Document Type"::Renewal;
            LicenseRequest."Parent Renewal Of" := OrignalLicense_gRec."License No.";
            IF OrignalLicense_gRec."Original Renewal Of" <> '' then
                LicenseRequest."Original Renewal Of" := OrignalLicense_gRec."Original Renewal Of"
            else
                LicenseRequest."Original Renewal Of" := OrignalLicense_gRec."License No.";
            LicenseRequest.Validate("License Type", OrignalLicense_gRec."License Type");
            LicenseRequest."Activation Date" := CALCDATE('1D', OrignalLicense_gRec."Expiry Date");
            LicenseRequest."Expiry Date" := CalcDate(LicenseRequest.Duration, LicenseRequest."Activation Date");
            LicenseRequest."Old Expiry Date" := LicenseRequest."Expiry Date";
            LicenseRequest."Requested Activation Date" := 0D;
            LicenseRequest.Status := LicenseRequest.Status::Open;
            LicenseRequest.Dunning := false;
            LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";
            LicenseRequest.Modify(true);
            NewLicCod_lCod := LicenseRequest."No.";
            OrignalLicense_gRec.Renewed := true;
            // If OrignalLicense_gRec.Dunning then begin
            //     OrignalLicense_gRec.Status := OrignalLicense_gRec.Status::Expired;
            //     OrignalLicense_gRec."Expiry Date" := CalcDate('-1D', Today);
            //     OrignalLicense_gRec.Dunning := false;
            //     OrignalLicense_gRec."Dunning Type" := OrignalLicense_gRec."Dunning Type"::" ";
            // end;
            OrignalLicense_gRec.Modify(true);
            Commit();
            LicenseRequest.Reset();
            LicenseRequest.SetRange("No.", NewLicCod_lCod);
            Clear(LicensRequestCard);
            LicensRequestCard.SetTableView(LicenseRequest);
            LicensRequestCard.RunModal();
        end
        else
            Error('Renewal already generated for License No: %1.', OrignalLicense_gRec."License No.");
    end;

    local procedure IssueAddOn_lFnc(OriginalLicense_iCod: Code[20])
    var
        LicenseRequest: Record "License Request";
        LicensRequestCard: Page "License Request";
        NewLicCod_lCod: Code[20];
    begin
        GetOriginalLicense(OriginalLicense_iCod);
        GetEMSSetup();
        GetOriginalLicense(OriginalLicense_iCod);
        IF NOT (OrignalLicense_gRec."License Type" in [OrignalLicense_gRec."License Type"::Commercial]) then exit;
        LicenseRequest.Reset();
        LicenseRequest.SetRange("Parent Add on Of", OrignalLicense_gRec."License No.");
        IF NOT LicenseRequest.FindFirst() then begin
            IF not Confirm('Do you want to Issue Add On for Active License: %1?', true, OrignalLicense_gRec."License No.") then exit;
            OrignalLicense_gRec.TestField(Terminated, false);
            OrignalLicense_gRec.TestField(Renewed, false);
            OrignalLicense_gRec.TestField(Extended, false);
            OrignalLicense_gRec.TestField("Converted from Notice", false);
            LicenseRequest.Init();
            LicenseRequest.TransferFields(OrignalLicense_gRec);
            LicenseRequest."No. Series" := EMSSetup."License Request Nos.";
            LicenseRequest."No." := '';
            LicenseRequest."License No." := '';
            LicenseRequest.Insert(true);
            LicenseRequest."Document Type" := OrignalLicense_gRec."Document Type"::"Add on";
            LicenseRequest.Status := LicenseRequest.Status::Open;
            LicenseRequest."Parent Add on Of" := OrignalLicense_gRec."License No.";
            IF OrignalLicense_gRec."Original Add on Of" <> '' then
                LicenseRequest."Original Add on Of" := OrignalLicense_gRec."Original Add on Of"
            else
                LicenseRequest."Original Add on Of" := OrignalLicense_gRec."License No.";
            LicenseRequest.Validate("License Type", OrignalLicense_gRec."License Type");
            LicenseRequest.validate("Activation Date", WorkDate());
            //LicenseRequest."Expiry Date" := OrignalLicense_gRec."Expiry Date";
            LicenseRequest."Requested Activation Date" := 0D;
            //LicenseRequest.Dunning := false;
            //LicenseRequest."Dunning Type" := LicenseRequest."Dunning Type"::" ";
            LicenseRequest.Modify(true);
            NewLicCod_lCod := LicenseRequest."No.";
            Commit();
            LicenseRequest.Reset();
            LicenseRequest.SetRange("No.", NewLicCod_lCod);
        end;
        Clear(LicensRequestCard);
        LicensRequestCard.SetTableView(LicenseRequest);
        LicensRequestCard.RunModal();
    end;

    local procedure GetOriginalLicense(var OriginalLicense_iCod: Code[20])
    var
    begin
        IF OriginalLicense_iCod = '' then exit;
        Clear(OrignalLicense_gRec);
        OrignalLicense_gRec.get(OriginalLicense_iCod);
        OrignalLicense_gRec.TestField(Status, OrignalLicense_gRec.Status::Active);
    end;

    local procedure ConvertToCommercial(var OriginalLicense_iCod: Code[20])
    begin
        EXIT;
        // GetOriginalLicense(OriginalLicense_iCod);
        // SalesSetupRec.GET;
        // SalesSetupRec.TESTFIELD("License Request No.");
        // GetOriginalLicense(OriginalLicense_iCod);
        // IF NOT (OrignalLicense_gRec."License Type" in [OrignalLicense_gRec."License Type"::Notice]) then
        //     exit;
        // LicenseRequest.Reset();
        // LicenseRequest.SetRange("Parent Renewal Of", OriginalLicense_iCod);
        // IF NOT LicenseRequest.FindFirst() then begin
        //     IF not Confirm('Do you want to create Commercial card for Active License : %1?', true, OrignalLicense_gRec."No.") then
        //         exit;
        //     OrignalLicense_gRec.TestField(Terminated, false);
        //     OrignalLicense_gRec.TestField(Renewed, false);
        //     OrignalLicense_gRec.TestField(Extended, false);
        //     OrignalLicense_gRec.TestField("Converted from Notice", false);
        //     LicenseRequest.Init();
        //     LicenseRequest.TransferFields(OrignalLicense_gRec);
        //     LicenseRequest."No. Series" := SalesSetupRec."License Request No.";
        //     LicenseRequest."No." := '';
        //     LicenseRequest."License No." := '';
        //     LicenseRequest.Insert(true);
        //     LicenseRequest."Document Type" := OrignalLicense_gRec."Document Type"::Renewal;
        //     LicenseRequest.VALidate("Requested Activation Date", OrignalLicense_gRec."Activation Date");
        //     LicenseRequest.validate("Activation Date", OrignalLicense_gRec."Activation Date");
        //     LicenseRequest.Status := LicenseRequest.Status::Open;
        //     LicenseRequest."Parent Renewal Of" := OrignalLicense_gRec."No.";
        //     IF OrignalLicense_gRec."Original Renewal Of" <> '' then
        //         LicenseRequest."Original Renewal Of" := OrignalLicense_gRec."Original Renewal Of"
        //     else
        //         LicenseRequest."Original Renewal Of" := OrignalLicense_gRec."No.";
        //     LicenseRequest.Validate("License Type", LicenseRequest."License Type"::Commercial);
        //     LicenseRequest."Converted from Notice" := true;
        //     LicenseRequest.Modify(true);
        //     OrignalLicense_gRec.Renewed := true;
        //     OrignalLicense_gRec.Modify(true);
        //     NewLicCod_lCod := LicenseRequest."No.";
        //     Commit();
        //     LicenseRequest.Reset();
        //     LicenseRequest.SetRange("No.", NewLicCod_lCod);
        // end;
        // Clear(LicensRequestCard);
        // LicensRequestCard.SetTableView(LicenseRequest);
        // LicensRequestCard.RunModal();
    end;

    local procedure IssueNotice(var OriginalLicense_iCod: Code[20])
    begin
        EXIT;
        // GetOriginalLicense(OriginalLicense_iCod);
        // SalesSetupRec.GET;
        // SalesSetupRec.TESTFIELD("License Request No.");
        // GetOriginalLicense(OriginalLicense_iCod);
        // IF NOT (OrignalLicense_gRec."License Type" in [OrignalLicense_gRec."License Type"::Commercial]) then
        //     exit;
        // IF not Confirm('Do you want to Issue Notice for Active License : %1?', true, OrignalLicense_gRec."No.") then
        //     exit;
        // OrignalLicense_gRec.TestField(Terminated, false);
        // LicenseRequest.Init();
        // LicenseRequest.TransferFields(OrignalLicense_gRec);
        // LicenseRequest."No. Series" := SalesSetupRec."License Request No.";
        // LicenseRequest."No." := '';
        // LicenseRequest."License No." := '';
        // LicenseRequest.Insert(true);
        // LicenseRequest."Document Type" := OrignalLicense_gRec."Document Type"::New;
        // LicenseRequest.Validate("Requested Activation Date", CALCDATE('1D', OrignalLicense_gRec."Expiry Date"));
        // LicenseRequest.Validate("Activation Date", CALCDATE('1D', OrignalLicense_gRec."Expiry Date"));
        // LicenseRequest.Status := LicenseRequest.Status::Open;
        // LicenseRequest.Validate("License Type", LicenseRequest."License Type"::Notice);
        // LicenseRequest.Modify(true);
        // NewLicCod_lCod := LicenseRequest."No.";
        // Commit();
        // LicenseRequest.Reset();
        // LicenseRequest.SetRange("No.", NewLicCod_lCod);
        // Clear(LicensRequestCard);
        // LicensRequestCard.SetTableView(LicenseRequest);
        // LicensRequestCard.RunModal();
    end;

    procedure TerminateLicenseRequest(Var LiceCode: Code[20])
    var
        EnterTermDate_lRpt: Report "Enter Termination Date";
        NewTerminationDate_lDte: Date;
        DeviceLinkedToDevice_lRec: Record "Dozee Device";
        ModLinkedToDevice_lRec: Record "Dozee Device";
    begin
        IF LiceCode = '' then exit;
        GetOriginalLicense(LiceCode);
        OrignalLicense_gRec.TestField("Expiry Date");
        OrignalLicense_gRec.TestField(Terminated, false);
        EnterTermDate_lRpt.RunModal();
        EnterTermDate_lRpt.GetTerminationDate(NewTerminationDate_lDte);
        IF NewTerminationDate_lDte = 0D then Error('Termination Date must have a value.');
        IF NewTerminationDate_lDte > CalcDate('7D', Today) then Error('Termnination Date cannot be greater than %1: Current Date: %2', CalcDate('7D', Today), NewTerminationDate_lDte);
        OrignalLicense_gRec.Terminated := true;
        OrignalLicense_gRec."Terminated Date" := NewTerminationDate_lDte;
        OrignalLicense_gRec."Expiry Date" := NewTerminationDate_lDte;
        OrignalLicense_gRec.Status := OrignalLicense_gRec.Status::Terminated;
        OrignalLicense_gRec.Modify();
        DeviceLinkedToDevice_lRec.Reset();
        DeviceLinkedToDevice_lRec.SetRange("License No.", OrignalLicense_gRec."License No.");
        If DeviceLinkedToDevice_lRec.FindSet() Then begin
            repeat
                ModLinkedToDevice_lRec.GET(DeviceLinkedToDevice_lRec."Entry No.");
                ModLinkedToDevice_lRec.Terminated := TRUE;
                ModLinkedToDevice_lRec."Expiry Date" := OrignalLicense_gRec."Expiry Date";
                ModLinkedToDevice_lRec.Modify();
                InsertArchiveDeviceLedgEntry(ModLinkedToDevice_lRec);
            // EMSAPIMgt_lCdu.ExpireTerminateDeviceLicense(ModLinkedToDevice_lRec, 0);  //Obsolete
            until DeviceLinkedToDevice_lRec.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"License Request", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure LicReq_OnOBeforeDeleteEvent(RunTrigger: Boolean; var Rec: Record "License Request")
    var
        FindParentLicenseReq_lRec: Record "License Request";
        ParentReqNo_lCod: Code[20];
    begin
        case Rec."Document Type" of
            "Document Type"::"Add on":
                begin
                    IF Rec."Parent Add on Of" <> '' then ParentReqNo_lCod := Rec."Parent Add on Of";
                    FindParentLicenseReq_lRec.Reset();
                    FindParentLicenseReq_lRec.SetRange("License No.", ParentReqNo_lCod);
                    IF FindParentLicenseReq_lRec.FindFirst() then begin
                    end;
                end;
            "Document Type"::Extension:
                begin
                    IF Rec."Parent Extension Of" <> '' then ParentReqNo_lCod := Rec."Parent Extension Of";
                    FindParentLicenseReq_lRec.Reset();
                    FindParentLicenseReq_lRec.SetRange("License No.", ParentReqNo_lCod);
                    IF FindParentLicenseReq_lRec.FindFirst() then begin
                        FindParentLicenseReq_lRec.Extended := false;
                        FindParentLicenseReq_lRec.Modify(true);
                    end;
                end;
            "Document Type"::Renewal:
                begin
                    IF Rec."Parent Renewal Of" <> '' then ParentReqNo_lCod := Rec."Parent Renewal Of";
                    FindParentLicenseReq_lRec.Reset();
                    FindParentLicenseReq_lRec.SetRange("License No.", ParentReqNo_lCod);
                    IF FindParentLicenseReq_lRec.FindFirst() then begin
                        IF FindParentLicenseReq_lRec.Renewed then FindParentLicenseReq_lRec.Renewed := false;
                        // IF FindParentLicenseReq_lRec."Converted from Notice" then
                        //     FindParentLicenseReq_lRec."Converted from Notice" := false;
                        FindParentLicenseReq_lRec.Modify(true);
                    end;
                end;
        end;
    end;

    procedure InsertArchiveDeviceLedgEntry(var DeviceLinkedToLic: Record "Dozee Device")
    var
        ArchiveDeviceLedgerEntry_lRec: Record "Archive Device Led. Entry";
    begin
        ArchiveDeviceLedgerEntry_lRec.Init();
        ArchiveDeviceLedgerEntry_lRec.TransferFields(DeviceLinkedToLic);
        ArchiveDeviceLedgerEntry_lRec."Source Entry No." := DeviceLinkedToLic."Entry No.";
        ArchiveDeviceLedgerEntry_lRec."User ID" := UserId;
        ArchiveDeviceLedgerEntry_lRec."Entry No." := 0;
        ArchiveDeviceLedgerEntry_lRec.Insert(true);
    end;

    var
        OrignalLicense_gRec: Record "License Request";
}
