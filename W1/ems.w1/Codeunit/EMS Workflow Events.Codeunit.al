codeunit 52101 "EMS Workflow Events"
{
    trigger OnRun()
    begin
    end;

    var
        WorkflowManagement: Codeunit "Workflow Management";
        LicenseDocSendForApprovalEventDescTxt: Label 'Approval of a License document is requested.';
        LicenseDocApprReqCancelledEventDescTxt: Label 'An approval request for a License document is canceled.';
        LicenseDocReleasedEventDescTxt: Label 'A License document is released.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', true, true)]
    procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendLicenseDocForApprovalCode, Database::"License Request", LicenseDocSendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelLicenseApprovalRequestCode, Database::"License Request", LicenseDocApprReqCancelledEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnAfterReleaseLicenseDocCode, DATABASE::"License Request", LicenseDocReleasedEventDescTxt, 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    Local procedure AddWorkflowEventHierarchiesToLibrary(EventFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            RunWorkflowOnCancelLicenseApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(RunWorkflowOnCancelLicenseApprovalRequestCode, RunWorkflowOnSendLicenseDocForApprovalCode);
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendLicenseDocForApprovalCode);
        End
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowTableRelationsToLibrary', '', false, false)]
    procedure AddWorkflowTableRelationsToLibrary()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertTableRelation(Database::"License Request", 1, Database::"Approval Entry", 2);
    end;

    procedure RunWorkflowOnSendLicenseDocForApprovalCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnSendLicenseDocForApproval'));
    end;

    procedure RunWorkflowOnCancelLicenseApprovalRequestCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnCancelLicenseApprovalRequest'));
    end;

    procedure RunWorkflowOnAfterReleaseLicenseDocCode(): Code[128]
    begin
        exit(UpperCase('RunWorkflowOnAfterReleaseLicenseDocument'))
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Licesne Approval Mgmt.", 'OnSendLicenseDocForApproval', '', false, false)]
    local procedure RunWorkflowOnSendLicenseDocForApproval(var LicenseRequest: Record "License Request")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendLicenseDocForApprovalCode, LicenseRequest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Licesne Approval Mgmt.", 'OnCancelLicenseApprovalRequest', '', false, false)]
    procedure RunWorkflowOnCancelLicenseApprovalRequest(var LicenseRequest: Record "License Request")
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelLicenseApprovalRequestCode, LicenseRequest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release License Document", 'OnAfterReleaseLicenseDoc', '', false, false)]
    procedure RunWorkflowOnAfterReleaseLicenseDoc(var LicenseRequest: Record "License Request"; PreviewMode: Boolean)
    begin
        if not PreviewMode then
            WorkflowManagement.HandleEvent(RunWorkflowOnAfterReleaseLicenseDocCode, LicenseRequest);
    end;
}