pageextension 51202 TST_TransferOrders extends "Transfer Orders"
{
    layout
    {
        // Add changes to page layout here
        modify(Status)
        {
            Visible = false;
        }
        addafter(Status)
        {
            field(Status1; rec.Status1)
            {
                ApplicationArea = All;
            }
        }
        addfirst(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(5740),
                              "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        modify("Re&lease")
        {
            Enabled = false;
            Visible = false;
        }
        modify(Post)
        {
            trigger OnBeforeAction()
            begin
                rec.TestField(Status, rec.Status::Released);
            end;
        }
        addfirst(Release)
        {
            action("Re&&lease")
            {
                ApplicationArea = Location;
                Caption = 'Re&lease';
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ShortCutKey = 'Ctrl+F9';
                ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                trigger OnAction()
                begin
                    rec.PerformManualRelease();
                end;
            }
        }
        modify("Reo&pen")
        {
            trigger OnBeforeAction()
            begin
                if rec.Status1 = rec.Status1::"Pending Approval" then
                    Error(Text001);
            end;
        }
        addlast("O&rder")
        {
            action(Approvals)
            {
                AccessByPermission = TableData "Approval Entry" = R;
                ApplicationArea = Suite;
                Caption = 'Approvals';
                Image = Approvals;
                Promoted = true;
                PromotedCategory = Category6;
                ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                begin
                    ApprovalsMgmt.OpenApprovalsTransfer(Rec);
                end;
            }
        }
        addlast(processing)
        {
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist AND CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                    begin
                        if ApprovalsMgmt.CheckTransferApprovalPossible(rec) then
                            ApprovalsMgmt.OnSendTransferDocForApproval(rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelTransferApprovalRequest(rec);
                        WorkflowWebhookMgt.FindAndCancel(rec.RecordId);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetControlVisibility;
    end;

    var
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        CanCancelApprovalForRecord: Boolean;
        OpenApprovalEntriesExist: Boolean;
        Text001: Label 'The approval process must be cancelled or completed to reopen this document.';
        TransferPrePostCheckErr: Label 'Transfer Order %1 must be approved and released before you can perform this action', Comment = '%1=Transfer Order No.';

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(rec.RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(rec.RecordId);

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
    end;
}