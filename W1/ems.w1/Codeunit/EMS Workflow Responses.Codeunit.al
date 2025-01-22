codeunit 52102 "EMS Workflow Resposnses"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure AddEMSWorkflowEventOnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    var
        EMSWorkflowEvents: Codeunit "EMS Workflow Events";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        Case ResponseFunctionName of
            WorkflowResponseHandling.SetStatusToPendingApprovalCode:
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SetStatusToPendingApprovalCode, EMSWorkflowEvents.RunWorkflowOnSendLicenseDocForApprovalCode);
                end;
            WorkflowResponseHandling.SendApprovalRequestForApprovalCode:
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode, EMSWorkflowEvents.RunWorkflowOnSendLicenseDocForApprovalCode);
                end;
            WorkflowResponseHandling.CancelAllApprovalRequestsCode:
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode, EMSWorkflowEvents.RunWorkflowOnCancelLicenseApprovalRequestCode);
                end;
            WorkflowResponseHandling.OpenDocumentCode:
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.OpenDocumentCode, EMSWorkflowEvents.RunWorkflowOnCancelLicenseApprovalRequestCode);
                end;
        End
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure OnOpenDocument(RecRef: RecordRef; Var Handled: Boolean)
    var
        LicesneRequest: Record "License Request";
        ReleaseLicenseDocument: Codeunit "Release License Document";
    begin
        case RecRef.Number of
            DATABASE::"License Request":
                begin
                    RecRef.SetTable(LicesneRequest);
                    ReleaseLicenseDocument.Reopen(LicesneRequest);
                    Handled := true;
                end;
        End;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', true, true)]
    local procedure SetLicenseStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        LicenseRequest: Record "License Request";
        TransferHeader: Record "Transfer Header";
    begin
        case RecRef.Number of
            DATABASE::"License Request":
                begin
                    RecRef.SetTable(LicenseRequest);
                    LicenseRequest.Validate(Status, LicenseRequest.Status::"Pending Approval");
                    LicenseRequest.Modify(true);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        LicenseRequest: Record "License Request";
        ReleaseLicenseDocument: Codeunit "Release License Document";
    begin
        case RecRef.Number of
            DATABASE::"License Request":
                begin
                    RecRef.SetTable(LicenseRequest);
                    ReleaseLicenseDocument.PerformManualCheckAndRelease(LicenseRequest);
                    Handled := true;
                end;
        end;
    end;
}