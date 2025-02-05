namespace TSTChanges.Automation;

using System.Automation;
using TSTChanges.FA.Conversion;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.FAItem;
using Microsoft.Inventory.Transfer;

codeunit 51240 "TST Workflow Setup"
{
    trigger OnRun()
    begin
    end;

    var
        DozeeWorkflowCategoryTxt: Label 'DOZEE', Locked = true;
        DozeeWorkflowCategoryDescTxt: Label 'Dozee';
        FAConApprovalCodeTxt: Label 'FACAPW', Locked = true;
        FAConApprovalDescTxt: Label 'FA Conversion Approval Workflow';
        TransferOrderApprovalCodeTxt: Label 'TOAPW', Locked = true;
        TransferOrderApprovalDescTxt: Label 'Transfer Order Approval Workflow';
        FATransferOrderApprovalCodeTxt: Label 'FATAPW', Locked = true;
        FATransferOrderApprovalDescTxt: Label 'FA Transfer Order Approval Workflow';
        ItemApprWorkflowCodeTxt: Label 'FAITAPW', Locked = true;
        ItemApprWorkflowDescTxt: Label 'FA Item Approval Workflow';
        FAConversionHeaderTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="FA Conversion Header">%1</DataItem><DataItem name="FA Conversion Line">%2</DataItem></DataItems></ReportParameters>', Locked = true;
        TransferHeaderTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Transfer Header">%1</DataItem><DataItem name="Transfer Line">%2</DataItem></DataItems></ReportParameters>', Locked = true;
        FATransferHeaderTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="FA Transfer Header">%1</DataItem><DataItem name="FA Transfer Line">%2</DataItem></DataItems></ReportParameters>', Locked = true;
        FAItemTypeCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="FA Item">%1</DataItem></DataItems></ReportParameters>', Locked = true;
        WorkflowSetup: Codeunit "Workflow Setup";
        TSTWorkflowEvents: Codeunit "TST Workflow Events";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        BlankDateFormula: DateFormula;
        TSTTemplateTok: Label 'TST', Locked = true;

    internal procedure ResetWorkflowTemplates()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        WorkflowSetup.SetCustomTemplateToken(TSTTemplateTok);
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

        // WorkflowSetup.InitWorkflow();
    end;

    // Insert Custom workflow setup events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAddWorkflowCategoriesToLibrary, '', true, true)]
    local procedure OnAddWorkflowCategoriesToLibrary()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        WorkflowSetup.InsertWorkflowCategory(DozeeWorkflowCategoryTxt, DozeeWorkflowCategoryDescTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAfterInsertApprovalsTableRelations, '', true, true)]
    local procedure OnAfterInsertApprovalsTableRelations()
    begin
        TSTWorkflowEvents.AddWorkflowTableRelationsToLibrary();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", OnAfterInitWorkflowTemplates, '', true, true)]
    local procedure OnInsertWorkflowTemplates()
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.SetCustomTemplateToken(TSTTemplateTok);
        Workflow.SetRange(Template, true);
        Workflow.SetFilter(Code, '%1', WorkflowSetup.GetWorkflowTemplateToken() + '*');
        if Workflow.IsEmpty() then
            InsertWorkflowTemplates();
    end;

    local procedure InsertWorkflowTemplates()
    begin
        InsertConversionApprovalWorkflowTemplate();
        InsertTransferOrderApprovalWorkflowTemplate();
        InsertFATransferOrderApprovalWorkflowTemplate();
        InsertFAItemApprovalWorkflowTemplate();
    end;

    local procedure InsertConversionApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.InsertWorkflowTemplate(Workflow, FAConApprovalCodeTxt, FAConApprovalDescTxt, DozeeWorkflowCategoryTxt);
        InsertConversionApprovalWorkflowDetails(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertConversionApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        BlankDateFormula: DateFormula;
        ConversionHeader: Record "FA Conversion Header";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        WorkflowSetup.InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildConversionTypeCondition(ConversionHeader.Status::Open.AsInteger()),
            TSTWorkflowEvents.RunWorkflowOnSendConversionDocForApprovalCode(),
            BuildConversionTypeCondition(ConversionHeader.Status::"Pending Approval".AsInteger()),
            TSTWorkflowEvents.RunWorkflowOnCancelConversionApprovalRequestCode(),
            WorkflowStepArgument,
            true);
    end;

    local procedure InsertTransferOrderApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.InsertWorkflowTemplate(Workflow, TransferOrderApprovalCodeTxt, TransferOrderApprovalDescTxt, DozeeWorkflowCategoryTxt);
        InsertTransferOrderApprovalWorkflowDetails(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertTransferOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        BlankDateFormula: DateFormula;
        TransferHeader: Record "Transfer Header";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        WorkflowSetup.InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildTransferOrderTypeCondition(TransferHeader.Status1::Open),
            TSTWorkflowEvents.RunWorkflowOnSendTransferDocForApprovalCode(),
            BuildTransferOrderTypeCondition(TransferHeader.Status1::"Pending Approval"),
            TSTWorkflowEvents.RunWorkflowOnCancelTransferApprovalRequestCode(),
            WorkflowStepArgument,
            true);
    end;

    local procedure InsertFATransferOrderApprovalWorkflowTemplate();
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.InsertWorkflowTemplate(Workflow, FATransferOrderApprovalCodeTxt, FATransferOrderApprovalDescTxt, DozeeWorkflowCategoryTxt);
        InsertFATransferOrderApprovalWorkflowDetails(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertFATransferOrderApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        BlankDateFormula: DateFormula;
        FATransferHeader: Record "FA Transfer Header";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver", 0, '', BlankDateFormula, true);

        WorkflowSetup.InsertDocApprovalWorkflowSteps(
            Workflow,
            BuildFATransferOrderTypeCondition(FATransferHeader.Status::Open.AsInteger()),
            TSTWorkflowEvents.RunWorkflowOnSendFATransferDocForApprovalCode(),
            BuildFATransferOrderTypeCondition(FATransferHeader.Status::"Pending Approval".AsInteger()),
            TSTWorkflowEvents.RunWorkflowOnCancelFATransferApprovalRequestCode(),
            WorkflowStepArgument,
            true);
    end;

    local procedure BuildConversionTypeCondition(Status: Integer): Text
    var
        ConversionHeader: Record "FA Conversion Header";
        ConversionLine: Record "FA Conversion Line";
    begin
        ConversionHeader.SetRange(Status, Status);
        exit(StrSubstNo(FAConversionHeaderTypeCondnTxt, WorkflowSetup.Encode(ConversionHeader.GetView(false)), WorkflowSetup.Encode(ConversionLine.GetView(false))));
    end;

    local procedure BuildTransferOrderTypeCondition(Status: Integer): Text
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        TransferHeader.SetRange(Status, Status);
        exit(StrSubstNo(TransferHeaderTypeCondnTxt, WorkflowSetup.Encode(TransferHeader.GetView(false)), WorkflowSetup.Encode(TransferLine.GetView(false))));
    end;

    local procedure BuildFATransferOrderTypeCondition(Status: Integer): Text
    var
        FATransferHeader: Record "FA Transfer Header";
        FATransferLine: Record "FA Transfer Line";
    begin
        FATransferHeader.SetRange(Status, Status);
        exit(StrSubstNo(FATransferHeaderTypeCondnTxt, WorkflowSetup.Encode(FATransferHeader.GetView(false)), WorkflowSetup.Encode(FATransferLine.GetView(false))));
    end;

    local procedure InsertFAItemApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
    begin
        WorkflowSetup.InsertWorkflowTemplate(Workflow, ItemApprWorkflowCodeTxt, ItemApprWorkflowDescTxt, DozeeWorkflowCategoryTxt);
        InsertItemApprovalWorkflowDetails(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertItemApprovalWorkflowDetails(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver",
            0, '', BlankDateFormula, true);

        WorkflowSetup.InsertRecApprovalWorkflowSteps(Workflow, BuildItemTypeConditions(),
          TSTWorkflowEvents.RunWorkflowOnSendFAItemForApprovalCode(),
          WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          TSTWorkflowEvents.RunWorkflowOnCancelFAItemApprovalRequestCode(),
          WorkflowStepArgument,
          true, true);
    end;

    procedure BuildItemTypeConditions(): Text
    var
        Item: Record "FA Item";
    begin
        exit(StrSubstNo(FAItemTypeCondnTxt, WorkflowSetup.Encode(Item.GetView(false))));
    end;
}