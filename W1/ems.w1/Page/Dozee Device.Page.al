page 52105 "Dozee Device"
{
    PageType = Card;
    UsageCategory = None;
    SourceTable = "Dozee Device";
    DataCaptionFields = "Serial No.";
    Caption = 'Dozee Device';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Serial No. field.';
                }
                field("Item No"; Rec."Item No")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the Item no (SKU)';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Item Description field.';
                }
                field(Variant; Rec.Variant)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Variant field.';
                }
            }
            group(GroupName)
            {
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Source Type field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Visible = false;
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
                    Importance = Additional;
                    Caption = 'Organisation ID';
                    ToolTip = 'Specifies the value of the Org ID field.';
                }
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License No. field.';
                }
                field("Device ID"; Rec."Device ID")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID used by sanes.';
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Installation Date field.';
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warranty End Date field.';
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
                field(Return; Rec.Return)
                {
                    ApplicationArea = All;
                    Editable = not rec.Licensed;
                    ToolTip = 'The device is returned to Warehouse.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            // action(ActionName)
            // {
            //     ApplicationArea = All;
            //     ToolTip = 'Executes the ActionName action.';

            //     trigger OnAction()
            //     begin
            //     end;
            // }
        }
    }
}
