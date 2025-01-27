codeunit 52114 "EMS Workflow Setup"
{
    trigger OnRun()
    begin

    end;

    var
        EMSWorkflowCategoryTxt: Label 'EMS', Locked = true;
        EMSWorkflowCategoryDescTxt: Label 'EMS';
        EMSApprovalCodeTxt: Label 'LICAPW', Locked = true;
        EMSApprovalDescTxt: Label 'License Approval Workflow';
        EMSTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="License Request">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        WorkflowSetup: Codeunit "Workflow Setup";
        EMSWorkflowEvents: Codeunit "EMS Workflow Events";
        EMSTemplateTok: Label 'EMS', Locked = true;


    internal procedure ResetWorkflowTemplates()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        WorkflowSetup.SetCustomTemplateToken(EMSTemplateTok);
        Workflow.SetRange(Template, true);
        Workflow.SetFilter(Code, '%1', WorkflowSetup.GetWorkflowTemplateToken() + '*');
        Workflow.DeleteAll();

        WorkflowStep.SetFilter("Workflow Code", '%1', WorkflowSetup.GetWorkflowTemplateToken() + '*');
        if WorkflowStep.FindSet() then begin
            repeat
                WorkflowStepArgument.SetRange(ID, WorkflowStep.Argument);
                WorkflowStepArgument.DeleteAll();
            until WorkflowStep.Next() = 0;
            WorkflowStep.DeleteAll();
        end;
    end;

    // Insert Custom workflow setup events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAddWorkflowCategoriesToLibrary, '', true, true)]
    local procedure OnAddWorkflowCategoriesToLibrary()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertWorkflowCategory(EMSWorkflowCategoryTxt, EMSWorkflowCategoryDescTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAfterInsertApprovalsTableRelations, '', true, true)]
    local procedure OnAfterInsertApprovalsTableRelations()
    begin
        EMSWorkflowEvents.AddWorkflowTableRelationsToLibrary();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAfterInitWorkflowTemplates, '', true, true)]
    local procedure OnInsertWorkflowTemplates()
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.SetCustomTemplateToken(EMSTemplateTok);
        Workflow.SetRange(Template, true);
        Workflow.SetFilter(Code, '%1', WorkflowSetup.GetWorkflowTemplateToken() + '*');
        if Workflow.IsEmpty() then
            InsertWorkflowTemplates();
    end;

    local procedure InsertWorkflowTemplates()
    begin
        InsertEMSApprovalWorkflowTemplate();
    end;

    local procedure InsertEMSApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.InsertWorkflowTemplate(Workflow, EMSApprovalCodeTxt, EMSApprovalDescTxt, EMSWorkflowCategoryTxt);
        InsertEMSApprovalWorkflowDetails(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertEMSApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        BlankDateFormula: DateFormula;
        LicenseRequst: Record "License Request";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true
        );

        WorkflowSetup.InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildEMSTypeCondition(LicenseRequst.Status::Open.AsInteger()),
            EMSWorkflowEvents.RunWorkflowOnSendLicenseDocForApprovalCode(),
            BuildEMSTypeCondition(LicenseRequst.Status::"Pending Approval".AsInteger()),
            EMSWorkflowEvents.RunWorkflowOnCancelLicenseApprovalRequestCode(),
            WorkflowStepArgument,
            true
        );
    end;

    local procedure BuildEMSTypeCondition(Status: Integer): Text
    var
        LicenseRequest: Record "License Request";
    begin
        LicenseRequest.SetRange(Status, Status);
        exit(StrSubstNo(EMSTypeCondnTxt, WorkflowSetup.Encode(LicenseRequest.GetView(false))))
    end;
}