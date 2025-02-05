namespace TSTChanges.FA.History;

using System.Automation;
using TSTChanges.FA.Posting;
using System.Environment;

page 51212 "Posted Conversion Order"
{
    Caption = 'Posted Conversion Order';
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Posted Conversion Header";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the conversion order that the posted conversion order line originates from.';
                }
                field("FA Item No."; Rec."FA Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted conversion item.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the posted conversion item.';
                }
                group(Control8)
                {
                    ShowCaption = false;
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies how many units of the conversion item were posted with this posted conversion order.';
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the conversion order was posted.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which the posted conversion order started.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the posted conversion order finished, which means the date on which all conversion items were output.';
                }
            }
            part(Lines; "Posted conversion Ord Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies to which location the conversion item was output from this posted conversion order header.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Item &Tracking Lines")
            {
                ApplicationArea = ItemTracking;
                Caption = 'Item &Tracking Lines';
                Image = ItemTrackingLines;
                ShortCutKey = 'Ctrl+Alt+I';
                ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                trigger OnAction()
                begin
                    Rec.ShowItemTrackingLines();
                end;
            }
            action(Approvals)
            {
                Caption = 'Approvals';
                ApplicationArea = All;
                Image = Approvals;
                ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    ApprovalsMgmt.ShowPostedApprovalEntries(rec.RecordId);
                end;
            }
        }
        area(Processing)
        {
            action(Navigate)
            {
                ApplicationArea = Assembly;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Undo Post")
            {
                ApplicationArea = Assembly;
                Caption = 'Undo Conversion';
                Enabled = UndoPostEnabledExpr;
                Image = Undo;
                ToolTip = 'Cancel the posting of the assembly order. A set of corrective item ledger entries is created to reverse the original entries. Each positive output entry for the assembly item is reversed by a negative output entry. Each negative consumption entry for an assembly component is reversed by a positive consumption entry. Fixed cost application is automatically created between the corrective and original entries to ensure exact cost reversal.';

                trigger OnAction()
                var
                    EnvInfo: Codeunit "Environment Information";
                begin
                    if EnvInfo.IsProduction() then
                        Message('Under Development')
                    else
                        CODEUNIT.Run(CODEUNIT::"Pstd. Conversion-Undo (Yes/No)", Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                // actionref(Print_Promoted; Print)
                // {
                // }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref("Undo Post_Promoted"; "Undo Post")
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category4)
            {
                Caption = 'Conversion Order', Comment = 'Generated from the PromotedActionCategories property index 3.';

                // actionref(Dimensions_Promoted; Dimensions)
                // {
                // }
                // actionref(Statistics_Promoted; Statistics)
                // {
                // }
                // actionref(Comments_Promoted; Comments)
                // {
                // }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UndoPostEnabledExpr := not Rec.Reversed;// and not Rec.IsAsmToOrder();
    end;

    var
        UndoPostEnabledExpr: Boolean;
}