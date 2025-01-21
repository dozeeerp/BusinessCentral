codeunit 52103 "Release License Document"
{
    TableNo = "License Request";
    Permissions = tabledata "License Request" = rm;

    trigger OnRun()
    begin
        LicenseRequest.Copy(Rec);
        Code;
        rec := LicenseRequest;
    end;

    var
        Text001: Label 'There is nothing to release for the document of type %1 with the number %2.';
        SalesSetup: Record "Sales & Receivables Setup";
        LicenseRequest: Record "License Request";
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;

    local procedure Code() LinesWereModified: Boolean
    begin
        if LicenseRequest.Status = LicenseRequest.Status::Released then
            exit;
        if not (PreviewMode or SkipCheckReleaseRestrictions) then
            LicenseRequest.CheckLicenseReleaseRestrictions;

        LicenseRequest.TestField("Customer No.");

        LicenseRequest.Status := LicenseRequest.Status::Released;
        LicenseRequest.Validate("Release Date", Today);

        LinesWereModified := LinesWereModified;

        LicenseRequest.Modify(true);

        OnAfterReleaseLicenseDoc(LicenseRequest, PreviewMode, LinesWereModified);
    end;

    procedure Reopen(var LicenseRequest: Record "License Request")
    var
        IsHandled: Boolean;
    begin
        if LicenseRequest.Status = LicenseRequest.Status::Open then
            exit;
        LicenseRequest.Status := LicenseRequest.Status::Open;
        Clear(LicenseRequest."Release Date");
        LicenseRequest.Modify(true);
    end;

    procedure PerformManualRelease(var LicenseRequest: Record "License Request")
    var
    begin
        PerformManualCheckAndRelease(LicenseRequest);
    end;

    procedure PerformManualCheckAndRelease(var LicenseRequest: Record "License Request")
    var
        IsHandled: Boolean;
    begin

        LicenseRequest.CheckMandateFields();
        CheckLicensePendingApproval(LicenseRequest);

        CODEUNIT.Run(CODEUNIT::"Release License Document", LicenseRequest);
    end;

    local procedure CheckLicensePendingApproval(var LicenseRequest: Record "License Request")
    var
        ApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
        IsHandled: Boolean;
    begin

        if ApprovalsMgmt.IsLicenseRequestPendingApproval(LicenseRequest) then
            Error(Text002);
    end;

    procedure PerformManualReopen(var LicenseRequest: Record "License Request")
    begin
        CheckReopenStatus(LicenseRequest);

        OnBeforeManualReOpenLicenseDoc(LicenseRequest, PreviewMode);
        Reopen(LicenseRequest);
        OnAfterManualReOpenLicenseDoc(LicenseRequest, PreviewMode);
    end;

    local procedure CheckReopenStatus(LicenseRequest: Record "License Request")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReopenStatus(LicenseRequest, IsHandled);
        if IsHandled then
            exit;

        if LicenseRequest.Status = LicenseRequest.Status::"Pending Approval" then
            Error(Text003);
    end;

    procedure ReleaseSalesHeader(var LicesneReq: Record "License Request"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        LicenseRequest.Copy(LicesneReq);
        //LinesWereModified := Code;
        LicesneReq := LicenseRequest;
    end;

    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReOpenLicenseDoc(var LicenseRequest: Record "License Request"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReOpenLicenseDoc(var LicenseRequest: Record "License Request"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReopenStatus(LicenseRequest: Record "License Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseLicenseDoc(var LicenseRequest: Record "License Request"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
    end;
}