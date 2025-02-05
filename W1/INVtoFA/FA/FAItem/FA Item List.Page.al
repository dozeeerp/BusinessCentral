namespace TSTChanges.FA.FAItem;

using System.Integration.PowerBI;
using System.Text;
using Microsoft.Foundation.Attachment;
using TSTChanges.FA.Ledger;
using TSTChanges.Automation;
using Microsoft.Finance.Dimension;
using System.Automation;
using TSTChanges.FA.Tracking;

page 51200 "FA Item List"
{
    Caption = 'FA Items';
    PageType = List;
    Editable = false;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "FA Item";
    CardPageId = "FA Item Card";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                Caption = 'FA Item';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a number to identify the FA item. You can use ranges of item numbers to logically group products or to imply information about them. Or use simple numbers and item categories to group items.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a default text to describe the FA item on related documents such as orders or invoices. You can translate the descriptions so that they show up in the language of the customer or vendor.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
            }
        }
        area(FactBoxes)
        {
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"FA Item"), "No." = field("No.");
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
            group(History)
            {
                Caption = 'History';
                Image = History;
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Category5;
                        RunObject = Page "FA Item Ledger Entries";
                        RunPageLink = "FA Item No." = field("No.");
                        RunPageView = sorting("FA Item No.")
                                      order(Descending);
                        Scope = Repeater;
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
                group(RequestApproval)
                {
                    Caption = 'Request Approval';
                    Image = SendApprovalRequest;
                    action(SendApprovalRequest)
                    {
                        ApplicationArea = Suite;
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
                        ApplicationArea = Suite;
                        Caption = 'Cancel Approval Re&quest';
                        Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;
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
        }
        area(navigation)
        {
            group(Action126)
            {
                Caption = 'Item';
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
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action(DimensionsSingle)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(51200),
                                      "No." = field("No.");
                        Scope = Repeater;
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action(DimensionsMultiple)
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Item: Record "FA Item";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Item);
                            DefaultDimMultiple.SetMultiRecord(Item, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("&Units of Measure")
                {
                    ApplicationArea = Suite;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "FA Item Units of Measure";
                    RunPageLink = "Item No." = field("No.");
                    Scope = Repeater;
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        FilteredItem: Record "FA Item";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
        WorkflowWebhookManagement.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        SetWorkflowManagementEnabledState();
        CurrPage.SetSelectionFilter(FilteredItem);
        CurrPage.PowerBIEmbeddedReportPart.Page.SetFilterToMultipleValues(FilteredItem, FilteredItem.FieldNo("No."));
    end;

    trigger OnInit()
    begin
        CurrPage.PowerBIEmbeddedReportPart.Page.SetPageContext(CurrPage.ObjectId(false));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        if RunOnTempRec then begin
            TempItemFilteredFromAttributes.Copy(Rec);
            Found := TempItemFilteredFromAttributes.Find(Which);
            if Found then
                Rec := TempItemFilteredFromAttributes;
            exit(Found);
        end;
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        if RunOnTempRec then begin
            TempItemFilteredFromAttributes.Copy(Rec);
            ResultSteps := TempItemFilteredFromAttributes.Next(Steps);
            if ResultSteps <> 0 then
                Rec := TempItemFilteredFromAttributes;
            exit(ResultSteps);
        end;
        exit(Rec.Next(Steps));
    end;

    var
        TempItemFilteredFromAttributes: Record "FA Item" temporary;
        TempItemFilteredFromPickItem: Record "FA Item" temporary;
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";

    protected var
        RunOnTempRec: Boolean;
        RunOnPickItem: Boolean;
        OpenApprovalEntriesExist: Boolean;
        EnabledApprovalWorkflowsExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        EventFilter: Text;

    procedure SetTempFilteredItemRec(var FAItem: Record "FA Item")
    begin
        TempItemFilteredFromAttributes.Reset();
        TempItemFilteredFromAttributes.DeleteAll();

        TempItemFilteredFromPickItem.Reset();
        TempItemFilteredFromPickItem.DeleteAll();

        RunOnTempRec := true;
        RunOnPickItem := true;

        if FAItem.FindSet() then
            repeat
                TempItemFilteredFromAttributes := FAItem;
                TempItemFilteredFromAttributes.Insert();
                TempItemFilteredFromPickItem := FAItem;
                TempItemFilteredFromPickItem.Insert();
            until FAItem.Next() = 0;
    end;

    procedure SelectActiveItemsForTransfer(): Text
    var
        SelectedItem: Record "FA Item";
    begin
        SelectedItem.SetRange(Type, SelectedItem.Type::Inventory);
        // OnSelectActiveItemsForTransferAfterSetFilters(SelectedItem);
        exit(SelectInItemList(SelectedItem));
    end;

    procedure SelectInItemList(var FAItem: Record "FA Item"): Text
    var
        ItemListPage: Page "FA Item List";
    begin
        FAItem.SetRange(Blocked, false);
        ItemListPage.SetTableView(FAItem);
        ItemListPage.LookupMode(true);
        if ItemListPage.RunModal() = ACTION::LookupOK then
            exit(ItemListPage.GetSelectionFilter());
    end;

    procedure GetSelectionFilter(): Text
    var
        FAItem: Record "FA Item";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        CurrPage.SetSelectionFilter(FAItem);
        RecRef.GetTable(FAItem);
        exit(SelectionFilterManagement.GetSelectionFilter(RecRef, FAItem.FieldNo("No.")));
    end;

    local procedure SetWorkflowManagementEnabledState()
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        EventFilter := WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode() + '|' +
          WorkflowEventHandling.RunWorkflowOnItemChangedCode();

        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::"FA Item", EventFilter);
    end;
}