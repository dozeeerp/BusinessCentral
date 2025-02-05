namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Item;

page 51206 "FA Conversion Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "FA Conversion Line";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Avail. Warning"; Rec."Avail. Warning")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    DrillDown = true;
                    ToolTip = 'Specifies Yes if the assembly component is not available in the quantity and on the due date of the assembly order line.';

                    trigger OnDrillDown()
                    begin
                        // Rec.ShowAvailabilityWarningPage();
                    end;
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

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        // Rec.ShowShortcutDimCode(ShortcutDimCode);
                        ReserveItem();
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly component.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        ReserveItem();
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location from which you want to post consumption of the assembly component.';

                    trigger OnValidate()
                    begin
                        // Rec.ShowShortcutDimCode(ShortcutDimCode);
                        ReserveItem();
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        ReserveItem();
                    end;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are required to assemble one assembly item.';

                    trigger OnValidate()
                    begin
                        ReserveItem();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be consumed.';

                    trigger OnValidate()
                    begin
                        ReserveItem();
                    end;
                }
                field("Quantity to Consume"; Rec."Quantity to Consume")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly component you want to post as consumed when you post the assembly order.';
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
                field("Qty. Picked"; Rec."Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the assembly component have been moved or picked for the assembly order line.';
                    Visible = false;
                }
                field("Pick Qty."; Rec."Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the assembly component are currently on warehouse pick lines.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly component must be available for consumption by the assembly order.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ReserveItem();
                    end;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin where assembly components must be placed prior to assembly and from where they are posted as consumed.';
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
                    ToolTip = 'Specifies the cost of the assembly order line.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies how many units of the assembly component have been reserved for this assembly order line.';
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the reserve option for the assembly order line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ReserveItem();
                    end;
                }
                field(ReservationStatusField; ReservationStatusField)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Status';
                    Editable = false;
                    OptionCaption = ' ,Partial,Full';
                    ToolTip = 'Specifies if the value in the Quantity field on the assembly order line is fully or partially reserved.';
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the quantity per unit of measure of the component item on the assembly order line.';
                }
                field("Resource Usage Type"; Rec."Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how the cost of the resource on the assembly order line is allocated to the assembly item.';
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                }
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            // ItemAvailFormsMgt.ShowItemAvailFromAsmLine(Rec, ItemAvailFormsMgt.ByEvent());
                        end;
                    }
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
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
                action("Show Warning")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Warning';
                    Image = ShowWarning;
                    ToolTip = 'View details about availability issues.';

                    trigger OnAction()
                    begin
                        // Rec.ShowAvailabilityWarning();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SelectItemSubstitution)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Select Item Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowItemSub();
                        CurrPage.Update(true);
                        if (Rec.Reserve = Rec.Reserve::Always) and (Rec."No." <> xRec."No.") then begin
                            Rec.AutoReserve();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action("Reserve Item")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Ellipsis = true;
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservation();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record "Item";
    begin
        // Rec.ShowShortcutDimCode(ShortcutDimCode);
        ReservationStatusField := Rec.ReservationStatus();
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ConversionLineReserve: Codeunit "Conversion Line-Reserve";
    begin
        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            Commit();
            if not ConversionLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            ConversionLineReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        //     Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        //     SetDimensionsVisibility();
    end;

    var
        ReservationStatusField: Option " ",Partial,Full;
        VariantCodeMandatory: Boolean;

    protected procedure ReserveItem()
    begin
        if Rec.Type <> Rec.Type::Item then
            exit;

        if (Rec."Remaining Quantity (Base)" <> xRec."Remaining Quantity (Base)") or
           (Rec."No." <> xRec."No.") or
           (Rec."Location Code" <> xRec."Location Code") or
           (Rec."Variant Code" <> xRec."Variant Code") or
           (Rec."Due Date" <> xRec."Due Date") or
           ((Rec.Reserve <> xRec.Reserve) and (Rec."Remaining Quantity (Base)" <> 0))
        then
            if Rec.Reserve = Rec.Reserve::Always then begin
                CurrPage.SaveRecord();
                Rec.AutoReserve();
                CurrPage.Update(false);
            end;

        ReservationStatusField := Rec.ReservationStatus();
    end;
}