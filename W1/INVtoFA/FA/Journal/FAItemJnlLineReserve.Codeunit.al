namespace TSTChanges.FA.Journal;

using TSTChanges.FA.Ledger;
using Microsoft.Inventory.Tracking;
using TSTChanges.FA.Tracking;

codeunit 51214 "FA Item Jnl. Line-Reserve"
{
    trigger OnRun()
    begin
    end;

    var
        CreateReservEntry: Codeunit "FA Create Reserv. Entry";
        ReservationManagement: Codeunit "FA Reservation Management";
        ReservationEngineMgt: Codeunit "FA Reservation Engine Mgt.";
        Blocked: Boolean;
        DeleteItemTracking: Boolean;

        Text002Err: Label 'must be filled in when a quantity is reserved';
        Text004Err: Label 'must not be changed when a quantity is reserved';

    procedure Caption(ItemJournalLine: Record "FA Item Journal Line") CaptionText: Text
    begin
        CaptionText := ItemJournalLine.GetSourceCaption();
    end;

    procedure FindReservEntry(ItemJournalLine: Record "FA Item Journal Line"; var ReservationEntry: Record "FA Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ItemJournalLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    procedure ReservEntryExist(ItemJournalLine: Record "FA Item Journal Line"): Boolean
    begin
        exit(ItemJournalLine.ReservEntryExist());
    end;

    procedure ReservEntryExist(FAItemJournalLine: Record "FA Item Journal Line"; var ReservationEntry: Record "FA Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        FAItemJournalLine.SetReservationFilters(ReservationEntry);
        exit(not ReservationEntry.IsEmpty());
    end;

    procedure VerifyChange(var NewItemJournalLine: Record "FA Item Journal Line"; var OldItemJournalLine: Record "FA Item Journal Line")
    var
        ItemJournalLine: Record "FA Item Journal Line";
        ReservationEntry: Record "FA Reservation Entry";
        ItemTrackingManagement: Codeunit "FA Item Tracking Management";
        ShowError: Boolean;
        HasError: Boolean;
        PointerChanged, IsHandled : Boolean;
    begin
        IsHandled := false;
        // OnBeforeVerifyChange(NewItemJournalLine, OldItemJournalLine, ReservationManagement, Blocked, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;
        if NewItemJournalLine."Line No." = 0 then
            if not ItemJournalLine.Get(
                 NewItemJournalLine."Journal Template Name",
                 NewItemJournalLine."Journal Batch Name",
                 NewItemJournalLine."Line No.")
            then
                exit;

        NewItemJournalLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewItemJournalLine."Reserved Qty. (Base)" <> 0;

        if NewItemJournalLine."Posting Date" = 0D then
            if ShowError then
                NewItemJournalLine.FieldError("Posting Date", Text002Err)
            else
                HasError := true;

        // if NewItemJournalLine."Drop Shipment" then
        //     if ShowError then
        //         NewItemJournalLine.FieldError("Drop Shipment", Text003Err)
        //     else
        //         HasError := true;

        if NewItemJournalLine."FA Item No." <> OldItemJournalLine."FA Item No." then
            if ShowError then
                NewItemJournalLine.FieldError("FA Item No.", Text004Err)
            else
                HasError := true;

        if NewItemJournalLine."Entry Type" <> OldItemJournalLine."Entry Type" then
            if ShowError then
                NewItemJournalLine.FieldError("Entry Type", Text004Err)
            else
                HasError := true;

        if (NewItemJournalLine."Entry Type" = NewItemJournalLine."Entry Type"::Transfer) and
           (NewItemJournalLine."Quantity (Base)" < 0)
        then begin
            if NewItemJournalLine."New Location Code" <> OldItemJournalLine."Location Code" then
                if ShowError then
                    NewItemJournalLine.FieldError("New Location Code", Text004Err)
                else
                    HasError := true;
            if NewItemJournalLine."New Bin Code" <> OldItemJournalLine."Bin Code" then
                if ItemTrackingManagement.GetWhseItemTrkgSetup(NewItemJournalLine."FA Item No.") then
                    if ShowError then
                        NewItemJournalLine.FieldError("New Bin Code", Text004Err)
                    else
                        HasError := true;
        end else begin
            if NewItemJournalLine."Location Code" <> OldItemJournalLine."Location Code" then
                if ShowError then
                    NewItemJournalLine.FieldError("Location Code", Text004Err)
                else
                    HasError := true;
            if (NewItemJournalLine."Bin Code" <> OldItemJournalLine."Bin Code") and
               (not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                  NewItemJournalLine."FA Item No.", NewItemJournalLine."Bin Code",
                  NewItemJournalLine."Location Code", NewItemJournalLine."Variant Code",
                  Database::"FA Item Journal Line", NewItemJournalLine."Entry Type".AsInteger(),
                  NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name",
                  0, NewItemJournalLine."Line No."))
            then begin
                if ShowError then
                    NewItemJournalLine.FieldError("Bin Code", Text004Err);
                HasError := true;
            end;
        end;
        if NewItemJournalLine."Variant Code" <> OldItemJournalLine."Variant Code" then
            if ShowError then
                NewItemJournalLine.FieldError("Variant Code", Text004Err)
            else
                HasError := true;
        if NewItemJournalLine."Line No." <> OldItemJournalLine."Line No." then
            HasError := true;

        // OnVerifyChangeOnBeforeHasError(NewItemJournalLine, OldItemJournalLine, HasError, ShowError);

        if HasError then begin
            FindReservEntry(NewItemJournalLine, ReservationEntry);
            ReservationEntry.ClearTrackingFilter();

            PointerChanged := (NewItemJournalLine."FA Item No." <> OldItemJournalLine."FA Item No.") or
              (NewItemJournalLine."Entry Type" <> OldItemJournalLine."Entry Type");

            if PointerChanged or (not ReservationEntry.IsEmpty()) then
                if PointerChanged then begin
                    ReservationManagement.SetReservSource(OldItemJournalLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewItemJournalLine);
                end else begin
                    ReservationManagement.SetReservSource(NewItemJournalLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
        end;
    end;

    procedure VerifyQuantity(var NewItemJournalLine: Record "FA Item Journal Line"; var OldItemJournalLine: Record "FA Item Journal Line")
    var
        ItemJournalLine: Record "FA Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeVerifyQuantity(NewItemJournalLine, OldItemJournalLine, ReservationManagement, Blocked, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        if NewItemJournalLine."Line No." = OldItemJournalLine."Line No." then
            if NewItemJournalLine."Quantity (Base)" = OldItemJournalLine."Quantity (Base)" then
                exit;
        if NewItemJournalLine."Line No." = 0 then
            if not ItemJournalLine.Get(NewItemJournalLine."Journal Template Name", NewItemJournalLine."Journal Batch Name", NewItemJournalLine."Line No.") then
                exit;
        ReservationManagement.SetReservSource(NewItemJournalLine);
        if NewItemJournalLine."Qty. per Unit of Measure" <> OldItemJournalLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        if NewItemJournalLine."Quantity (Base)" * OldItemJournalLine."Quantity (Base)" < 0 then
            ReservationManagement.DeleteReservEntries(true, 0)
        else
            ReservationManagement.DeleteReservEntries(false, NewItemJournalLine."Quantity (Base)");
    end;

    procedure TransferItemJnlToItemLedgEntry(var FAItemJournalLine: Record "FA Item Journal Line"; var FAItemLedgerEntry: Record "FA Item ledger Entry"; TransferQty: Decimal; SkipInventory: Boolean): Boolean
    var
        OldReservationEntry: Record "FA Reservation Entry";
        OldReservationEntry2: Record "FA Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        SkipThisRecord: Boolean;
        IsHandled: Boolean;
    begin
        if not ReservEntryExist(FAItemJournalLine, OldReservationEntry) then
            exit(false);

        LockReservationEntry(FAItemJournalLine);

        FAItemLedgerEntry.TestField("FA Item No.", FAItemJournalLine."FA Item No.");
        FAItemLedgerEntry.TestField("Variant Code", FAItemJournalLine."Variant Code");
        if FAItemJournalLine."Entry Type" = FAItemJournalLine."Entry Type"::Transfer then
            FAItemLedgerEntry.TestField("Location Code", FAItemJournalLine."New Location Code")
        else
            FAItemLedgerEntry.TestField("Location Code", FAItemJournalLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit(true);
            OldReservationEntry.SetRange("Reservation Status", ReservStatus);

            if OldReservationEntry.FindSet() then
                repeat
                    OldReservationEntry.TestField("Item No.", FAItemJournalLine."FA Item No.");
                    // OnTransferItemJnlToItemLedgEntryOnBeforeTestVariantCode(OldReservationEntry, ItemJournalLine, IsHandled);
                    OldReservationEntry.TestField("Variant Code", FAItemJournalLine."Variant Code");

                    if SkipInventory then
                        if OldReservationEntry.IsReservationOrTracking() then begin
                            OldReservationEntry2.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                            SkipThisRecord := OldReservationEntry2."Source Type" = Database::"FA Item Ledger Entry";
                        end else
                            SkipThisRecord := false;

                    if not SkipThisRecord then begin
                        if FAItemJournalLine."Entry Type" = FAItemJournalLine."Entry Type"::Transfer then begin
                            if FAItemLedgerEntry.Quantity < 0 then
                                TestOldReservEntryLocationCode(OldReservationEntry, FAItemJournalLine);
                            CreateReservEntry.SetInbound(true);
                        end else
                            TestOldReservEntryLocationCode(OldReservationEntry, FAItemJournalLine);

                        // OnTransferItemJnlToItemLedgEntryOnBeforeTransferReservEntry(ItemLedgerEntry);
                        TransferQty :=
                          CreateReservEntry.TransferReservEntry(
                            Database::"FA Item Ledger Entry", 0, '', '', 0,
                            FAItemLedgerEntry."Entry No.", FAItemLedgerEntry."Qty. per Unit of Measure",
                            OldReservationEntry, TransferQty);
                        // OnTransferItemJnlToItemLedgEntryOnAfterTransferReservEntry(OldReservationEntry2, ReservStatus, ItemLedgerEntry);
                    end else
                        if ReservStatus = ReservStatus::Tracking then begin
                            OldReservationEntry2.Delete();
                            OldReservationEntry.Delete();
                            ReservationManagement.ModifyActionMessage(OldReservationEntry."Entry No.", 0, true);
                        end;
                until (OldReservationEntry.Next() = 0) or (TransferQty = 0);
        end; // DO

        exit(true);
    end;

    local procedure TestOldReservEntryLocationCode(var OldReservationEntry: Record "FA Reservation Entry"; var ItemJournalLine: Record "FA Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeTestOldReservEntryLocationCode(OldReservationEntry, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        OldReservationEntry.TestField("Location Code", ItemJournalLine."Location Code");
    end;

    procedure RenameLine(var NewItemJournalLine: Record "FA Item Journal Line"; var OldItemJournalLine: Record "FA Item Journal Line")
    begin
        ReservationEngineMgt.RenamePointer(
            Database::"FA Item Journal Line",
            OldItemJournalLine."Entry Type".AsInteger(),
            OldItemJournalLine."Journal Template Name",
            OldItemJournalLine."Journal Batch Name",
            0,
            OldItemJournalLine."Line No.",
            NewItemJournalLine."Entry Type".AsInteger(),
            NewItemJournalLine."Journal Template Name",
            NewItemJournalLine."Journal Batch Name",
            0,
            NewItemJournalLine."Line No.");
    end;

    procedure DeleteLineConfirm(var ItemJournalLine: Record "FA Item Journal Line"): Boolean
    begin
        if not ItemJournalLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(ItemJournalLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure DeleteLine(var ItemJournalLine: Record "FA Item Journal Line")
    begin
        // OnBeforeDeleteLine(ItemJournalLine);
        if Blocked then
            exit;

        // with ItemJournalLine do begin
        ReservationManagement.SetReservSource(ItemJournalLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        ItemJournalLine.CalcFields("Reserved Qty. (Base)");
        // end;
    end;

    // procedure AssignForPlanning(var ItemJournalLine: Record "FA Item Journal Line")
    // var
    //     PlanningAssignment: Record "Planning Assignment";
    // begin
    //     if ItemJournalLine."Item No." <> '' then
    //         with ItemJournalLine do begin
    //             PlanningAssignment.ChkAssignOne("FA Item No.", "Variant Code", "Location Code", "Posting Date");
    //             if "Entry Type" = "Entry Type"::Transfer then
    //                 PlanningAssignment.ChkAssignOne("Item No.", "Variant Code", "New Location Code", "Posting Date");
    //         end;
    // end;

    procedure Block(SetBlocked: Boolean)
    begin
        Blocked := SetBlocked;
    end;

    local procedure LockReservationEntry(FAItemJournalLine: Record "FA Item Journal Line")
    var
        ReservationEntry: Record "FA Reservation Entry";
    begin
        ReservationEntry.SetItemData(FAItemJournalLine."FA Item No.", '', FAItemJournalLine."Location Code", FAItemJournalLine."Variant Code", 0);
        // TempSKU."Location Code" := ReservationEntry."Location Code";
        // TempSKU."Item No." := ReservationEntry."Item No.";
        // TempSKU."Variant Code" := ReservationEntry."Variant Code";
        // if not TempSKU.Find() then begin
        //     TempSKU.Insert();
        //     ReservationEntry.Lock();
        // end;
    end;
}