namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Ledger;
using TSTChanges.FA.Posting;
using TSTChanges.FA.Ledger;

page 51204 "FA Conversion Orders"
{
    Caption = 'FA Conversion Orders';
    CardPageId = "FA Conversion Order";
    DataCaptionFields = "No.";
    Editable = false;
    RefreshOnActivate = true;
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "FA Conversion Header";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("FA Item No."; Rec."FA Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(navigation)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                group(Entries)
                {
                    Caption = 'Entries';
                    Image = Entries;
                    action("FA Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Item Ledger E&ntries';
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
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = const(Conversion),
                                      "Order No." = field("No.");
                        RunPageView = sorting("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
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
                        CODEUNIT.Run(CODEUNIT::"Conversion-Post (Yes/No)", Rec);
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
        }
        area(Promoted)
        {
            group(Category_Release)
            {
                Caption = 'Release';
                ShowAs = SplitButton;

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';
                ShowAs = SplitButton;

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Preview Posting_Promoted"; PreviewPosting)
                {
                }
            }
        }
    }

    local procedure ShowPreview()
    var
        ConversionPostYesNo: Codeunit "Conversion-Post (Yes/No)";
    begin
        ConversionPostYesNo.Preview(Rec);
    end;
}