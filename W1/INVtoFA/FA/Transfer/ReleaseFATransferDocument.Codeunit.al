namespace TSTChanges.FA.Transfer;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using TSTChanges.Automation;

codeunit 51223 "Release FA Transfer Document"
{
    Permissions = tabledata "FA Transfer Header" = rm,
                  tabledata "FA Transfer Line" = r;
    TableNo = "FA Transfer Header";
    trigger OnRun()
    begin
        FATransferHeader.Copy(Rec);
        Code();
        Rec := FATransferHeader;
    end;

    var
        FATransferHeader: Record "FA Transfer Header";
        InvtSetup: Record "Inventory Setup";
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;
        Text001: Label 'The transfer order %1 cannot be released because %2 and %3 are the same.';
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';
        NothingToReleaseErr: Label 'There is nothing to release for transfer order %1.';

    local procedure Code(): Boolean
    var
        Location: Record Location;
        FATransLine: Record "FA Transfer Line";
    begin
        if FATransferHeader.Status = FATransferHeader.Status::Released then
            exit;

        if not (PreviewMode or SkipCheckReleaseRestrictions) then
            FATransferHeader.CheckFATransferReleaseRestrictions;

        FATransferHeader.TestField("Transfer-from Code");
        if Location.Get(FATransferHeader."Transfer-from Code") then
            if Location."Demo Location" then
                FATransferHeader.TestField("Transfer-from Customer");
        FATransferHeader.TestField("Transfer-to Code");
        if Location.Get(FATransferHeader."Transfer-to Code") then
            if Location."Demo Location" then
                FATransferHeader.TestField("Transfer-to Customer");

        if FATransferHeader."Transfer-from Code" = FATransferHeader."Transfer-to Code" then
            Error(Text001, FATransferHeader."No.", FATransferHeader.FieldCaption("Transfer-from Code"), FATransferHeader.FieldCaption("Transfer-to Code"));
        InvtSetup.Get();
        if not FATransferHeader."Direct Transfer" then
            FATransferHeader.TestField("In-Transit Code")
        else
            if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Receipt and Shipment" then begin
                FATransferHeader.VerifyNoOutboundWhseHandlingOnLocation(FATransferHeader."Transfer-from Code");
                FATransferHeader.VerifyNoInboundWhseHandlingOnLocation(FATransferHeader."Transfer-to Code");
            end;

        CheckFATransLines(FATransLine, FATransferHeader);

        FATransferHeader.Validate(Status, FATransferHeader.Status::Released);
        FATransferHeader.Modify();

        // if not (
        //     FATransferHeader."Direct Transfer" and
        //     (InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer"))
        // then
        // WhseTransferRelease.SetCallFromTransferOrder(true);

        // WhseTransferRelease.Release(FATransferHeader);

        OnAfterReleaseFATransferDoc(FATransferHeader);
    end;

    procedure PerformManualCheckAndRelease(var FATransferHeader: Record "FA Transfer Header")
    begin
        CheckFATransferPendingApproval(FATransferHeader);

        Codeunit.Run(Codeunit::"Release FA Transfer Document", FATransferHeader);
    end;

    local procedure CheckFATransferPendingApproval(var FATransferHeader: Record "FA Transfer Header")
    var
        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
    begin
        if ApprovalsMgmt.IsFATransferHeaderPendingApproval(FATransferHeader) then
            Error(Text002);
    end;

    procedure Reopen(var FATransferHeader: Record "FA Transfer Header")
    begin
        if FATransferHeader.Status = FATransferHeader.Status::Open then
            exit;

        // WhseTransferRelease.Reopen(FATransferHeader);
        FATransferHeader.Validate(Status, FATransferHeader.Status::Open);
        FATransferHeader.Modify();
    end;

    procedure PerformManualReopen(var FATransferHeader: Record "FA Transfer Header")
    begin
        CheckReopenStatus(FATransferHeader);

        // OnBeforeManualReOpenLicenseDoc(ConversionHeader, PreviewMode);
        Reopen(FATransferHeader);
        // OnAfterManualReOpenLicenseDoc(ConversionHeader, PreviewMode);
    end;

    local procedure CheckReopenStatus(FATransferHeader: Record "FA Transfer Header")
    begin
        if FATransferHeader.Status = FATransferHeader.Status::"Pending Approval" then
            Error(Text003);
    end;


    local procedure CheckFATransLines(var FATransLine: Record "FA Transfer Line"; FATransHeader: Record "FA Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckTransLines(TransLine, IsHandled, TransHeader);
        if IsHandled then
            exit;

        FATransLine.SetRange("Document No.", FATransHeader."No.");
        FATransLine.SetFilter(Quantity, '<>0');
        if FATransLine.IsEmpty() then
            Error(NothingToReleaseErr, FATransHeader."No.");
    end;

    procedure ReleaseFATransferHeader(var FATransHdr: Record "FA Transfer Header"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        FATransferHeader.Copy(FATransHdr);
        LinesWereModified := Code();
        FATransHdr := FATransferHeader;
    end;

    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseFATransferDoc(var FATransferHeader: Record "FA Transfer Header")
    begin
    end;
}