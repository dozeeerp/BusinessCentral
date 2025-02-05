namespace TSTChanges.FA.Transfer;

using Microsoft.Finance.Dimension;
using TSTChanges.FA.FAItem;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Location;

page 51219 "FA Transfer Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "FA Transfer Line";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."FA Item No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the item that will be transferred.';

                    trigger OnValidate()
                    begin
                        UpdateForm(true);
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Location;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the item that will be processed as the document stipulates.';
                }
                field("Reserved Quantity Inbnd."; Rec."Reserved Quantity Inbnd.")
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the item reserved at the transfer-to location.';
                }
                field("Reserved Quantity Shipped"; Rec."Reserved Quantity Shipped")
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units on the shipped transfer order are reserved.';
                }
                field("Reserved Quantity Outbnd."; Rec."Reserved Quantity Outbnd.")
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the item reserved at the transfer-from location.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Location;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = Location;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as shipped.';

                    trigger OnDrillDown()
                    var
                        TransShptLine: Record "FA Transfer Shipment Line";
                    begin
                        Rec.TestField("Document No.");
                        Rec.TestField("FA Item No.");
                        TransShptLine.SetCurrentKey("Transfer Order No.", "FA Item No.", "Shipment Date");
                        TransShptLine.SetRange("Transfer Order No.", Rec."Document No.");
                        TransShptLine.SetRange("Line No.", Rec."Line No.");
                        PAGE.RunModal(0, TransShptLine);
                    end;
                }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = Location;
                    BlankZero = true;
                    Editable = NOT Rec."Direct Transfer";
                    ToolTip = 'Specifies the quantity of items that remains to be received.';
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = Location;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as received.';

                    trigger OnDrillDown()
                    var
                        TransRcptLine: Record "FA Transfer Receipt Line";
                    begin
                        Rec.TestField("Document No.");
                        Rec.TestField("FA Item No.");
                        TransRcptLine.SetCurrentKey("Transfer Order No.", "Item No.", "Receipt Date");
                        TransRcptLine.SetRange("Transfer Order No.", Rec."Document No.");
                        TransRcptLine.SetRange("Line No.", Rec."Line No.");
                        PAGE.RunModal(0, TransRcptLine);
                    end;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the date that you expect the transfer-to location to receive the shipment.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectMultiItems)
            {
                AccessByPermission = TableData "FA Item" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Select items';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more items from the full list of your inventory items.';

                trigger OnAction()
                begin
                    Rec.SelectMultipleItems();
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        Rec.Find();
                        Rec.ShowReservation();
                    end;
                }
                action(ReserveFromInventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reserve from &Inventory';
                    Image = LineReserve;
                    ToolTip = 'Reserve items for the selected line from inventory.';

                    trigger OnAction()
                    begin
                        ReserveSelectedLines();
                    end;
                }
            }
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            // ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByEvent());
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            // ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByPeriod());
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            // ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByVariant());
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            // ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByLocation());
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        // RunObject = Page "Item Availability by Lot No.";
                        // RunPageLink = "No." = field("Item No."),
                        // "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    // action("BOM Level")
                    // {
                    //     ApplicationArea = Location;
                    //     Caption = 'BOM Level';
                    //     Image = BOMLevel;
                    //     ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    //     trigger OnAction()
                    //     begin
                    //         // ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByBOM());
                    //     end;
                    // }
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                group("Item &Tracking Lines")
                {
                    Caption = 'Item &Tracking Lines';
                    Image = AllLines;
                    action(Shipment)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Shipment';
                        Image = Shipment;
                        ShortCutKey = 'Ctrl+Alt+I';
                        ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                        trigger OnAction()
                        begin
                            Rec.OpenItemTrackingLines(Enum::"Transfer Direction"::Outbound);
                        end;
                    }
                    action(Receipt)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Receipt';
                        Image = Receipt;
                        ShortCutKey = 'Shift+Ctrl+R';
                        ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                        trigger OnAction()
                        begin
                            Rec.OpenItemTrackingLinesWithReclass(Enum::"Transfer Direction"::Inbound);
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        FATransferLineReserve: Codeunit "FA Transfer Line-Reserve";
    begin
        Commit();
        if not FATransferLineReserve.DeleteLineConfirm(Rec) then
            exit(false);
        FATransferLineReserve.DeleteLine(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
    end;

    var
        myInt: Integer;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    // procedure ExplodeBOM()
    // begin
    //     Codeunit.Run(Codeunit::"Transfer-Explode BOM", Rec);
    // end;

    local procedure ReserveSelectedLines()
    var
        FATransLine: Record "FA Transfer Line";
    begin
        CurrPage.SetSelectionFilter(FATransLine);
        Rec.ReserveFromInventory(FATransLine);
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;
}