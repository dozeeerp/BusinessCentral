namespace TSTChanges.FA.Transfer;

using TSTChanges.FA.Tracking;
using TSTChanges.FA.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;

codeunit 51220 "FA Transfer Line-Reserve"
{
    Permissions = TableData "FA Reservation Entry" = rimd,
                  TableData "Planning Assignment" = rimd;

    //     trigger OnRun()
    //     begin
    //     end;

    var
        FromTrackingSpecification: Record "FA Tracking Specification";
        ReservationManagement: Codeunit "FA Reservation Management";
        CreateReservEntry: Codeunit "FA Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "FA Reservation Engine Mgt.";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;

        Text000Err: Label 'Codeunit is not initialized correctly.';
        Text001Err: Label 'Reserved quantity cannot be greater than %1', Comment = '%1 - quantity';
        Text002Err: Label 'must be filled in when a quantity is reserved';
        Text003Err: Label 'must not be changed when a quantity is reserved';
        Text006Err: Label 'Outbound,Inbound';
        SummaryTypeTxt: Label '%1, %2', Locked = true;

    procedure CreateReservation(var TransferLine: Record "FA Transfer Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "FA Reservation Entry"; Direction: Enum "Transfer Direction")
    var
        ShipmentDate: Date;
    // IsHandled: Boolean;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text000Err);

        TransferLine.TestField("FA Item No.");
        TransferLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");

        case Direction of
            Direction::Outbound:
                begin
                    TransferLine.TestField("Shipment Date");
                    TransferLine.TestField("Transfer-from Code", FromTrackingSpecification."Location Code");
                    TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    if Abs(TransferLine."Outstanding Qty. (Base)") <
                       Abs(TransferLine."Reserved Qty. Outbnd. (Base)") + QuantityBase
                    then
                        Error(
                          Text001Err,
                          Abs(TransferLine."Outstanding Qty. (Base)") - Abs(TransferLine."Reserved Qty. Outbnd. (Base)"));
                    ShipmentDate := TransferLine."Shipment Date";
                end;
            Direction::Inbound:
                begin
                    TransferLine.TestField("Receipt Date");
                    TransferLine.TestField("Transfer-to Code", FromTrackingSpecification."Location Code");
                    TransferLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                    if Abs(TransferLine."Outstanding Qty. (Base)") <
                       Abs(TransferLine."Reserved Qty. Inbnd. (Base)") + QuantityBase
                    then
                        Error(
                          Text001Err,
                          Abs(TransferLine."Outstanding Qty. (Base)") - Abs(TransferLine."Reserved Qty. Inbnd. (Base)"));
                    ExpectedReceiptDate := TransferLine."Receipt Date";
                    ShipmentDate := GetInboundReservEntryShipmentDate();
                end;
        end;

        //         IsHandled := false;
        //         OnCreateReservationOnBeforeCreateReservEntry(TransferLine, Quantity, QuantityBase, ForReservationEntry, Direction, IsHandled);
        //         if not IsHandled then 
        begin
            CreateReservEntry.CreateReservEntryFor(
                Database::"FA Transfer Line", Direction.AsInteger(), TransferLine."Document No.", '',
                TransferLine."Derived From Line No.", TransferLine."Line No.", TransferLine."Qty. per Unit of Measure",
                Quantity, QuantityBase, ForReservationEntry);
            CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        end;
        CreateReservEntry.CreateReservEntry(
          TransferLine."FA Item No.", TransferLine."Variant Code", FromTrackingSpecification."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "FA Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    procedure Caption(FATransferLine: Record "FA Transfer Line") CaptionText: Text
    begin
        CaptionText := FATransferLine.GetSourceCaption();
    end;

    procedure FindReservEntry(FATransferLine: Record "FA Transfer Line"; var FAReservationEntry: Record "FA Reservation Entry"; Direction: Enum "Transfer Direction"): Boolean
    begin
        FAReservationEntry.InitSortingAndFilters(false);
        FATransferLine.SetReservationFilters(FAReservationEntry, Direction);
        exit(FAReservationEntry.FindLast());
    end;

    procedure FindReservEntrySet(TransferLine: Record "FA Transfer Line"; var ReservationEntry: Record "FA Reservation Entry"; Direction: Enum "Transfer Direction"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        TransferLine.SetReservationFilters(ReservationEntry, Direction);
        exit(ReservationEntry.FindSet());
    end;

    //     procedure FindInboundReservEntry(TransferLine: Record "Transfer Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    //     var
    //         DerivedTransferLine: Record "Transfer Line";
    //     begin
    //         ReservationEntry.InitSortingAndFilters(false);

    //         DerivedTransferLine.SetRange("Document No.", TransferLine."Document No.");
    //         DerivedTransferLine.SetRange("Derived From Line No.", TransferLine."Line No.");
    //         if not DerivedTransferLine.IsEmpty() then begin
    //             ReservationEntry.SetSourceFilter(
    //                 Database::"Transfer Line", Enum::"Transfer Direction"::Inbound.AsInteger(), TransferLine."Document No.", -1, false);
    //             ReservationEntry.SetSourceFilter('', TransferLine."Line No.");
    //         end else
    //             TransferLine.SetReservationFilters(ReservationEntry, Enum::"Transfer Direction"::Inbound);
    //         exit(ReservationEntry.FindLast());
    //     end;

    //     procedure GetReservedQtyFromInventory(TransferLine: Record "Transfer Line"): Decimal
    //     var
    //         ReservationEntry: Record "Reservation Entry";
    //         QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    //     begin
    //         TransferLine.SetReservationEntry(ReservationEntry, Enum::"Transfer Direction"::Outbound);
    //         QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
    //         QtyReservedFromItemLedger.Open();
    //         if QtyReservedFromItemLedger.Read() then
    //             exit(QtyReservedFromItemLedger.Quantity__Base_);

    //         exit(0);
    //     end;

    //     procedure GetReservedQtyFromInventory(TransferHeader: Record "Transfer Header"): Decimal
    //     var
    //         ReservationEntry: Record "Reservation Entry";
    //         QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
    //     begin
    //         ReservationEntry.SetSource(
    //             Database::"Transfer Line", Enum::"Transfer Direction"::Outbound.AsInteger(), TransferHeader."No.", 0, '', 0);
    //         QtyReservedFromItemLedger.SetSourceFilter(ReservationEntry);
    //         QtyReservedFromItemLedger.Open();
    //         if QtyReservedFromItemLedger.Read() then
    //             exit(QtyReservedFromItemLedger.Quantity__Base_);

    //         exit(0);
    //     end;

    procedure VerifyChange(var NewTransferLine: Record "FA Transfer Line"; var OldTransferLine: Record "FA Transfer Line")
    var
        TransferLine: Record "FA Transfer Line";
        ReservationEntry: Record "FA Reservation Entry";
        ShowErrorInbnd: Boolean;
        ShowErrorOutbnd: Boolean;
        HasErrorInbnd: Boolean;
        HasErrorOutbnd: Boolean;
    //         IsHandled: Boolean;
    begin
        //         IsHandled := false;
        //         OnBeforeVerifyChange(NewTransferLine, OldTransferLine, IsHandled);
        //         if IsHandled then
        //             exit;

        if Blocked then
            exit;
        if NewTransferLine."Line No." = 0 then
            if not TransferLine.Get(NewTransferLine."Document No.", NewTransferLine."Line No.") then
                exit;

        NewTransferLine.CalcFields("Reserved Qty. Inbnd. (Base)");
        NewTransferLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ShowErrorInbnd := (NewTransferLine."Reserved Qty. Inbnd. (Base)" <> 0);
        ShowErrorOutbnd := (NewTransferLine."Reserved Qty. Outbnd. (Base)" <> 0);

        if NewTransferLine."Shipment Date" = 0D then
            if ShowErrorOutbnd then
                NewTransferLine.FieldError("Shipment Date", Text002Err)
            else
                HasErrorOutbnd := true;

        CheckTransLineReceiptDate(NewTransferLine, ShowErrorInbnd, HasErrorInbnd);

        if NewTransferLine."FA Item No." <> OldTransferLine."FA Item No." then
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewTransferLine.FieldError("FA Item No.", Text003Err)
            else begin
                HasErrorInbnd := true;
                HasErrorOutbnd := true;
            end;

        if NewTransferLine."Transfer-from Code" <> OldTransferLine."Transfer-from Code" then
            if ShowErrorOutbnd then
                NewTransferLine.FieldError("Transfer-from Code", Text003Err)
            else
                HasErrorOutbnd := true;

        If NewTransferLine."Transfer-from Customer" <> OldTransferLine."Transfer-from Customer" then
            if ShowErrorOutbnd then
                NewTransferLine.FieldError("Transfer-from Customer", Text003Err)
            else
                HasErrorOutbnd := true;

        if NewTransferLine."Transfer-to Code" <> OldTransferLine."Transfer-to Code" then
            if ShowErrorInbnd then
                NewTransferLine.FieldError("Transfer-to Code", Text003Err)
            else
                HasErrorInbnd := true;

        if NewTransferLine."Transfer-to Customer" <> OldTransferLine."Transfer-to Customer" then
            if ShowErrorInbnd then
                NewTransferLine.FieldError("Transfer-to Customer", Text003Err)
            else
                HasErrorInbnd := true;

        if (NewTransferLine."Transfer-from Bin Code" <> OldTransferLine."Transfer-from Bin Code") and
           (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
              NewTransferLine."FA Item No.", NewTransferLine."Transfer-from Bin Code",
              NewTransferLine."Transfer-from Code", NewTransferLine."Variant Code",
              Database::"FA Transfer Line", 0, NewTransferLine."Document No.", '',
              NewTransferLine."Derived From Line No.", NewTransferLine."Line No."))
        then begin
            if ShowErrorOutbnd then
                NewTransferLine.FieldError("Transfer-from Bin Code", Text003Err);
            HasErrorOutbnd := true;
        end;

        if (NewTransferLine."Transfer-To Bin Code" <> OldTransferLine."Transfer-To Bin Code") and
           (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
              NewTransferLine."FA Item No.", NewTransferLine."Transfer-To Bin Code",
              NewTransferLine."Transfer-to Code", NewTransferLine."Variant Code",
              Database::"FA Transfer Line", 1, NewTransferLine."Document No.", '',
              NewTransferLine."Derived From Line No.", NewTransferLine."Line No."))
        then begin
            if ShowErrorInbnd then
                NewTransferLine.FieldError("Transfer-To Bin Code", Text003Err);
            HasErrorInbnd := true;
        end;

        if NewTransferLine."Variant Code" <> OldTransferLine."Variant Code" then
            if ShowErrorInbnd or ShowErrorOutbnd then
                NewTransferLine.FieldError("Variant Code", Text003Err)
            else begin
                HasErrorInbnd := true;
                HasErrorOutbnd := true;
            end;

        if NewTransferLine."Line No." <> OldTransferLine."Line No." then begin
            HasErrorInbnd := true;
            HasErrorOutbnd := true;
        end;

        //         OnVerifyChangeOnBeforeHasError(NewTransferLine, OldTransferLine, HasErrorInbnd, HasErrorOutbnd, ShowErrorInbnd, ShowErrorOutbnd);

        if HasErrorOutbnd then begin
            AutoTracking(OldTransferLine, NewTransferLine, ReservationEntry, Enum::"Transfer Direction"::Outbound);
            AssignForPlanning(NewTransferLine, Enum::"Transfer Direction"::Outbound);
            if (NewTransferLine."FA Item No." <> OldTransferLine."FA Item No.") or
               (NewTransferLine."Variant Code" <> OldTransferLine."Variant Code") or
               (NewTransferLine."Transfer-to Code" <> OldTransferLine."Transfer-to Code")
            then
                AssignForPlanning(OldTransferLine, Enum::"Transfer Direction"::Outbound);
        end;

        if HasErrorInbnd then begin
            AutoTracking(OldTransferLine, NewTransferLine, ReservationEntry, Enum::"Transfer Direction"::Inbound);
            AssignForPlanning(NewTransferLine, Enum::"Transfer Direction"::Inbound);
            if (NewTransferLine."FA Item No." <> OldTransferLine."FA Item No.") or
               (NewTransferLine."Variant Code" <> OldTransferLine."Variant Code") or
               (NewTransferLine."Transfer-from Code" <> OldTransferLine."Transfer-from Code")
            then
                AssignForPlanning(OldTransferLine, Enum::"Transfer Direction"::Inbound);
        end;
    end;

    local procedure CheckTransLineReceiptDate(var NewTransferLine: Record "FA Transfer Line"; var ShowErrorInbnd: Boolean; var HasErrorInbnd: Boolean)
    //     var
    //         IsHandled: Boolean;
    begin
        //         IsHandled := false;
        //         OnBeforeCheckTransLineReceiptDate(NewTransferLine, ShowErrorInbnd, HasErrorInbnd, IsHandled);
        //         if IsHandled then
        //             exit;

        if NewTransferLine."Receipt Date" = 0D then
            if ShowErrorInbnd then
                NewTransferLine.FieldError("Receipt Date", Text002Err)
            else
                HasErrorInbnd := true;
    end;

    procedure VerifyQuantity(var NewTransferLine: Record "FA Transfer Line"; var OldTransferLine: Record "FA Transfer Line")
    var
        TransferLine: Record "FA Transfer Line";
        Direction: Enum "Transfer Direction";
    begin
        //         OnBeforeVerifyReserved(NewTransferLine, OldTransferLine);

        if Blocked then
            exit;

        if NewTransferLine."Line No." = OldTransferLine."Line No." then
            if NewTransferLine."Quantity (Base)" = OldTransferLine."Quantity (Base)" then
                exit;
        if NewTransferLine."Line No." = 0 then
            if not TransferLine.Get(NewTransferLine."Document No.", NewTransferLine."Line No.") then
                exit;
        for Direction := Direction::Outbound to Direction::Inbound do begin
            ReservationManagement.SetReservSource(NewTransferLine, Direction);
            if NewTransferLine."Qty. per Unit of Measure" <> OldTransferLine."Qty. per Unit of Measure" then
                ReservationManagement.ModifyUnitOfMeasure();
            ReservationManagement.DeleteReservEntries(false, NewTransferLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(NewTransferLine."Outstanding Qty. (Base)");
            AssignForPlanning(NewTransferLine, Direction);
        end;
    end;

    // procedure UpdatePlanningFlexibility(var FATransferLine: Record "FA Transfer Line")
    // var
    //     ReservationEntry: Record "FA Reservation Entry";
    // begin
    //     if FindReservEntry(FATransferLine, ReservationEntry, Enum::"Transfer Direction"::Outbound) then
    //         ReservationEntry.ModifyAll("Planning Flexibility", FATransferLine."Planning Flexibility");
    //     if FindReservEntry(FATransferLine, ReservationEntry, Enum::"Transfer Direction"::Inbound) then
    //         ReservationEntry.ModifyAll("Planning Flexibility", FATransferLine."Planning Flexibility");
    // end;

    procedure TransferTransferToItemJnlLine(var FATransferLine: Record "FA Transfer Line"; var FAItemJournalLine: Record "FA Item Journal Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction")
    begin
        TransferTransferToItemJnlLine(FATransferLine, FAItemJournalLine, TransferQty, Direction, false);
    end;

    procedure TransferTransferToItemJnlLine(var FATransferLine: Record "FA Transfer Line"; var FAItemJournalLine: Record "FA Item Journal Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction"; IsReclass: Boolean)
    var
        OldReservationEntry: Record "FA Reservation Entry";
        TransferLocation: Code[10];
    //         IsHandled: Boolean;
    begin
        //         IsHandled := false;
        //         OnBeforeTransferTransferToItemJnlLine(TransferLine, ItemJournalLine, Direction, IsHandled);
        //         if IsHandled then
        //             exit;

        if not FindReservEntry(FATransferLine, OldReservationEntry, Direction) then
            exit;

        OldReservationEntry.Lock();

        case Direction of
            Direction::Outbound:
                begin
                    TransferLocation := FATransferLine."Transfer-from Code";
                    FAItemJournalLine.TestField("Location Code", TransferLocation);
                end;
            Direction::Inbound:
                begin
                    TransferLocation := FATransferLine."Transfer-to Code";
                    FAItemJournalLine.TestField("New Location Code", TransferLocation);
                end;
        end;

        FAItemJournalLine.TestField("FA Item No.", FATransferLine."FA Item No.");
        FAItemJournalLine.TestField("Variant Code", FATransferLine."Variant Code");

        if TransferQty = 0 then
            exit;
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then
            repeat
                OldReservationEntry.TestItemFields(FATransferLine."FA Item No.", FATransferLine."Variant Code", TransferLocation);
                if not IsReclass or not OldReservationEntry.NewTrackingExists() then
                    OldReservationEntry.CopyNewTrackingFromReservEntry(OldReservationEntry);

                // IsHandled := false;
                // OnTransferTransferToItemJnlLineTransferFields(OldReservationEntry, TransferLine, ItemJournalLine, TransferQty, Direction, IsHandled);
                // if not IsHandled then
                TransferQty :=
                  CreateReservEntry.TransferReservEntry(
                    Database::"FA Item Journal Line",
                    FAItemJournalLine."Entry Type".AsInteger(), FAItemJournalLine."Journal Template Name",
                    FAItemJournalLine."Journal Batch Name", 0, FAItemJournalLine."Line No.",
                    FAItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
    end;

    procedure TransferWhseShipmentToItemJnlLine(var FATransferLine: Record "FA Transfer Line"; var FAItemJournalLine: Record "FA Item Journal Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferQty: Decimal)
    var
        OldReservationEntry: Record "FA Reservation Entry";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        QtyToHandleBase: Decimal;
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(FATransferLine, OldReservationEntry, Enum::"Transfer Direction"::Outbound) then
            exit;

        FAItemJournalLine.TestField("Location Code", FATransferLine."Transfer-from Code");
        FAItemJournalLine.TestField("FA Item No.", FATransferLine."FA Item No.");
        FAItemJournalLine.TestField("Variant Code", FATransferLine."Variant Code");

        WarehouseShipmentLine.GetWhseShptLine(
          WarehouseShipmentHeader."No.", Database::"FA Transfer Line", 0, FATransferLine."Document No.", FATransferLine."Line No.");

        OldReservationEntry.Lock();
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then
            repeat
                OldReservationEntry.TestItemFields(FATransferLine."FA Item No.", FATransferLine."Variant Code", FATransferLine."Transfer-from Code");
                ItemTrackingManagement.GetWhseItemTrkgSetup(FATransferLine."FA Item No.", WhseItemTrackingSetup);
                OnTransferWhseShipmentToItemJnlLineOnAfterGetWhseItemTrkgSetup(FATransferLine, WhseItemTrackingSetup);

                WarehouseEntry.SetSourceFilter(
                  OldReservationEntry."Source Type", OldReservationEntry."Source Subtype",
                  OldReservationEntry."Source ID", OldReservationEntry."Source Ref. No.", false);
                WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Shipment);
                WarehouseEntry.SetRange("Whse. Document No.", WarehouseShipmentLine."No.");
                WarehouseEntry.SetRange("Whse. Document Line No.", WarehouseShipmentLine."Line No.");
                WarehouseEntry.SetRange("Bin Code", WarehouseShipmentLine."Bin Code");
                WhseItemTrackingSetup.CopyTrackingFromFAReservEntry(OldReservationEntry);
                WarehouseEntry.SetTrackingFilterFromItemTrackingSetupIfRequired(WhseItemTrackingSetup);
                WarehouseEntry.CalcSums("Qty. (Base)");
                QtyToHandleBase := -WarehouseEntry."Qty. (Base)";
                OnTransferWhseShipmentToItemJnlLineOnAfterCalcWarehouseQtyBase(WarehouseShipmentHeader, WarehouseShipmentLine, OldReservationEntry, WhseItemTrackingSetup, QtyToHandleBase);
                if Abs(QtyToHandleBase) > Abs(OldReservationEntry."Qty. to Handle (Base)") then
                    QtyToHandleBase := OldReservationEntry."Qty. to Handle (Base)";

                if QtyToHandleBase < 0 then begin
                    OldReservationEntry.CopyNewTrackingFromReservEntry(OldReservationEntry);
                    OldReservationEntry."Qty. to Handle (Base)" := QtyToHandleBase;
                    OldReservationEntry."Qty. to Invoice (Base)" := QtyToHandleBase;

                    TransferQty :=
                      CreateReservEntry.TransferReservEntry(
                        Database::"FA Item Journal Line",
                        FAItemJournalLine."Entry Type".AsInteger(), FAItemJournalLine."Journal Template Name",
                        FAItemJournalLine."Journal Batch Name", 0, FAItemJournalLine."Line No.",
                        FAItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);
                end;
            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
    end;

    procedure TransferTransferToTransfer(var OldTransferLine: Record "FA Transfer Line"; var NewTransferLine: Record "FA Transfer Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction"; var TrackingSpecification: Record "FA Tracking Specification")
    var
        OldReservationEntry: Record "FA Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        TransferLocation: Code[10];
    begin
        // Used when derived Transfer Lines are created during posting of shipment.
        if not FindReservEntry(OldTransferLine, OldReservationEntry, Direction) then
            exit;

        OldReservationEntry.SetTrackingFilterFromSpec(TrackingSpecification);
        if OldReservationEntry.IsEmpty() then
            exit;

        OldReservationEntry.Lock();

        case Direction of
            Direction::Outbound:
                begin
                    TransferLocation := OldTransferLine."Transfer-from Code";
                    NewTransferLine.TestField("Transfer-from Code", TransferLocation);
                end;
            Direction::Inbound:
                begin
                    TransferLocation := OldTransferLine."Transfer-to Code";
                    NewTransferLine.TestField("Transfer-to Code", TransferLocation);
                end;
        end;

        NewTransferLine.TestField("FA Item No.", OldTransferLine."FA Item No.");
        NewTransferLine.TestField("Variant Code", OldTransferLine."Variant Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestItemFields(OldTransferLine."FA Item No.", OldTransferLine."Variant Code", TransferLocation);

                    UpdateTransferQuantity(TransferQty, Direction, NewTransferLine, OldTransferLine, OldReservationEntry);

                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end;
    end;

    local procedure UpdateTransferQuantity(var TransferQty: Decimal; var Direction: Enum "Transfer Direction"; var NewTransferLine: Record "FA Transfer Line"; var OldTransferLine: Record "FA Transfer Line"; var OldReservationEntry: Record "FA Reservation Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeUpdateTransferQuantity(TransferQty, Direction, NewTransferLine, OldTransferLine, OldReservationEntry, IsHandled);
        if IsHandled then
            exit;

        TransferQty :=
            CreateReservEntry.TransferReservEntry(
                Database::"FA Transfer Line",
                Direction.AsInteger(), NewTransferLine."Document No.", '', NewTransferLine."Derived From Line No.",
                NewTransferLine."Line No.", NewTransferLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);
    end;

    procedure DeleteLineConfirm(var FATransferLine: Record "FA Transfer Line"): Boolean
    begin
        if not FATransferLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(FATransferLine, Enum::"Transfer Direction"::Outbound);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var FATransferLine: Record "FA Transfer Line")
    begin
        if Blocked then
            exit;

        ReservationManagement.SetReservSource(FATransferLine, Enum::"Transfer Direction"::Outbound);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        FATransferLine.CalcFields("Reserved Qty. Outbnd. (Base)");

        ReservationManagement.SetReservSource(FATransferLine, Enum::"Transfer Direction"::Inbound);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        FATransferLine.CalcFields("Reserved Qty. Inbnd. (Base)");
    end;

    local procedure AssignForPlanning(var TransferLine: Record "FA Transfer Line"; Direction: Enum "Transfer Direction")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        if TransferLine."FA Item No." <> '' then
            case Direction of
                Direction::Outbound:
                    PlanningAssignment.ChkAssignOne(
                        TransferLine."FA Item No.", TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Shipment Date");
                Direction::Inbound:
                    PlanningAssignment.ChkAssignOne(
                        TransferLine."FA Item No.", TransferLine."Variant Code", TransferLine."Transfer-from Code", TransferLine."Receipt Date");
            end;
    end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    procedure CallItemTracking(var TransferLine: Record "FA Transfer Line"; Direction: Enum "Transfer Direction")
    begin
        CallItemTracking(TransferLine, Direction, false);
    end;

    procedure CallItemTracking(var TransferLine: Record "FA Transfer Line"; Direction: Enum "Transfer Direction"; DirectTransfer: Boolean)
    var
        TrackingSpecification: Record "FA Tracking Specification";
        ItemTrackingLines: Page "FA Item Tracking Lines";
        AvalabilityDate: Date;
    begin
        TrackingSpecification.InitFromTransLine(TransferLine, AvalabilityDate, Direction);
        if DirectTransfer then
            ItemTrackingLines.SetDirectTransfer(true);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AvalabilityDate);
        ItemTrackingLines.SetInbound(TransferLine.IsInbound());
        // OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(TransferLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
        // OnAfterCallItemTracking(TransferLine);
    end;

    procedure CallItemTracking(var TransferLine: Record "FA Transfer Line"; Direction: Enum "Transfer Direction"; SecondSourceQuantityArray: array[3] of Decimal)
    var
        TrackingSpecification: Record "FA Tracking Specification";
        ItemTrackingLines: Page "FA Item Tracking Lines";
        AvailabilityDate: Date;
    begin
        TrackingSpecification.InitFromTransLine(TransferLine, AvailabilityDate, Direction);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, AvailabilityDate);
        ItemTrackingLines.SetSecondSourceQuantity(SecondSourceQuantityArray);
        // OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(TransferLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
        // OnAfterCallItemTracking(TransferLine);
    end;

    procedure UpdateItemTrackingAfterPosting(TransferHeader: Record "FA Transfer Header"; Direction: Enum "Transfer Direction")
    var
        ReservationEntry: Record "FA Reservation Entry";
        ReservationEntry2: Record "FA Reservation Entry";
    begin
        // Used for updating Quantity to Handle after posting;
        ReservationEntry.SetSourceFilter(
            Database::"FA Transfer Line", Direction.AsInteger(), TransferHeader."No.", -1, true);
        ReservationEntry.SetRange("Source Batch Name", '');
        if Direction = Direction::Outbound then
            ReservationEntry.SetRange("Source Prod. Order Line", 0)
        else
            ReservationEntry.SetFilter("Source Prod. Order Line", '<>%1', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
        if Direction = Direction::Outbound then begin
            ReservationEntry2.Copy(ReservationEntry);
            ReservationEntry2.SetRange("Source Subtype", Direction::Inbound);
            CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry2);
        end;
    end;

    //     procedure RegisterBinContentItemTracking(var TransferLine: Record "Transfer Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    //     var
    //         SourceTrackingSpecification: Record "Tracking Specification";
    //         ItemTrackingLines: Page "Item Tracking Lines";
    //     begin
    //         if not TempTrackingSpecification.FindSet() then
    //             exit;
    //         SourceTrackingSpecification.InitFromTransLine(TransferLine, TransferLine."Shipment Date", Enum::"Transfer Direction"::Outbound);

    //         Clear(ItemTrackingLines);
    //         ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::Transfer);
    //         ItemTrackingLines.SetSourceSpec(SourceTrackingSpecification, TransferLine."Shipment Date");
    //         ItemTrackingLines.RegisterItemTrackingLines(
    //           SourceTrackingSpecification, TransferLine."Shipment Date", TempTrackingSpecification);
    //     end;

    local procedure GetInboundReservEntryShipmentDate() InboundReservEntryShipmentDate: Date
    begin
        case FromTrackingSpecification."Source Type" of
            //             Database::"Sales Line":
            //                 InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateBySalesLine();
            //             Database::"Purchase Line":
            //                 InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByPurchaseLine();
            Database::"FA Transfer Line":
                InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByTransferLine();
        //             Database::"Service Line":
        //                 InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByServiceLine();
        //             Database::"Job Planning Line":
        //                 InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByJobPlanningLine();
        //             Database::"Prod. Order Component":
        //                 InboundReservEntryShipmentDate := GetInboundReservEntryShipmentDateByProdOrderComponent();
        end;
    end;

    //     local procedure GetInboundReservEntryShipmentDateByProdOrderComponent(): Date
    //     var
    //         ProdOrderComponent: Record "Prod. Order Component";
    //     begin
    //         ProdOrderComponent.Get(
    //             FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
    //             FromTrackingSpecification."Source Prod. Order Line", FromTrackingSpecification."Source Ref. No.");
    //         exit(ProdOrderComponent."Due Date");
    //     end;

    //     local procedure GetInboundReservEntryShipmentDateBySalesLine(): Date
    //     var
    //         SalesLine: Record "Sales Line";
    //     begin
    //         SalesLine.Get(
    //             FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
    //             FromTrackingSpecification."Source Ref. No.");
    //         exit(SalesLine."Shipment Date");
    //     end;

    //     local procedure GetInboundReservEntryShipmentDateByPurchaseLine(): Date
    //     var
    //         PurchaseLine: Record "Purchase Line";
    //     begin
    //         PurchaseLine.Get(
    //             FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
    //             FromTrackingSpecification."Source Ref. No.");
    //         exit(PurchaseLine."Expected Receipt Date");
    //     end;

    local procedure GetInboundReservEntryShipmentDateByTransferLine(): Date
    var
        FATransferLine: Record "FA Transfer Line";
    begin
        FATransferLine.Get(
            FromTrackingSpecification."Source ID", FromTrackingSpecification."Source Ref. No.");
        exit(FATransferLine."Shipment Date");
    end;

    //     local procedure GetInboundReservEntryShipmentDateByServiceLine(): Date
    //     var
    //         ServiceLine: Record "Service Line";
    //     begin
    //         ServiceLine.Get(
    //             FromTrackingSpecification."Source Subtype", FromTrackingSpecification."Source ID",
    //             FromTrackingSpecification."Source Ref. No.");
    //         exit(ServiceLine."Needed by Date");
    //     end;

    //     local procedure GetInboundReservEntryShipmentDateByJobPlanningLine(): Date
    //     var
    //         JobPlanningLine: Record "Job Planning Line";
    //     begin
    //         JobPlanningLine.SetRange(Status, FromTrackingSpecification."Source Subtype");
    //         JobPlanningLine.SetRange("Job No.", FromTrackingSpecification."Source ID");
    //         JobPlanningLine.SetRange("Job Contract Entry No.", FromTrackingSpecification."Source Ref. No.");
    //         JobPlanningLine.FindFirst();
    //         exit(JobPlanningLine."Planning Date");
    //     end;

    local procedure AutoTracking(OldTransferLine: Record "FA Transfer Line"; NewTransferLine: Record "FA Transfer Line"; var TempReservationEntry: Record "FA Reservation Entry" temporary; Direction: Enum "Transfer Direction")
    begin
        if (NewTransferLine."FA Item No." <> OldTransferLine."FA Item No.") or FindReservEntry(NewTransferLine, TempReservationEntry, Direction::Outbound) then begin
            if NewTransferLine."FA Item No." <> OldTransferLine."FA Item No." then begin
                ReservationManagement.SetReservSource(OldTransferLine, Direction);
                ReservationManagement.DeleteReservEntries(true, 0);
                ReservationManagement.SetReservSource(NewTransferLine, Direction);
            end else begin
                ReservationManagement.SetReservSource(NewTransferLine, Direction);
                ReservationManagement.DeleteReservEntries(true, 0);
            end;
            ReservationManagement.AutoTrack(NewTransferLine."Outstanding Qty. (Base)");
        end;
    end;

    //     [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    //     local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; ReservEntry: Record "Reservation Entry")
    //     var
    //         TransferLine: Record "Transfer Line";
    //     begin
    //         if MatchThisTable(SourceRecRef.Number) then begin
    //             SourceRecRef.SetTable(TransferLine);
    //             TransferLine.Find();
    //             QtyPerUOM := TransferLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, ReservEntry."Source Subtype");
    //         end;
    //     end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "FA Reservation Entry"; var CaptionText: Text; Direction: Enum "Transfer Direction")
    var
        FATransferLine: Record "FA Transfer Line";
    begin
        SourceRecordRef.SetTable(FATransferLine);
        ClearAll();
        SourceRecordRef.GetTable(FATransferLine);

        FATransferLine.SetReservationEntry(ReservationEntry, Direction);

        CaptionText := FATransferLine.GetSourceCaption();
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger(),
                         Enum::"Reservation Summary Type"::"Transfer Receipt".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"FA Transfer Line");
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "FA Reservation Entry"; var CaptionText: Text; Direction: Integer)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText, Enum::"Transfer Direction".FromInteger(Direction));
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "FA Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
    // AvailableTransferLines: page "Available - Transfer Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin
            // Clear(AvailableTransferLines);
            // AvailableTransferLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            // AvailableTransferLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "FA Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"FA Transfer Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "FA Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"FA Transfer Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "FA Tracking Specification"; ForReservEntry: Record "FA Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        TransferLine: Record "FA Transfer Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(TransferLine);
            CreateReservation(
                TransferLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry, ForReservEntry.GetTransferDirection());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure MyProcedure(SourceType: Integer; SourceID: Code[20])
    var
        TransHeader: Record "FA Transfer Header";
    begin
        if MatchThisTable(SourceType) then begin
            TransHeader.Reset();
            TransHeader.SetRange("No.", SourceID);
            PAGE.RunModal(PAGE::"FA Transfer Order", TransHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "FA Reservation Entry"; Direction: Integer; var CaptionText: Text)
    var
        TransferLine: Record "FA Transfer Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(TransferLine);
            TransferLine.SetReservationFilters(ReservEntry, Enum::"Transfer Direction".FromInteger(Direction));
            CaptionText := TransferLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "FA Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        TransferLine: Record "FA Transfer Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(TransferLine);
            TransferLine.GetRemainingQty(RemainingQty, RemainingQtyBase, ReservEntry."Source Subtype");
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "FA Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        TransferLine: Record "FA Transfer Line";
    begin
        TransferLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(TransferLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(TransferLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(TransferLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "FA Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(ReservationEntry: Record "FA Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; Direction: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        TransferLine: Record "FA Transfer Line";
        AvailabilityFilter: Text;
    begin
        if not TransferLine.ReadPermission then
            exit;

        AvailabilityFilter := ReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        case Direction of
            0: // Outbound
                TransferLine.FilterOutboundLinesForReservation(ReservationEntry, AvailabilityFilter, Positive);
            1: // Inbound
                TransferLine.FilterInboundLinesForReservation(ReservationEntry, AvailabilityFilter, Positive);
        end;
        if TransferLine.FindSet() then
            repeat
                case Direction of
                    0:
                        begin
                            TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" -= TransferLine."Reserved Qty. Outbnd. (Base)";
                            TotalQuantity -= TransferLine."Outstanding Qty. (Base)";
                        end;
                    1:
                        begin
                            TransferLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            TempEntrySummary."Total Reserved Quantity" += TransferLine."Reserved Qty. Inbnd. (Base)";
                            TotalQuantity += TransferLine."Outstanding Qty. (Base)";
                        end;
                end;
            until TransferLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"FA Transfer Line";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo(SummaryTypeTxt, TransferLine.TableCaption(), SelectStr(Direction + 1, Text006Err)), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "FA Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [101, 102] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 101, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "FA Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "FA Reservation Entry")
    var
        TransferLine: Record "FA Transfer Line";
    begin
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReservationEntry."Source ID");
        TransferLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        TransferLine.SetRange("Derived From Line No.", ReservationEntry."Source Prod. Order Line");
        PAGE.RunModal(0, TransferLine);
    end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnAfterCallItemTracking(var TransferLine: Record "Transfer Line")
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnBeforeCheckTransLineReceiptDate(var NewTransLine: REcord "Transfer Line"; var ShowErrorInbnd: Boolean; var HasErrorInbnd: Boolean; var IsHandled: Boolean)
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnBeforeTransferTransferToItemJnlLine(var TransferLine: Record "Transfer Line"; var ItemJournalLine: Record "Item Journal Line"; Direction: Enum "Transfer Direction"; var IsHandled: Boolean)
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnBeforeUpdateTransferQuantity(var TransferQty: Decimal; var Direction: Enum "Transfer Direction"; var NewTransLine: Record "Transfer Line"; var OldTransLine: Record "Transfer Line"; var OldReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnBeforeVerifyChange(var NewTransferLine: Record "Transfer Line"; var OldfTransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnBeforeVerifyReserved(var NewTransferLine: Record "Transfer Line"; OldfTransferLine: Record "Transfer Line")
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnTransferTransferToItemJnlLineTransferFields(var ReservationEntry: Record "Reservation Entry"; var TransferLine: Record "Transfer Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; Direction: Enum "Transfer Direction"; var IsHandled: Boolean)
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnVerifyChangeOnBeforeHasError(NewTransLine: Record "Transfer Line"; OldTransLine: Record "Transfer Line"; var HasErrorInbnd: Boolean; var HasErrorOutbnd: Boolean; var ShowErrorInbnd: Boolean; var ShowErrorOutbnd: Boolean)
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(var TransLine: REcord "Transfer Line"; var ItemTrackingLines: Page "Item Tracking Lines")
    //     begin
    //     end;

    //     [IntegrationEvent(false, false)]
    //     local procedure OnCreateReservationOnBeforeCreateReservEntry(var TransLine: Record "Transfer Line"; var Quantity: Decimal; var QuantityBase: Decimal; var ForReservEntry: Record "Reservation Entry"; var Direction: Enum "Transfer Direction"; var IsHandled: Boolean)
    //     begin
    //     end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferWhseShipmentToItemJnlLineOnAfterGetWhseItemTrkgSetup(FATransferLine: Record "FA Transfer Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferWhseShipmentToItemJnlLineOnAfterCalcWarehouseQtyBase(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line"; var OldReservEntry: Record "FA Reservation Entry"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyToHandleBase: Decimal)
    begin
    end;
}