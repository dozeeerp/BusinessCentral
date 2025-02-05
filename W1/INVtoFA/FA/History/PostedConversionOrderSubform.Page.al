namespace TSTChanges.FA.History;

page 51213 "Posted conversion Ord Subform"
{
    Caption = 'Posted Conversion Order Subform';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Posted Conversion Line";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the assembly order line that the posted assembly order line originates from.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the posted assembly order line is of type Item or Resource.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly component on the posted assembly line.';
                }
                // field("Description 2"; Rec."Description 2")
                // {
                //     ApplicationArea = Assembly;
                //     ToolTip = 'Specifies the second description of the assembly component on the posted assembly line.';
                //     Visible = false;
                // }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies from which location the assembly component was consumed on this posted assembly order line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component were posted as consumed by the posted assembly order line.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are required to assemble one assembly item.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies from which bin the assembly component was consumed on the posted assembly order line.';
                    Visible = false;
                }
                field("Inventory Posting Group"; Rec."Inventory Posting Group")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of the posted assembly order line.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity per unit of measure of the component item on the posted assembly order line.';
                }
                field("Resource Usage Type"; Rec."Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how the cost of the resource on the posted assembly order line is allocated to the assembly item.';
                }
                // field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                // {
                //     ApplicationArea = Dimensions;
                //     ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                //     Visible = DimVisible1;
                // }
                // field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                // {
                //     ApplicationArea = Dimensions;
                //     ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                //     Visible = DimVisible2;
                // }
                // field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                // {
                //     ApplicationArea = Dimensions;
                //     CaptionClass = '1,2,3';
                //     TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                //                                                   "Dimension Value Type" = const(Standard),
                //                                                   Blocked = const(false));
                //     Visible = DimVisible3;
                // }
                // field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                // {
                //     ApplicationArea = Dimensions;
                //     CaptionClass = '1,2,4';
                //     TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                //                                                   "Dimension Value Type" = const(Standard),
                //                                                   Blocked = const(false));
                //     Visible = DimVisible4;
                // }
                // field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                // {
                //     ApplicationArea = Dimensions;
                //     CaptionClass = '1,2,5';
                //     TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                //                                                   "Dimension Value Type" = const(Standard),
                //                                                   Blocked = const(false));
                //     Visible = DimVisible5;
                // }
                // field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                // {
                //     ApplicationArea = Dimensions;
                //     CaptionClass = '1,2,6';
                //     TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                //                                                   "Dimension Value Type" = const(Standard),
                //                                                   Blocked = const(false));
                //     Visible = DimVisible6;
                // }
                // field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                // {
                //     ApplicationArea = Dimensions;
                //     CaptionClass = '1,2,7';
                //     TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                //                                                   "Dimension Value Type" = const(Standard),
                //                                                   Blocked = const(false));
                //     Visible = DimVisible7;
                // }
                // field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                // {
                //     ApplicationArea = Dimensions;
                //     CaptionClass = '1,2,8';
                //     TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                //                                                   "Dimension Value Type" = const(Standard),
                //                                                   Blocked = const(false));
                //     Visible = DimVisible8;
                // }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;
}