namespace TSTChanges.Automation;

using System.Automation;
using Microsoft.Inventory.Transfer;
using System.Environment.Configuration;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.Conversion;
using Microsoft.Utilities;

codeunit 51239 "TST Workflow Responses"
{
    Permissions = tabledata "FA Conversion Header" = rm,
                    tabledata "Transfer Header" = rm,
                    tabledata "Notification Entry" = rimd,
                    tabledata "Workflow Response" = r;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure AddWorkflowEventOnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    var
        TSTWorkflowEvents: Codeunit "TST Workflow Events";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        Case ResponseFunctionName of
            WorkflowResponseHandling.SetStatusToPendingApprovalCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendTransferDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendConversionDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SetStatusToPendingApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendFATransferDocForApprovalCode());
                end;
            WorkflowResponseHandling.CreateApprovalRequestsCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CreateApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendTransferDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CreateApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendConversionDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CreateApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendFATransferDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CreateApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendFAItemForApprovalCode());
                end;
            WorkflowResponseHandling.SendApprovalRequestForApprovalCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendTransferDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendConversionDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendFATransferDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
                        TSTWorkflowEvents.RunWorkflowOnSendFAItemForApprovalCode());
                end;
            WorkflowResponseHandling.CancelAllApprovalRequestsCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelTransferApprovalRequestCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelConversionApprovalRequestCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelFATransferApprovalRequestCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelFAItemApprovalRequestCode());
                end;
            WorkflowResponseHandling.OpenDocumentCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelTransferApprovalRequestCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelConversionApprovalRequestCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelFATransferApprovalRequestCode());
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode(),
                        TSTWorkflowEvents.RunWorkflowOnCancelFAItemApprovalRequestCode());
                end;
        End;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        ConversionHeader: Record "FA Conversion Header";
        FATransferHeader: Record "FA Transfer Header";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
        ReleaseConversionDocument: Codeunit "Release Conversion Document";
        ReleaseFATransferDocument: Codeunit "Release FA Transfer Document";
    begin
        case RecRef.Number of
            Database::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    ReleaseTransferDocument.Reopen(TransferHeader);
                    TransferHeader.Status1 := TransferHeader.Status1::Open;
                    TransferHeader.Modify();
                    Handled := true;
                end;
            Database::"FA Conversion Header":
                begin
                    RecRef.SetTable(ConversionHeader);
                    ReleaseConversionDocument.Reopen(ConversionHeader);
                    Handled := true;
                end;
            Database::"FA Transfer Header":
                begin
                    RecRef.SetTable(FATransferHeader);
                    ReleaseFATransferDocument.Reopen(FATransferHeader);
                    Handled := true;
                end;
        End;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', true, true)]
    local procedure SetLicenseStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        ConversionHeader: Record "FA Conversion Header";
        FATransferHeader: Record "FA Transfer Header";
    begin
        case RecRef.Number of
            Database::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    TransferHeader.Validate(Status1, TransferHeader.Status1::"Pending Approval");
                    TransferHeader.Modify(true);
                    Variant := TransferHeader;
                    IsHandled := true;
                end;
            Database::"FA Conversion Header":
                begin
                    RecRef.SetTable(ConversionHeader);
                    ConversionHeader.Validate(Status, ConversionHeader.Status::"Pending Approval");
                    ConversionHeader.Modify(true);
                    Variant := ConversionHeader;
                    IsHandled := true;
                end;
            Database::"FA Transfer Header":
                begin
                    RecRef.SetTable(FATransferHeader);
                    FATransferHeader.Validate(Status, FATransferHeader.Status::"Pending Approval");
                    FATransferHeader.Modify(true);
                    Variant := FATransferHeader;
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        ConversionHeader: Record "FA Conversion Header";
        FATransferHeader: Record "FA Transfer Header";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
        ReleaseConversionDocuemnt: Codeunit "Release Conversion Document";
        ReleaseFATransferDocument: Codeunit "Release FA Transfer Document";
    begin
        case RecRef.Number of
            Database::"Transfer Header":
                begin
                    RecRef.SetTable(TransferHeader);
                    ReleaseTransferDocument.Run(TransferHeader);
                    Handled := true;
                end;
            Database::"FA Conversion Header":
                begin
                    RecRef.SetTable(ConversionHeader);
                    ReleaseConversionDocuemnt.PerformManualCheckAndRelease(ConversionHeader);
                    Handled := true;
                end;
            Database::"FA Transfer Header":
                begin
                    RecRef.SetTable(FATransferHeader);
                    ReleaseFATransferDocument.PerformManualCheckAndRelease(FATransferHeader);
                    Handled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", OnConditionalCardPageIDNotFound, '', true, true)]
    local procedure OnConditionalCardPageIDNotFound(RecordRef: RecordRef; var CardPageID: Integer)
    begin
        case RecordRef.Number of
            database::"Transfer Header":
                CardPageID := Page::"Transfer Order";
            Database::"FA Conversion Header":
                CardPageID := Page::"FA Conversion Order";
            Database::"FA Transfer Header":
                CardPageID := Page::"FA Transfer Order";
        end;
    end;
}