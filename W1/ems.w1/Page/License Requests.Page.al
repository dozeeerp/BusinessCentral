page 52101 "License Requests"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "License Request";
    RefreshOnActivate = true;
    Caption = 'License Requests';
    DataCaptionFields = "Customer No.";
    CardPageId = "License Request";
    Editable = false;
    SourceTableView = where(Status = filter(Open | "Pending Approval" | Released));

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Customer Name field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status field.';
                    StyleExpr = StatusStyleTxt;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                // field("Device Type"; Rec."Device Type")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Device Type field.';
                // }
                // field("License Type"; Rec."License Type")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the License Type field.';
                // }
                // field("License Qty."; rec."License Qty.")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the qty of device that can be linked with the license';
                // }
                field(Duration; rec.Duration)
                {
                    ApplicationArea = All;
                    Caption = 'License Duration';
                    ToolTip = 'Specifies the duration of license (D=Days, M=Months, Y=Years)';
                }
                field("Request Date"; Rec."Request Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Request Date field.';
                }
                field("Release Date"; Rec."Release Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Release Date field.';
                }
                // field("Requested By"; Rec."Requested By")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Requester field.';
                // }
                // field("Approved BY"; Rec."Approved BY")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Approver field.';
                // }
                // field("Duration In Day"; Rec."Duration In Day")
                // {
                //     ToolTip = 'Specifies the value of the Duration In Day field.';
                //     ApplicationArea = All;
                // }
                // field("Invoice Amount"; Rec."Invoice Amount")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Invoice Amount field.';
                // }
                // field("Invoice Qty"; Rec."Invoice Qty")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Invoice Qty field.';
                // }
                // field("Invoice Duration"; Rec."Invoice Duration")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Invoice Duration field.';
                // }
            }
        }
        area(Factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"License Request"),
                              "No." = FIELD("No.");
                //   "Document Type" = FIELD("Document Type");
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Customer No."),
                              "Date Filter" = FIELD("Date Filter");
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Customer No."),
                              "Date Filter" = FIELD("Date Filter");
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action("SendApprovalRequest")
                {
                    ApplicationArea = Basic;
                    Image = SendApprovalRequest;
                    Enabled = NOT OpenApprovalEntriesExist AND CanRequestApprovalForFlow;
                    ToolTip = 'Request Approval of the document';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckLicenseApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendLicenseDocForApproval(Rec);
                    end;
                }
                action("Cancel Approval Request")
                {
                    ApplicationArea = Basic;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request';
                    Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelLicenseApprovalRequest(rec);
                        WorkflowWebhookManagement.FindAndCancel(rec.RecordId);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetControlVisibility;
    end;

    trigger OnAfterGetRecord()
    begin
        StatusStyleTxt := rec.GetStatusStyleText();
    end;

    var
        StatusStyleTxt: Text;
        OpenApprovalEntriesExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;

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