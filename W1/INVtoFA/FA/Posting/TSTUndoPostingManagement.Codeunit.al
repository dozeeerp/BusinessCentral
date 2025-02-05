namespace TSTChanges.FA.Posting;

using TSTChanges.FA.Transfer;
using TSTChanges.FA.Ledger;
using Microsoft.Warehouse.Activity;
using TSTChanges.FA.Conversion;
using TSTChanges.FA.History;
using Microsoft.Sales.History;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Ledger;
using TSTChanges.FA.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.Enums;
using TSTChanges.FA.FAItem;
using TSTChanges.FA.Tracking;

codeunit 51231 "TST Undo Posting Management"
{
    trigger OnRun()
    begin

    end;

    var
        ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
        Text001: Label 'You cannot undo line %1 because there is not sufficient content in the receiving bins.';
        Text002: Label 'You cannot undo line %1 because warehouse put-away lines have already been created.';
        Text003: Label 'You cannot undo line %1 because warehouse activity lines have already been created.';
        Text004: Label 'You must delete the related %1 before you undo line %2.';
        Text005: Label 'You cannot undo line %1 because warehouse receipt lines have already been created.';
        Text006: Label 'You cannot undo line %1 because warehouse shipment lines have already been created.';
        Text007: Label 'The items have been picked. If you undo line %1, the items will remain in the shipping area until you put them away.\Do you still want to undo the shipment?';
        Text008: Label 'You cannot undo line %1 because warehouse worksheet lines exist for this line.';
        Text009: Label 'You cannot undo line %1 because warehouse put-away lines have already been posted.';
        Text010: Label 'You cannot undo line %1 because inventory pick lines have already been posted.';
        Text013: Label 'Item ledger entries are missing for line %1.';
        Text015: Label 'You cannot undo posting of item %1 with variant ''%2'' and unit of measure %3 because it is not available at location %4, bin code %5. The required quantity is %6. The available quantity is %7.';
        NonSurplusResEntriesErr: Label 'You cannot undo transfer shipment line %1 because this line is Reserved. Reservation Entry No. %2', Comment = '%1 = Line No., %2 = Entry No.';

    procedure TestFATransferShptLine(FATransferShptLine: Record "FA Transfer Shipment Line")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestTransferShptLine(TransferShptLine, IsHandled);
        // if IsHandled then
        //     exit;

        TestAllTransactions(
            DATABASE::"FA Transfer Shipment Line", FATransferShptLine."Document No.", FATransferShptLine."Line No.",
            DATABASE::"FA Transfer Line", 0, FATransferShptLine."Transfer Order No.", FATransferShptLine."Line No.");
    end;

    procedure TestConHeader(PostedConHeader: Record "Posted Conversion Header")
    var
        ConHeader: Record "FA Conversion Header";
    begin
        // with PostedAsmHeader do
        TestAllTransactions(
            DATABASE::"Posted Conversion Header", PostedConHeader."No.", 0,
            DATABASE::"FA Conversion Header", 0, PostedConHeader."Order No.", 0);
    end;

    procedure TestConLine(PostedConLine: Record "Posted Conversion Line")
    var
        ConLine: Record "FA Conversion Line";
    begin
        // with PostedAsmLine do
        TestAllTransactions(
            DATABASE::"Posted Conversion Line", PostedConLine."Document No.", PostedConLine."Line No.",
            DATABASE::"FA Conversion Line", 0, PostedConLine."Order No.", PostedConLine."Order Line No.");
    end;

    local procedure TestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        if not TestPostedWhseReceiptLine(
             UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then begin
            TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        end;

        TestPostedWhseShipmentLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPutAwayLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPickLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
    end;

    local procedure TestPostedWhseReceiptLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer): Boolean
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedConHeader: Record "Posted Conversion Header";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
    begin
        case UndoType of
            DATABASE::"Posted Conversion Line":
                begin
                    TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
                    exit(true);
                end;
            DATABASE::"Posted Conversion Header":
                begin
                    PostedConHeader.Get(UndoID);
                    // if not PostedConHeader.IsAsmToOrder() then
                    TestWarehouseBinContent(SourceType, SourceSubtype, SourceID, SourceRefNo, PostedConHeader."Quantity (Base)");
                    exit(true);
                end;
        end;

        if not WhseUndoQty.FindPostedWhseRcptLine(
             PostedWhseReceiptLine, UndoType, UndoID, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then
            exit(false);

        TestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine);
        TestWarehouseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestRgstrdWhseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestWhseWorksheetLine2(UndoLineNo, PostedWhseReceiptLine);
        exit(true);
    end;

    local procedure TestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine, IsHandled);
        // if IsHandled then
        //     exit;

        // with WarehouseEntry do begin
        if PostedWhseReceiptLine."Location Code" = '' then
            exit;
        Location.Get(PostedWhseReceiptLine."Location Code");
        if Location."Bin Mandatory" then begin
            WarehouseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
            WarehouseEntry.SetRange("Item No.", PostedWhseReceiptLine."Item No.");
            WarehouseEntry.SetRange("Location Code", PostedWhseReceiptLine."Location Code");
            WarehouseEntry.SetRange("Variant Code", PostedWhseReceiptLine."Variant Code");
            if Location."Directed Put-away and Pick" then
                WarehouseEntry.SetFilter("Bin Type Code", GetBinTypeFilter(0)); // Receiving area
                                                                                // OnTestWarehouseEntryOnAfterSetFilters(WarehouseEntry, PostedWhseReceiptLine);
            WarehouseEntry.CalcSums("Qty. (Base)");
            if WarehouseEntry."Qty. (Base)" < PostedWhseReceiptLine."Qty. (Base)" then
                Error(Text001, UndoLineNo);
        end;
        // end;
    end;

    local procedure TestWarehouseBinContent(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; UndoQtyBase: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        QtyAvailToTake: Decimal;
    begin
        // with WhseEntry do begin
        WhseEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WhseEntry.FindFirst() then
            exit;

        BinContent.Get(WhseEntry."Location Code", WhseEntry."Bin Code", WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Unit of Measure Code");
        QtyAvailToTake := BinContent.CalcQtyAvailToTake(0);
        if QtyAvailToTake < UndoQtyBase then
            Error(Text015,
              WhseEntry."Item No.",
              WhseEntry."Variant Code",
              WhseEntry."Unit of Measure Code",
              WhseEntry."Location Code",
              WhseEntry."Bin Code",
              UndoQtyBase,
              QtyAvailToTake);
        // end;
    end;

    local procedure TestWarehouseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestWarehouseActivityLine2(WarehouseActivityLine, IsHandled);
        // if IsHandled then
        //     exit;

        // with WarehouseActivityLine do begin
        WarehouseActivityLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
        WarehouseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Receipt);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not WarehouseActivityLine.IsEmpty() then
            Error(Text002, UndoLineNo);
        // end;
    end;

    local procedure TestRgstrdWhseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestRgstrdWhseActivityLine2(PostedWhseReceiptLine, IsHandled);
        // if IsHandled then
        //     exit;

        // with RegisteredWhseActivityLine do begin
        RegisteredWhseActivityLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document Type", RegisteredWhseActivityLine."Whse. Document Type"::Receipt);
        RegisteredWhseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not RegisteredWhseActivityLine.IsEmpty() then
            Error(Text003, UndoLineNo);
        // end;
    end;

    local procedure TestWhseWorksheetLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // with WhseWorksheetLine do begin
        WhseWorksheetLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Receipt);
        WhseWorksheetLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not WhseWorksheetLine.IsEmpty() then
            Error(Text004, WhseWorksheetLine.TableCaption(), UndoLineNo);
        // end;
    end;

    local procedure TestWarehouseActivityLine(UndoType: Integer; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        // if IsHandled then
        //     exit;

        // with WarehouseActivityLine do begin
        WarehouseActivityLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
        if not WarehouseActivityLine.IsEmpty() then begin
            if UndoType = DATABASE::"FA Conversion Line" then
                Error(Text002, UndoLineNo);
            Error(Text003, UndoLineNo);
        end;
        // end;
    end;

    local procedure TestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        // if IsHandled then
        //     exit;

        // with RegisteredWhseActivityLine do begin
        RegisteredWhseActivityLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::"Put-away");
        if not RegisteredWhseActivityLine.IsEmpty() then
            Error(Text002, UndoLineNo);
        // end;
    end;

    local procedure TestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        // if IsHandled then
        //     exit;

        // with WarehouseReceiptLine do begin
        WhseManagement.SetSourceFilterForWhseRcptLine(WarehouseReceiptLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WarehouseReceiptLine.IsEmpty() then
            Error(Text005, UndoLineNo);
        // end;
    end;

    local procedure TestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        // if IsHandled then
        //     exit;

        // with WarehouseShipmentLine do begin
        WarehouseShipmentLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WarehouseShipmentLine.IsEmpty() then
            Error(Text006, UndoLineNo);
        // end;
    end;

    local procedure TestPostedWhseShipmentLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestPostedWhseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled, UndoType, UndoID);
        // if IsHandled then
        //     exit;

        // with PostedWhseShipmentLine do begin
        WhseManagement.SetSourceFilterForPostedWhseShptLine(PostedWhseShipmentLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedWhseShipmentLine.IsEmpty() then
            if not Confirm(Text007, true, UndoLineNo) then
                Error('');
        // end;
    end;

    local procedure TestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        // if IsHandled then
        //     exit;

        // with WhseWorksheetLine do begin
        WhseWorksheetLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WhseWorksheetLine.IsEmpty() then
            Error(Text008, UndoLineNo);
        // end;
    end;

    local procedure TestPostedInvtPutAwayLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestPostedInvtPutAwayLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled, UndoType, UndoID);
        // if IsHandled then
        //     exit;

        // with PostedInvtPutAwayLine do begin
        PostedInvtPutAwayLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedInvtPutAwayLine.IsEmpty() then
            Error(Text009, UndoLineNo);
        // end;
    end;

    local procedure TestPostedInvtPickLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestPostedInvtPickLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled, UndoType, UndoID);
        // if IsHandled then
        //     exit;

        // with PostedInvtPickLine do begin
        PostedInvtPickLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if ShouldThrowErrorForPostedInvtPickLine(PostedInvtPickLine, UndoType, UndoID) then
            Error(Text010, UndoLineNo);
        // end;
    end;

    local procedure ShouldThrowErrorForPostedInvtPickLine(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; UndoType: Integer; UndoID: Code[20]): Boolean
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        CheckedPostedInvtPickHeaderList: List of [Text];
    begin
        if PostedInvtPickLine.IsEmpty() then
            exit(false);

        if not (UndoType in [Database::"Sales Shipment Line"]) then
            exit(true);

        PostedInvtPickLine.SetLoadFields("No.");
        if PostedInvtPickLine.FindSet() then
            repeat
                if not CheckedPostedInvtPickHeaderList.Contains(PostedInvtPickLine."No.") then begin
                    CheckedPostedInvtPickHeaderList.Add(PostedInvtPickLine."No.");

                    PostedInvtPickHeader.SetLoadFields("Source Type", "Source No.");
                    if not PostedInvtPickHeader.Get(PostedInvtPickLine."No.") then
                        exit(true);

                    case UndoType of
                        Database::"Sales Shipment Line":
                            begin
                                if PostedInvtPickHeader."Source Type" <> Database::"Sales Shipment Header" then
                                    exit(true);

                                if PostedInvtPickHeader."Source No." = UndoID then
                                    exit(true);
                            end;
                        else
                            exit(true);
                    end;
                end;
            until PostedInvtPickLine.Next() = 0;

        exit(false);
    end;

    local procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick): Text[1024]
    var
        BinType: Record "Bin Type";
        "Filter": Text[1024];
    begin
        // with BinType do begin
        case Type of
            Type::Receive:
                BinType.SetRange(Receive, true);
            Type::Ship:
                BinType.SetRange(Ship, true);
            Type::"Put Away":
                BinType.SetRange("Put Away", true);
            Type::Pick:
                BinType.SetRange(Pick, true);
        end;
        if BinType.Find('-') then
            repeat
                Filter := StrSubstNo('%1|%2', Filter, BinType.Code);
            until BinType.Next() = 0;
        if Filter <> '' then
            Filter := CopyStr(Filter, 2);
        // end;
        exit(Filter);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "FA Item Ledger Entry" temporary; LineRef: Integer)
    begin
        CheckItemLedgEntries(TempItemLedgEntry, LineRef, false);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "FA Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean)
    var
        ItemRec: Record "FA Item";
    begin
        TempItemLedgEntry.Find('-'); // Assertion: will fail if not found.
        ItemRec.Get(TempItemLedgEntry."FA Item No.");
        if ItemRec.IsNonInventoriableType() then
            exit;
        repeat
            // IsHandled := false;
            // OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(TempItemLedgEntry, IsHandled);
            // if not IsHandled then
            if TempItemLedgEntry.Positive then begin
                // if ("Job No." = '') and
                // not (("Order Type" = "Order Type"::Assembly) and
                //         PostedATOLink.Get(PostedATOLink."Assembly Document Type"::Assembly, "Document No."))
                // then
                //     if InvoicedEntry then
                //         TestField("Remaining Quantity", Quantity - "Invoiced Quantity")
                // else
                TempItemLedgEntry.TestField("Remaining Quantity", TempItemLedgEntry.Quantity);
            end else
                if TempItemLedgEntry."Entry Type" <> TempItemLedgEntry."Entry Type"::Transfer then
                    if InvoicedEntry then
                        TempItemLedgEntry.TestField("Shipped Qty. Not Returned", TempItemLedgEntry.Quantity - TempItemLedgEntry."Invoiced Quantity")
                    else
                        TempItemLedgEntry.TestField("Shipped Qty. Not Returned", TempItemLedgEntry.Quantity);

            TempItemLedgEntry.CalcFields("Reserved Quantity");
            TempItemLedgEntry.TestField("Reserved Quantity", 0);

        // TempItemLedgEntry.CheckValueEntries(TempItemLedgEntry, LineRef, InvoicedEntry);

        // if ItemRec."Costing Method" = ItemRec."Costing Method"::Specific then
        //     TempItemLedgEntry.TestField("Serial No.");
        until TempItemLedgEntry.Next() = 0;
    end;

    procedure CollectItemLedgEntries(var TempItemLedgEntry: Record "FA Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal; EntryRef: Integer)
    var
        ItemLedgEntry: Record "FA Item ledger Entry";
    begin
        TempItemLedgEntry.Reset();
        if not TempItemLedgEntry.IsEmpty() then
            TempItemLedgEntry.DeleteAll();
        if EntryRef <> 0 then begin
            ItemLedgEntry.Get(EntryRef); // Assertion: will fail if no entry exists.
            TempItemLedgEntry := ItemLedgEntry;
            TempItemLedgEntry.Insert();
        end else begin
            if SourceType in [//DATABASE::"Sales Shipment Line",
                              //   DATABASE::"Return Shipment Line",
                              //   DATABASE::"Service Shipment Line",
                              DATABASE::"Posted Conversion Line",
                              DATABASE::"FA Transfer Shipment Line"]
            then
                BaseQty := BaseQty * -1;
            CheckMissingItemLedgers(TempItemLedgEntry, SourceType, DocumentNo, LineNo, BaseQty);
        end;
    end;

    local procedure CheckMissingItemLedgers(var TempItemLedgEntry: Record "FA Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal)
    var
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckMissingItemLedgers(TempItemLedgEntry, SourceType, DocumentNo, LineNo, BaseQty, IsHandled);
        // if IsHandled then
        //     exit;

        if not ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry, SourceType, 0, DocumentNo, '', 0, LineNo, BaseQty) then
            Error(Text013, LineNo);
    end;

    internal procedure UpdateDerivedTransferLine(var TransferLine: Record "FA Transfer Line"; var TransferShptLine: Record "FA Transfer Shipment Line")
    var
        DerivedTransferLine: Record "FA Transfer Line";
        TransferShipmentLine: Record "FA Transfer Shipment Line";
    begin
        // Find the derived line
        DerivedTransferLine.SetRange("Document No.", TransferShptLine."Transfer Order No.");
        DerivedTransferLine.SetRange("Line No.", TransferShptLine."Derived Trans. Order Line No.");
        DerivedTransferLine.FindFirst();
        DerivedTransferLine.TestField("Derived From Line No.", TransferLine."Line No.");

        // Move tracking information from the derived line to the original line
        TransferTracking(DerivedTransferLine, TransferLine, TransferShptLine);

        // Update any Transfer Shipment Lines that are pointing to this Derived Transfer Order Line
        TransferShipmentLine.SetRange("Transfer Order No.", DerivedTransferLine."Document No.");
        TransferShipmentLine.SetRange("Derived Trans. Order Line No.", DerivedTransferLine."Line No.");
        if TransferShipmentLine.FindSet() then
            TransferShipmentLine.ModifyAll("Derived Trans. Order Line No.", 0);

        // Reload the TransShptLine now that it has changed
        TransferShptLine.Get(TransferShptLine."Document No.", TransferShptLine."Line No.");

        // Delete the derived line - a new one gets created for each shipment
        DerivedTransferLine.Delete();
    end;

    local procedure TransferTracking(var FromTransLine: Record "FA Transfer Line"; var ToTransLine: Record "FA Transfer Line"; var TransferShptLine: Record "FA Transfer Shipment Line")
    var
        ReservationEntry: Record "FA Reservation Entry";
        ReserveTransLine: Codeunit "FA Transfer Line-Reserve";
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        FromReservationEntryRowID: Text[250];
        ToReservationEntryRowID: Text[250];
        TransferQty: Decimal;
    begin
        TransferQty := FromTransLine.Quantity;
        ReserveTransLine.FindReservEntrySet(FromTransLine, ReservationEntry, "Transfer Direction"::Inbound);
        if ReservationEntry.IsEmpty() then
            exit;

        CheckReservationEntryStatus(ReservationEntry, TransferShptLine);

        FromReservationEntryRowID := ItemTrackingMgt.ComposeRowID( // From invisible TransferLine holding tracking
                    DATABASE::"FA Transfer Line", 1, ReservationEntry."Source ID", '', ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
        ToReservationEntryRowID := ItemTrackingMgt.ComposeRowID( // To original TransferLine
              DATABASE::"FA Transfer Line", 0, ReservationEntry."Source ID", '', 0, ReservationEntry."Source Prod. Order Line");

        ToTransLine.TestField("Variant Code", FromTransLine."Variant Code");

        // Recreate reservation entries on from-location which were deleted on posting shipment
        ItemTrackingMgt.CopyItemTracking(FromReservationEntryRowID, ToReservationEntryRowID, true); // Switch sign on quantities

        if not ReservationEntry.IsEmpty() then
            repeat
                ReservationEntry.TestItemFields(FromTransLine."FA Item No.", FromTransLine."Variant Code", FromTransLine."Transfer-to Code");
                UpdateTransferQuantity(TransferQty, ToTransLine, ReservationEntry);
            until (ReservationEntry.Next() = 0) or (TransferQty = 0);
    end;

    local procedure CheckReservationEntryStatus(var ReservationEntry: Record "FA Reservation Entry"; var TransferShipmentLine: Record "FA Transfer Shipment Line")
    begin
        ReservationEntry.SetFilter("Reservation Status", '<>%1', "Reservation Status"::Surplus);
        if ReservationEntry.FindFirst() then
            Error(NonSurplusResEntriesErr, TransferShipmentLine."Line No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange("Reservation Status");
        ReservationEntry.FindSet();
    end;

    local procedure UpdateTransferQuantity(var TransferQty: Decimal; var NewTransLine: Record "FA Transfer Line"; var OldReservEntry: Record "FA Reservation Entry")
    var
        CreateReservEntry: Codeunit "FA Create Reserv. Entry";
    begin
        TransferQty :=
            CreateReservEntry.TransferReservEntry(DATABASE::"FA Transfer Line",
            "Transfer Direction"::Inbound.AsInteger(), NewTransLine."Document No.", '', NewTransLine."Derived From Line No.",
            NewTransLine."Line No.", NewTransLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);
    end;

    procedure UpdateTransLine(TransferLine: Record "FA Transfer Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "FA Item Ledger Entry" temporary)
    var
        xTransferLine: Record "FA Transfer Line";
        SalesSetup: Record "Sales & Receivables Setup";
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateTransLine(TransferLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
        // if IsHandled then
        //     exit;

        SalesSetup.Get();
        xTransferLine := TransferLine;
        TransferLine."Quantity Shipped" := TransferLine."Quantity Shipped" - UndoQty;
        TransferLine."Qty. Shipped (Base)" := TransferLine."Qty. Shipped (Base)" - UndoQtyBase;
        TransferLine."Qty. to Receive" := Maximum(TransferLine."Qty. to Receive" - UndoQty, 0);
        TransferLine."Qty. to Receive (Base)" := Maximum(TransferLine."Qty. to Receive (Base)" - UndoQtyBase, 0);
        TransferLine.InitOutstandingQty();
        TransferLine.InitQtyToShip();
        TransferLine.InitQtyInTransit();

        TransferLine.Modify();
        xTransferLine."Quantity (Base)" := 0;
        TransferLineReserveVerifyQuantity(TransferLine, xTransferLine);

        UpdateWarehouseRequest(DATABASE::"FA Transfer Line", Direction::Outbound.AsInteger(), TransferLine."Document No.", TransferLine."Transfer-from Code");

        // OnAfterUpdateTransLine(TransferLine);
    end;

    local procedure TransferLineReserveVerifyQuantity(TransferLine: Record "FA Transfer Line"; xTransferLine: Record "FA Transfer Line")
    var
        TransferLineReserve: Codeunit "FA Transfer Line-Reserve";
    begin
        TransferLineReserve.VerifyQuantity(TransferLine, xTransferLine);
    end;

    local procedure UpdateWarehouseRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        // with WarehouseRequest do begin
        WarehouseRequest.SetSourceFilter(SourceType, SourceSubtype, SourceNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("Completely Handled", false);
        // end;
    end;

    local procedure Maximum(A: Decimal; B: Decimal): Decimal
    begin
        if A < B then
            exit(B);

        exit(A);
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "FA Item Journal Line"; var TempApplyToItemLedgEntry: Record "FA Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "FA Item Ledger Entry" temporary; var TempItemEntryRelation: Record "FA Item Entry Relation" temporary)
    begin
        PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToItemLedgEntry, UndoQty, UndoQtyBase, TempItemLedgEntry, TempItemEntryRelation, false);
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "FA Item Journal Line"; var TempApplyToItemLedgEntry: Record "FA Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "FA Item Ledger Entry" temporary; var TempItemEntryRelation: Record "FA Item Entry Relation" temporary; InvoicedEntry: Boolean)
    var
        ItemApplicationEntry: Record "FA Item Application Entry";
        NonDistrQuantity: Decimal;
        NonDistrQuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        if InvoicedEntry then begin
            TempApplyToItemLedgEntry.SetRange("Completely Invoiced", false);
            if AreAllItemEntriesCompletelyInvoiced(TempApplyToItemLedgEntry) then begin
                TempApplyToItemLedgEntry.SetRange("Completely Invoiced");
                exit;
            end;
        end;
        TempApplyToItemLedgEntry.Find('-'); // Assertion: will fail if not found.
                                            // if ItemJnlLine."Job No." = '' then
        ItemJnlLine.TestField(Correction, true);
        NonDistrQuantity := -UndoQty;
        NonDistrQuantityBase := -UndoQtyBase;
        repeat
            // if ItemJnlLine."Job No." = '' then
            ItemJnlLine."Applies-to Entry" := TempApplyToItemLedgEntry."Entry No.";
            // else
            // ItemJnlLine."Applies-to Entry" := 0;

            ItemJnlLine."Item Shpt. Entry No." := 0;
            ItemJnlLine."Quantity (Base)" := -TempApplyToItemLedgEntry.Quantity;
            ItemJnlLine."Invoiced Quantity" := -TempApplyToItemLedgEntry."Invoiced Quantity";
            ItemJnlLine.CopyTrackingFromItemLedgEntry(TempApplyToItemLedgEntry);
            if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then
                ItemJnlLine.CopyNewTrackingFromOldItemLedgerEntry(TempApplyToItemLedgEntry);

            // Quantity is filled in according to UOM:
            AdjustQuantityRounding(ItemJnlLine, NonDistrQuantity, NonDistrQuantityBase);

            NonDistrQuantity := NonDistrQuantity - ItemJnlLine.Quantity;
            NonDistrQuantityBase := NonDistrQuantityBase - ItemJnlLine."Quantity (Base)";

            // OnBeforePostItemJnlLine(ItemJnlLine, TempApplyToItemLedgEntry);
            PostItemJnlLine(ItemJnlLine);
            // OnPostItemJnlLineAppliedToListOnAfterPostItemJnlLine(ItemJnlLine, TempApplyToItemLedgEntry);

            // UndoValuePostingFromJob(ItemJnlLine, ItemApplicationEntry, TempApplyToItemLedgEntry);

            TempItemEntryRelation."Item Entry No." := ItemJnlLine."Item Shpt. Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemJnlLine(ItemJnlLine);
            // OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemJnlLine);
            TempItemEntryRelation.Insert();
            TempItemLedgEntry := TempApplyToItemLedgEntry;
            TempItemLedgEntry.Insert();
        until TempApplyToItemLedgEntry.Next() = 0;
    end;

    procedure AreAllItemEntriesCompletelyInvoiced(var TempApplyToItemLedgEntry: Record "FA Item Ledger Entry" temporary): Boolean
    var
        TempItemLedgerEntry: Record "FA Item Ledger Entry" temporary;
    begin
        TempItemLedgerEntry.Copy(TempApplyToItemLedgEntry, true);
        TempItemLedgerEntry.SetRange("Completely Invoiced", false);
        exit(TempItemLedgerEntry.IsEmpty());
    end;

    local procedure AdjustQuantityRounding(var ItemJnlLine: Record "FA Item Journal Line"; var NonDistrQuantity: Decimal; NonDistrQuantityBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeAdjustQuantityRounding(ItemJnlLine, NonDistrQuantity, NonDistrQuantityBase, IsHandled);
        // if IsHandled then
        //     exit;

        ItemTrackingMgt.AdjustQuantityRounding(
          NonDistrQuantity, ItemJnlLine.Quantity,
          NonDistrQuantityBase, ItemJnlLine."Quantity (Base)");
    end;

    procedure PostItemJnlLine(var ItemJnlLine: Record "FA Item Journal Line")
    var
        ItemJnlLine2: Record "FA Item Journal Line";
        PostJobConsumptionBeforePurch: Boolean;
        IsHandled: Boolean;
    begin
        Clear(ItemJnlLine2);
        ItemJnlLine2 := ItemJnlLine;

        // if ItemJnlLine2."Job No." <> '' then begin
        //     IsHandled := false;
        //     OnPostItemJnlLineOnBeforePostItemJnlLineForJob(ItemJnlLine2, IsHandled, ItemJnlLine, PostJobConsumptionBeforePurch);
        //     if not IsHandled then
        //         PostJobConsumptionBeforePurch := PostItemJnlLineForJob(ItemJnlLine, ItemJnlLine2);
        // end;

        ItemJnlPostLine.Run(ItemJnlLine);

        // IsHandled := false;
        // OnPostItemJnlLineOnBeforePostJobConsumption(ItemJnlLine2, IsHandled);
        // if not IsHandled then
        // if ItemJnlLine2."Job No." <> '' then
        // if not PostJobConsumptionBeforePurch then begin
        // SetItemJnlLineAppliesToEntry(ItemJnlLine2, ItemJnlLine."Item Shpt. Entry No.");
        // ItemJnlPostLine.Run(ItemJnlLine2);
        // end;
    end;
}