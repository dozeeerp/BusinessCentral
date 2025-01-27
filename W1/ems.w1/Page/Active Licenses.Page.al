page 52107 "Active Licenses"
{
    AdditionalSearchTerms = 'Posted License';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    Caption = 'Activated Licenses';
    SourceTable = "License Request";
    Editable = false;
    CardPageId = "Active License Card";
    QueryCategory = 'Active License List';
    PromotedActionCategories = 'New,Process,Report,License,Navigate,Correct,Print/Send';
    RefreshOnActivate = true;
    //SourceTableView = sorting("License No.") order(descending) where(Status = filter(Active | Expired | Terminated));
    SourceTableView = sorting("License No.") order(descending) where(Status = filter(Active));

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License No. field.';
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
                field("Request Date"; Rec."Request Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Request Date field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Release Date"; Rec."Release Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Release Date field.';
                }
                field("Device Type"; Rec."Device Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Device Type field.';
                }
                field("Invoice Amount"; Rec."Invoice Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice Amount field.';
                }
                field("Requested By"; Rec."Requested By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requester field.';
                }
                field("Approved BY"; Rec."Approved BY")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Approver field.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field("License Type"; Rec."License Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License Type field.';
                }
                field(Terminated; Rec.Terminated)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Terminated field.';
                }
                field(Dunning; Rec.Dunning)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dunning field.';
                }
                field("Dunning Type"; Rec."Dunning Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dunning Type field.';
                }
            }
        }
    }
    actions
    {
        area(navigation)
        {
            // Group(License)
            // {
            //     action(Dimensions)
            //     {
            //         AccessByPermission = TableData Dimension = R;
            //         ApplicationArea = Dimensions;
            //         Caption = 'Dimensions';
            //         Enabled = Rec."No." <> '';
            //         Image = Dimensions;
            //         ShortCutKey = 'Alt+D';
            //         ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            //         trigger OnAction()
            //         begin
            //             Rec.ShowDocDim;
            //             CurrPage.SaveRecord;
            //         end;
            //     }
            //     action("Co&mments")
            //     {
            //         ApplicationArea = Comments;
            //         Caption = 'Co&mments';
            //         Image = ViewComments;
            //         RunObject = Page "Licence Comment Sheet";
            //         RunPageLink = "No." = FIELD("No."),
            //                       "Document Line No." = CONST(0);
            //         ToolTip = 'View or add comments for the record.';
            //     }
            // }
            // Group(Status)
            // {
            //     action(Release, reopen)
            //     {
            //         ApplicationArea = All;
            //         trigger OnAction()
            //         begin
            //         end;
            //     }
            //     action("Cancel Approval")
            //     {
            //         ApplicationArea = All;
            //         trigger OnAction()
            //         begin
            //         end;
            //     }
            // }
            group(Navigate)
            {
                action(Invoice)
                {
                    ApplicationArea = All;
                    Caption = 'Invoice';
                    Image = Invoice;
                    RunObject = Page "Posted Sales Invoices";
                    RunPageLink = "No." = field("Invoice No");
                    ToolTip = 'View or add Invoice for the record.';
                }
                action(Customer)
                {
                    ApplicationArea = All;
                    Caption = 'Customer';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = field("Customer No.");
                    ToolTip = 'View or add Customer for the record.';
                }
            }
            Group("Request Approval")
            {
                action("Send For Approval")
                {
                    ApplicationArea = All;
                    ToolTip = 'Executes the Send For Approval action.';

                    trigger OnAction()
                    begin
                    end;
                }
                action("Cancel Approval")
                {
                    ApplicationArea = All;
                    ToolTip = 'Executes the Cancel Approval action.';

                    trigger OnAction()
                    begin
                    end;
                }
            }
            action("Issue Extension")
            {
                ApplicationArea = All;
                Image = ExtendedDataEntry;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = EnableAction_l;
                ToolTip = 'Executes the Issue Extension action.';

                trigger OnAction()
                begin
                    // LicenseRequest.Reset();
                    // LicenseRequest.SetRange(Status, LicenseRequest.Status::Open);
                    // LicenseRequest.setfilter("License Type", '%1|%2', LicenseRequest."License Type"::Demo, LicenseRequest."License Type"::Notice);
                    // LicenseList.SetTableView(LicenseRequest);
                    // LicenseList.LookupMode := true;
                    // IF LicenseList.RunModal() = Action::RunObject then
                    //     SinCodeunit.InsertValue(Rec."License No.");
                    ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Extension");
                end;
            }
            action("Issue Renewal")
            {
                ApplicationArea = All;
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = NOT Rec.Renewed;
                ToolTip = 'Executes the Issue Renewal action.';

                trigger OnAction()
                begin
                    // LicenseRequest.Reset();
                    // LicenseRequest.SetRange(Status, LicenseRequest.Status::Open);
                    // LicenseRequest.setfilter("License Type", '%1', LicenseRequest."License Type"::Commercial);
                    // LicenseList.SetTableView(LicenseRequest);
                    // LicenseList.LookupMode := true;
                    // IF LicenseList.RunModal() = Action::LookupOK then
                    //     Rec."Renewal Of" := LicenseList.ReturnSchName();
                    ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Renewal");
                end;
            }
            action("Issue Add On")
            {
                ApplicationArea = All;
                Image = Add;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Executes the Issue Add On action.';

                trigger OnAction()
                begin
                    // LicenseRequest.Reset();
                    // LicenseRequest.SetRange(Status, LicenseRequest.Status::Open);
                    // LicenseRequest.setfilter("License Type", '%1', LicenseRequest."License Type"::Commercial);
                    // LicenseList.SetTableView(LicenseRequest);
                    // LicenseList.LookupMode := true;
                    // IF LicenseList.RunModal() = Action::LookupOK then
                    //     Rec."Renewal Of" := LicenseList.ReturnSchName();
                    ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Add On");
                end;
            }
            action("Terminate")
            {
                ApplicationArea = All;
                Image = TerminationDescription;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Executes the Terminate action.';

                trigger OnAction()
                begin
                    IF not Confirm('Do you want to terminate Active License: %1?', true, Rec."No.") then exit;
                    ActiveLicMgt_gCdu.TerminateLicenseRequest(Rec."No.");
                end;
            }
            // action("Convert to Commercial")
            // {
            //     ApplicationArea = All;
            //     Image = Card;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     ToolTip = 'Executes the Convert to Commercial action.';
            //     trigger OnAction()
            //     begin
            //         ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Convert to Commercial");
            //     end;
            // }
            // action("Issue Notice")
            // {
            //     ApplicationArea = All;
            //     Image = Card;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     ToolTip = 'Executes the Issue Notice action.';
            //     trigger OnAction()
            //     begin
            //         ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Notice");
            //     end;
            // }
        }
    }
    trigger OnOpenPage()
    begin
        EnableAction1;
    end;

    trigger OnAfterGetRecord()
    begin
        EnableAction1;
    end;

    procedure EnableAction1()
    begin
        IF (Rec."License Type" = Rec."License Type"::Demo) AND (NOT Rec.Extended) Then
            EnableAction_l := true
        else
            EnableAction_l := false;
    end;

    var
        EnableAction_l: boolean;
        Action_gOpt: Option "Issue Extension","Issue Renewal","Issue Add On","Convert to Commercial","Issue Notice";
        ActiveLicMgt_gCdu: Codeunit "Active License Mgt.";
}
