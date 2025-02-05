namespace TSTChanges.Automation;

using System.Automation;
using Microsoft.Inventory.Transfer;
using TSTChanges.FA.Conversion;
using System.Environment.Configuration;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.FAItem;

codeunit 51235 "TST Approvals Mgmt"
{
    Permissions = TableData "Approval Entry" = Rimd,
                  TableData "Approval Comment Line" = rimd,
                  TableData "Posted Approval Entry" = rimd,
                  TableData "Posted Approval Comment Line" = rimd,
                  TableData "Overdue Approval Entry" = rimd,
                  TableData "Notification Entry" = rimd;

    trigger OnRun()
    begin

    end;

    var
        DocStatusChangedMsg: Label '%1 %2 has been automatically approved. The status has been changed to %3.', Comment = 'Order 1001 has been automatically approved. The status has been changed to Released.';
        PendingApprovalMsg: Label 'An approval request has been sent.';
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        NothingToApproveErr: Label 'There is nothing to approve.';
        ConversionPrePostCheckErr: Label 'FA Conversion %1 must be approved and released before you can perform this action,', Comment = '%1 = Docuemnt No.';
        FATransferPrePostCheckErr: Label 'FA Transfer Order %1 must be approved and released before you can perform this action,', Comment = '%1 = Docuemnt No.';
        WorkflowManagement: Codeunit "Workflow Management";
        TSTWorkflowEventHandling: Codeunit "TST Workflow Events";
        ApprovalsMgt: Codeunit "Approvals Mgmt.";

    [IntegrationEvent(false, false)]
    procedure OnSendTransferDocForApproval(Var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelTransferApprovalRequest(Var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendConversionDocForApproval(var ConversionHeader: Record "FA Conversion Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelConversionApprovalRequest(var ConversionHeader: Record "FA Conversion Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendFATransferDocForApproval(Var FATransferHeader: Record "FA Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelFATransferApprovalRequest(Var FATransferHeader: Record "FA Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendFAItemForApproval(var Item: Record "FA Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelFAItemApprovalRequest(var Item: Record "FA Item")
    begin
    end;

    procedure OpenApprovalsTransfer(TransferHeader: Record "Transfer Header")
    begin
        ApprovalsMgt.RunWorkflowEntriesPage(
            TransferHeader.RecordId(), Database::"Transfer Header", Enum::"Approval Document Type"::"Transfer Order", TransferHeader."No.");
    end;

    procedure OpenApprovalsConversion(ConversionHeader: Record "FA Conversion Header")
    begin
        ApprovalsMgt.RunWorkflowEntriesPage(
            ConversionHeader.RecordId(), Database::"FA Conversion Header", Enum::"Approval Document Type"::"FA Conversion Order", ConversionHeader."No.");
    end;

    procedure OpenApprovalsFATransfer(FATransferHeader: Record "FA Transfer Header")
    begin
        ApprovalsMgt.RunWorkflowEntriesPage(
            FATransferHeader.RecordId(), Database::"FA Transfer Header", Enum::"Approval Document Type"::"FA Transfer Order", FATransferHeader."No.");
    end;

    procedure CheckTransferApprovalPossible(Var TransferHeader: Record "Transfer Header"): Boolean
    begin
        if not IsTransferApprovalsWorkflowEnabled(TransferHeader) then
            Error(NoWorkflowEnabledErr);

        if not TransferHeader.TransferLinesExist then
            Error(NothingToApproveErr);

        TransferHeader.CheckBeforeTransferApprove();

        exit(true);
    end;

    procedure CheckConversionApprovalPossible(var ConversionHeader: Record "FA Conversion Header"): Boolean
    begin
        if not IsConversionApprovalWorkflowEnabled(ConversionHeader) then
            Error(NoWorkflowEnabledErr);

        if not ConversionHeader.ConversionLinesExists then
            Error(NothingToApproveErr);

        exit(true);
    end;

    procedure CheckFATransferApprovalPossible(Var FATransferHeader: Record "FA Transfer Header"): Boolean
    begin
        if not IsFATransferApprovalsWorkflowEnabled(FATransferHeader) then
            Error(NoWorkflowEnabledErr);

        if not FATransferHeader.TransferLinesExist then
            Error(NothingToApproveErr);

        // FATransferHeader.CheckBeforeTransferApprove();

        exit(true);
    end;

    procedure PrePostApprovalCheckConversion(var ConversionHeader: Record "FA Conversion Header"): Boolean
    begin
        if IsConversionHeaderPendingApproval(ConversionHeader) then
            Error(ConversionPrePostCheckErr, ConversionHeader."No.");

        exit(true);
    end;

    procedure PrePostApprovalCheckFATransfer(var FATransferHeader: Record "FA Transfer Header"): Boolean
    begin
        if IsFATransferHeaderPendingApproval(FATransferHeader) then
            Error(FATransferPrePostCheckErr, FATransferHeader."No.");

        exit(true);
    end;

    procedure IsTransferApprovalsWorkflowEnabled(Var TransferHeader: Record "Transfer Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(TransferHeader, TSTWorkflowEventHandling.RunWorkflowOnSendTransferDocForApprovalCode))
    end;

    procedure IsConversionApprovalWorkflowEnabled(var ConversionHeader: Record "FA Conversion Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(ConversionHeader, TSTWorkflowEventHandling.RunWorkflowOnSendConversionDocForApprovalCode));
    end;

    procedure IsFATransferApprovalsWorkflowEnabled(var FATransferHeader: Record "FA Transfer Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(FATransferHeader, TSTWorkflowEventHandling.RunWorkflowOnSendFATransferDocForApprovalCode()));
    end;


    procedure IsTransferOrderPendingApproval(Var TransferHeader: Record "Transfer Header"): Boolean
    begin
        if TransferHeader.Status <> TransferHeader.Status::Open then
            exit(false);
        exit(IsTransferApprovalsWorkflowEnabled(TransferHeader));
    end;

    procedure IsConversionHeaderPendingApproval(Var ConversionHeader: Record "FA Conversion Header"): Boolean
    begin
        if ConversionHeader.Status <> ConversionHeader.Status::Open then
            exit(false);

        exit(IsConversionApprovalWorkflowEnabled(ConversionHeader));
    end;

    procedure IsFATransferHeaderPendingApproval(Var FATransferHeader: Record "FA Transfer Header"): Boolean
    begin
        if FATransferHeader.Status <> FATransferHeader.Status::Open then
            exit(false);

        exit(IsFATransferApprovalsWorkflowEnabled(FATransferHeader));
    end;

    procedure CheckFAItemApprovalsWorkflowEnabled(var Item: Record "FA Item"): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Item, TSTWorkflowEventHandling.RunWorkflowOnSendFAItemForApprovalCode()) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::"FA Item", TSTWorkflowEventHandling.RunWorkflowOnFAItemChangedCode()) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', true, true)]
    local procedure OnPopulateApprovalEntryArgument(RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        TransferHeader: Record "Transfer Header";
        ConversionHeader: Record "FA Conversion Header";
        FATransferHeader: Record "FA Transfer Header";
    begin
        case RecRef.Number of
            Database::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    ApprovalEntryArgument."Document No." := TransferHeader."No.";
                    ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::"Transfer Order";
                end;
            Database::"FA Conversion Header":
                begin
                    RecRef.SetTable(ConversionHeader);
                    ApprovalEntryArgument."Document No." := ConversionHeader."No.";
                    ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::"FA Conversion Order";
                end;
            Database::"FA Transfer Header":
                begin
                    RecRef.SetTable(FATransferHeader);
                    ApprovalEntryArgument."Document No." := FATransferHeader."No.";
                    ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::"FA Transfer Order";
                end;
            else
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnBeforeShowCommonApprovalStatus', '', false, false)]
    local procedure OnBeforeShowCommonApprovalStatus(var IsHandle: Boolean; var RecRef: RecordRef)
    var
        TransferHeader: Record "Transfer Header";
        ConversionHeader: Record "FA Conversion Header";
        FATransferHeader: Record "FA Transfer Header";
    begin
        case RecRef.Number of
            Database::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    ShowTransferApprovalStatus(TransferHeader);
                    IsHandle := true;
                end;
            Database::"FA Conversion Header":
                begin
                    RecRef.SetTable(ConversionHeader);
                    ShowConversionApprovalStatus(ConversionHeader);
                    IsHandle := true;
                end;
            Database::"FA Transfer Header":
                begin
                    RecRef.SetTable(FATransferHeader);
                    ShowFATransferApprovalStatus(FATransferHeader);
                    IsHandle := true;
                end;
        end;
    end;

    procedure ShowTransferApprovalStatus(TransferHeader: Record "Transfer Header")
    var
        ApprovalMgt: Codeunit "Approvals Mgmt.";
    begin
        TransferHeader.Find;

        case TransferHeader.Status1 of
            TransferHeader.Status1::Released:
                Message(DocStatusChangedMsg, TransferHeader."No.", TransferHeader.Status);
            TransferHeader.status1::"Pending Approval":
                if ApprovalMgt.HasOpenOrPendingApprovalEntries(TransferHeader.RecordId) then
                    Message(PendingApprovalMsg);
        end;
    end;

    procedure ShowConversionApprovalStatus(ConversionHeader: Record "FA Conversion Header")
    begin
        ConversionHeader.Find();
        case ConversionHeader.Status of
            ConversionHeader.Status::Released:
                Message(DocStatusChangedMsg, ConversionHeader."No.", ConversionHeader.Status);
            ConversionHeader.Status::"Pending Approval":
                if ApprovalsMgt.HasOpenOrPendingApprovalEntries(ConversionHeader.RecordId) then
                    Message(PendingApprovalMsg);
        end;
    end;

    procedure ShowFATransferApprovalStatus(FATransferHeader: Record "FA Transfer Header")
    begin
        FATransferHeader.Find();
        case FATransferHeader.Status of
            FATransferHeader.Status::Released:
                Message(DocStatusChangedMsg, FATransferHeader."No.", FATransferHeader.Status);
            FATransferHeader.Status::"Pending Approval":
                if ApprovalsMgt.HasOpenOrPendingApprovalEntries(FATransferHeader.RecordId) then
                    Message(PendingApprovalMsg);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptHeader', '', false, false)]
    local procedure PostApprovalEntryTransferShipment(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.PostApprovalEntries(TransferHeader.RecordId, TransferShipmentHeader.RecordId, TransferShipmentHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptHeader', '', false, false)]
    Local procedure PostApprovalEntryTransferReceipt(var TransHeader: Record "Transfer Header"; var TransRcptHeader: Record "Transfer Receipt Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.PostApprovalEntries(TransHeader.RecordId, TransRcptHeader.RecordId, TransRcptHeader."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnDeleteOneTransferOrderOnBeforeTransHeaderDelete', '', false, false)]
    local procedure OnDeleteOneTransferOrderOnBeforeTransHeaderDelete(var TransferHeader: Record "Transfer Header"; var HideValidationDialog: Boolean)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // ApprovalsMgmt.DeleteApprovalEntries(TransferHeader.RecordId);
        ApprovalsMgmt.OnDeleteRecordInApprovalRequest(TransferHeader.RecordId);
    end;
}