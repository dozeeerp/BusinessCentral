namespace TSTChanges.FA.Journal;

using TSTChanges.FA.Ledger;
using TSTChanges.FA.Tracking;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.NoSeries;
using TSTChanges.FA.Setup;
using TSTChanges.FA.FAItem;
using Microsoft.Inventory.Tracking;
using Microsoft.FixedAssets.Setup;
// using Microsoft.FixedAssets.FADepreciation;

codeunit 51208 "FA Item Jnl.-Post Line"
{
    Permissions = TableData "Fixed Asset" = rim,
                  TableData "FA Depreciation Book" = ri,
                  TableData "FA Subclass" = r,
                  tabledata "FA Class" = r;
    //   tabledata "Fixed Asset Block" = r;
    TableNo = "FA Item Journal Line";
    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    var
        GlobalFAItemLedgEntry: Record "FA Item Ledger Entry";
        OldFAItemLedgEntry: Record "FA Item Ledger Entry";
        FAItemJnlLine: Record "FA Item Journal Line";
        ItemJnlLineOrigin: Record "FA Item Journal Line";
        TempSplitItemJnlLine: Record "FA Item Journal Line" temporary;
        PrevAppliedItemLedgEntry: Record "FA Item Ledger Entry";
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        TempTrackingSpecification: Record "FA Tracking Specification" temporary;
        GlobalItemTrackingCode: Record "Item Tracking Code";
        GlobalItemTrackingSetup: Record "Item Tracking Setup";
        ReservEngineMgt: Codeunit "FA Reservation Engine Mgt.";
        LateBindingMgt: Codeunit "FA Late Binding Management";
        Location: Record Location;
        NewLocation: Record Location;
        FAItem: Record "FA Item";
        ItemVariant: Record "FA Item Variant";
        TempTouchedItemLedgerEntries: Record "FA Item Ledger Entry" temporary;
        FAItemLedgEntryNo: Integer;
        DisableItemTracking: Boolean;
        PostponeReservationHandling: Boolean;
        Text01: Label 'Checking for open entries.';
        Text003: Label 'Reserved item %1 is not on inventory.';
        Text004: Label 'is too low';
        Text014: Label 'Serial No. %1 is already on inventory.';
        Text018: Label 'Item Tracking Serial No. %1 Lot No. %2 for Item No. %3 Variant %4 cannot be fully applied.';
        Text021: Label 'You must not define item tracking on %1 %2.';
        Text023: Label 'Entries applied to an Outbound Transfer cannot be unapplied.';
        Text024: Label 'Entries applied to a Drop Shipment Order cannot be unapplied.';
        Text027: Label 'A fixed application was not unapplied and this prevented the reapplication. Use the Application Worksheet to remove the applications.';
        Text029: Label '%1 %2 for %3 %4 is reserved for %5.';
        Text033: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        Text100: Label 'Fatal error when retrieving Tracking Specification.';
        Text99000000: Label 'must not be filled out when reservations exist';
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        CannotUnapplyItemLedgEntryErr: Label 'You cannot proceed with the posting as it will result in negative inventory for item %1. \Item ledger entry %2 cannot be left unapplied.', Comment = '%1 - Item no., %2 - Item ledger entry no.';
        CannotUnapplyCorrEntryErr: Label 'Entries applied to a Correction entry cannot be unapplied.';
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        TempItemEntryRelation: Record "FA Item Entry Relation" temporary;
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;
        QtyPerUnitOfMeasure: Decimal;
        LastOperation: Boolean;
        SkipSerialNoQtyValidation: Boolean;
        ItemApplnEntryNo: Integer;
        ItemJnlLineReserve: Codeunit "FA Item Jnl. Line-Reserve";
        ItemApplnEntry: Record "FA Item Application Entry";
        TotalAppliedQty: Decimal;
        CalledFromApplicationWorksheet: Boolean;
        SkipApplicationCheck: Boolean;

    procedure RunWithCheck(var FAItemJnlLine2: Record "FA Item Journal Line"): Boolean
    var
        TrackingSpecExists: Boolean;
    begin
        PrepareItem(FAItemJnlLine2);
        TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(FAItemJnlLine2, TempTrackingSpecification);
        exit(PostSplitJnlLine(FAItemJnlLine2, TrackingSpecExists))
    end;

    local procedure Code()
    begin
        IF FAItemJnlLine.EmptyLine() and not FAItemJnlLine.Correction then
            exit;

        ItemJnlCheckLine.SetCalledFromInvtPutawayPick(CalledFromInvtPutawayPick);
        ItemJnlCheckLine.SetCalledFromAdjustment(CalledFromAdjustment);

        if FAItemJnlLine."Document Date" = 0D then
            FAItemJnlLine."Document Date" := FAItemJnlLine."Posting Date";

        if FAItemLedgEntryNo = 0 then begin
            GlobalFAItemLedgEntry.LockTable();
            FAItemLedgEntryNo := GlobalFAItemLedgEntry.GetLastEntryNo();
            GlobalFAItemLedgEntry."Entry No." := FAItemLedgEntryNo;
        end;

        if GlobalItemTrackingSetup.TrackingRequired() and (FAItemJnlLine."Quantity (Base)" <> 0) and
                   //("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                   not DisableItemTracking //and not Adjustment and
                                           //    not Subcontracting and not IsAssemblyResourceConsumpLine()
            then
            CheckItemTracking();

        if FAItemJnlLine.Correction then
            UndoQuantityPosting();

        // if FAItemJnlLine."Entry Type" in [FAItemJnlLine."Entry Type"::"Conversion Output"] then begin

        // end;

        // GetGeneralPostingSetup(ItemJnlLine);

        if FAItemJnlLine."Qty. per Unit of Measure" = 0 then
            FAItemJnlLine."Qty. per Unit of Measure" := 1;
        // if FAItemJnlLine."Qty. per Cap. Unit of Measure" = 0 then
        //     FAItemJnlLine."Qty. per Cap. Unit of Measure" := 1;

        FAItemJnlLine.Quantity := FAItemJnlLine."Quantity (Base)";
        FAItemJnlLine."Invoiced Quantity" := FAItemJnlLine."Invoiced Qty. (Base)";
        // "Setup Time" := "Setup Time (Base)";
        // "Run Time" := "Run Time (Base)";
        // "Stop Time" := "Stop Time (Base)";
        // "Output Quantity" := "Output Quantity (Base)";
        // "Scrap Quantity" := "Scrap Quantity (Base)";

        // if not Subcontracting and
        //    (("Entry Type" = "Entry Type"::Output) or
        //     IsAssemblyResourceConsumpLine())
        // then
        //     QtyPerUnitOfMeasure := FAItemJnlLine."Qty. per Cap. Unit of Measure"
        // else
        QtyPerUnitOfMeasure := FAItemJnlLine."Qty. per Unit of Measure";

        // RoundingResidualAmount := 0;
        // RoundingResidualAmountACY := 0;
        // RoundingResidualAmount := Quantity *
        //   ("Unit Cost" / QtyPerUnitOfMeasure - Round("Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision"));
        // RoundingResidualAmountACY := Quantity *
        //   ("Unit Cost (ACY)" / QtyPerUnitOfMeasure - Round("Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision"));

        // "Unit Amount" := Round(
        //     "Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
        // "Unit Cost" := Round(
        //     "Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
        // "Unit Cost (ACY)" := Round(
        //     "Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");

        // OverheadAmount := 0;
        // VarianceAmount := 0;
        // OverheadAmountACY := 0;
        // VarianceAmountACY := 0;
        // VarianceRequired := false;
        LastOperation := false;

        Case true of
            // IsAssemblyResourceConsumpLine():
            // PostAssemblyResourceConsump();
            // Adjustment,
            //     "Value Entry Type" in ["Value Entry Type"::Rounding, "Value Entry Type"::Revaluation],
            //     "Entry Type" = "Entry Type"::"Assembly Consumption",
            FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::"Conversion Output":
                PostItem();
            // FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::Consumption:
            //     PostConsumption();
            // FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::Output:
            //     PostOutput();
            not FAItemJnlLine.Correction:
                PostItem();
        end;

        // Entry no. is returned to shipment/receipt
        // if Subcontracting then
        //     "Item Shpt. Entry No." := CapLedgEntryNo
        // else
        FAItemJnlLine."Item Shpt. Entry No." := GlobalFAItemLedgEntry."Entry No.";
    end;

    procedure PostSplitJnlLine(var FAItemJnlLineToPost: Record "FA Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        PostItemJnlLine: Boolean;
    begin
        PostItemJnlLine := SetupSplitJnlLine(FAItemJnlLineToPost, TrackingSpecExists);
        if not PostItemJnlLine then
            PostItemJnlLine := IsNotInternalWhseMovement(FAItemJnlLineToPost);
        while SplitItemJnlLine(FAItemJnlLine, PostItemJnlLine) do
            if PostItemJnlLine then
                Code();

        Clear(PrevAppliedItemLedgEntry);
        FAItemJnlLineToPost := FAItemJnlLine;
        // CorrectOutputValuationDate(GlobalFAItemLedgEntry);
        RedoApplications();

        exit(PostItemJnlLine);
    end;

    local procedure SetupSplitJnlLine(var FAItemJnlLine2: Record "FA Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        UOMMgt: Codeunit "Unit of Measure Management";
        Invoice: Boolean;
        PostItemJnlLine: Boolean;
        SignFactor: Integer;
        CalcWarrantyDate: Date;
        NonDistrQuantity: Decimal;
        NonDistrAmount: Decimal;
        NonDistrAmountACY: Decimal;
        NonDistrDiscountAmount: Decimal;
    begin
        ItemJnlLineOrigin := FAItemJnlLine2;
        TempSplitItemJnlLine.Reset();
        TempSplitItemJnlLine.DeleteAll();

        DisableItemTracking := not FAItemJnlLine2.ItemPosting();
        Invoice := FAItemJnlLine2."Invoiced Qty. (Base)" <> 0;

        if (FAItemJnlLine2."Entry Type" = FAItemJnlLine2."Entry Type"::Transfer) and PostponeReservationHandling then
            SignFactor := 1
        else
            SignFactor := FAItemJnlLine2.Signed(1);

        GlobalItemTrackingCode.Code := FAItem."Item Tracking Code";
        ItemTrackingMgt.GetItemTrackingSetup(
            GlobalItemTrackingCode, FAItemJnlLine."Entry Type",
            FAItemJnlLine.Signed(FAItemJnlLine."Quantity (Base)") > 0, GlobalItemTrackingSetup);

        if not FAItemJnlLine2.Correction and (FAItemJnlLine2."Quantity (Base)" <> 0) and TrackingSpecExists then begin
            if DisableItemTracking then begin
                if not TempTrackingSpecification.IsEmpty() then
                    Error(Text021);//, FAItemJnlLine2.FieldCaption("Operation No."), FAItemJnlLine2."Operation No.");
            end else begin
                if TempTrackingSpecification.IsEmpty() then
                    Error(Text100);

                CheckItemTrackingIsEmpty(FAItemJnlLine2);

                if Format(GlobalItemTrackingCode."Warranty Date Formula") <> '' then
                    CalcWarrantyDate := CalcDate(GlobalItemTrackingCode."Warranty Date Formula", FAItemJnlLine2."Document Date");

                if SignFactor * FAItemJnlLine2.Quantity < 0 then // Demand
                    if GlobalItemTrackingCode."SN Specific Tracking" or GlobalItemTrackingCode."Lot Specific Tracking" then
                        LateBindingMgt.ReallocateTrkgSpecification(TempTrackingSpecification);

                TempTrackingSpecification.CalcSums(
                  "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Qty. to Handle", "Qty. to Invoice");
                TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Handle (Base)"),
                  TempTrackingSpecification."Qty. to Handle (Base)", SignFactor * FAItemJnlLine2."Quantity (Base)");

                if Invoice then
                    TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Invoice (Base)"),
                      TempTrackingSpecification."Qty. to Invoice (Base)", SignFactor * FAItemJnlLine2."Invoiced Qty. (Base)");

                NonDistrQuantity :=
                    UOMMgt.CalcQtyFromBase(
                        FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code",
                        FAItemJnlLine2."Unit of Measure Code",
                        UOMMgt.RoundQty(
                            UOMMgt.CalcBaseQty(
                                FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code", FAItemJnlLine2."Unit of Measure Code",
                                FAItemJnlLine2.Quantity, FAItemJnlLine2."Qty. per Unit of Measure")),
                    FAItemJnlLine2."Qty. per Unit of Measure");
                // NonDistrAmount := FAItemJnlLine2.Amount;
                // NonDistrAmountACY := FAItemJnlLine2."Amount (ACY)";
                // NonDistrDiscountAmount := FAItemJnlLine2."Discount Amount";

                TempTrackingSpecification.FindSet();
                repeat
                    if GlobalItemTrackingCode."Man. Warranty Date Entry Reqd." then
                        TempTrackingSpecification.TestField("Warranty Date");

                    // if GlobalItemTrackingCode."Use Expiration Dates" then
                    //     CheckExpirationDate(ItemJnlLine2, SignFactor, CalcExpirationDate, ExpirationDateChecked);

                    CheckItemTrackingInformation(
                        FAItemJnlLine2, TempTrackingSpecification, SignFactor, GlobalItemTrackingCode, GlobalItemTrackingSetup);

                    if TempTrackingSpecification."Warranty Date" = 0D then
                        TempTrackingSpecification."Warranty Date" := CalcWarrantyDate;

                    TempTrackingSpecification.Modify();
                    TempSplitItemJnlLine := FAItemJnlLine2;
                    PostItemJnlLine :=
                      PostItemJnlLine or
                      SetupTempSplitItemJnlLine(
                        FAItemJnlLine2, SignFactor, NonDistrQuantity, NonDistrAmount,
                        NonDistrAmountACY, NonDistrDiscountAmount, Invoice);
                until TempTrackingSpecification.Next() = 0;
            end;
        end else
            InsertTempSplitItemJnlLine(FAItemJnlLine2, PostItemJnlLine);

        exit(PostItemJnlLine);
    end;

    local procedure InsertTempSplitItemJnlLine(FAItemJnlLine2: Record "FA Item Journal Line"; var PostItemJnlLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeInsertTempSplitItemJnlLine(ItemJnlLine2, IsServUndoConsumption, PostponeReservationHandling, TempSplitItemJnlLine, IsHandled, PostItemJnlLine);
        if IsHandled then
            exit;

        TempSplitItemJnlLine := FAItemJnlLine2;
        TempSplitItemJnlLine.Insert();

        // OnAfterInsertTempSplitItemJnlLine(TempSplitItemJnlLine, ItemJnlLine2)
    end;

    local procedure SplitItemJnlLine(var FAItemJnlLine2: Record "FA Item Journal Line"; PostItemJnlLine: Boolean): Boolean
    var
        FreeEntryNo: Integer;
        JnlLineNo: Integer;
        SignFactor: Integer;
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnSplitItemJnlLineOnBeforeTracking(
        //     ItemJnlLine2, PostItemJnlLine, TempTrackingSpecification, GlobalItemLedgEntry, TempItemEntryRelation,
        //     PostponeReservationHandling, SignFactor, IsHandled);
        // if not IsHandled then
        if (FAItemJnlLine2."Quantity (Base)" <> 0) and FAItemJnlLine2.TrackingExists() then begin
            if (FAItemJnlLine2."Entry Type" in
                [//FAItemJnlLine2."Entry Type"::Sale,
                FAItemJnlLine2."Entry Type"::"Negative Adjmt."//,
                                                              // FAItemJnlLine2."Entry Type"::Consumption,
                                                              // FAItemJnlLine2."Entry Type"::"Assembly Consumption"
                ]) or
            ((FAItemJnlLine2."Entry Type" = FAItemJnlLine2."Entry Type"::Transfer) and
                not PostponeReservationHandling)
            then
                SignFactor := -1
            else
                SignFactor := 1;

            TempTrackingSpecification.SetTrackingFilterFromItemJnlLine(FAItemJnlLine2);
            if TempTrackingSpecification.FindFirst() then begin
                FreeEntryNo := TempTrackingSpecification."Entry No.";
                TempTrackingSpecification.Delete();
                FAItemJnlLine2.CheckTrackingEqualTrackingSpecification(TempTrackingSpecification);
                TempTrackingSpecification."Quantity (Base)" := SignFactor * FAItemJnlLine2."Quantity (Base)";
                TempTrackingSpecification."Quantity Handled (Base)" := SignFactor * FAItemJnlLine2."Quantity (Base)";
                TempTrackingSpecification."Quantity actual Handled (Base)" := SignFactor * FAItemJnlLine2."Quantity (Base)";
                TempTrackingSpecification."Quantity Invoiced (Base)" := SignFactor * FAItemJnlLine2."Invoiced Qty. (Base)";
                TempTrackingSpecification."Qty. to Invoice (Base)" :=
                SignFactor * (FAItemJnlLine2."Quantity (Base)" - FAItemJnlLine2."Invoiced Qty. (Base)");
                TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                TempTrackingSpecification."Qty. to Handle" := 0;
                TempTrackingSpecification."Qty. to Invoice" :=
                SignFactor * (FAItemJnlLine2.Quantity - FAItemJnlLine2."Invoiced Quantity");
                TempTrackingSpecification."Item Ledger Entry No." := GlobalFAItemLedgEntry."Entry No.";
                TempTrackingSpecification."Transfer Item Entry No." := TempItemEntryRelation."Item Entry No.";
                // OnSplitItemJnlLineOnBeforePostItemJnlLine(TempTrackingSpecification, GlobalItemLedgEntry);
                if PostItemJnlLine then
                    TempTrackingSpecification."Entry No." := TempTrackingSpecification."Item Ledger Entry No.";
                // OnSplitItemJnlLineOnBeforeInsertTempTrkgSpecification(TempTrackingSpecification, ItemJnlLine2, SignFactor);
                InsertTempTrkgSpecification(FreeEntryNo);
            end;// else
                // if (FAItemJnlLine2."Item Charge No." = '') and (FAItemJnlLine2."Job No." = '') then
                //     if not FAItemJnlLine2.Correction then begin // Undo quantity posting
                //         // IsHandled := false;
                //         // OnBeforeTrackingSpecificationMissingErr(ItemJnlLine2, IsHandled);
                //         // if not IsHandled then
                //             Error(TrackingSpecificationMissingErr);
                //     end;
        end;

        if TempSplitItemJnlLine.FindFirst() then begin
            JnlLineNo := FAItemJnlLine2."Line No.";
            FAItemJnlLine2 := TempSplitItemJnlLine;
            FAItemJnlLine2."Line No." := JnlLineNo;
            TempSplitItemJnlLine.Delete();
            exit(true);
        end;
        // if FAItemJnlLine."Phys. Inventory" then
        //     InsertPhysInventoryEntry(ItemJnlLineOrigin);
        exit(false);
    end;

    local procedure InsertTempTrkgSpecification(FreeEntryNo: Integer)
    var
        TempTrackingSpecification2: Record "FA Tracking Specification" temporary;
    begin
        if not TempTrackingSpecification.Insert() then begin
            TempTrackingSpecification2 := TempTrackingSpecification;
            TempTrackingSpecification.Get(TempTrackingSpecification2."Item Ledger Entry No.");
            TempTrackingSpecification.Delete();
            TempTrackingSpecification."Entry No." := FreeEntryNo;
            TempTrackingSpecification.Insert();
            TempTrackingSpecification := TempTrackingSpecification2;
            TempTrackingSpecification.Insert();
        end;
    end;

    procedure PrepareItem(var FAItemJnlLineToPost: Record "FA Item Journal Line")
    begin
        FAItemJnlLine.Copy(FAItemJnlLineToPost);

        // GetGLSetup();
        // GetInvtSetup();
        CheckItemAndItemVariant(FAItemJnlLineToPost."FA Item No.", FAItemJnlLineToPost."Variant Code");

        // OnAfterPrepareItem(ItemJnlLineToPost);
    end;

    procedure SetSkipApplicationCheck(NewValue: Boolean)
    begin
        SkipApplicationCheck := NewValue;
    end;

    local procedure CheckItemAndItemVariant(ItemNo: Code[20]; VariantCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // // OnBeforeCheckItemAndItemVariant(ItemNo, VariantCode, Item, ItemVariant, IsHandled);
        // if IsHandled then
        //     exit;

        if GetItem(ItemNo, false) then begin
            // if not CalledFromAdjustment then
            FAItem.TestField(Blocked, false);
            // OnCheckItemOnAfterGetItem(Item, ItemJnlLine, CalledFromAdjustment);

            if GetItemVariant(ItemNo, VariantCode, false) then begin
                //     if not CalledFromAdjustment then
                ItemVariant.TestField(Blocked, false);
                //     OnCheckItemVariantOnAfterGetItemVariant(ItemVariant, ItemJnlLine, CalledFromAdjustment);
            end else
                ItemVariant.Init();
        end else
            FAItem.Init();

        // OnAfterCheckItemAndVariant(ItemJnlLine, CalledFromAdjustment);
    end;

    local procedure GetItemVariant(ItemNo: Code[20]; VariantCode: Code[10]; Unconditionally: Boolean): Boolean
    var
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        // OnBeforeGetItemVariant(ItemVariant, ItemNo, VariantCode, Unconditionally, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if VariantCode = '' then begin
            Clear(ItemVariant);
            exit(false);
        end;

        if not Unconditionally then
            exit(ItemVariant.Get(ItemNo, VariantCode))
        else
            ItemVariant.Get(ItemNo, VariantCode);
        exit(true);
    end;

    local procedure GetItem(ItemNo: Code[20]; Unconditionally: Boolean): Boolean
    var
        HasGotItem: Boolean;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeGetItem(Item, ItemNo, Unconditionally, HasGotItem, IsHandled);
        // if IsHandled then
        //     exit(HasGotItem);

        if not Unconditionally then
            exit(FAItem.Get(ItemNo))
        else
            FAItem.Get(ItemNo);
        exit(true);
    end;

    procedure PostItem()
    var
    begin
        if FAItemJnlLine."Item Shpt. Entry No." <> 0 then begin
            FAItemJnlLine."Location Code" := '';
            FAItemJnlLine."Variant Code" := '';
        end;

        if GetItem(FAItemJnlLine."FA Item No.", false) then
            CheckIfItemIsBlocked();

        if (FAItemJnlLine.Quantity <> 0) then
            ItemQtyPosting()
    end;

    procedure ItemQtyPosting()
    var
        IsReserved: Boolean;
        InsertItemLedgEntryNeeded: Boolean;
    begin
        if FAItemJnlLine.Quantity <> FAItemJnlLine."Invoiced Quantity" then
            FAItemJnlLine.TestField("Invoiced Quantity", 0);
        FAItemJnlLine.TestField("Item Shpt. Entry No.", 0);
        InitFAItemLedgEntry(GlobalFAItemLedgEntry);

        GlobalFAItemLedgEntry."Remaining Quantity" := GlobalFAItemLedgEntry.Quantity;
        GlobalFAItemLedgEntry.Open := GlobalFAItemLedgEntry."Remaining Quantity" <> 0;

        GlobalFAItemLedgEntry.Positive := GlobalFAItemLedgEntry.Quantity > 0;
        if GlobalFAItemLedgEntry."Entry Type" = GlobalFAItemLedgEntry."Entry Type"::Transfer then
            GlobalFAItemLedgEntry."Completely Invoiced" := true;

        if GlobalFAItemLedgEntry.Quantity > 0 then
            if GlobalFAItemLedgEntry."Entry Type" <> GlobalFAItemLedgEntry."Entry Type"::Transfer then
                IsReserved :=
                  ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                    FAItemJnlLine, GlobalFAItemLedgEntry, FAItemJnlLine."Quantity (Base)", true);

        ApplyItemLedgEntry(GlobalFAItemLedgEntry, OldFAItemLedgEntry, false);// GlobalValueEntry, false);
        // CheckApplFromInProduction(GlobalFAItemLedgEntry, FAItemJnlLine."Applies-from Entry");
        AutoTrack(GlobalFAItemLedgEntry, IsReserved);

        // if ("Entry Type" = "Entry Type"::Transfer) and AverageTransfer then
        //         InsertTransferEntry(GlobalItemLedgEntry, OldItemLedgEntry, TotalAppliedQty);

        if FAItemJnlLine."Entry Type" in [FAItemJnlLine."Entry Type"::"Conversion Output"] then begin
            InsertConItemEntryRelation(GlobalFAItemLedgEntry);
            InsertFixedAssets(GlobalFAItemLedgEntry);
        end;

        InsertItemLedgEntryNeeded := //(not "Phys. Inventory") or 
                                    (FAItemJnlLine.Quantity <> 0);
        if InsertItemLedgEntryNeeded then begin
            InsertItemLedgEntry(GlobalFAItemLedgEntry, false);
            // OnItemQtyPostingOnBeforeInsertApplEntry(GlobalFAItemLedgEntry, FAItemJnlLine);
            if GlobalFAItemLedgEntry.Positive then
                InsertApplEntry(
                  GlobalFAItemLedgEntry."Entry No.", GlobalFAItemLedgEntry."Entry No.",
                  FAItemJnlLine."Applies-from Entry", 0, GlobalFAItemLedgEntry."Posting Date",
                  GlobalFAItemLedgEntry.Quantity, true);
            // OnItemQtyPostingOnAfterInsertApplEntry(ItemJnlLine, TempSplitItemJnlLine, GlobalItemLedgEntry);
        end;
    end;

    procedure InitFAItemLedgEntry(var FAItemLedgEntry: Record "FA Item ledger Entry")
    var
        Loc: Record Location;
    begin
        FAItemLedgEntryNo := FAItemLedgEntryNo + 1;

        FAItemLedgEntry.Init();
        FAItemLedgEntry."Entry No." := FAItemLedgEntryNo;
        FAItemLedgEntry."FA Item No." := FAItemJnlLine."FA Item No.";
        FAItemLedgEntry."Posting Date" := FAItemJnlLine."Posting Date";
        // FAItemLedgEntry."Document Date" := FAItemJnlLine."Document Date";
        FAItemLedgEntry."Entry Type" := FAItemJnlLine."Entry Type";
        FAItemLedgEntry."Source No." := FAItemJnlLine."Source No.";
        FAItemLedgEntry."Document No." := FAItemJnlLine."Document No.";
        FAItemLedgEntry."Document Type" := FAItemJnlLine."Document Type";
        FAItemLedgEntry."Document Line No." := FAItemJnlLine."Document Line No.";
        FAItemLedgEntry."Order Type" := FAItemJnlLine."Order Type";
        FAItemLedgEntry."Order No." := FAItemJnlLine."Order No.";
        FAItemLedgEntry."Order Line No." := FAItemJnlLine."Order Line No.";
        // FAItemLedgEntry."External Document No." := FAItemJnlLine."External Document No.";
        FAItemLedgEntry.Description := FAItemJnlLine.Description;
        FAItemLedgEntry."Location Code" := FAItemJnlLine."Location Code";
        FAItemLedgEntry."Applies-to Entry" := FAItemJnlLine."Applies-to Entry";
        FAItemLedgEntry."Source Type" := FAItemJnlLine."Source Type";
        // FAItemLedgEntry."Transaction Type" := FAItemJnlLine."Transaction Type";
        // FAItemLedgEntry."Transport Method" := FAItemJnlLine."Transport Method";
        // FAItemLedgEntry."Country/Region Code" := FAItemJnlLine."Country/Region Code";
        if (FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::Transfer) and (FAItemJnlLine."New Location Code" <> '') then begin
            if NewLocation.Code <> FAItemJnlLine."New Location Code" then
                NewLocation.Get(FAItemJnlLine."New Location Code");
            // FAItemLedgEntry."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        // FAItemLedgEntry."Entry/Exit Point" := FAItemJnlLine."Entry/Exit Point";
        // FAItemLedgEntry.Area := FAItemJnlLine.Area;
        // FAItemLedgEntry."Transaction Specification" := FAItemJnlLine."Transaction Specification";
        // FAItemLedgEntry."Drop Shipment" := "Drop Shipment";
        // FAItemLedgEntry."Assemble to Order" := "Assemble to Order";
        // FAItemLedgEntry."No. Series" := FAItemJnlLine."Posting No. Series";
        //     GetInvtSetup();
        //     if (ItemLedgEntry.Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
        //         ItemLedgEntry.Description := '';
        //     ItemLedgEntry."Prod. Order Comp. Line No." := "Prod. Order Comp. Line No.";
        FAItemLedgEntry."Variant Code" := FAItemJnlLine."Variant Code";
        FAItemLedgEntry."Unit of Measure Code" := FAItemJnlLine."Unit of Measure Code";
        FAItemLedgEntry."Qty. per Unit of Measure" := FAItemJnlLine."Qty. per Unit of Measure";
        //     ItemLedgEntry."Derived from Blanket Order" := "Derived from Blanket Order";
        //     ItemLedgEntry."Item Reference No." := "Item Reference No.";
        //     ItemLedgEntry."Originally Ordered No." := "Originally Ordered No.";
        //     ItemLedgEntry."Originally Ordered Var. Code" := "Originally Ordered Var. Code";
        //     ItemLedgEntry."Out-of-Stock Substitution" := "Out-of-Stock Substitution";
        //     ItemLedgEntry."Item Category Code" := "Item Category Code";
        //     ItemLedgEntry.Nonstock := Nonstock;
        //     ItemLedgEntry."Purchasing Code" := "Purchasing Code";
        //     ItemLedgEntry."Return Reason Code" := "Return Reason Code";
        //     ItemLedgEntry."Job No." := "Job No.";
        //     ItemLedgEntry."Job Task No." := "Job Task No.";
        //     ItemLedgEntry."Job Purchase" := "Job Purchase";
        FAItemLedgEntry.CopyTrackingFromItemJnlLine(FAItemJnlLine);
        //     ItemLedgEntry."Warranty Date" := "Warranty Date";
        //     ItemLedgEntry."Expiration Date" := "Item Expiration Date";
        // FAItemLedgEntry."Shpt. Method Code" := FAItemJnlLine."Shpt. Method Code";

        if not Loc.IsInTransit(FAItemLedgEntry."Location Code") then
            FAItemLedgEntry."Customer No." := FAItemJnlLine."Customer No.";

        FAItemLedgEntry.Correction := FAItemJnlLine.Correction;

        if FAItemJnlLine."Entry Type" in
           [//"Entry Type"::Sale,
            FAItemJnlLine."Entry Type"::"Negative Adjmt.",
            FAItemJnlLine."Entry Type"::Transfer
            //         "Entry Type"::Consumption,
            //         "Entry Type"::"Assembly Consumption"
            ]
            then begin
            FAItemLedgEntry.Quantity := -FAItemJnlLine.Quantity;
            FAItemLedgEntry."Invoiced Quantity" := -FAItemJnlLine."Invoiced Quantity";
        end else begin
            FAItemLedgEntry.Quantity := FAItemJnlLine.Quantity;
            FAItemLedgEntry."Invoiced Quantity" := FAItemJnlLine."Invoiced Quantity";
        end;
        if (FAItemLedgEntry.Quantity < 0) and (FAItemJnlLine."Entry Type" <> FAItemJnlLine."Entry Type"::Transfer) then
            FAItemLedgEntry."Shipped Qty. Not Returned" := FAItemLedgEntry.Quantity;
    end;

    procedure InsertItemLedgEntry(var FAItemLedgEntry: Record "FA Item Ledger Entry"; TransferItem: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeInsertItemLedgEntryProcedure(ItemLedgEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if FAItemLedgEntry.Open then begin
            FAItemLedgEntry.VerifyOnInventory();

            // if not (("Document Type" in ["Document Type"::"Purchase Return Shipment", "Document Type"::"Purchase Receipt"]) and
            //         ("Job No." <> ''))
            // then
            if (FAItemLedgEntry.Quantity < 0) and GlobalItemTrackingCode.IsSpecific() then
                Error(Text018, FAItemJnlLine."Serial No.", FAItemJnlLine."Lot No.", FAItemJnlLine."FA Item No.", FAItemJnlLine."Variant Code");

            if GlobalItemTrackingCode."SN Specific Tracking" then begin
                if FAItemLedgEntry.Quantity > 0 then
                    CheckItemSerialNo(FAItemJnlLine);

                if not (FAItemLedgEntry.Quantity in [-1, 0, 1]) then
                    Error(Text033);
            end;



            // if ("Document Type" <> "Document Type"::"Purchase Return Shipment") and ("Job No." = '') then
            // if (FAItem.Reserve = FAItem.Reserve::Always) and (FAItemLedgEntry.Quantity < 0) then begin
            //     // IsHandled := false;
            //     // OnInsertItemLedgEntryOnBeforeReservationError(ItemJnlLine, ItemLedgEntry, IsHandled, Location);
            //     //         if not IsHandled then
            //     Error(Text012, FAItemLedgEntry."FA Item No.");
            // end;
        end;

        if IsWarehouseReclassification(FAItemJnlLine) then begin
            FAItemLedgEntry."Global Dimension 1 Code" := OldFAItemLedgEntry."Global Dimension 1 Code";
            FAItemLedgEntry."Global Dimension 2 Code" := OldFAItemLedgEntry."Global Dimension 2 Code";
            FAItemLedgEntry."Dimension Set ID" := OldFAItemLedgEntry."Dimension Set ID"
        end else
            if TransferItem then begin
                FAItemLedgEntry."Global Dimension 1 Code" := FAItemJnlLine."New Shortcut Dimension 1 Code";
                FAItemLedgEntry."Global Dimension 2 Code" := FAItemJnlLine."New Shortcut Dimension 2 Code";
                FAItemLedgEntry."Dimension Set ID" := FAItemJnlLine."New Dimension Set ID";
            end else begin
                FAItemLedgEntry."Global Dimension 1 Code" := FAItemJnlLine."Shortcut Dimension 1 Code";
                FAItemLedgEntry."Global Dimension 2 Code" := FAItemJnlLine."Shortcut Dimension 2 Code";
                FAItemLedgEntry."Dimension Set ID" := FAItemJnlLine."Dimension Set ID";
            end;

        if not (FAItemJnlLine."Entry Type" in [FAItemJnlLine."Entry Type"::Transfer]) and//, FAItemJnlLine."Entry Type"::Output]) and
           (FAItemLedgEntry.Quantity = FAItemLedgEntry."Invoiced Quantity")
        then
            FAItemLedgEntry."Completely Invoiced" := true;

        // if ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '') and
        //    ("Invoiced Quantity" <> 0) and ("Posting Date" > ItemLedgEntry."Last Invoice Date")
        // then
        //     ItemLedgEntry."Last Invoice Date" := "Posting Date";

        // if "Entry Type" = "Entry Type"::Consumption then
        //     ItemLedgEntry."Applied Entry to Adjust" := true;

        // if "Job No." <> '' then begin
        //     ItemLedgEntry."Job No." := "Job No.";
        //     ItemLedgEntry."Job Task No." := "Job Task No.";
        //     ItemLedgEntry."Order Line No." := "Job Contract Entry No.";
        // end;

        FAItemLedgEntry.UpdateItemTracking();

        // OnBeforeInsertItemLedgEntry(ItemLedgEntry, ItemJnlLine, TransferItem, OldItemLedgEntry, ItemJnlLineOrigin);
        FAItemLedgEntry.Insert(true);
        // OnAfterInsertItemLedgEntry(ItemLedgEntry, ItemJnlLine, ItemLedgEntryNo, ValueEntryNo, ItemApplnEntryNo, GlobalValueEntry, TransferItem, InventoryPostingToGL, OldItemLedgEntry);

        InsertItemReg(FAItemLedgEntry."Entry No.", 0, 0, 0);
        // end;
    end;

    local procedure InsertItemReg(ItemLedgEntryNo: Integer; PhysInvtEntryNo: Integer; ValueEntryNo: Integer; CapLedgEntryNo: Integer)
    begin
        // with ItemJnlLine do
        //     if ItemReg."No." = 0 then begin
        //         ItemReg.LockTable();
        //         ItemReg."No." := ItemReg.GetLastEntryNo() + 1;
        //         ItemReg.Init();
        //         ItemReg."From Entry No." := ItemLedgEntryNo;
        //         ItemReg."To Entry No." := ItemLedgEntryNo;
        //         ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
        //         ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;
        //         ItemReg."From Value Entry No." := ValueEntryNo;
        //         ItemReg."To Value Entry No." := ValueEntryNo;
        //         ItemReg."From Capacity Entry No." := CapLedgEntryNo;
        //         ItemReg."To Capacity Entry No." := CapLedgEntryNo;
        //         ItemReg."Creation Date" := Today;
        //         ItemReg."Creation Time" := Time;
        //         ItemReg."Source Code" := "Source Code";
        //         ItemReg."Journal Batch Name" := "Journal Batch Name";
        //         ItemReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(ItemReg."User ID"));
        //         OnInsertItemRegOnBeforeItemRegInsert(ItemReg, ItemJnlLine);
        //         ItemReg.Insert();
        //     end else begin
        //         if ((ItemLedgEntryNo < ItemReg."From Entry No.") and (ItemLedgEntryNo <> 0)) or
        //            ((ItemReg."From Entry No." = 0) and (ItemLedgEntryNo > 0))
        //         then
        //             ItemReg."From Entry No." := ItemLedgEntryNo;
        //         if ItemLedgEntryNo > ItemReg."To Entry No." then
        //             ItemReg."To Entry No." := ItemLedgEntryNo;

        //         if ((PhysInvtEntryNo < ItemReg."From Phys. Inventory Entry No.") and (PhysInvtEntryNo <> 0)) or
        //            ((ItemReg."From Phys. Inventory Entry No." = 0) and (PhysInvtEntryNo > 0))
        //         then
        //             ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
        //         if PhysInvtEntryNo > ItemReg."To Phys. Inventory Entry No." then
        //             ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;

        //         if ((ValueEntryNo < ItemReg."From Value Entry No.") and (ValueEntryNo <> 0)) or
        //            ((ItemReg."From Value Entry No." = 0) and (ValueEntryNo > 0))
        //         then
        //             ItemReg."From Value Entry No." := ValueEntryNo;
        //         if ValueEntryNo > ItemReg."To Value Entry No." then
        //             ItemReg."To Value Entry No." := ValueEntryNo;
        //         if ((CapLedgEntryNo < ItemReg."From Capacity Entry No.") and (CapLedgEntryNo <> 0)) or
        //            ((ItemReg."From Capacity Entry No." = 0) and (CapLedgEntryNo > 0))
        //         then
        //             ItemReg."From Capacity Entry No." := CapLedgEntryNo;
        //         if CapLedgEntryNo > ItemReg."To Capacity Entry No." then
        //             ItemReg."To Capacity Entry No." := CapLedgEntryNo;

        //         ItemReg.Modify();
        //     end;
    end;

    procedure InsertApplEntry(ItemLedgEntryNo: Integer; InboundItemEntry: Integer; OutboundItemEntry: Integer; TransferedFromEntryNo: Integer; PostingDate: Date; Quantity: Decimal; CostToApply: Boolean)
    var
        ApplItemLedgEntry: Record "FA Item Ledger Entry";
        OldItemApplnEntry: Record "FA Item Application Entry";
        ItemApplHistoryEntry: Record "FA Item App Entry History";
        ItemApplnEntryExists: Boolean;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeInsertApplEntry(
        //     ItemLedgEntryNo, InboundItemEntry, OutboundItemEntry, TransferedFromEntryNo, PostingDate, Quantity, CostToApply, IsHandled);
        // if IsHandled then
        //     exit;

        if FAItem.IsNonInventoriableType() then
            exit;

        if ItemApplnEntryNo = 0 then begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.LockTable();
            ItemApplnEntryNo := ItemApplnEntry.GetLastEntryNo();
            if ItemApplnEntryNo > 0 then begin
                ItemApplHistoryEntry.Reset();
                ItemApplHistoryEntry.LockTable();
                ItemApplHistoryEntry.SetCurrentKey("Entry No.");
                if ItemApplHistoryEntry.FindLast() then
                    if ItemApplHistoryEntry."Entry No." > ItemApplnEntryNo then
                        ItemApplnEntryNo := ItemApplHistoryEntry."Entry No.";
            end
            else
                ItemApplnEntryNo := 0;
        end;

        if Quantity < 0 then begin
            OldItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            OldItemApplnEntry.SetRange("Inbound Item Entry No.", InboundItemEntry);
            OldItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            OldItemApplnEntry.SetRange("Outbound Item Entry No.", OutboundItemEntry);
            if OldItemApplnEntry.FindFirst() then begin
                ItemApplnEntry := OldItemApplnEntry;
                ItemApplnEntry.Quantity := ItemApplnEntry.Quantity + Quantity;
                ItemApplnEntry."Last Modified Date" := CurrentDateTime;
                ItemApplnEntry."Last Modified By User" := UserId;

                // OnInsertApplEntryOnBeforeModify(ItemApplnEntry);

                ItemApplnEntry.Modify();
                ItemApplnEntryExists := true;
            end;
        end;

        if not ItemApplnEntryExists then begin
            ItemApplnEntryNo := ItemApplnEntryNo + 1;
            ItemApplnEntry.Init();
            ItemApplnEntry."Entry No." := ItemApplnEntryNo;
            ItemApplnEntry."Item Ledger Entry No." := ItemLedgEntryNo;
            ItemApplnEntry."Inbound Item Entry No." := InboundItemEntry;
            ItemApplnEntry."Outbound Item Entry No." := OutboundItemEntry;
            ItemApplnEntry."Transferred-from Entry No." := TransferedFromEntryNo;
            ItemApplnEntry.Quantity := Quantity;
            ItemApplnEntry."Posting Date" := PostingDate;
            ItemApplnEntry."Output Completely Invd. Date" := GetOutputComplInvcdDate(ItemApplnEntry);

            // if AverageTransfer then begin
            // if (Quantity > 0) or (FAItemJnlLine."Document Type" = FAItemJnlLine."Document Type"::"Transfer Receipt") then
            // ItemApplnEntry."Cost Application" :=
            //           ItemApplnEntry.IsOutbndItemApplEntryCostApplication(ItemLedgEntryNo) and IsNotValuedByAverageCost(ItemLedgEntryNo);
            // end else
            case true of
                // FAItem."Costing Method" <> FAItem."Costing Method"::Average,
                // FAItemJnlLine.Correction and (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Posted Assembly"):
                //     ItemApplnEntry."Cost Application" := true;
                FAItemJnlLine.Correction:
                    begin
                        ApplItemLedgEntry.Get(ItemApplnEntry."Item Ledger Entry No.");
                        ItemApplnEntry."Cost Application" :=
                          (ApplItemLedgEntry.Quantity > 0) or (ApplItemLedgEntry."Applies-to Entry" <> 0);
                    end;
                else
                    if (FAItemJnlLine."Applies-to Entry" <> 0) or
                       (CostToApply and FAItemJnlLine.IsInbound())
                    then
                        ItemApplnEntry."Cost Application" := true;
            end;

            ItemApplnEntry."Creation Date" := CurrentDateTime;
            ItemApplnEntry."Created By User" := UserId;
            // OnBeforeItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
            ItemApplnEntry.Insert(true);
            // OnAfterItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
        end;
    end;

    local procedure UpdateItemApplnEntry(ItemLedgEntryNo: Integer; PostingDate: Date)
    var
        ItemApplnEntry: Record "FA Item Application Entry";
    begin
        // with ItemApplnEntry do begin
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ItemApplnEntry.SetRange("Output Completely Invd. Date", 0D);
        if not ItemApplnEntry.IsEmpty() then
            ItemApplnEntry.ModifyAll("Output Completely Invd. Date", PostingDate);
        // end;
    end;

    local procedure GetOutputComplInvcdDate(ItemApplnEntry: Record "FA Item Application Entry"): Date
    var
        OutbndItemLedgEntry: Record "FA Item Ledger Entry";
    begin
        // with ItemApplnEntry do begin
        if ItemApplnEntry.Quantity > 0 then
            exit(ItemApplnEntry."Posting Date");
        if OutbndItemLedgEntry.Get(ItemApplnEntry."Outbound Item Entry No.") then
            if OutbndItemLedgEntry."Completely Invoiced" then
                exit(OutbndItemLedgEntry."Last Invoice Date");
        // end;
    end;

    local procedure CheckItemTrackingIsEmpty(FAItemJnlLine: Record "FA Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckItemTrackingIsEmpty(ItemJnlLine, IsHandled);
        // if IsHandled then
        //     exit;

        FAItemJnlLine.CheckTrackingIsEmpty();
        FAItemJnlLine.CheckNewTrackingIsEmpty();
    end;

    local procedure CheckItemSerialNo(FAItemJnlLine: Record "FA Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckSerialNo(ItemJnlLine, IsHandled);
        // if IsHandled then
        //     exit;

        if SkipSerialNoQtyValidation then
            exit;

        // with FAItemJnlLine do
        if FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::Transfer then begin
            if ItemTrackingMgt.FindInInventory(FAItemJnlLine."FA Item No.", FAItemJnlLine."Variant Code"
                                , FAItemJnlLine."New Serial No.") then
                Error(Text014, FAItemJnlLine."New Serial No.")
        end else
            if ItemTrackingMgt.FindInInventory(FAItemJnlLine."FA Item No.", FAItemJnlLine."Variant Code"
            , FAItemJnlLine."Serial No.") then
                Error(Text014, FAItemJnlLine."Serial No.");
    end;

    local procedure CheckItemTrackingInformation(var FAItemJnlLine2: Record "FA Item Journal Line"; var FATrackingSpecification: Record "FA Tracking Specification"; SignFactor: Decimal; ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingSetup: Record "Item Tracking Setup")
    var
        SerialNoInfo: Record "Serial No. Information";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckItemTrackingInformation(ItemJnlLine2, TrackingSpecification, ItemTrackingSetup, SignFactor, ItemTrackingCode, IsHandled, GlobalItemTrackingCode);
        // if IsHandled then
        //     exit;

        if ItemTrackingCode."Create SN Info on Posting" then
            ItemTrackingMgt.CreateSerialNoInformation(FATrackingSpecification);

        IsHandled := false;
        // OnCheckItemTrackingInformationOnBeforeTestFields(ItemTrackingSetup, TrackingSpecification, ItemJnlLine2, IsHandled);
        if not IsHandled then
            if ItemTrackingSetup."Serial No. Info Required" then begin
                SerialNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                                , FATrackingSpecification."Serial No.");
                SerialNoInfo.TestField(Blocked, false);
                if FATrackingSpecification."New Serial No." <> '' then begin
                    SerialNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code",
                                    FATrackingSpecification."New Serial No.");
                    SerialNoInfo.TestField(Blocked, false);
                end;
            end else begin
                if SerialNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                                    , FATrackingSpecification."Serial No.") then
                    SerialNoInfo.TestField(Blocked, false);
                if FATrackingSpecification."New Serial No." <> '' then
                    if SerialNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                                        , FATrackingSpecification."New Serial No.") then
                        SerialNoInfo.TestField(Blocked, false);
            end;

        if ItemTrackingCode."Create Lot No. Info on posting" then
            ItemTrackingMgt.CreateLotNoInformation(FATrackingSpecification);

        CheckLotNoInfoNotBlocked(ItemTrackingSetup, FAItemJnlLine2, FATrackingSpecification);

        // OnAfterCheckItemTrackingInformation(ItemJnlLine2, TrackingSpecification, ItemTrackingSetup, Item);
    end;

    local procedure CheckLotNoInfoNotBlocked(ItemTrackingSetup: Record "Item Tracking Setup"; var FAItemJnlLine2: Record "FA Item Journal Line"; var FATrackingSpecification: Record "FA Tracking Specification")
    var
        LotNoInfo: Record "Lot No. Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckLotNoInfoNotBlocked(ItemJnlLine2, IsHandled, ItemTrackingSetup, TrackingSpecification);
        if IsHandled then
            exit;

        if ItemTrackingSetup."Lot No. Info Required" then begin
            LotNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                        , FATrackingSpecification."Lot No.");
            LotNoInfo.TestField(Blocked, false);
            if FATrackingSpecification."New Lot No." <> '' then begin
                LotNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                            , FATrackingSpecification."New Lot No.");
                LotNoInfo.TestField(Blocked, false);
            end;
        end else begin
            if LotNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                            , FATrackingSpecification."Lot No.") then
                LotNoInfo.TestField(Blocked, false);
            if FATrackingSpecification."New Lot No." <> '' then
                if LotNoInfo.Get(FAItemJnlLine2."FA Item No.", FAItemJnlLine2."Variant Code"
                                , FATrackingSpecification."New Lot No.") then
                    LotNoInfo.TestField(Blocked, false);
        end;
    end;

    procedure SetupTempSplitItemJnlLine(FAItemJnlLine2: Record "FA Item Journal Line"; SignFactor: Integer; var NonDistrQuantity: Decimal; var NonDistrAmount: Decimal; var NonDistrAmountACY: Decimal; var NonDistrDiscountAmount: Decimal; Invoice: Boolean): Boolean
    var
        FloatingFactor: Decimal;
        PostItemJnlLine: Boolean;
    begin
        TempSplitItemJnlLine."Quantity (Base)" := SignFactor * TempTrackingSpecification."Qty. to Handle (Base)";
        TempSplitItemJnlLine.Quantity := SignFactor * TempTrackingSpecification."Qty. to Handle";

        if Invoice then begin
            TempSplitItemJnlLine."Invoiced Quantity" := SignFactor * TempTrackingSpecification."Qty. to Invoice";
            TempSplitItemJnlLine."Invoiced Qty. (Base)" := SignFactor * TempTrackingSpecification."Qty. to Invoice (Base)";
        end;

        // with TempSplitItemJnlLine do begin

        // if FAItemJnlLine2."Output Quantity" <> 0 then begin
        //     "Output Quantity (Base)" := "Quantity (Base)";
        //     "Output Quantity" := Quantity;
        // end;

        if FAItemJnlLine2."Phys. Inventory" then
            FAItemJnlLine2."Qty. (Phys. Inventory)" := FAItemJnlLine2."Qty. (Calculated)" + SignFactor * FAItemJnlLine2."Quantity (Base)";

        // OnAfterSetupTempSplitItemJnlLineSetQty(TempSplitItemJnlLine, ItemJnlLine2, SignFactor, TempTrackingSpecification);

        FloatingFactor := FAItemJnlLine2.Quantity / NonDistrQuantity;
        if FloatingFactor < 1 then begin
            // Amount := Round(NonDistrAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
            // "Amount (ACY)" := Round(NonDistrAmountACY * FloatingFactor, Currency."Amount Rounding Precision");
            // "Discount Amount" := Round(NonDistrDiscountAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
            // NonDistrAmount := NonDistrAmount - Amount;
            // NonDistrAmountACY := NonDistrAmountACY - "Amount (ACY)";
            // NonDistrDiscountAmount := NonDistrDiscountAmount - "Discount Amount";
            NonDistrQuantity := NonDistrQuantity - FAItemJnlLine2.Quantity;
            // "Setup Time" := 0;
            // "Run Time" := 0;
            // "Stop Time" := 0;
            // "Setup Time (Base)" := 0;
            // "Run Time (Base)" := 0;
            // "Stop Time (Base)" := 0;
            // "Starting Time" := 0T;
            // "Ending Time" := 0T;
            // "Scrap Quantity" := 0;
            // "Scrap Quantity (Base)" := 0;
            // "Concurrent Capacity" := 0;
        end else begin // the last record
            // Amount := NonDistrAmount;
            // "Amount (ACY)" := NonDistrAmountACY;
            // "Discount Amount" := NonDistrDiscountAmount;
        end;

        // if Round("Unit Amount" * Quantity, GLSetup."Amount Rounding Precision") <> Amount then
        //     if ("Unit Amount" = "Unit Cost") and ("Unit Cost" <> 0) then begin
        //         "Unit Amount" := Round(Amount / Quantity, 0.00001);
        //         "Unit Cost" := Round(Amount / Quantity, 0.00001);
        //         "Unit Cost (ACY)" := Round("Amount (ACY)" / Quantity, 0.00001);
        //     end else
        //         "Unit Amount" := Round(Amount / Quantity, 0.00001);

        TempSplitItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification);
        // "Item Expiration Date" := TempTrackingSpecification."Expiration Date";
        TempSplitItemJnlLine.CopyNewTrackingFromNewSpec(TempTrackingSpecification);
        // "New Item Expiration Date" := TempTrackingSpecification."New Expiration Date";

        // OnSetupTempSplitItemJnlLineOnBeforeCalcPostItemJnlLine(TempSplitItemJnlLine, TempTrackingSpecification);
        PostItemJnlLine := not TempSplitItemJnlLine.HasSameNewTracking(); //or ("Item Expiration Date" <> "New Item Expiration Date");
                                                                          // OnSetupTempSplitItemJnlLineOnAfterCalcPostItemJnlLine(TempSplitItemJnlLine, TempTrackingSpecification, PostItemJnlLine);

        // "Warranty Date" := TempTrackingSpecification."Warranty Date";

        TempSplitItemJnlLine."Line No." := TempTrackingSpecification."Entry No.";

        if TempTrackingSpecification.Correction then //or "Drop Shipment" or IsServUndoConsumption then
            TempSplitItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Item Ledger Entry No."
        else
            TempSplitItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Appl.-to Item Entry";
        TempSplitItemJnlLine."Applies-from Entry" := TempTrackingSpecification."Appl.-from Item Entry";

        // OnBeforeInsertSetupTempSplitItemJnlLine(TempTrackingSpecification, TempSplitItemJnlLine, PostItemJnlLine, ItemJnlLine2, SignFactor, FloatingFactor);

        TempSplitItemJnlLine.Insert();
        // end;

        exit(PostItemJnlLine);
    end;

    procedure CheckItemTracking()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckItemTracking(ItemJnlLine, GlobalItemTrackingSetup, IsHandled, TempTrackingSpecification);
        if IsHandled then
            exit;

        if GlobalItemTrackingSetup."Serial No. Required" and (FAItemJnlLine."Serial No." = '') then
            Error(GetTextStringWithLineNo(SerialNoRequiredErr, FAItemJnlLine."FA Item No.", FAItemJnlLine."Line No."));
        if GlobalItemTrackingSetup."Lot No. Required" and (FAItemJnlLine."Lot No." = '') then
            Error(GetTextStringWithLineNo(LotNoRequiredErr, FAItemJnlLine."FA Item No.", FAItemJnlLine."Line No."));

        // OnCheckItemTrackingOnAfterCheckRequiredTrackingNos(ItemJnlLine, GlobalItemTrackingSetup);

        if FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::Transfer then
            FAItemJnlLine.CheckNewTrackingIfRequired(GlobalItemTrackingSetup);

        // OnAfterCheckItemTracking(ItemJnlLine, GlobalItemTrackingSetup, GlobalItemTrackingCode);
    end;

    local procedure GetTextStringWithLineNo(BasicTextString: Text; ItemNo: Code[20]; LineNo: Integer): Text
    begin
        if LineNo = 0 then
            exit(StrSubstNo(BasicTextString, ItemNo));
        exit(StrSubstNo(BasicTextString, ItemNo) + StrSubstNo(LineNoTxt, LineNo));
    end;

    local procedure InsertConItemEntryRelation(FAItemLedgerEntry: Record "FA Item Ledger Entry")
    begin
        GetItem(FAItemLedgerEntry."FA Item No.", true);
        if FAItem."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := FAItemLedgerEntry."Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(FAItemLedgerEntry);
            // OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemLedgerEntry);
            TempItemEntryRelation.Insert();
        end;
    end;

    local procedure InsertFixedAssets(var FAItemLedgerEntry: Record "FA Item Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        FADepBooks: Record "FA Depreciation Book";
        MainAsset: Code[20];
        FAConSetup: Record "FA Conversion Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if FAItemLedgerEntry."Entry Type" <> FAItemLedgerEntry."Entry Type"::"Conversion Output" then
            exit;

        FAItem.TestFixedAssetFields();
        FAConSetup.Get();
        if FAConSetup."Use Diffrent No Series for FA" then
            FAConSetup.TestField("FA Nos.");

        //Insert Fixed Asset
        FixedAsset.Init();
        if FAConSetup."Use Diffrent No Series for FA" then begin
            FixedAsset."No. Series" := FAConSetup."FA Nos.";
            FixedAsset."No." := NoSeries.GetNextNo(FAConSetup."FA Nos.");
        end;
        FixedAsset.Insert(true);

        FixedAsset.Validate(Description, FAItemLedgerEntry.Description);
        FixedAsset."Serial No." := FAItemLedgerEntry."Serial No.";
        FixedAsset.validate("FA Class Code", FAItem."FA Class Code");
        FixedAsset.Validate("FA Subclass Code", FAItem."FA Subclass Code");
        FixedAsset."FA Posting Group" := FAItem."FA Posting Group";
        // FixedAsset."FA Block Code" := FAItem."FA Block Code";
        FixedAsset.Modify(true);

        //Insert Fixed Asset Depreciation Books - Company
        FADepBooks.Init();
        FADepBooks."FA No." := FixedAsset."No.";
        FADepBooks.Validate("Depreciation Book Code", 'COMPANY');
        FADepBooks.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepBooks.Validate("Depreciation Method", FADepBooks."Depreciation Method"::"Straight-Line");
        FADepBooks.Validate("Depreciation Starting Date", FAItemLedgerEntry."Posting Date");
        FADepBooks.Validate("No. of Depreciation Years", FAItem."No. of Depreciation Years");
        FADepBooks.Insert(true);

        //Insert Fixed Asset Depreciation Books - Income Tax
        FADepBooks.Init();
        FADepBooks."FA No." := FixedAsset."No.";
        FADepBooks.Validate("Depreciation Book Code", 'INCOME TAX');
        FADepBooks.Validate("Depreciation Method", FADepBooks."Depreciation Method"::"Declining-Balance 1");
        FADepBooks.Validate("Depreciation Starting Date", FAItemLedgerEntry."Posting Date");
        FADepBooks.Insert(true);

        //Add Fixed asset no on FA Item Ledger Entry
        MainAsset := FixedAsset."No.";
        FAItemLedgerEntry."FA No." := MainAsset;
    end;

    procedure RedoApplications()
    var
        TouchedItemLedgEntry: Record "FA Item Ledger Entry";
        DialogWindow: Dialog;
        "Count": Integer;
        t: Integer;
    begin
        TempTouchedItemLedgerEntries.SetCurrentKey("FA Item No.", Open, Positive, "Location Code", "Posting Date");
        if TempTouchedItemLedgerEntries.Find('-') then begin
            DialogWindow.Open(Text01 +
              '@1@@@@@@@@@@@@@@@@@@@@@@@');
            Count := TempTouchedItemLedgerEntries.Count();
            t := 0;

            repeat
                t := t + 1;
                DialogWindow.Update(1, Round(t * 10000 / Count, 1));
                TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                if TouchedItemLedgEntry."Remaining Quantity" <> 0 then begin
                    ReApply(TouchedItemLedgEntry, 0);
                    TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                end;
            until TempTouchedItemLedgerEntries.Next() = 0;
            if AnyTouchedEntries() then
                VerifyTouchedOnInventory();
            TempTouchedItemLedgerEntries.DeleteAll();
            DeleteTouchedEntries();
            DialogWindow.Close();
        end;
    end;

    procedure ReApply(ItemLedgEntry: Record "FA Item Ledger Entry"; ApplyWith: Integer)
    var
        ItemLedgEntry2: Record "FA Item Ledger Entry";
        // ValueEntry: Record "Value Entry";
        InventoryPeriod: Record "Inventory Period";
        CostApplication: Boolean;
    begin
        GetItem(ItemLedgEntry."FA Item No.", true);

        if not InventoryPeriod.IsValidDate(ItemLedgEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemLedgEntry."Posting Date");

        GlobalItemTrackingCode.Code := FAItem."Item Tracking Code";
        // OnReApplyOnBeforeGetItemTrackingSetup(Item, GlobalItemTrackingCode);
        ItemTrackingMgt.GetItemTrackingSetup(
            GlobalItemTrackingCode, FAItemJnlLine."Entry Type",
            FAItemJnlLine.Signed(FAItemJnlLine."Quantity (Base)") > 0, GlobalItemTrackingSetup);

        TotalAppliedQty := 0;
        CostApplication := false;
        if ApplyWith <> 0 then begin
            ItemLedgEntry2.Get(ApplyWith);
            if ItemLedgEntry2.Quantity > 0 then begin
                // Switch around so ItemLedgEntry is positive and ItemLedgEntry2 is negative
                OldFAItemLedgEntry := ItemLedgEntry;
                ItemLedgEntry := ItemLedgEntry2;
                ItemLedgEntry2 := OldFAItemLedgEntry;
            end;

            // OnReApplyOnBeforeStartApply(ItemLedgEntry, ItemLedgEntry2);

            if not ((ItemLedgEntry.Quantity > 0) and // not(Costprovider(ItemLedgEntry))
                    (//(ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Purchase) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Positive Adjmt.") or
                     //(ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Output) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Conversion Output"))
                    )
            then
                CostApplication := true;
            if (ItemLedgEntry."Remaining Quantity" <> 0) and (ItemLedgEntry2."Remaining Quantity" <> 0) then
                CostApplication := false;
            // if CostApplication then
            //     CostApply(ItemLedgEntry, ItemLedgEntry2)
            // else begin
            CreateItemJnlLineFromEntry(ItemLedgEntry2, ItemLedgEntry2."Remaining Quantity", FAItemJnlLine);
            if ApplyWith = ItemLedgEntry2."Entry No." then
                ItemLedgEntry2."Applies-to Entry" := ItemLedgEntry."Entry No."
            else
                ItemLedgEntry2."Applies-to Entry" := ApplyWith;
            FAItemJnlLine."Applies-to Entry" := ItemLedgEntry2."Applies-to Entry";
            GlobalFAItemLedgEntry := ItemLedgEntry2;
            ApplyItemLedgEntry(ItemLedgEntry2, OldFAItemLedgEntry, false);//ValueEntry, false);
            // TouchItemEntryCost(ItemLedgEntry2, false);
            ItemLedgEntry2.Modify();
            // EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry2);
            // GetValuationDate(ValueEntry, ItemLedgEntry);
            // UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            // end;

            // if ItemApplnEntry.Fixed() and (ItemApplnEntry.CostReceiver() <> 0) then
            //     if GetItem(ItemLedgEntry."FA Item No.", false) then
            //         if FAItem."Costing Method" = FAItem."Costing Method"::Average then
            //             UpdateValuedByAverageCost(ItemApplnEntry.CostReceiver(), false);
        end else begin  // ApplyWith is 0
            ItemLedgEntry."Applies-to Entry" := ApplyWith;
            CreateItemJnlLineFromEntry(ItemLedgEntry, ItemLedgEntry."Remaining Quantity", FAItemJnlLine);
            FAItemJnlLine."Applies-to Entry" := ItemLedgEntry."Applies-to Entry";
            GlobalFAItemLedgEntry := ItemLedgEntry;
            ApplyItemLedgEntry(ItemLedgEntry, OldFAItemLedgEntry, false);// ValueEntry, false);
            // TouchItemEntryCost(ItemLedgEntry, false);
            ItemLedgEntry.Modify();
            // EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
            // GetValuationDate(ValueEntry, ItemLedgEntry);
            // UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
        end;
    end;

    local procedure CreateItemJnlLineFromEntry(ItemLedgEntry: Record "FA Item Ledger Entry"; NewQuantity: Decimal; var ItemJnlLine: Record "FA Item Journal Line")
    begin
        Clear(ItemJnlLine);
        // with ItemJnlLine do begin
        ItemJnlLine."Entry Type" := ItemLedgEntry."Entry Type"; // no mapping needed
        ItemJnlLine.Quantity := ItemJnlLine.Signed(NewQuantity);
        ItemJnlLine."FA Item No." := ItemLedgEntry."Fa Item No.";
        ItemJnlLine.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
        // end;

        // OnAfterCreateItemJnlLineFromEntry(ItemJnlLine, ItemLedgEntry);
    end;

    procedure AnyTouchedEntries(): Boolean
    begin
        exit(TempTouchedItemLedgerEntries.Find('-'));
    end;

    local procedure VerifyTouchedOnInventory()
    var
        ItemLedgEntryApplied: Record "FA Item Ledger Entry";
    begin
        // with TempTouchedItemLedgerEntries do begin
        TempTouchedItemLedgerEntries.FindSet();
        repeat
            ItemLedgEntryApplied.Get(TempTouchedItemLedgerEntries."Entry No.");
            ItemLedgEntryApplied.VerifyOnInventory(
                StrSubstNo(CannotUnapplyItemLedgEntryErr, ItemLedgEntryApplied."FA Item No.", ItemLedgEntryApplied."Entry No."));
        until TempTouchedItemLedgerEntries.Next() = 0;
        // end;
    end;

    local procedure DeleteTouchedEntries()
    var
        ItemApplicationEntryHistory: Record "FA Item App Entry History";
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        // with ItemApplicationEntryHistory do begin
        ItemApplicationEntryHistory.SetRange("Entry No.", 0);
        ItemApplicationEntryHistory.SetRange("Created By User", UpperCase(UserId));
        ItemApplicationEntryHistory.DeleteAll();
        // end;
    end;

    procedure CollectItemEntryRelation(var TargetItemEntryRelation: Record "FA Item Entry Relation" temporary): Boolean
    begin
        TempItemEntryRelation.Reset();
        TargetItemEntryRelation.Reset();

        if TempItemEntryRelation.FindSet() then
            repeat
                TargetItemEntryRelation := TempItemEntryRelation;
                TargetItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0
        else
            exit(false);

        TempItemEntryRelation.DeleteAll();

        exit(true);
    end;

    procedure ApplyItemLedgEntry(var FAItemLedgEntry: Record "FA Item Ledger Entry"; var OldFAItemLedgEntry: Record "FA Item Ledger Entry"; //var ValueEntry: Record "Value Entry"; 
            CausedByTransfer: Boolean)
    var
        FAItemLedgEntry2: Record "FA Item Ledger Entry";
        ReservEntry: Record "FA Reservation Entry";
        ReservEntry2: Record "FA Reservation Entry";
        AppliesFromItemLedgEntry: Record "FA Item Ledger Entry";
        AppliedQty: Decimal;
        FirstReservation: Boolean;
        FirstApplication: Boolean;
        StartApplication: Boolean;
        UseReservationApplication: Boolean;
        Handled: Boolean;
    begin
        if (FAItemLedgEntry."Remaining Quantity" = 0)
        then
            exit;

        Clear(OldFAItemLedgEntry);
        FirstReservation := true;
        FirstApplication := true;
        StartApplication := false;
        repeat
            VerifyItemJnlLineApplication(FAItemJnlLine, FAItemLedgEntry);

            if not CausedByTransfer and not PostponeReservationHandling then begin
                Handled := false;
                // OnApplyItemLedgEntryOnBeforeFirstReservationSetFilters(ItemJnlLine, StartApplication, FirstReservation, Handled);
                ReservEntry.SetLoadFields("Entry No.", Positive, "Item No.", "Quantity (Base)");
                if not Handled then
                    if FirstReservation then begin
                        FirstReservation := false;
                        ReservEntry.Reset();
                        ReservEntry.SetCurrentKey(
                          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
                          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
                        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                        FAItemJnlLine.SetReservationFilters(ReservEntry);
                        ReservEntry.SetRange("Item No.", FAItemJnlLine."FA Item No.");
                    end;

                UseReservationApplication := ReservEntry.FindFirst();

                Handled := false;
                // OnApplyItemLedgEntryOnBeforeCloseSurplusTrackingEntry(ItemJnlLine, StartApplication, UseReservationApplication, Handled);
                if not Handled then
                    if not UseReservationApplication then begin // No reservations exist
                        ReservEntry.SetRange(
                          "Reservation Status", ReservEntry."Reservation Status"::Tracking,
                          ReservEntry."Reservation Status"::Prospect);
                        if ReservEntry.FindSet() then
                            repeat
                                ReservEngineMgt.CloseSurplusTrackingEntry(ReservEntry);
                            until ReservEntry.Next() = 0;
                        StartApplication := true;
                    end;

                if UseReservationApplication then begin
                    ReservEntry2.SetLoadFields("Source Type", "Source Ref. No.", "Item No.", "Quantity (Base)");
                    ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                    if ReservEntry2."Source Type" <> DATABASE::"FA Item Ledger Entry" then
                        if FAItemLedgEntry.Quantity < 0 then
                            Error(Text003, ReservEntry."Item No.");
                    OldFAItemLedgEntry.Get(ReservEntry2."Source Ref. No.");
                    if FAItemLedgEntry.Quantity < 0 then
                        if OldFAItemLedgEntry."Remaining Quantity" < ReservEntry2."Quantity (Base)" then
                            Error(Text003, ReservEntry2."Item No.");

                    OldFAItemLedgEntry.TestField("FA Item No.", FAItemJnlLine."FA Item No.");
                    OldFAItemLedgEntry.TestField("Variant Code", FAItemJnlLine."Variant Code");
                    OldFAItemLedgEntry.TestField("Location Code", FAItemJnlLine."Location Code");
                    // OnApplyItemLedgEntryOnBeforeCloseReservEntry(OldItemLedgEntry, ItemJnlLine, ItemLedgEntry);
                    ReservEngineMgt.CloseReservEntry(ReservEntry, false, false);
                    // OnApplyItemLedgEntryOnAfterCloseReservEntry(OldItemLedgEntry, ItemJnlLine, ItemLedgEntry, ReservEntry);
                    OldFAItemLedgEntry.CalcReservedQuantity();
                    AppliedQty := -Abs(ReservEntry."Quantity (Base)");
                end;
            end else
                StartApplication := true;

            if StartApplication then begin
                FAItemLedgEntry.CalcReservedQuantity();
                if FAItemLedgEntry."Applies-to Entry" <> 0 then begin
                    if FirstApplication then begin
                        FirstApplication := false;
                        OldFAItemLedgEntry.Get(FAItemLedgEntry."Applies-to Entry");
                        TestFirstApplyItemLedgEntry(OldFAItemLedgEntry, FAItemLedgEntry);
                        // OnApplyItemLedgEntryOnAfterTestFirstApplyItemLedgEntry(OldItemLedgEntry, FAItemLedgEntry);
                    end else
                        exit;
                end else
                    if FindOpenItemLedgEntryToApply(FAItemLedgEntry2, FAItemLedgEntry, FirstApplication) then
                        OldFAItemLedgEntry.Copy(FAItemLedgEntry2)
                    else
                        exit;

                OldFAItemLedgEntry.CalcReservedQuantity();
                // OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(OldItemLedgEntry, FAItemLedgEntry);

                if Abs(OldFAItemLedgEntry."Remaining Quantity" - OldFAItemLedgEntry."Reserved Quantity") >
                   Abs(FAItemLedgEntry."Remaining Quantity" - FAItemLedgEntry."Reserved Quantity")
                then
                    AppliedQty := FAItemLedgEntry."Remaining Quantity" - FAItemLedgEntry."Reserved Quantity"
                else
                    AppliedQty := -(OldFAItemLedgEntry."Remaining Quantity" - OldFAItemLedgEntry."Reserved Quantity");

                // OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry, FAItemLedgEntry, AppliedQty);

                if FAItemLedgEntry."Entry Type" = FAItemLedgEntry."Entry Type"::Transfer then
                    if (OldFAItemLedgEntry."Entry No." > FAItemLedgEntry."Entry No.") and not FAItemLedgEntry.Positive then
                        AppliedQty := 0;
                // if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
                //    (OldItemLedgEntry."Order No." <> '')
                // then
                //     if not AllowProdApplication(OldItemLedgEntry, FAItemLedgEntry) then
                //         AppliedQty := 0;
                if FAItemJnlLine."Applies-from Entry" <> 0 then begin
                    AppliesFromItemLedgEntry.Get(FAItemJnlLine."Applies-from Entry");
                    if ItemApplnEntry.CheckIsCyclicalLoop(AppliesFromItemLedgEntry, OldFAItemLedgEntry) then
                        AppliedQty := 0;
                end;
                // OnApplyItemLedgEntryOnAfterSetAppliedQtyZero(OldItemLedgEntry, FAItemLedgEntry, AppliedQty, FAItemJnlLine);
            end;

            CheckIsCyclicalLoop(FAItemLedgEntry, OldFAItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty);

            if AppliedQty <> 0 then begin
                UpdateOldItemLedgerEntryRemainingQuantity(OldFAItemLedgEntry, AppliedQty);

                //Check and copy FA No. from OldFAItemLedgEntry to FAItemLedgEntry
                if OldFAItemLedgEntry."Serial No." <> '' then
                    if OldFAItemLedgEntry."FA No." <> '' then
                        FAItemLedgEntry."FA No." := OldFAItemLedgEntry."FA No.";

                if FAItemLedgEntry.Positive then begin
                    // OnApplyItemLedgEntryOnItemLedgEntryPositiveOnBeforeInsertApplEntry(OldItemLedgEntry, ItemLedgEntry, GlobalItemLedgEntry, AppliedQty);
                    if FAItemLedgEntry."Posting Date" >= OldFAItemLedgEntry."Posting Date" then
                        InsertApplEntry(
                          OldFAItemLedgEntry."Entry No.", FAItemLedgEntry."Entry No.",
                          OldFAItemLedgEntry."Entry No.", 0, FAItemLedgEntry."Posting Date", -AppliedQty, false)
                    else
                        InsertApplEntry(
                          OldFAItemLedgEntry."Entry No.", FAItemLedgEntry."Entry No.",
                          OldFAItemLedgEntry."Entry No.", 0, OldFAItemLedgEntry."Posting Date", -AppliedQty, false);

                    // if ItemApplnEntry."Cost Application" then
                    //     FAItemLedgEntry."Applied Entry to Adjust" := true;
                end else begin
                    // OnApplyItemLedgEntryOnBeforeCheckApplyEntry(OldItemLedgEntry);

                    // CheckPostingDateWithExpirationDate(FAItemLedgEntry);

                    // OnApplyItemLedgEntryOnBeforeInsertApplEntry(ItemLedgEntry, ItemJnlLine, OldItemLedgEntry, GlobalItemLedgEntry, AppliedQty);

                    InsertApplEntry(
                      FAItemLedgEntry."Entry No.", OldFAItemLedgEntry."Entry No.", FAItemLedgEntry."Entry No.", 0,
                      FAItemLedgEntry."Posting Date", AppliedQty, true);

                    // if ItemApplnEntry."Cost Application" then
                    // OldItemLedgEntry."Applied Entry to Adjust" := true;
                end;

                // OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(ItemLedgEntry, OldItemLedgEntry, ItemJnlLine);
                OldFAItemLedgEntry.Modify();
                AutoTrack(OldFAItemLedgEntry, true);

                // EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
                // GetValuationDate(ValueEntry, OldItemLedgEntry);

                if (FAItemLedgEntry."Entry Type" = FAItemLedgEntry."Entry Type"::Transfer) and
                   (AppliedQty < 0) and
                   not CausedByTransfer and
                   not FAItemLedgEntry.Correction
                then begin
                    if FAItemLedgEntry."Completely Invoiced" then
                        FAItemLedgEntry."Completely Invoiced" := OldFAItemLedgEntry."Completely Invoiced";
                    // if AverageTransfer then
                    // TotalAppliedQty := TotalAppliedQty + AppliedQty
                    // else
                    InsertTransferEntry(FAItemLedgEntry, OldFAItemLedgEntry, AppliedQty);
                end;

                UpdateItemLedgerEntryRemainingQuantity(FAItemLedgEntry, AppliedQty, OldFAItemLedgEntry, CausedByTransfer);

                FAItemLedgEntry.CalcReservedQuantity();
                if FAItemLedgEntry."Remaining Quantity" + FAItemLedgEntry."Reserved Quantity" = 0 then
                    exit;
            end;
        until false;
    end;

    local procedure UpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "FA Item Ledger Entry"; AppliedQty: Decimal; var OldItemLedgEntry: Record "FA Item Ledger Entry"; CausedByTransfer: Boolean)
    begin
        // OnBeforeUpdateItemLedgerEntryRemainingQuantity(ItemLedgerEntry, OldItemLedgEntry, AppliedQty, CausedByTransfer, AverageTransfer);

        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry."Remaining Quantity" - AppliedQty;
        ItemLedgerEntry.Open := ItemLedgerEntry."Remaining Quantity" <> 0;

        // OnAfterUpdateItemLedgerEntryRemainingQuantity(ItemLedgerEntry, AppliedQty);
    end;

    local procedure VerifyItemJnlLineApplication(var ItemJournalLine: Record "FA Item Journal Line"; ItemLedgerEntry: Record "FA Item Ledger Entry")
    begin
        if ItemJournalLine."Applies-to Entry" = 0 then
            exit;

        ItemJournalLine.CalcReservedQuantity();
        if ItemJournalLine."Reserved Qty. (Base)" <> 0 then
            ItemLedgerEntry.FieldError("Applies-to Entry", Text99000000);
    end;

    local procedure TestFirstApplyItemLedgEntry(var OldItemLedgEntry: Record "FA Item Ledger Entry"; ItemLedgEntry: Record "FA Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeTestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry, ItemJnlLine, IsHandled);
        // if IsHandled then
        //     exit;

        OldItemLedgEntry.TestField("FA Item No.", ItemLedgEntry."FA Item No.");
        OldItemLedgEntry.TestField("Variant Code", ItemLedgEntry."Variant Code");
        OldItemLedgEntry.TestField(Positive, not ItemLedgEntry.Positive);
        OldItemLedgEntry.TestField("Location Code", ItemLedgEntry."Location Code");
        if Location.Get(ItemLedgEntry."Location Code") then
            if Location."Use As In-Transit" then begin
                OldItemLedgEntry.TestField("Order Type", OldItemLedgEntry."Order Type"::Transfer);
                OldItemLedgEntry.TestField("Order No.", ItemLedgEntry."Order No.");
            end;

        TestFirstApplyItemLedgerEntryTracking(ItemLedgEntry, OldItemLedgEntry, GlobalItemTrackingCode);

        IsHandled := false;
        // OnTestFirstApplyItemLedgEntryOnBeforeTestFields(OldItemLedgEntry, ItemLedgEntry, ItemJnlLine, IsHandled);
        if not IsHandled then
            if not (OldItemLedgEntry.Open and
                    (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >=
                     Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")))
            then
                if (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <=
                    Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"))
                then begin
                    if not MoveApplication(ItemLedgEntry, OldItemLedgEntry) then
                        OldItemLedgEntry.FieldError("Remaining Quantity", Text004);
                end else
                    OldItemLedgEntry.TestField(Open, true);

        // OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgEntry, OldItemLedgEntry, ItemJnlLine);

        OldItemLedgEntry.CalcReservedQuantity();
        CheckApplication(ItemLedgEntry, OldItemLedgEntry);


        IsHandled := false;
        // OnTestFirstApplyItemLedgEntryOnBeforeReservationPreventsApplication(OldItemLedgEntry, ItemLedgEntry, IsHandled);
        if not IsHandled then
            if Abs(OldItemLedgEntry."Remaining Quantity") <= Abs(OldItemLedgEntry."Reserved Quantity") then
                ReservationPreventsApplication(ItemLedgEntry."Applies-to Entry", ItemLedgEntry."FA Item No.", OldItemLedgEntry);

        // if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
        //    (OldItemLedgEntry."Order No." <> '')
        // then
        //     if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
        //         Error(
        //           Text022,
        //           ItemLedgEntry."Entry Type", OldItemLedgEntry."Entry Type", OldItemLedgEntry."Item No.", OldItemLedgEntry."Order No.");
    end;

    local procedure MoveApplication(var ItemLedgerEntry: Record "FA Item Ledger Entry"; var OldItemLedgerEntry: Record "FA Item Ledger Entry"): Boolean
    var
        ItemApplicationEntry: Record "FA Item Application Entry";
        Enough: Boolean;
        FixedApplication: Boolean;
    begin
        // OnBeforeMoveApplication(ItemLedgerEntry, OldItemLedgerEntry);

        // with ItemLedgerEntry do begin
        FixedApplication := false;
        OldItemLedgerEntry.TestField(Positive, true);

        if (OldItemLedgerEntry."Remaining Quantity" < Abs(ItemLedgerEntry.Quantity)) and
           (OldItemLedgerEntry."Remaining Quantity" < OldItemLedgerEntry.Quantity)
        then begin
            Enough := false;
            ItemApplicationEntry.Reset();
            ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.");
            ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Applies-to Entry");
            ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>0');

            if ItemApplicationEntry.FindSet() then begin
                repeat
                    if not ItemApplicationEntry.Fixed() then begin
                        UnApply(ItemApplicationEntry);
                        OldItemLedgerEntry.Get(OldItemLedgerEntry."Entry No.");
                        OldItemLedgerEntry.CalcReservedQuantity();
                        Enough :=
                          Abs(OldItemLedgerEntry."Remaining Quantity" - OldItemLedgerEntry."Reserved Quantity") >=
                          Abs(ItemLedgerEntry."Remaining Quantity");
                    end else
                        FixedApplication := true;
                until (ItemApplicationEntry.Next() = 0) or Enough;
            end else
                exit(false); // no applications found that could be undone
                             // OnAfterMoveApplication(ItemLedgerEntry, OldItemLedgerEntry, Enough);
            if not Enough and FixedApplication then
                ShowFixedApplicationError();
            exit(Enough);
        end;
        exit(true);
        // end;
    end;

    local procedure CheckApplication(ItemLedgEntry: Record "FA Item Ledger Entry"; OldItemLedgEntry: Record "FA Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckApplication(ItemLedgEntry, OldItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if SkipApplicationCheck then begin
            SkipApplicationCheck := false;
            exit;
        end;

        IsHandled := false;
        // OnCheckApplicationOnBeforeRemainingQtyError(OldItemLedgEntry, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <
           Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
        then
            OldItemLedgEntry.FieldError("Remaining Quantity", Text004)
    end;

    local procedure ShowFixedApplicationError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeShowFixedApplicationError(IsHandled);
        if IsHandled then
            exit;

        Error(Text027);
    end;

    procedure UnApply(ItemApplnEntry: Record "FA Item Application Entry")
    var
        ItemLedgEntry1: Record "FA Item Ledger Entry";
        ItemLedgEntry2: Record "FA Item Ledger Entry";
        CostItemLedgEntry: Record "FA Item Ledger Entry";
        InventoryPeriod: Record "Inventory Period";
        Valuationdate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeUnApply(ItemApplnEntry, IsHandled);
        if IsHandled then
            exit;

        if not InventoryPeriod.IsValidDate(ItemApplnEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemApplnEntry."Posting Date");

        // If we can't get both entries then the application is not a real application or a date compression might have been done
        ItemLedgEntry1.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemLedgEntry2.Get(ItemApplnEntry."Outbound Item Entry No.");

        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Inbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry1);
        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Outbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry2);

        // if ItemLedgEntry1."Drop Shipment" and ItemLedgEntry2."Drop Shipment" then
        //     Error(Text024);

        if ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Transfer then
            Error(Text023);

        ItemApplnEntry.TestField("Transferred-from Entry No.", 0);

        // We won't allow deletion of applications for deleted items
        GetItem(ItemLedgEntry1."FA Item No.", true);
        CostItemLedgEntry.Get(ItemApplnEntry.CostReceiver()); // costreceiver

        // OnUnApplyOnBeforeUpdateItemLedgerEntries(ItemLedgEntry1, ItemLedgEntry2, ItemApplnEntry);

        if ItemLedgEntry1."Applies-to Entry" = ItemLedgEntry2."Entry No." then
            ItemLedgEntry1."Applies-to Entry" := 0;

        if ItemLedgEntry2."Applies-to Entry" = ItemLedgEntry1."Entry No." then
            ItemLedgEntry2."Applies-to Entry" := 0;

        // only if real/quantity application
        if not ItemApplnEntry.CostApplication() then begin
            ItemLedgEntry1."Remaining Quantity" := ItemLedgEntry1."Remaining Quantity" - ItemApplnEntry.Quantity;
            ItemLedgEntry1.Open := ItemLedgEntry1."Remaining Quantity" <> 0;
            ItemLedgEntry1.Modify();

            ItemLedgEntry2."Remaining Quantity" := ItemLedgEntry2."Remaining Quantity" + ItemApplnEntry.Quantity;
            ItemLedgEntry2.Open := ItemLedgEntry2."Remaining Quantity" <> 0;
            ItemLedgEntry2.Modify();
        end else begin
            ItemLedgEntry2."Shipped Qty. Not Returned" := ItemLedgEntry2."Shipped Qty. Not Returned" - Abs(ItemApplnEntry.Quantity);
            if Abs(ItemLedgEntry2."Shipped Qty. Not Returned") > Abs(ItemLedgEntry2.Quantity) then
                ItemLedgEntry2.FieldError("Shipped Qty. Not Returned", Text004); // Assert - should never happen
            ItemLedgEntry2.Modify();

            // OnUnApplyOnBeforeInsertApplEntry(ItemApplnEntry);
            // If cost application we need to insert a 0 application instead if there is none before
            if ItemApplnEntry.Quantity > 0 then
                if not ZeroApplication(ItemApplnEntry."Item Ledger Entry No.") then
                    InsertApplEntry(
                      ItemApplnEntry."Item Ledger Entry No.", ItemApplnEntry."Inbound Item Entry No.",
                      0, 0, ItemApplnEntry."Posting Date", ItemApplnEntry.Quantity, true);
        end;

        // if FAItem."Costing Method" = FAItem."Costing Method"::Average then
        //     if not ItemApplnEntry.Fixed() then
        //         UpdateValuedByAverageCost(CostItemLedgEntry."Entry No.", true);

        ItemApplnEntry.InsertHistory();
        TouchEntry(ItemApplnEntry."Inbound Item Entry No.");
        SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", true);
        if ItemApplnEntry."Outbound Item Entry No." <> 0 then begin
            TouchEntry(ItemApplnEntry."Outbound Item Entry No.");
            SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", false);
        end;

        // OnUnApplyOnBeforeItemApplnEntryDelete(ItemApplnEntry);
        ItemApplnEntry.Delete();

        // Valuationdate := GetMaxAppliedValuationdate(CostItemLedgEntry);
        // if Valuationdate = 0D then
        //     Valuationdate := CostItemLedgEntry."Posting Date"
        // else
        //     Valuationdate := max(CostItemLedgEntry."Posting Date", Valuationdate);

        // SetValuationDateAllValueEntrie(CostItemLedgEntry."Entry No.", Valuationdate, false);

        UpdateLinkedValuationUnapply(Valuationdate, CostItemLedgEntry."Entry No.", CostItemLedgEntry.Positive);
    end;

    local procedure CheckItemCorrection(ItemLedgerEntry: Record "FA Item Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        RaiseError := ItemLedgerEntry.Correction;
        // OnBeforeCheckItemCorrection(ItemLedgerEntry, RaiseError);
        if RaiseError then
            Error(CannotUnapplyCorrEntryErr);
    end;

    local procedure "Max"(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);
        exit(Date2);
    end;

    local procedure ZeroApplication(EntryNo: Integer): Boolean
    var
        Application: Record "FA Item Application Entry";
    begin
        Application.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        Application.SetRange("Item Ledger Entry No.", EntryNo);
        Application.SetRange("Inbound Item Entry No.", EntryNo);
        Application.SetRange("Outbound Item Entry No.", 0);
        exit(not Application.IsEmpty);
    end;

    Procedure TouchEntry(EntryNo: Integer)
    var
        TouchedItemLedgEntry: Record "FA Item Ledger Entry";
    begin
        TouchedItemLedgEntry.Get(EntryNo);
        TempTouchedItemLedgerEntries := TouchedItemLedgEntry;
        if not TempTouchedItemLedgerEntries.Insert() then;
    end;

    local procedure SaveTouchedEntry(ItemLedgerEntryNo: Integer; IsInbound: Boolean)
    var
        ItemApplicationEntryHistory: Record "FA Item App Entry History";
        NextEntryNo: Integer;
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        // with ItemApplicationEntryHistory do begin
        NextEntryNo := ItemApplicationEntryHistory.GetLastEntryNo() + 1;

        ItemApplicationEntryHistory.Init();
        ItemApplicationEntryHistory."Primary Entry No." := NextEntryNo;
        ItemApplicationEntryHistory."Entry No." := 0;
        ItemApplicationEntryHistory."Item Ledger Entry No." := ItemLedgerEntryNo;
        if IsInbound then
            ItemApplicationEntryHistory."Inbound Item Entry No." := ItemLedgerEntryNo
        else
            ItemApplicationEntryHistory."Outbound Item Entry No." := ItemLedgerEntryNo;
        ItemApplicationEntryHistory."Creation Date" := CurrentDateTime;
        ItemApplicationEntryHistory."Created By User" := UserId;
        ItemApplicationEntryHistory.Insert();
        // end;
    end;

    // procedure RestoreTouchedEntries(var TempItem: Record "FA Item" temporary)
    // var
    //     ItemApplicationEntryHistory: Record "FA Item App Entry History";
    //     ItemLedgerEntry: Record "FA Item Ledger Entry";
    // begin
    //     with ItemApplicationEntryHistory do begin
    //         SetRange("Entry No.", 0);
    //         SetRange("Created By User", UpperCase(UserId));
    //         if FindSet() then
    //             repeat
    //                 TouchEntry("Item Ledger Entry No.");

    //                 ItemLedgerEntry.Get("Item Ledger Entry No.");
    //                 TempItem."No." := ItemLedgerEntry."FA Item No.";
    //                 if TempItem.Insert() then;
    //             until Next() = 0;
    //     end;
    // end;

    local procedure UpdateLinkedValuationUnapply(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "FA Item Application Entry";
        ItemLedgerEntry: Record "FA Item Ledger Entry";
    begin
        // with ToItemApplnEntry do begin
        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemLedgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemLedgEntryNo);
        end;
        ToItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', FromItemLedgEntryNo);
        if ToItemApplnEntry.Find('-') then
            repeat
                if FromInbound or (ToItemApplnEntry."Inbound Item Entry No." <> 0) then begin
                    // GetLastDirectCostValEntry("Inbound Item Entry No.");
                    // if DirCostValueEntry."Valuation Date" < FromValuationDate then begin
                    //     UpdateValuationDate(FromValuationDate, "Item Ledger Entry No.", FromInbound);
                    //     UpdateLinkedValuationUnapply(FromValuationDate, "Item Ledger Entry No.", not FromInbound);
                    // end
                    // else begin
                    //     ItemLedgerEntry.Get("Inbound Item Entry No.");
                    //     FromValuationDate := GetMaxAppliedValuationdate(ItemLedgerEntry);
                    //     if FromValuationDate < DirCostValueEntry."Valuation Date" then begin
                    //         UpdateValuationDate(FromValuationDate, ItemLedgerEntry."Entry No.", FromInbound);
                    //         UpdateLinkedValuationUnapply(FromValuationDate, ItemLedgerEntry."Entry No.", not FromInbound);
                    //     end;
                    // end;
                end;
            until ToItemApplnEntry.Next() = 0;
        // end;
    end;

    local procedure FindOpenItemLedgEntryToApply(var OpenItemLedgEntry: Record "FA Item Ledger Entry"; ItemLedgEntry: Record "FA Item Ledger Entry"; var FirstApplication: Boolean): Boolean
    begin
        if FirstApplication then begin
            FirstApplication := false;
            ApplyItemLedgEntrySetFilters(OpenItemLedgEntry, ItemLedgEntry, GlobalItemTrackingCode);
            // OpenItemLedgEntry.Ascending(FAItem."Costing Method" <> FAItem."Costing Method"::LIFO);
            exit(OpenItemLedgEntry.FindSet());
        end else
            exit(OpenItemLedgEntry.Next() <> 0);
    end;

    local procedure TestFirstApplyItemLedgerEntryTracking(ItemLedgEntry: Record "FA Item Ledger Entry"; OldItemLedgEntry: Record "FA Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code");
    begin
        if ItemTrackingCode."SN Specific Tracking" then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");
        // if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Serial No." <> '') then
        //     OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");

        if ItemTrackingCode."Lot Specific Tracking" then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");
        // if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Lot No." <> '') then
        //     OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");

        // OnAfterTestFirstApplyItemLedgerEntryTracking(ItemLedgEntry, OldItemLedgEntry, ItemTrackingCode);
    end;

    local procedure ApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "FA Item Ledger Entry"; FromItemLedgEntry: Record "FA Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    var
        Location: Record Location;
        ItemTrackingSetup2: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemTrackingCode, IsHandled);
        if IsHandled then
            exit;

        if FromItemLedgEntry."Serial No." <> '' then
            ToItemLedgEntry.SetCurrentKey("Serial No.", "FA Item No.", Open, Positive, "Location Code", "Posting Date")
        else
            ToItemLedgEntry.SetCurrentKey("FA Item No.", Open, Positive, "Location Code", "Posting Date");
        ToItemLedgEntry.SetRange("FA Item No.", FromItemLedgEntry."FA Item No.");
        ToItemLedgEntry.SetRange(Open, true);
        ToItemLedgEntry.SetRange("Variant Code", FromItemLedgEntry."Variant Code");
        ToItemLedgEntry.SetRange(Positive, not FromItemLedgEntry.Positive);
        ToItemLedgEntry.SetRange("Location Code", FromItemLedgEntry."Location Code");
        // if FromItemLedgEntry."Job Purchase" then begin
        //     ToItemLedgEntry.SetRange("Job No.", FromItemLedgEntry."Job No.");
        //     ToItemLedgEntry.SetRange("Job Task No.", FromItemLedgEntry."Job Task No.");
        // ToItemLedgEntry.SetRange("Document Type", FromItemLedgEntry."Document Type");
        //     ToItemLedgEntry.SetRange("Document No.", FromItemLedgEntry."Document No.");
        // end;
        ItemTrackingSetup2.CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode);
        ItemTrackingSetup2.CopyTrackingFromFAItemLedgerEntry(FromItemLedgEntry);
        ToItemLedgEntry.SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup2);
        if (Location.Get(FromItemLedgEntry."Location Code") and Location."Use As In-Transit") or
           (FromItemLedgEntry."Location Code" = '') and
           (FromItemLedgEntry."Document Type" = FromItemLedgEntry."Document Type"::"Transfer Receipt")
        then begin
            ToItemLedgEntry.SetRange("Order Type", FromItemLedgEntry."Order Type"::Transfer);
            ToItemLedgEntry.SetRange("Order No.", FromItemLedgEntry."Order No.");
        end;

        // OnAfterApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemJnlLine);
    end;

    local procedure ReservationPreventsApplication(ApplicationEntry: Integer; ItemNo: Code[20]; ReservationsEntry: Record "FA Item Ledger Entry")
    var
        ReservationEntries: Record "FA Reservation Entry";
        ReservEngineMgt: Codeunit "FA Reservation Engine Mgt.";
        ReserveItemLedgEntry: Codeunit "FA Item Ledger Entry-Reserve";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservationEntries, true);
        ReserveItemLedgEntry.FilterReservFor(ReservationEntries, ReservationsEntry);
        if ReservationEntries.FindFirst() then;
        Error(
          Text029,
          ReservationsEntry.FieldCaption("Applies-to Entry"),
          ApplicationEntry,
          FAItem.FieldCaption("No."),
          ItemNo,
          ReservEngineMgt.CreateForText(ReservationEntries));
    end;

    procedure AutoTrack(var ItemLedgEntryRec: Record "FA Item Ledger Entry"; IsReserved: Boolean)
    var
        ReservMgt: Codeunit "FA Reservation Management";
    begin
        if FAItem."Order Tracking Policy" = FAItem."Order Tracking Policy"::None then begin
            if not IsReserved then
                exit;

            // Ensure that Item Tracking is not left on the item ledger entry:
            ReservMgt.SetReservSource(ItemLedgEntryRec);
            ReservMgt.SetItemTrackingHandling(1);
            ReservMgt.ClearSurplus();
            exit;
        end;

        ReservMgt.SetReservSource(ItemLedgEntryRec);
        ReservMgt.SetItemTrackingHandling(1);
        ReservMgt.DeleteReservEntries(false, ItemLedgEntryRec."Remaining Quantity");
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ItemLedgEntryRec."Remaining Quantity");
    end;

    local procedure CheckIsCyclicalLoop(ItemLedgEntry: Record "FA Item Ledger Entry"; OldItemLedgEntry: Record "FA Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "FA Item Ledger Entry"; var AppliedQty: Decimal)
    var
        PrevProcessedProdOrder: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty, IsHandled);
        if IsHandled then
            exit;

        // PrevProcessedProdOrder :=
        //   (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Consumption) and
        //   (OldItemLedgEntry."Entry Type" = OldItemLedgEntry."Entry Type"::Output) and
        //   (ItemLedgEntry."Order Type" = ItemLedgEntry."Order Type"::Production) and
        //   EntriesInTheSameOrder(OldItemLedgEntry, PrevAppliedItemLedgEntry);

        if not PrevProcessedProdOrder then
            if AppliedQty <> 0 then
                if ItemLedgEntry.Positive then begin
                    if ItemApplnEntry.CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end else
                    if ItemApplnEntry.CheckIsCyclicalLoop(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;

        if AppliedQty <> 0 then
            PrevAppliedItemLedgEntry := OldItemLedgEntry;
    end;

    local procedure UpdateOldItemLedgerEntryRemainingQuantity(var OldItemLedgerEntry: Record "FA Item Ledger Entry"; AppliedQty: Decimal)
    begin
        OldItemLedgerEntry."Remaining Quantity" := OldItemLedgerEntry."Remaining Quantity" + AppliedQty;
        OldItemLedgerEntry.Open := OldItemLedgerEntry."Remaining Quantity" <> 0;

        // OnAfterUpdateOldItemLedgerEntryRemainingQuantity(OldItemLedgerEntry, AppliedQty);
    end;

    local procedure IsNotInternalWhseMovement(ItemJnlLine: Record "FA Item Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeIsNotInternalWhseMovement(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ItemJnlLine.IsNotInternalWhseMovement());
    end;

    local procedure CheckIfItemIsBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckIfItemIsBlocked(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if IsHandled then
            exit;

        if not CalledFromAdjustment then
            FAItemJnlLine.DisplayErrorIfItemIsBlocked(FAItem);
        FAItem.CheckBlockedByApplWorksheet();
    end;

    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "FA Tracking Specification" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        // OnBeforeCollectTrackingSpecification(TempTrackingSpecification, TargetTrackingSpecification, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempTrackingSpecification.Reset();
        TargetTrackingSpecification.Reset();
        TargetTrackingSpecification.DeleteAll();

        if TempTrackingSpecification.FindSet() then
            repeat
                TargetTrackingSpecification := TempTrackingSpecification;
                TargetTrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0
        else
            exit(false);

        TempTrackingSpecification.DeleteAll();

        exit(true);
    end;

    local procedure InsertTransferEntry(var ItemLedgEntry: Record "FA Item Ledger Entry"; var OldItemLedgEntry: Record "FA Item Ledger Entry"; AppliedQty: Decimal)
    var
        NewItemLedgEntry: Record "FA Item Ledger Entry";
        // NewValueEntry: Record "Value Entry";
        ItemLedgEntry2: Record "FA Item Ledger Entry";
        IsReserved: Boolean;
    begin
        // with FAItemJnlLine do begin
        InitItemLedgEntry(NewItemLedgEntry);
        NewItemLedgEntry."Applies-to Entry" := 0;
        NewItemLedgEntry.Quantity := -AppliedQty;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry."Location Code" := FAItemJnlLine."New Location Code";
        // NewItemLedgEntry."Country/Region Code" := "Country/Region Code";
        // InsertCountryCode(NewItemLedgEntry, ItemLedgEntry);
        NewItemLedgEntry.CopyTrackingFromNewItemJnlLine(FAItemJnlLine);
        // NewItemLedgEntry."Expiration Date" := "New Item Expiration Date";
        // IsHandled := false;
        // OnInsertTransferEntryOnTransferValues(NewItemLedgEntry, OldItemLedgEntry, ItemLedgEntry, FAItemJnlLine, TempItemEntryRelation, IsHandled);
        // if not IsHandled then
        if FAItem."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := NewItemLedgEntry."Entry No."; // Save Entry No. in a global variable
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(NewItemLedgEntry);
            // OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, NewItemLedgEntry);
            TempItemEntryRelation.Insert();
        end;
        if OldFAItemLedgEntry."FA No." <> '' then
            NewItemLedgEntry."FA No." := OldFAItemLedgEntry."FA No.";
        // OnInsertTransferEntryOnBeforeInitTransValueEntry(TempItemEntryRelation, NewItemLedgEntry, Item);
        // InitTransValueEntry(NewValueEntry, NewItemLedgEntry);

        // OnInsertTransferEntryOnBeforeInsertApplEntry(NewItemLedgEntry, ItemLedgEntry);
        // if AverageTransfer then begin
        //     InsertApplEntry(
        //       NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
        //       0, NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
        //     NewItemLedgEntry."Completely Invoiced" := ItemLedgEntry."Completely Invoiced";
        // end else 
        begin
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
            NewItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
        end;

        // IsHandled := false;
        // OnInsertTransferEntryOnBeforeCalcIsReserved(ItemJnlLine, TempTrackingSpecification, NewItemLedgEntry, ItemLedgEntry, IsReserved, IsHandled);
        // if not IsHandled then
        if NewItemLedgEntry.Quantity > 0 then
            IsReserved :=
                ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                    FAItemJnlLine, NewItemLedgEntry, NewItemLedgEntry."Remaining Quantity", true);

        ApplyItemLedgEntry(NewItemLedgEntry, ItemLedgEntry2, true);
        AutoTrack(NewItemLedgEntry, IsReserved);

        // OnBeforeInsertTransferEntry(NewItemLedgEntry, OldItemLedgEntry, ItemJnlLine);

        InsertItemLedgEntry(NewItemLedgEntry, true);
        // InsertValueEntry(NewValueEntry, NewItemLedgEntry, true);

        // UpdateUnitCost(NewValueEntry);

        // OnAfterInsertTransferEntry(ItemJnlLine, NewItemLedgEntry, OldItemLedgEntry, NewValueEntry, ValueEntryNo);
        // end;
    end;

    procedure InitItemLedgEntry(var ItemLedgEntry: Record "FA Item Ledger Entry")
    begin
        FAItemLedgEntryNo := FAItemLedgEntryNo + 1;

        // with FAItemJnlLine do begin
        ItemLedgEntry.Init();
        ItemLedgEntry."Entry No." := FAItemLedgEntryNo;
        ItemLedgEntry."FA Item No." := FAItemJnlLine."FA Item No.";
        ItemLedgEntry."Posting Date" := FAItemJnlLine."Posting Date";
        // ItemLedgEntry."Document Date" := "Document Date";
        ItemLedgEntry."Entry Type" := FAItemJnlLine."Entry Type";
        ItemLedgEntry."Source No." := FAItemJnlLine."Source No.";
        ItemLedgEntry."Document No." := FAItemJnlLine."Document No.";
        ItemLedgEntry."Document Type" := FAItemJnlLine."Document Type";
        ItemLedgEntry."Document Line No." := FAItemJnlLine."Document Line No.";
        ItemLedgEntry."Order Type" := FAItemJnlLine."Order Type";
        ItemLedgEntry."Order No." := FAItemJnlLine."Order No.";
        ItemLedgEntry."Order Line No." := FAItemJnlLine."Order Line No.";
        // ItemLedgEntry."External Document No." := "External Document No.";
        ItemLedgEntry.Description := FAItemJnlLine.Description;
        ItemLedgEntry."Location Code" := FAItemJnlLine."Location Code";
        ItemLedgEntry."Applies-to Entry" := FAItemJnlLine."Applies-to Entry";
        ItemLedgEntry."Source Type" := FAItemJnlLine."Source Type";
        // ItemLedgEntry."Transaction Type" := "Transaction Type";
        // ItemLedgEntry."Transport Method" := "Transport Method";
        // ItemLedgEntry."Country/Region Code" := "Country/Region Code";
        if (FAItemJnlLine."Entry Type" = FAItemJnlLine."Entry Type"::Transfer) and (FAItemJnlLine."New Location Code" <> '') then begin
            if NewLocation.Code <> FAItemJnlLine."New Location Code" then
                NewLocation.Get(FAItemJnlLine."New Location Code");
            if NewLocation."Demo Location" then
                ItemLedgEntry."Customer No." := FAItemJnlLine."Customer No.";
            // ItemLedgEntry."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        // ItemLedgEntry."Entry/Exit Point" := "Entry/Exit Point";
        // ItemLedgEntry.Area := Area;
        // ItemLedgEntry."Transaction Specification" := "Transaction Specification";
        // ItemLedgEntry."Drop Shipment" := "Drop Shipment";
        // ItemLedgEntry."Assemble to Order" := "Assemble to Order";
        // ItemLedgEntry."No. Series" := "Posting No. Series";
        // GetInvtSetup();
        // if (ItemLedgEntry.Description = FAItem.Description) and not InvtSetup."Copy Item Descr. to Entries" then
        //     ItemLedgEntry.Description := '';
        // ItemLedgEntry."Prod. Order Comp. Line No." := "Prod. Order Comp. Line No.";
        ItemLedgEntry."Variant Code" := FAItemJnlLine."Variant Code";
        ItemLedgEntry."Unit of Measure Code" := FAItemJnlLine."Unit of Measure Code";
        ItemLedgEntry."Qty. per Unit of Measure" := FAItemJnlLine."Qty. per Unit of Measure";
        // ItemLedgEntry."Derived from Blanket Order" := "Derived from Blanket Order";
        // ItemLedgEntry."Item Reference No." := "Item Reference No.";
        // ItemLedgEntry."Originally Ordered No." := "Originally Ordered No.";
        // ItemLedgEntry."Originally Ordered Var. Code" := "Originally Ordered Var. Code";
        // ItemLedgEntry."Out-of-Stock Substitution" := "Out-of-Stock Substitution";
        // ItemLedgEntry."Item Category Code" := "Item Category Code";
        // ItemLedgEntry.Nonstock := Nonstock;
        // ItemLedgEntry."Purchasing Code" := "Purchasing Code";
        // ItemLedgEntry."Return Reason Code" := "Return Reason Code";
        // ItemLedgEntry."Job No." := "Job No.";
        // ItemLedgEntry."Job Task No." := "Job Task No.";
        // ItemLedgEntry."Job Purchase" := "Job Purchase";
        // ItemLedgEntry.CopyTrackingFromItemJnlLine(ItemJnlLine);
        // ItemLedgEntry."Warranty Date" := "Warranty Date";
        // ItemLedgEntry."Expiration Date" := "Item Expiration Date";
        // ItemLedgEntry."Shpt. Method Code" := "Shpt. Method Code";

        ItemLedgEntry.Correction := FAItemJnlLine.Correction;

        if FAItemJnlLine."Entry Type" in
           [//"Entry Type"::Sale,
            FAItemJnlLine."Entry Type"::"Negative Adjmt.",
            FAItemJnlLine."Entry Type"::Transfer
            //"Entry Type"::Consumption,
            //"Entry Type"::"Assembly Consumption"
            ]
        then begin
            ItemLedgEntry.Quantity := -FAItemJnlLine.Quantity;
            ItemLedgEntry."Invoiced Quantity" := -FAItemJnlLine."Invoiced Quantity";
        end else begin
            ItemLedgEntry.Quantity := FAItemJnlLine.Quantity;
            ItemLedgEntry."Invoiced Quantity" := FAItemJnlLine."Invoiced Quantity";
        end;
        if (ItemLedgEntry.Quantity < 0) and (FAItemJnlLine."Entry Type" <> FAItemJnlLine."Entry Type"::Transfer) then
            ItemLedgEntry."Shipped Qty. Not Returned" := ItemLedgEntry.Quantity;
        // end;

        // OnAfterInitItemLedgEntry(ItemLedgEntry, ItemJnlLine, ItemLedgEntryNo);
    end;

    local procedure IsWarehouseReclassification(ItemJournalLine: Record "FA Item Journal Line"): Boolean
    begin
        // exit(ItemJournalLine."Warehouse Adjustment" and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer));
    end;

    procedure SetPostponeReservationHandling(Postpone: Boolean)
    begin
        // Used when posting Transfer Order receipts
        PostponeReservationHandling := Postpone;
    end;

    local procedure UndoQuantityPosting()
    var
        OldItemLedgEntry: Record "FA Item Ledger Entry";
        OldItemLedgEntry2: Record "FA Item Ledger Entry";
        NewItemLedgEntry: Record "FA Item Ledger Entry";
        IsReserved: Boolean;
    begin
        if FAItemJnlLine."Entry Type" in [//FAItemJnlLine."Entry Type"::"Assembly Consumption",
                                        FAItemJnlLine."Entry Type"::"Conversion Output"]
        then
            exit;

        if FAItemJnlLine."Applies-to Entry" <> 0 then begin
            OldItemLedgEntry.Get(FAItemJnlLine."Applies-to Entry");

            // IsHandled := false;
            // OnUndoQuantityPostingOnBeforeCheckPositive(ItemJnlLine, OldItemLedgEntry, IsHandled);
            // if not IsHandled then
            if not OldItemLedgEntry.Positive then
                FAItemJnlLine."Applies-from Entry" := FAItemJnlLine."Applies-to Entry";
        end else
            OldItemLedgEntry.Get(FAItemJnlLine."Applies-from Entry");

        if GetItem(OldItemLedgEntry."FA Item No.", false) then begin
            FAItem.TestField(Blocked, false);
            FAItem.CheckBlockedByApplWorksheet();

            if GetItemVariant(OldItemLedgEntry."FA Item No.", OldItemLedgEntry."Variant Code", false) then
                ItemVariant.TestField(Blocked, false);
        end;

        FAItemJnlLine."FA Item No." := OldItemLedgEntry."FA Item No.";

        // OnUndoQuantityPostingOnBeforeInitCorrItemLedgEntry(ItemJnlLine, OldItemLedgEntry);
        InitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);
        // OnUndoQuantityPostingOnAfterInitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);

        if FAItem.IsNonInventoriableType() then begin
            NewItemLedgEntry."Remaining Quantity" := 0;
            NewItemLedgEntry.Open := false;
        end;

        InsertItemReg(NewItemLedgEntry."Entry No.", 0, 0, 0);
        // OnUndoQuantityPostingOnAfterInsertItemReg(ItemJnlLine, OldItemLedgEntry, NewItemLedgEntry);
        GlobalFAItemLedgEntry := NewItemLedgEntry;

        // CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
        // if OldValueEntry.Inventoriable then
        // AvgCostEntryPointHandler.UpdateValuationDate(OldValueEntry);

        // ShouldInsertCorrValueEntries := OldItemLedgEntry."Invoiced Quantity" = 0;
        // OnUndoQuantityPostingOnAfterCalcShouldInsertCorrValueEntry(OldItemLedgEntry, ShouldInsertCorrValueEntries);
        // if ShouldInsertCorrValueEntries then begin
        //     IsHandled := false;
        //     OnUndoQuantityPostingOnBeforeInsertCorrOldItemLedgEntry(OldItemLedgEntry, IsHandled);
        //     if not IsHandled then
        //         InsertCorrValueEntry(
        //         OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
        //         0, OldItemLedgEntry.Quantity);
        //     InsertCorrValueEntry(
        //       OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
        //       NewItemLedgEntry.Quantity, 0);
        //     InsertCorrValueEntry(
        //       OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
        //       0, NewItemLedgEntry.Quantity);
        // end else
        //     InsertCorrValueEntry(
        //       OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
        //       NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);
        // OnUndoQuantityPostingOnBeforeUpdateOldItemLedgEntry(OldValueEntry, NewItemLedgEntry, NewValueEntry, ItemJnlLine);
        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");
        // OnUndoQuantityPostingOnAfterUpdateItemApplnEntry(ItemJnlLine, OldItemLedgEntry, NewItemLedgEntry, NewValueEntry, InventoryPostingToGL);

        if GlobalFAItemLedgEntry.Quantity > 0 then
            IsReserved :=
              ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                FAItemJnlLine, GlobalFAItemLedgEntry, FAItemJnlLine."Quantity (Base)", true);

        // if not FAItemJnlLine.IsATOCorrection() then begin
        // ApplyItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry2, NewValueEntry, false);
        // OnUndoQuantityPostingOnBeforeAutoTrack(NewItemLedgEntry);
        // AutoTrack(NewItemLedgEntry, IsReserved);
        // OnUndoQuantityPostingOnAfterAutoTrack(NewItemLedgEntry, NewValueEntry, ItemJnlLine, Item);
        // end;

        NewItemLedgEntry.Modify();
        // UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        // OnUndoQuantityPostingOnBeforeInsertApplEntry(NewItemLedgEntry, OldItemLedgEntry, GlobalItemLedgEntry);
        if NewItemLedgEntry.Positive then begin
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", 0, NewItemLedgEntry."Posting Date",
              -OldItemLedgEntry.Quantity, false);
        end;
        // OnAfterUndoQuantityPosting(NewItemLedgEntry, ItemJnlLine);
    end;

    local procedure InitCorrItemLedgEntry(var OldItemLedgEntry: Record "FA Item Ledger Entry"; var NewItemLedgEntry: Record "FA Item Ledger Entry")
    var
        EntriesExist: Boolean;
    begin
        if FAItemLedgEntryNo = 0 then
            FAItemLedgEntryNo := GlobalFAItemLedgEntry."Entry No.";

        FAItemLedgEntryNo := FAItemLedgEntryNo + 1;
        NewItemLedgEntry := OldItemLedgEntry;
        ItemTrackingMgt.RetrieveAppliedExpirationDate(NewItemLedgEntry);
        // OnInitCorrItemLedgEntryOnAfterRetrieveAppliedExpirationDate(NewItemLedgEntry);

        NewItemLedgEntry."Entry No." := FAItemLedgEntryNo;
        NewItemLedgEntry.Quantity := -OldItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := -OldItemLedgEntry.Quantity;
        if NewItemLedgEntry.Quantity > 0 then
            NewItemLedgEntry."Shipped Qty. Not Returned" := 0
        else
            NewItemLedgEntry."Shipped Qty. Not Returned" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry."Completely Invoiced" := true;
        NewItemLedgEntry."Last Invoice Date" := NewItemLedgEntry."Posting Date";
        NewItemLedgEntry.Correction := true;
        NewItemLedgEntry."Document Line No." := FAItemJnlLine."Document Line No.";
        if OldItemLedgEntry.Positive then
            NewItemLedgEntry."Applies-to Entry" := OldItemLedgEntry."Entry No."
        else
            NewItemLedgEntry."Applies-to Entry" := 0;

        // OnBeforeInsertCorrItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry, ItemJnlLine);
        NewItemLedgEntry.Insert();
        // OnAfterInsertCorrItemLedgEntry(NewItemLedgEntry, ItemJnlLine, OldItemLedgEntry);

        if NewItemLedgEntry."Item Tracking" <> NewItemLedgEntry."Item Tracking"::None then
            ItemTrackingMgt.ExistingExpirationDate(NewItemLedgEntry, true, EntriesExist);

        // OnAfterInitCorrItemLedgEntry(NewItemLedgEntry, EntriesExist);
    end;

    local procedure UpdateOldItemLedgEntry(var OldItemLedgEntry: Record "FA Item Ledger Entry"; LastInvoiceDate: Date)
    begin
        OldItemLedgEntry."Completely Invoiced" := true;
        OldItemLedgEntry."Last Invoice Date" := LastInvoiceDate;
        OldItemLedgEntry."Invoiced Quantity" := OldItemLedgEntry.Quantity;
        OldItemLedgEntry."Shipped Qty. Not Returned" := 0;
        // OnBeforeOldItemLedgEntryModify(OldItemLedgEntry);
        OldItemLedgEntry.Modify();
    end;

    local procedure UpdateOrigAppliedFromEntry(OldItemLedgEntryNo: Integer)
    var
        ItemApplEntry: Record "FA Item Application Entry";
        ItemLedgEntry: Record "FA Item Ledger Entry";
    begin
        ItemApplEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        ItemApplEntry.SetRange("Outbound Item Entry No.", OldItemLedgEntryNo);
        ItemApplEntry.SetFilter("Item Ledger Entry No.", '<>%1', OldItemLedgEntryNo);
        if ItemApplEntry.FindSet() then
            repeat
                if ItemLedgEntry.Get(ItemApplEntry."Inbound Item Entry No.") and
                   not ItemLedgEntry."Applied Entry to Adjust"
                then begin
                    ItemLedgEntry."Applied Entry to Adjust" := true;
                    ItemLedgEntry.Modify();
                end;
            // OnUpdateOrigAppliedFromEntryOnItemApplEntryLoop(ItemLedgEntry, ItemApplEntry);
            until ItemApplEntry.Next() = 0;
    end;
}