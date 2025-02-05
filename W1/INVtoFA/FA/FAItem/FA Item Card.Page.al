namespace TSTChanges.FA.FAItem;

using TSTChanges.FA.FAItem.Picture;
using Microsoft.Foundation.Attachment;
using Microsoft.FixedAssets.Setup;
using Microsoft.Finance.Dimension;
using TSTChanges.FA;
using TSTChanges.Automation;
using System.Automation;
using TSTChanges.FA.Costing;
using TSTChanges.FA.Ledger;
using TSTChanges.FA.Tracking;

page 51201 "FA Item Card"
{
    Caption = 'FA Item Card';
    PageType = Card;
    SourceTable = "FA Item";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(FAItem)
            {
                Caption = 'FA Item';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        // if Rec.AssistEdit() then
                        // CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a description of the FA item.';
                    AboutTitle = 'Describe the product or service';
                    AboutText = 'This appears on the documents you create when buying or selling this item. You can create Extended Texts with additional item description available to insert in the document lines.';
                    // Visible = DescriptionFieldVisible;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item that is placed in quarantine.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item card represents a physical inventory unit (Inventory), a labor time unit (Service), or a physical unit that is not tracked in inventory (Non-Inventory).';

                    trigger OnValidate()
                    begin
                        // EnableControls();
                    end;
                }
                field(Device; Rec.Device)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a FA Item is considered for licensing activity.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                        Rec.Get(Rec."No.");
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the item card was last modified.';
                }
                field(MRP; Rec.MRP)
                {
                    ApplicationArea = Basic, Suite;
                }
                // field("GST Group Code"; Rec."GST Group Code")
                // {
                //     ApplicationArea = Basic, Suite;
                //     ToolTip = 'Specifies an unique identifier for the GST group code used to calculate and post GST.';
                // }
                // field("HSN/SAC Code"; Rec."HSN/SAC Code")
                // {
                //     ApplicationArea = Basic, Suite;
                //     ToolTip = 'Specifies an unique identifier for the type of HSN or SAC that is used to calculate and post GST.';
                // }
            }
            group(InventoryGrp)
            {
                Caption = 'Inventory';
                // Visible = IsInventoriable;
                AboutTitle = 'For items on inventory';
                AboutText = 'Here are settings and information for an item that is kept on inventory. See or update the available inventory, current orders, physical volume and weight, and settings for low inventory handling.';

                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    // Enabled = IsInventoriable;
                    // HideValue = IsNonInventoriable;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                    // Visible = IsInventoryAdjmtAllowed;
                }
                field("Inventory Demo"; Rec."Inventory Demo")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field("Inventory Rental"; Rec."Inventory Rental")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field("Inventory Warehosue"; Rec."Inventory Warehosue")
                {
                    ApplicationArea = basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field("Qty. on Conversion Order"; Rec."Qty. on Conversion Order")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units of the item are allocated to conversion orders, which is how many are listed on outstanding FA conversion order headers.';
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how calculated consumption quantities are rounded when entered on consumption journal lines.';
                }
            }
            group(ItemTracking)
            {
                Caption = 'Item Tracking';
                // Visible = IsInventoriable;
                field("Item Tracking Code"; Rec."Item Tracking Code")
                {
                    ApplicationArea = ItemTracking;
                    Importance = Promoted;
                    ToolTip = 'Specifies how serial or lot numbers assigned to the item are tracked in the supply chain.';

                    trigger OnValidate()
                    begin
                        // SetExpirationCalculationEditable();
                    end;
                }
                field("Serial Nos."; Rec."Serial Nos.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a number series code to assign consecutive serial numbers to items produced.';
                }
                field("Lot Nos."; Rec."Lot Nos.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number series code that will be used when assigning lot numbers.';
                }
                // field("Expiration Calculation"; Rec."Expiration Calculation")
                // {
                //     ApplicationArea = ItemTracking;
                //     Editable = ExpirationCalculationEditable;
                //     ToolTip = 'Specifies the date formula for calculating the expiration date on the item tracking line. Note: This field will be ignored if the involved item has Require Expiration Date Entry set to Yes on the Item Tracking Code page.';

                //     trigger OnValidate()
                //     begin
                //         Rec.Validate("Item Tracking Code");
                //     end;
                // }
            }
            group(FixedAsset)
            {
                Caption = 'Fixed Asset';
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the class that the fixed asset belongs to.';
                }
                field("FA Subclass Code"; Rec."FA Subclass Code")
                {
                    ApplicationArea = FixedAssets;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the subclass of the class that the fixed asset belongs to.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FASubclass: Record "FA Subclass";
                    begin
                        if Rec."FA Class Code" <> '' then
                            FASubclass.SetFilter("FA Class Code", '%1|%2', '', Rec."FA Class Code");

                        if FASubclass.Get(Rec."FA Subclass Code") then;
                        if PAGE.RunModal(0, FASubclass) = ACTION::LookupOK then begin
                            Text := FASubclass.Code;
                            exit(true);
                        end;
                    end;
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                }
                // field("FA Block Code"; Rec."FA Block Code")
                // {
                //     ApplicationArea = FixedAssets;
                //     ToolTip = 'Specifies the FA Block Code for Income tax Depreciation Book.';
                // }
                field("No. of Depreciation Years"; Rec."No. of Depreciation Years")
                {
                    ApplicationArea = FixedAssets;
                }
            }
        }
        area(FactBoxes)
        {
            part(ItemPicture; "FA Item Picture")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"FA Item"),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
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
            // action(FAAquire)
            // {
            //     Caption = 'FA Aquire';
            //     ApplicationArea = All;

            //     trigger OnAction()
            //     var
            //         a: Codeunit "FA Adjustment";
            //         FAItem: Record "FA Item";
            //     begin
            //         FAItem.SetFilter("No.", Rec."No.");
            //         a.SetFilterItem(FAItem);
            //         a.SetProperties(false, false);
            //         a.MakeMultiLevelAdjmt();
            //         Clear(a);
            //     end;
            // }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistCurrUser;

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
                    Visible = OpenApprovalEntriesExistCurrUser;

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
                    Visible = OpenApprovalEntriesExistCurrUser;

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
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group(RequestApproval)
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = (NOT OpenApprovalEntriesExist) AND EnabledApprovalWorkflowsExist AND CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                    begin
                        if ApprovalsMgmt.CheckFAItemApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendFAItemForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelFAItemApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(Rec.RecordId);
                    end;
                }
            }
        }
        area(Navigation)
        {
            group(History)
            {
                Caption = 'History';
                Image = History;
                group(Entries)
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "FA Item Ledger Entries";
                        RunPageLink = "FA Item No." = field("No.");
                        RunPageView = sorting("FA Item No.")
                                      order(Descending);
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the history of transactions that have been posted for the selected record.';
                    }
                    action("&Reservation Entries")
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reservation Entries';
                        Image = ReservationLedger;
                        RunObject = Page "FA Reservation Entries";
                        RunPageLink = "Reservation Status" = const(Reservation),
                                      "Item No." = field("No.");
                        RunPageView = sorting("Item No.", "Variant Code", "Location Code", "Reservation Status");
                        ToolTip = 'View all reservations that are made for the item, either manually or automatically.';
                    }
                    action("Item &Tracking Entries")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item &Tracking Entries';
                        Image = ItemTrackingLedger;
                        ToolTip = 'View serial or lot numbers that are assigned to items.';

                        trigger OnAction()
                        var
                            ItemTrackingDocMgt: Codeunit "FA Item Tracking Doc. Mgmt";
                        begin
                            ItemTrackingDocMgt.ShowItemTrackingForEntity(3, '', Rec."No.", '', '');
                        end;
                    }
                }
            }
            group(Navigation_Item)
            {
                Caption = 'FA Item';

                action("Va&riants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Va&riants';
                    Image = ItemVariant;
                    RunObject = Page "FA Item Variants";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(51200),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("&Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "FA Item Units of Measure";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);
                    end;
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                Image = ItemAvailability;
                // Enabled = IsInventoriable;

            }
        }
        area(Promoted)
        {
            group(Category_Category7)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'FA Item', Comment = 'Generated from the PromotedActionCategories property index 3.';
                actionref(ApprovalEntries_Promoted; ApprovalEntries)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'History', Comment = 'Generated from the PromotedActionCategories property index 4.';
                actionref(Ledger_Promoted; "Ledger E&ntries")
                { }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        // EnableControls();
        // ItemReplenishmentSystem := Rec."Replenishment System";
        if GuiAllowed() then
            OnAfterGetCurrRecordFunc();
    end;

    Local procedure OnAfterGetCurrRecordFunc()
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesExistCurrUser := false;
        if OpenApprovalEntriesExist then
            OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);

        // ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(Rec.RecordId);
        WorkflowWebhookManagement.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
    end;

    trigger OnInit()
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        if not GuiAllowed then
            exit;

        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::"FA Item", EventFilter);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OnNewRec();
    end;

    trigger OnOpenPage()
    begin
        if GuiAllowed then
            SetNoFieldVisible();
    end;

    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        OpenApprovalEntriesExistCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        EnabledApprovalWorkflowsExist: Boolean;
        EventFilter: Text;

    protected var
        NoFieldVisible: Boolean;
        NewMode: Boolean;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit TSTDocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ItemNoIsVisible();
    end;

    local procedure OnNewRec()
    var
        DocumentNoVisibility: Codeunit TSTDocumentNoVisibility;
    begin
        if GuiAllowed then
            if Rec."No." = '' then
                if DocumentNoVisibility.ItemNoSeriesIsDefault() then
                    NewMode := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertItemUnitOfMeasure();
    end;

    local procedure InsertItemUnitOfMeasure()
    var
        ItemUnitOfMeasure: Record "FA Item Unit of Measure";
    begin
        if Rec."Base Unit of Measure" <> '' then begin
            ItemUnitOfMeasure.Init();
            ItemUnitOfMeasure."Item No." := Rec."No.";
            ItemUnitOfMeasure.Validate(Code, Rec."Base Unit of Measure");
            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Insert();
        end;
    end;
}