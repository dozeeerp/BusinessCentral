namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Setup;
using TSTChanges.Automation;

codeunit 51205 "Release Conversion Document"
{
    Permissions = TableData "FA Conversion Header" = rm,
                  TableData "FA Conversion Line" = r;
    TableNo = "FA Conversion Header";

    trigger OnRun()
    begin
        ConversionHeader.Copy(Rec);
        Code();
        Rec := ConversionHeader;
    end;

    var
        ConversionHeader: Record "FA Conversion Header";
        WhseConversionRelease: Codeunit "Whse.-Conversion Release";
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;
        Text001: Label 'There is nothing to release for %1.', Comment = '%1 = No.';
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';

    Local procedure Code()
    var
        ConversionLine: Record "FA Conversion Line";
        InvtSetup: Record "Inventory Setup";
    begin
        if ConversionHeader.Status = ConversionHeader.Status::Released then
            exit;

        if not (PreviewMode or SkipCheckReleaseRestrictions) then
            ConversionHeader.CheckConversionReleaseRestrictions;

        ConversionLine.SetRange("Document No.", ConversionHeader."No.");
        ConversionLine.SetFilter(Type, '<>%1', ConversionLine.Type::" ");
        ConversionLine.SetFilter(Quantity, '<>0');
        if not ConversionLine.Find('-') then
            Error(Text001, ConversionHeader."No.");

        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then begin
            ConversionLine.SetRange(Type, ConversionLine.Type::Item);
            if ConversionLine.FindSet() then
                repeat
                    if ConversionLine.IsInventoriableItem() then
                        ConversionLine.TestField("Location Code");
                until ConversionLine.Next() = 0;
        end;

        ConversionHeader.Status := ConversionHeader.Status::Released;
        ConversionHeader.Modify();

        WhseConversionRelease.Release(ConversionHeader);
        OnAfterReleaseConversionDoc(ConversionHeader, PreviewMode);
    end;

    procedure PerformManualCheckAndRelease(var ConversionHeader: Record "FA Conversion Header")
    begin
        CheckConversionPendingApproval(ConversionHeader);

        Codeunit.Run(Codeunit::"Release Conversion Document", ConversionHeader);
    end;

    local procedure CheckConversionPendingApproval(var ConversionHeader: Record "FA Conversion Header")
    var
        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
    begin
        if ApprovalsMgmt.IsConversionHeaderPendingApproval(ConversionHeader) then
            Error(Text002);
    end;

    procedure Reopen(var ConversionHeader: Record "FA Conversion Header")
    var
        WhseConversionRelease: Codeunit "Whse.-Conversion Release";
    begin
        if ConversionHeader.Status = ConversionHeader.Status::Open then
            exit;

        // OnBeforeReopenAssemblyDoc(AssemblyHeader);

        ConversionHeader.Status := ConversionHeader.Status::Open;
        ConversionHeader.Modify(true);

        // if "Document Type" = "Document Type"::Order then
        WhseConversionRelease.Reopen(ConversionHeader);

        // OnAfterReopenAssemblyDoc(AssemblyHeader);
    end;

    procedure PerformManualReopen(var ConversionHeader: Record "FA Conversion Header")
    begin
        CheckReopenStatus(ConversionHeader);

        // OnBeforeManualReOpenLicenseDoc(ConversionHeader, PreviewMode);
        Reopen(ConversionHeader);
        // OnAfterManualReOpenLicenseDoc(ConversionHeader, PreviewMode);
    end;

    local procedure CheckReopenStatus(ConversionHeader: Record "FA Conversion Header")
    begin
        if ConversionHeader.Status = ConversionHeader.Status::"Pending Approval" then
            Error(Text003);
    end;

    procedure ReleaseConversionHeader(var FAConHeader: Record "FA Conversion Header"; Preview: Boolean)
    begin
        PreviewMode := Preview;
        ConversionHeader.Copy(FAConHeader);
        Code();
        FAConHeader := ConversionHeader;
    end;

    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseConversionDoc(var ConversionHeader: Record "FA Conversion Header"; PreviewMode: Boolean)
    begin
    end;
}