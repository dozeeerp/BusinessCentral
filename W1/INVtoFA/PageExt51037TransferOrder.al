pageextension 51201 TST_TransferOrder extends "Transfer Order"
{
    PromotedActionCategories = 'New,Process,Report,Release,Posting,Order,Documents,Print/Send,Navigate,Approve,Request Approval';

    layout
    {
        // Add changes to page layout here
        modify(Status)
        {
            Visible = false;
        }
        modify("Customer No.")
        {
            Editable = (rec.Status = rec.Status::Open); //AND EnableTransferFields;
        }
        addafter("Posting Date")
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
            action(DocAttach)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attachments';
                Image = Attach;
                Promoted = true;
                PromotedCategory = Category6;
                ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                trigger OnAction()
                var
                    DocumentAttachmentDetails: Page "Document Attachment Details";
                    RecRef: RecordRef;
                begin
                    RecRef.GetTable(Rec);
                    DocumentAttachmentDetails.OpenForRecRef(RecRef);
                    DocumentAttachmentDetails.RunModal();
                end;
            }
        }
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
        addlast(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(rec.RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(rec.RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(rec.RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category10;
                    PromotedOnly = true;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
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
                    Promoted = true;
                    PromotedCategory = Category11;
                    PromotedIsBig = true;
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
                    Promoted = true;
                    PromotedCategory = Category11;
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
        SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility();
    end;

    var
        OpenApprovalEntriesExist: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        CanCancelApprovalForRecord: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        Text001: Label 'The approval process must be cancelled or completed to reopen this document.';

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(rec.RecordId);

        WorkflowWebhookMgt.GetCanRequestAndCanCancel(rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
    end;
}