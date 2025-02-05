namespace TSTChanges.FA.Conversion;

page 51208 "FA Conversion Lines"
{
    AutoSplitKey = true;
    Caption = 'FA Conversion Lines';
    Editable = false;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "FA Conversion Line";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                // field("Document Type"; Rec."Document Type")
                // {
                //     ApplicationArea = Assembly;
                //     ToolTip = 'Specifies the type of assembly document that the assembly order header represents in assemble-to-order scenarios.';
                // }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the assembly order header that the assembly order line refers to.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly order line is of type Item or Resource.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly component.';
                }
                // field("Description 2"; Rec."Description 2")
                // {
                //     ApplicationArea = Assembly;
                //     ToolTip = 'Specifies the second description of the assembly component.';
                //     Visible = false;
                // }
                // field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                // {
                //     ApplicationArea = Dimensions;
                //     ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                //     Visible = false;
                // }
                // field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                // {
                //     ApplicationArea = Dimensions;
                //     ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                //     Visible = false;
                // }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from which you want to post consumption of the assembly component.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin where assembly components must be placed prior to assembly and from where they are posted as consumed.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are required to assemble one assembly item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be consumed.';
                }
                field("Consumed Quantity"; Rec."Consumed Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component have been posted as consumed during the assembly.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component remain to be consumed during assembly.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly component must be available for consumption by the assembly order.';
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the assembly component have been reserved for this assembly order line.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity per unit of measure of the component item on the assembly order line.';
                }
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