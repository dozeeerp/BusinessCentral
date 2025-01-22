codeunit 52100 "Licesne Approval Mgmt."
{
    Permissions = TableData "Approval Entry" = imd,
                  TableData "Approval Comment Line" = imd,
                  TableData "Posted Approval Entry" = imd,
                  TableData "Posted Approval Comment Line" = imd,
                  TableData "Overdue Approval Entry" = imd,
                  TableData "Notification Entry" = imd;

    var
        DocStatusChangedMsg: Label '%1 %2 has been automatically approved. The status has been changed to %3.', Comment = 'Order 1001 has been automatically approved. The status has been changed to Released.';
        LicensePrePostCheckErr: Label 'License %1 %2 must be approved and released before you can perform this action.', Comment = '%1=document type, %2=document no., e.g. Sales Order 321 must be approved...';
        EMSWorkflowEventHandling: Codeunit "EMS Workflow Events";
        WorkflowManagement: Codeunit "Workflow Management";
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        NothingToApproveErr: Label 'There is nothing to approve.';
        PendingApprovalMsg: Label 'An approval request has been sent.';

    [IntegrationEvent(false, false)]
    procedure OnSendLicenseDocForApproval(var LicenseRequest: Record "License Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelLicenseApprovalRequest(var LicenseRequest: Record "License Request")
    begin
    end;

    procedure OpenApprovalsLicense(LicenseRequest: Record "License Request")
    var
        ApprovalsMgt: Codeunit "Approvals Mgmt.";
    begin
        Approvalsmgt.RunWorkflowEntriesPage(
            LicenseRequest.RecordId(), DATABASE::"License Request", Enum::"Approval Document Type"::" ", LicenseRequest."No.");
    end;

    procedure CheckLicenseApprovalPossible(var LicenseRequest: Record "License Request"): Boolean
    begin
        if not IsLicenseApprovalsWorkflowEnabled(LicenseRequest) then
            Error(NoWorkflowEnabledErr);

        if not LicenseRequest.LicenseLinesExist then
            Error(NothingToApproveErr);

        LicenseRequest.CheckMandateFields();

        exit(true);
    end;

    procedure IsLicenseApprovalsWorkflowEnabled(var LicesneRequest: Record "License Request"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(LicesneRequest, EMSWorkflowEventHandling.RunWorkflowOnSendLicenseDocForApprovalCode));
    end;

    procedure IsLicenseRequestPendingApproval(var LicesneRequest: Record "License Request"): Boolean
    begin
        if LicesneRequest.Status <> LicesneRequest.Status::Open then
            exit(false);

        exit(IsLicenseApprovalsWorkflowEnabled(LicesneRequest));
    end;

    procedure PrePostApprovalCheckLicense(var LicenseRequest: Record "License Request"): Boolean
    begin
        if IsLicenseRequestPendingApproval(LicenseRequest) then
            Error(LicensePrePostCheckErr, LicenseRequest."Document Type", LicenseRequest."No.");

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', true, true)]
    local procedure OnPopulateApprovalEntryArgument(RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        LicenseRequest: Record "License Request";
    begin
        case RecRef.Number of
            DATABASE::"License Request":
                begin
                    RecRef.SetTable(LicenseRequest);
                    ApprovalEntryArgument."Document No." := LicenseRequest."No.";
                    ApprovalEntryArgument."Salespers./Purch. Code" := LicenseRequest."Salesperson Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnBeforeShowCommonApprovalStatus', '', false, false)]
    local procedure OnBeforeShowCommonApprovalStatus(var IsHandle: Boolean; var RecRef: RecordRef)
    var
        LicenseRequest: Record "License Request";
    begin
        case RecRef.Number of
            DATABASE::"License Request":
                begin
                    RecRef.SetTable(LicenseRequest);
                    ShowLicenseApprovalStatus(LicenseRequest);
                    IsHandle := true;
                end;
        end;
    end;

    local procedure ShowLicenseApprovalStatus(LicenseRequest: Record "License Request")
    var
        ApprovalMgt: Codeunit "Approvals Mgmt.";
    begin
        LicenseRequest.Find;

        case LicenseRequest.Status of
            LicenseRequest.Status::Released:
                Message(DocStatusChangedMsg, LicenseRequest."Document Type", LicenseRequest."No.", LicenseRequest.Status);
            LicenseRequest.Status::"Pending Approval":
                if ApprovalMgt.HasOpenOrPendingApprovalEntries(LicenseRequest.RecordId) then
                    Message(PendingApprovalMsg);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterIsSufficientApprover', '', false, false)]
    procedure IsSufficientApprover(ApprovalEntryArgument: Record "Approval Entry"; UserSetup: Record "User Setup"; var IsHandled: Boolean; var IsSufficient: Boolean)
    begin
        case ApprovalEntryArgument."Table ID" of
            DATABASE::"License Request":
                begin
                    IsSufficient := IsSufficientLicenseApprover(UserSetup, ApprovalEntryArgument."Amount (LCY)");
                    IsHandled := true;
                end;
        end;
    end;

    local procedure IsSufficientLicenseApprover(UserSetup: Record "User Setup"; ApprovalAmountLCY: Decimal): Boolean
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Sales Approval" or
           ((ApprovalAmountLCY <= UserSetup."Sales Amount Approval Limit") and (UserSetup."Sales Amount Approval Limit" <> 0))
        then
            exit(true);

        exit(false);
    end;
}