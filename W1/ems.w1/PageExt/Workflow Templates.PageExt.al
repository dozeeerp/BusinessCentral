pageextension 52115 EMS_WorkflowTemplates extends "Workflow Templates"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addlast(processing)
        {
            action(ResetEMS)
            {
                ApplicationArea = Suite;
                Caption = 'Reset EMS Templates';
                Visible = not IsLookupMode;
                Image = ResetStatus;
                ToolTip = 'Recreate all EMS templates';

                trigger OnAction()
                var
                    WorkflowSetup: Codeunit "EMS Workflow Setup";
                begin
                    WorkflowSetup.ResetWorkflowTemplates();
                    Initialize();
                end;
            }
        }
    }

    var
        myInt: Integer;
}