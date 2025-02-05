namespace TSTChanges.FA.Conversion;

using TSTChanges.FA.FAItem;
using Microsoft.Warehouse.Activity;
using TSTChanges.FA.Journal;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Activity.History;
using TSTChanges.FA.History;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using TSTChanges.FA.Ledger;
using TSTChanges.Automation;
using System.Automation;
using Microsoft.Assembly.Document;
using TSTChanges.FA.Posting;

page 51205 "FA Conversion Order"
{
    Caption = 'FA Conversion Order';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "FA Conversion Header";

    layout
    {
        area(Content)
        {
            group(Control2)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    AssistEdit = true;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("FA Item No."; Rec."FA Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    // Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ShowMandatory = true;
                    TableRelation = "FA Item"."No.";
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }

                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    // Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    // ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = Assembly;
                        // Editable = IsAsmToOrderEditable;
                        Importance = Promoted;
                        BlankZero = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord();
                        end;
                    }
                    field("Quantity to Convert"; Rec."Quantity to Convert")
                    {
                        ApplicationArea = Assembly;
                        Importance = Promoted;
                        ToolTip = 'Specifies how many of the assembly item units you want to partially post. To post the full quantity on the assembly order, leave the field unchanged.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord();
                        end;
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                        // Editable = IsAsmToOrderEditable;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord();
                        end;
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Assembly;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the assembly order is posted.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    // Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                }
                field("Converted Quantity"; Rec."Converted Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item are posted as assembled output.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the assembly item are reserved for this assembly order header.';
                    Visible = false;
                }
                // field("Assemble to Order"; Rec."Assemble to Order")
                // {
                //     ApplicationArea = Assembly;
                //     ToolTip = 'Specifies if the assembly order is linked to a sales order, which indicates that the item is assembled to order.';

                //     trigger OnDrillDown()
                //     begin
                //         Rec.ShowAsmToOrder();
                //     end;
                // }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the document is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                }
            }
            part(Lines; "FA Conversion Order Subform")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    // Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(Control43; "Component - Resource Details")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "No." = field("No.");
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control9; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(General)
            {
                Caption = 'General';
                action("Item Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
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
                        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                    begin
                        ApprovalsMgmt.OpenApprovalsConversion(Rec);
                    end;
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                Image = Statistics;
                action(Action14)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunPageOnRec = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        // Rec.ShowStatistics();
                    end;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Pick Lines/Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Lines/Movement Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Source Type" = const(51205),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk");
                    ToolTip = 'View the related picks or movements.';
                }
                action("Registered P&ick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered P&ick Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Act.-Lines";
                    RunPageLink = "Source Type" = const(51205),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    ToolTip = 'View the list of warehouse picks that have been made for the order.';
                }
                action("Registered Invt. Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Invt. Movement Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Reg. Invt. Movement Lines";
                    RunPageLink = "Source Type" = const(51205),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    ToolTip = 'View the list of inventory movements that have been made for the order.';
                }
                // action("Asm.-to-Order Whse. Shpt. Line")
                // {
                //     ApplicationArea = Warehouse;
                //     Caption = 'Asm.-to-Order Whse. Shpt. Line';
                //     Enabled = NOT IsAsmToOrderEditable;
                //     Image = ShipmentLines;
                //     ToolTip = 'View the list of warehouse shipment lines that exist for sales orders that are linked to this assembly order as assemble-to-order links. ';

                //     trigger OnAction()
                //     var
                //         ATOLink: Record "Assemble-to-Order Link";
                //         WhseShptLine: Record "Warehouse Shipment Line";
                //         IsHandled: Boolean;
                //     begin
                //         IsHandled := false;
                //         OnBeforeAsmToOrderWhseShptLine(Rec, IsHandled);
                //         if IsHandled then
                //             exit;

                //         Rec.TestField("Assemble to Order", true);
                //         ATOLink.Get(Rec."Document Type", Rec."No.");
                //         WhseShptLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Assemble to Order");
                //         WhseShptLine.SetRange("Source Type", Database::"Sales Line");
                //         WhseShptLine.SetRange("Source Subtype", ATOLink."Document Type");
                //         WhseShptLine.SetRange("Source No.", ATOLink."Document No.");
                //         WhseShptLine.SetRange("Source Line No.", ATOLink."Document Line No.");
                //         WhseShptLine.SetRange("Assemble to Order", true);
                //         PAGE.RunModal(PAGE::"Asm.-to-Order Whse. Shpt. Line", WhseShptLine);
                //     end;
                // }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                group(Entries)
                {
                    Caption = 'Entries';
                    Image = Entries;
                    action("FA Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Item Ledger Entries';
                        Image = ItemLedger;
                        RunObject = Page "FA Item Ledger Entries";
                        RunPageLink = "Order Type" = const(Conversion),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
                    action("Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Ledger Entries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = const(Conversion),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
                    action("Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Source Type" = filter(51209 | 51205),
                                      "Source Subtype" = filter("0"),
                                      "Source No." = field("No.");
                        RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                        ToolTip = 'View completed warehouse activities related to the document.';
                    }
                    action("Reservation Entries")
                    {
                        AccessByPermission = TableData "FA Item" = R;
                        ApplicationArea = Reservation;
                        Caption = 'Reservation Entries';
                        Image = ReservationLedger;
                        ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                        trigger OnAction()
                        begin
                            Rec.ShowReservationEntries(true);
                        end;
                    }
                }
                action("Posted Conversion Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Posted Conversion Orders';
                    Image = PostedOrder;
                    RunObject = Page "Posted Conversion Orders";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.");
                    ToolTip = 'View completed conversion orders.';
                }
            }
        }
        area(Processing)
        {
            group("Re&lease")
            {
                Caption = 'Re&lease';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = all;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = All;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseConversionDoc: Codeunit "Release Conversion Document";
                    begin
                        ReleaseConversionDoc.PerformManualReopen(Rec);
                    end;
                }
            }
            group(Action80)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Create Inventor&y Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventor&y Movement';
                    Ellipsis = true;
                    Image = CreatePutAway;
                    ToolTip = 'Create an inventory movement to handle items on the document according to a basic warehouse configuration.';

                    trigger OnAction()
                    var
                        ATOMovementsCreated: Integer;
                        TotalATOMovementsToBeCreated: Integer;
                    begin
                        Rec.PerformManualRelease();
                        // Rec.CreateInvtMovement(false, false, false, ATOMovementsCreated, TotalATOMovementsToBeCreated);
                    end;
                }
                action("Create Warehouse Pick")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Pick';
                    Image = CreateWarehousePick;
                    ToolTip = 'Create warehouse pick documents for the assembly order lines.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                        Rec.CreatePick(true, UserId, 0, false, false, false);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = All;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    // Enabled = IsAsmToOrderEditable;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Conversion-post (Yes/No)", Rec);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
            }
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
            group(RequestApproval)
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist AND CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
                    begin
                        if ApprovalsMgmt.CheckConversionApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendConversionDocForApproval(Rec);
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
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelConversionApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
                group(Category_Category6)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 5.';
                    ShowAs = SplitButton;

                    actionref("P&ost_Promoted"; "P&ost")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                }
                group(Category_Category8)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 7.';
                    ShowAs = SplitButton;

                    actionref("Re&lease_Promoted"; Release)
                    {
                    }
                    actionref("Re&open_Promoted"; Reopen)
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
            group(Category_Category5)
            {
                Caption = 'Warehouse', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Create Warehouse Pick_Promoted"; "Create Warehouse Pick")
                {
                }
                actionref("Create Inventor&y Movement_Promoted"; "Create Inventor&y Movement")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 6.';
                actionref("Item Tracking Lines_Promoted"; "Item Tracking Lines")
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
        SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    var
        FAItem: Record "FA Item";
    begin
        SetControlVisibility();
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := FAItem.IsVariantMandatory(true, Rec."FA Item No.");
    end;

    trigger OnOpenPage()
    begin
        Rec.UpdateWarningOnLines();
    end;

    var
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        CanCancelApprovalForRecord: Boolean;
        VariantCodeMandatory: Boolean;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);

        WorkflowWebhookMgt.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow)
    end;

    local procedure ShowPreview()
    var
        ConversionPostYesNo: Codeunit "Conversion-Post (Yes/No)";
    begin
        ConversionPostYesNo.Preview(Rec);
    end;
}