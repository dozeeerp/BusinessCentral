page 52102 "License Request"
{
    PageType = Document;
    UsageCategory = None;
    Caption = 'License Request';
    SourceTable = "License Request";
    DataCaptionFields = "No.";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then;
                        CurrPage.Update;
                    end;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value Organization ID from Dozee SRPM Dashobard.';
                }
                // field("Ship-to Code"; Rec."Ship-to Code")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Ship-to Code field.';
                // }
                field("Organization ID"; Rec."Organization ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Org ID field.';
                }
                group("License To")
                {
                    field("Address"; Rec."Address")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Address field.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Address 2 field.';
                    }
                    field("City"; Rec."City")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the City field.';
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Post Code field.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Country Code field.';
                    }
                    field("Contact"; Rec."Contact")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Contact field.';
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                    }
                    field("Contact No."; Rec."Contact No.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                    }
                    field("Email"; Rec."E-Mail")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                    }
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Salesperson Code field.';
                }
                field("Salesperson Name"; Rec."Salesperson Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Salesperson Name field.';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Campaign No. field.';
                }
                field("Campaign Name"; Rec."Campaign Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Campaign Name field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Status field.';
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
                field("Requested Activation Date"; Rec."Requested Activation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requested Activation Date field.';
                }
                // field("Activation Date"; Rec."Activation Date")
                // {
                //     ApplicationArea = All;
                //     Visible = false;
                // }
                // field("Expiry Date"; Rec."Expiry Date")
                // {
                //     ApplicationArea = All;
                //     Visible = false;
                // }
                field("Requested By"; Rec."Requested By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requester field.';
                }
                field("Approved BY"; Rec."Approved BY")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Approver field.';
                }
                field("Generated By"; Rec."Generated By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Generated By field.';
                }
                // field("Doner ID"; Rec."Doner ID")
                // {
                //     ApplicationArea = All;
                // }
            }

            group(License)
            {
                Editable = Rec.Status = Rec.Status::Open;

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field("Device Type"; Rec."Device Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Device Type field.';
                }
                field("License Code"; Rec."License Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License Code field.';
                }
                field("License Type"; Rec."License Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the License Type field.';
                }
                field("License Qty."; Rec."License Qty.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Device Covered under license field.';
                }
                field("Total Devices"; Rec."Total Devices")
                {
                    ApplicationArea = All;
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Duration field.';

                    trigger OnValidate()
                    var
                    //LicenseRequest: Record "License Request";
                    begin
                        // IF Rec."Document Type" = Rec."Document Type"::New Then begin
                        //     IF Rec."Requested Activation Date" <> 0D Then Begin
                        //         Rec."Activation Date" := Rec."Requested Activation Date";
                        //         Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date")
                        //     End else begin
                        //         Rec."Activation Date" := Today;
                        //         Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date");
                        //     end;
                        // end;
                        // IF Rec."Document Type" = Rec."Document Type"::"Add on" Then begin
                        //     IF Rec."Requested Activation Date" <> 0D Then Begin
                        //         Rec."Activation Date" := Rec."Requested Activation Date";
                        //         Clear(LicenseRequest);
                        //         IF LicenseRequest.Get(Rec."Parent Add on Of") then
                        //             Rec."Expiry Date" := LicenseRequest."Expiry Date";
                        //     End else begin
                        //         Rec."Activation Date" := Today;
                        //         Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date");
                        //     end;
                        // end;
                        // IF Rec."Document Type" = Rec."Document Type"::Renewal Then begin
                        //     Clear(LicenseRequest);
                        //     IF LicenseRequest.Get(Rec."Parent Renewal Of") then
                        //         Rec."Activation Date" := LicenseRequest."Activation Date";
                        //     Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date" + 1);
                        // end;
                        // IF Rec."Document Type" = Rec."Document Type"::Extension Then begin
                        //     Clear(LicenseRequest);
                        //     IF LicenseRequest.Get(Rec."Parent Extension Of") then
                        //         Rec."Activation Date" := LicenseRequest."Activation Date";
                        //     Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date" + 1);
                        // end;
                    end;
                }
            }
            group(Invoice)
            {
                Editable = Rec.Status = Rec.Status::Open;

                field("Invoice No"; Rec."Invoice No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice No field.';

                    trigger OnValidate()
                    begin
                        IF Rec."Invoice No" = '' then begin
                            Rec."Invoice Amount" := 0;
                            Rec."Invoice Qty" := 0;
                            Rec.Duration := '';
                        end;
                    end;

                    // trigger OnDrillDown()
                    // var
                    //     SalesInvoiceHdr: Record "Sales Invoice Header";
                    //     PostedSalesInvoice: Page "Posted Sales Invoices";
                    //     SalesInvoiceLine: Record "Sales Invoice Line";
                    //     ItemCategory_lRec: Record "Item Category";
                    //     Duration_lCod: Code[10];
                    //     Amount_lDec: Decimal;
                    //     Qty_lDec: Decimal;
                    // begin
                    //     Amount_lDec := 0;
                    //     Qty_lDec := 0;
                    //     SalesInvoiceHdr.Reset();
                    //     SalesInvoiceHdr.SetRange(SalesInvoiceHdr."Sell-to Customer No.", Rec."Customer No.");
                    //     PostedSalesInvoice.SetTableView(SalesInvoiceHdr);
                    //     PostedSalesInvoice.LookupMode := true;
                    //     IF PostedSalesInvoice.RunModal() = Action::LookupOK then Rec.Validate("Invoice No", PostedSalesInvoice.ReturnSchName());
                    //     SalesInvoiceLine.Reset();
                    //     SalesInvoiceLine.SetRange("Document No.", PostedSalesInvoice.ReturnSchName());
                    //     SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
                    //     IF SalesInvoiceLine.FindSet() then begin
                    //         repeat
                    //             IF ItemCategory_lRec.Get(SalesInvoiceLine."Item Category Code") then begin
                    //                 IF ItemCategory_lRec."Used for License" then begin
                    //                     IF Duration_lCod = '' then Duration_lCod := SalesInvoiceLine.Duration;
                    //                     Amount_lDec += SalesInvoiceLine.Amount;
                    //                     Qty_lDec += SalesInvoiceLine.Quantity;
                    //                 end;
                    //             end;
                    //         until SalesInvoiceLine.Next() = 0;
                    //     end;
                    //     Rec."Invoice Amount" := Amount_lDec;
                    //     Rec."Invoice Qty" := Qty_lDec;
                    //     Rec."Invoice Duration" := Duration_lCod;
                    // End;
                }
                field("Invoice Amount"; Rec."Invoice Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Invoice Amount field.';
                }
                field("Invoice Qty"; Rec."Invoice Qty")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Invoice Qty field.';
                }
                field("Invoice Duration"; Rec."Invoice Duration")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Invoice Duration field.';
                }
                field("License Value"; Rec."License Value")
                {
                    ApplicationArea = All;
                    Editable = Rec."License Type" = Rec."License Type"::MillionICU;
                }
            }
            // part("Licence TypeDefa Fecture"; "Licence TypeDefa Fecture")
            // {
            //     ApplicationArea = All;
            //     SubPageLink = "License Request No." = field("No."), "License Type" = field("License Type");
            //     Editable = Rec.Status = Rec.Status::Open;
            // }
            group(Others)
            {
                group(Extension)
                {
                    Editable = false;

                    field("Original Extension Of"; Rec."Original Extension Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Original Extension Of field.';
                    }
                    field("Parent Extension Of"; Rec."Parent Extension Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Parent Extension Of field.';
                    }
                }
                group(Renewal)
                {
                    Editable = false;

                    field("Original Renewal Of"; Rec."Original Renewal Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Original Renewal Of field.';
                    }
                    field("Parent Renewal Of"; Rec."Parent Renewal Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Parent Renewal Of field.';
                    }
                }
                group("Add On")
                {
                    Editable = false;

                    field("Original Add on Of"; Rec."Original Add on Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Original Add on Of field.';
                    }
                    field("Parent Add on Of"; Rec."Parent Add on Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Parent Add on Of field.';
                    }
                }
            }
        }

    }

    actions
    {
        area(Navigation)
        {
            group("L&icense")
            {
                Caption = 'License';
                action(Customer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No."),
                                  "Date Filter" = field("Date Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer on the sales document.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalsLicense(Rec);
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attachments';
                    Image = Attach;
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
        }
        area(Processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
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
            group(Action21)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&lease';
                    Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseLicenseDoc: Codeunit "Release License Document";
                    begin
                        ReleaseLicenseDoc.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseLicenseDoc: Codeunit "Release License Document";
                    begin
                        ReleaseLicenseDoc.PerformManualReopen(Rec);
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
                    Enabled = not OpenApprovalEntriesExist and CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckLicenseApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendLicenseDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord or CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
                        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelLicenseApprovalRequest(Rec);
                        WorkflowWebhookMgt.FindAndCancel(Rec.RecordId);
                    end;
                }
                // group(Flow)
                // {
                //     Caption = 'Power Automate';
                //     Image = Flow;

                //     customaction(CreateFlowFromTemplate)
                //     {
                //         ApplicationArea = Basic, Suite;
                //         Caption = 'Create approval flow';
                //         ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                //         Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                //         CustomActionType = FlowTemplateGallery;
                //         FlowTemplateCategoryName = 'd365bc_approval_salesOrder';
                //     }
                // }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
                group(Category_Category5)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'License', Comment = 'Generated from the PromotedActionCategories property index 7.';
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                // actionref("Co&mments_Promoted"; "Co&mments")
                // {
                // }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
                separator(Navigate_Separator)
                {
                }
                // actionref(Invoices_Promoted; Invoices)
                // {
                // }
                actionref(Customer_Promoted; Customer)
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        StatusStyleTxt := rec.GetStatusStyleText();
        SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility;
        LICToContact.GetOrClear(rec."Contact No.");
    end;

    trigger OnOpenPage()
    begin
        SetDocNoVisible();
        rec.SetRange("Date Filter", 0D, WorkDate());
    end;

    var
        LICToContact: Record Contact;
        DocNoVisible: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForRecord: Boolean;
        IsCustomerOrContactNotEmpty: Boolean;
        CanCancelApprovalForFlow: Boolean;
        ShouldSearchForCustByName: Boolean;
        StatusStyleTxt: Text;
        IsNew: Boolean;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(rec.RecordId);

        WorkflowWebhookMgt.GetCanRequestAndCanCancel(rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
        IsCustomerOrContactNotEmpty := (rec."Customer No." <> '') or (rec."Contact No." <> '');

        ShouldSearchForCustByName := rec.ShouldSearchForCustomerByName(rec."Customer No.");

        IsNew := (rec.Status = rec.Status::Open) and (rec."Document Type" = rec."Document Type"::New);
    end;

    local procedure SetDocNoVisible()
    begin
        DocNoVisible := SetDocNoVisible(rec."Document Type")
    end;

    local procedure SetDocNoVisible(var DocType: Enum "Document Type"): Boolean
    var
        NoSeries: Record "No. Series";
        AgrmtDocsNoVisible: Dictionary of [Integer, Boolean];
        DocNoSeries: Code[20];
    begin
        if rec."No." <> '' then begin
            DocNoVisible := false;
            exit(false);
        end;
        if AgrmtDocsNoVisible.ContainsKey(DocType.AsInteger()) then
            exit(AgrmtDocsNoVisible.Get(DocType.AsInteger()));

        // DocNoSeries := DetermineSalesSeriesNo(DocType);
        // if not NoSeries.Get(DocNoSeries) then begin
        //     SalesNoSeriesSetup.SetFieldsVisibility(DocType);
        //     SalesNoSeriesSetup.RunModal();
        //     DocNoSeries := DetermineSalesSeriesNo(DocType);
        // end;
        // Result := ForceShowNoSeriesForDocNo(DocNoSeries);
        // SalesDocsNoVisible.Add(DocType, Result);
        // exit(Result);
    end;
}