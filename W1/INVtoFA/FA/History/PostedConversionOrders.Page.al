namespace TSTChanges.FA.History;

page 51211 "Posted Conversion Orders"
{
    Caption = 'Posted Conversion Orders';
    PageType = List;
    ApplicationArea = All;
    DataCaptionFields = "No.";
    Editable = false;
    CardPageId = "Posted Conversion Order";
    SourceTable = "Posted Conversion Header";
    SourceTableView = sorting("Posting Date")
                      order(Descending);
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the assembly order that the posted assembly order line originates from.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the posted assembly item.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the assembly order was posted.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which the posted assembly order started.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the posted assembly order finished, which means the date on which all assembly items were output.';
                }
                field("Item No."; Rec."FA Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted assembly item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item were posted with this posted assembly order.';
                }
                // field("Unit Cost"; Rec."Unit Cost")
                // {
                //     ApplicationArea = Assembly;
                //     ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                // }
            }
        }
        area(Factboxes)
        {
            systempart(Control11; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control12; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Line)
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = All;
                    Caption = '&Show Document';
                    Image = View;
                    RunObject = Page "Posted Conversion Order";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';
                }
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Navigate_Promoted; Navigate)
                { }
                actionref("Show Document_Promoted"; "Show Document")
                {
                }
            }
        }
    }
}