namespace TSTChanges.Automation;

using System.Automation;
using Microsoft.Inventory.Transfer;
using TSTChanges.FA.Conversion;
using TSTChanges.FA.Transfer;
using Microsoft.Finance.GeneralLedger.Preview;
using TSTChanges.FA.FAItem;

codeunit 51236 "TST Workflow Events"
{
    var
        WorkflowManagement: Codeunit "Workflow Management";
        TransferDocSendForApprovalEventDescTxt: Label 'Approval of a Transfer Order is requested.';
        TransferDocApprReqCancelledEventDescTxt: Label 'An approval request for a Transfer Order is canceled.';
        ConversionDocSendForApprovalEventDescTxt: Label 'Approval of a FA Conversion Order is requested.';
        ConversionDocApprReqCancelledEventDescTxt: Label 'An approval request for a FA Conversion Order is canceled.';
        FATransferDocSendForApprovalEventDescTxt: Label 'Approval of a FA Transfer Order is requested.';
        FATransferDocApprReqCancelledEventDescTxt: Label 'An approval request for a FA Transfer Order is canceled.';
        FAItemSendForApprovalEventDescTxt: Label 'Approval of an FA item is requested.';
        FAItemApprovalRequestCancelEventDescTxt: Label 'An approval request for an FA item is canceled.';
        FAItemChangedTxt: Label 'An FA item record is changed.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendTransferDocForApprovalCode, Database::"Transfer Header", TransferDocSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelTransferApprovalRequestCode, Database::"Transfer Header", TransferDocApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendConversionDocForApprovalCode, Database::"FA Conversion Header", ConversionDocSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelConversionApprovalRequestCode, Database::"FA Conversion Header", ConversionDocApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendFATransferDocForApprovalCode, Database::"FA Transfer Header", FATransferDocSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelFATransferApprovalRequestCode, Database::"FA Transfer Header", FATransferDocApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendFAItemForApprovalCode(), Database::"FA Item", FAItemSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelFAItemApprovalRequestCode(), DATABASE::"FA Item", FAItemApprovalRequestCancelEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnFAItemChangedCode(), Database::"FA Item", FAItemChangedTxt, 0, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    Local procedure AddWorkflowEventHierarchiesToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode():
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                                        RunWorkflowOnSendTransferDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                                        RunWorkflowOnSendConversionDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                                        RunWorkflowOnSendFATransferDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                        RunWorkflowOnSendFAItemForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(),
                        RunWorkflowOnFAItemChangedCode());
                end;

            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode():
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                                        RunWorkflowOnSendTransferDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                                        RunWorkflowOnSendConversionDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                                        RunWorkflowOnSendFATransferDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                        RunWorkflowOnSendFAItemForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(),
                        RunWorkflowOnFAItemChangedCode());
                end;

            WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode():
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                        RunWorkflowOnSendTransferDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                        RunWorkflowOnSendConversionDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                        RunWorkflowOnSendFATransferDocForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                        RunWorkflowOnSendFAItemForApprovalCode());
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(),
                        RunWorkflowOnFAItemChangedCode());
                end;
            RunWorkflowOnCancelTransferApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(RunWorkflowOnCancelTransferApprovalRequestCode(),
                    RunWorkflowOnSendTransferDocForApprovalCode());
            RunWorkflowOnCancelConversionApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(RunWorkflowOnCancelConversionApprovalRequestCode(),
                    RunWorkflowOnSendConversionDocForApprovalCode());
            RunWorkflowOnCancelFATransferApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(RunWorkflowOnCancelFATransferApprovalRequestCode(),
                    RunWorkflowOnSendFATransferDocForApprovalCode());
            RunWorkflowOnCancelFAItemApprovalRequestCode():
                WorkflowEventHandling.AddEventPredecessor(RunWorkflowOnCancelFAItemApprovalRequestCode(),
                    RunWorkflowOnSendFAItemForApprovalCode());
        End
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    procedure AddWorkflowTableRelationsToLibrary()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalEntry: Record "Approval Entry";
    begin
        WorkflowSetup.InsertTableRelation(Database::"Transfer Header", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(Database::"Transfer Header", 1, Database::"Transfer Line", 1);
        WorkflowSetup.InsertTableRelation(Database::"FA Conversion Header", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(Database::"FA Conversion Header", 1, Database::"FA Conversion Line", 1);
        WorkflowSetup.InsertTableRelation(Database::"FA Transfer Header", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
        WorkflowSetup.InsertTableRelation(Database::"FA Transfer Header", 1, Database::"FA Transfer Line", 1);
        WorkflowSetup.InsertTableRelation(DATABASE::"FA Item", 0, DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    procedure RunWorkflowOnSendTransferDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendTransferDocForApproval'));
    end;

    procedure RunWorkflowOnSendConversionDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendConversionDocForApproval'))
    end;

    procedure RunWorkflowOnSendFATransferDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendFATransferDocForApproval'))
    end;

    procedure RunWorkflowOnCancelTransferApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelTransferApprovalRequest'));
    end;

    procedure RunWorkflowOnCancelConversionApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelConversionApprovalRequest'));
    end;

    procedure RunWorkflowOnCancelFATransferApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelFATransferApprovalRequest'));
    end;

    procedure RunWorkflowOnSendFAItemForApprovalCode(): Code[128]
    begin
        exit('RUNWORKFLOWONSENDFAITEMFORAPPROVAL');
    end;

    procedure RunWorkflowOnCancelFAItemApprovalRequestCode(): Code[128]
    begin
        exit('RUNWORKFLOWONCANCELFAITEMAPPROVALREQUEST');
    end;

    procedure RunWorkflowOnFAItemChangedCode(): Code[128]
    begin
        exit('RUNWORKFLOWONFAITEMCHANGEDCODE');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnSendTransferDocForApproval', '', false, false)]
    local procedure RunWorkflowOnSendTransferDocForApproval(var TransferHeader: Record "Transfer Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendTransferDocForApprovalCode(), TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnSendConversionDocForApproval', '', false, false)]
    local procedure runworkflowonsendConversionDocForApproval(var ConversionHeader: Record "FA Conversion Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendConversionDocForApprovalCode(), ConversionHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnSendFATransferDocForApproval', '', false, false)]
    local procedure RunWorkflowOnSendFATransferDocForApproval(var FATransferHeader: Record "FA Transfer Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendFATransferDocForApprovalCode(), FATransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnCancelTransferApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnCancelTransferApprovalRequest(var TransferHeader: Record "Transfer Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelTransferApprovalRequestCode(), TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", OnCancelConversionApprovalRequest, '', false, false)]
    local procedure RunWorkflowOnCancelConversionApprovalRequest(var ConversionHeader: Record "FA Conversion Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelConversionApprovalRequestCode(), ConversionHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnCancelFATransferApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnCancelFATransferApprovalRequest(var FATransferHeader: Record "FA Transfer Header")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelFATransferApprovalRequestCode(), FATransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnSendFAItemForApproval', '', false, false)]
    local procedure RunWorkflowOnSendFAItemForApproval(Item: Record "FA Item")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendFAItemForApprovalCode(), Item);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TST Approvals Mgmt", 'OnCancelFAItemApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnCancelFAItemApprovalRequest(Item: Record "FA Item")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelFAItemApprovalRequestCode(), Item);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Item", 'OnAfterModifyEvent', '', false, false)]
    procedure RunWorkflowOnItemChanged(var Rec: Record "FA Item"; var xRec: Record "FA Item"; RunTrigger: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if Rec.IsTemporary() then
            exit;

        if GenJnlPostPreview.IsActive() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnFAItemChangedCode(), Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Item", 'OnAfterRenameEvent', '', false, false)]
    local procedure RunWorkflowOnItemRenamed(var Rec: Record "FA Item"; var xRec: Record "FA Item"; RunTrigger: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if Rec.IsTemporary() then
            exit;

        if GenJnlPostPreview.IsActive() then
            exit;

        if Format(xRec) <> Format(Rec) then
            WorkflowManagement.HandleEventWithxRec(RunWorkflowOnFAItemChangedCode(), Rec, xRec);
    end;
}