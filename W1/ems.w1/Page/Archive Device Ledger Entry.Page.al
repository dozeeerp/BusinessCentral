page 52106 "Archive Device Ledger Entry"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Archive Device Led. Entry";
    DataCaptionFields = "Serial No.";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Source Entry No."; Rec."Source Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Serial No. field.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item Description field.';
                }
                field(Variant; Rec.Variant)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant field.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source Type field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source No. field.';
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
                field("Partner No."; Rec."Partner No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Partner No. field.';
                }
                field("Org ID"; Rec."Org ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Org ID field.';
                }
                field("Item No"; Rec."Item No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No field.';
                }
                field("Device ID"; Rec."Device ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID used by sanes.';
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Installation Date field.';
                }
                field("Warranty Start Date"; Rec."Warranty Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warranty Start Date field.';
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warranty End Date field.';
                }
                field(Return; Rec.Return)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Return field.';
                }
                field(Licensed; Rec.Licensed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Licensed field.';
                }
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License No. field.';
                }
                field("Activation Date"; Rec."Activation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Activation Date field.';
                }
                field("Expiry Date"; Rec."Expiry Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Expiry Date field.';
                }
                field(Expired; Rec.Expired)
                {
                    ApplicationArea = All;
                }
                field(Terminated; Rec.Terminated)
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
