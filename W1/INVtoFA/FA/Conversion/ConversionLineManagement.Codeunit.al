namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Availability;
using System.Environment.Configuration;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Inventory.Tracking;
using TSTChanges.FA.Tracking;
using TSTChanges.FA.FAItem;
using TSTChanges.FA.Setup;
using Microsoft.Inventory.BOM;

codeunit 51200 "Conversion Line Management"
{
    trigger OnRun()
    begin

    end;

    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Text001: Label 'Do you want to update the %1 on the lines?';
        Text003: Label 'Changing %1 will change all the lines. Do you want to change the %1 from %2 to %3?';

    local procedure LinesExist(ConversionHeader: Record "FA Conversion Header"): Boolean
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        SetLinkToLines(ConversionHeader, ConversionLine);
        exit(not ConversionLine.IsEmpty);
    end;

    local procedure SetLinkToLines(ConversionHeader: Record "FA Conversion Header"; var ConversionLine: Record "FA Conversion Line")
    begin
        // ConversionLine.SetRange("Document Type", AsmHeader."Document Type");
        ConversionLine.SetRange("Document No.", ConversionHeader."No.");
    end;

    procedure UpdateWarningOnLines(ConversionHeader: Record "FA Conversion Header")
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        SetLinkToLines(ConversionHeader, ConversionLine);
        if ConversionLine.FindSet() then
            repeat
                ConversionLine.UpdateAvailWarning();
                ConversionLine.Modify();
            until ConversionLine.Next() = 0;
    end;

    local procedure SetLinkToItemLines(ConHeader: Record "FA Conversion Header"; var ConversionLine: Record "FA Conversion Line")
    begin
        SetLinkToLines(ConHeader, ConversionLine);
        ConversionLine.SetRange(Type, ConversionLine.Type::Item);
    end;

    procedure ConOrderLineShowWarning(ConversionLine: Record "FA Conversion Line") IsWarning: Boolean
    var
        OldConversionLine: Record "FA Conversion Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        OldItemNetChange: Decimal;
        OldItemNetResChange: Decimal;
        // AvailableToPromise: Codeunit "Available to Promise";
        UseOrderPromise: Boolean;
    // IsHandled: Boolean;
    begin
        if not ItemCheckAvail.ShowWarningForThisItem(ConversionLine."No.") then
            exit(false);

        // Clear(AvailableToPromise);

        OldItemNetChange := 0;

        OldConversionLine := ConversionLine;

        if OldConversionLine.Find() then // Find previous quantity
            if //(OldConversionLine."Document Type" = OldConversionLine."Document Type"::Order) and
               (OldConversionLine.Type = OldConversionLine.Type::Item) and
               (OldConversionLine."No." = ConversionLine."No.") and
               (OldConversionLine."Variant Code" = ConversionLine."Variant Code") and
               (OldConversionLine."Location Code" = ConversionLine."Location Code") and
                (OldConversionLine."Bin Code" = ConversionLine."Bin Code")
            then
                 //  if OldConversionLine."Due Date" > ConversionLine."Due Date" then
                 //  AvailableToPromise.SetChangedAsmLine(OldConversionLine)
                 //else
                 begin
                OldItemNetChange := -OldConversionLine."Remaining Quantity (Base)";
                OldConversionLine.CalcFields("Reserved Qty. (Base)");
                OldItemNetResChange := -OldConversionLine."Reserved Qty. (Base)";
            end;

        UseOrderPromise := true;
        // IsHandled := false;
        // OnAsmOrderLineShowWarningOnBeforeShowWarning(ConversionLine, ContextInfo, OldConversionLine, OldItemNetChange, IsWarning, IsHandled);
        // if IsHandled then
        //     exit(IsWarning);

        exit(
          ItemCheckAvail.ShowWarning(
            ConversionLine."No.",
            ConversionLine."Variant Code",
            ConversionLine."Location Code",
            ConversionLine."Unit of Measure Code",
            ConversionLine."Qty. per Unit of Measure",
            -ConversionLine."Remaining Quantity",
            OldItemNetChange,
            ConversionLine."Due Date",
            OldConversionLine."Due Date"));
    end;

    procedure ConversionLineCheck(AssemblyLine: Record "FA Conversion Line") Rollback: Boolean
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          AssemblyLine.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId(), true);
        if ConOrderLineShowWarning(AssemblyLine) then
            Rollback := ItemCheckAvail.ShowAndHandleAvailabilityPage(AssemblyLine.RecordId);
    end;

    procedure UpdateConversionLines(var ConversionHeader: Record "FA Conversion Header"; OldConversionHeader: Record "FA Conversion Header"; FieldNum: Integer; ReplaceLinesFromBOM: Boolean; CurrFieldNo: Integer; CurrentFieldNum: Integer)
    var
        ConversionLine: Record "FA Conversion Line";
        TempConversionHeader: Record "FA COnversion Header" temporary;
        TempConversionLine: Record "FA Conversion Line" temporary;
        BOMComponent: Record "BOM Component";
        TempCurrConLine: Record "FA Conversion Line" temporary;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        NoOfLinesFound: Integer;
        UpdateDueDate: Boolean;
        UpdateLocation: Boolean;
        UpdateQuantity: Boolean;
        UpdateUOM: Boolean;
        UpdateQtyToConsume: Boolean;
        UpdateDimension: Boolean;
        DueDateBeforeWorkDate: Boolean;
        NewLineDueDate: Date;
        IsHandled: Boolean;
        ShouldReplaceAsmLines: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateAssemblyLines(AsmHeader, OldAsmHeader, FieldNum, ReplaceLinesFromBOM, CurrFieldNo, CurrentFieldNum, IsHandled, HideValidationDialog);
        // if IsHandled then
        //     exit;

        if (FieldNum <> CurrentFieldNum) or // Update has been called from OnValidate of another field than was originally intended.
           ((not (FieldNum in [ConversionHeader.FieldNo("FA Item No."),
                               ConversionHeader.FieldNo("Variant Code"),
                               ConversionHeader.FieldNo("Location Code"),
                               ConversionHeader.FieldNo("Starting Date"),
                               ConversionHeader.FieldNo(Quantity),
                               ConversionHeader.FieldNo("Unit of Measure Code"),
                               ConversionHeader.FieldNo("Quantity to Convert")//,
                                                                              //    ConversionHeader.FieldNo("Dimension Set ID")
                            ])) and (not ReplaceLinesFromBOM))
        then
            exit;

        NoOfLinesFound := CopyConversionData(ConversionHeader, TempConversionHeader, TempConversionLine);
        // OnUpdateAssemblyLinesOnAfterCopyAssemblyData(TempConversionLine, ReplaceLinesFromBOM);
        if ReplaceLinesFromBOM then begin
            TempConversionLine.DeleteAll();
            ShouldReplaceAsmLines := not ((ConversionHeader."Quantity (Base)" = 0) or (ConversionHeader."FA Item No." = '')); // condition to replace asm lines
            // OnUpdateAssemblyLinesOnAfterCalcShouldReplaceAsmLines(ConversionHeader, TempConversionLine, ShouldReplaceAsmLines);
            if ShouldReplaceAsmLines then begin
                // IsHandled := false;
                // OnBeforeReplaceAssemblyLines(ConversionHeader, TempConversionLine, IsHandled);
                // if not IsHandled then begin
                // SetLinkToBOM(ConversionHeader, BOMComponent);
                // if BOMComponent.FindSet() then
                //     repeat
                //         InsertAsmLine(ConversionHeader, TempConversionLine, true);
                //         AddBOMLine(ConversionHeader, TempConversionLine, true, BOMComponent, false, ConversionHeader."Qty. per Unit of Measure");
                //     until BOMComponent.Next() <= 0;
                // end;
            end;
        end else
            if NoOfLinesFound = 0 then
                exit; // MODIFY condition but no lines to modify

        // make pre-checks OR ask user to confirm
        if PreCheckAndConfirmUpdate(ConversionHeader, OldConversionHeader, FieldNum, ReplaceLinesFromBOM, TempConversionLine,
             UpdateDueDate, UpdateLocation, UpdateQuantity, UpdateUOM, UpdateQtyToConsume, UpdateDimension)
        then
            exit;

        if not ReplaceLinesFromBOM then
            if TempConversionLine.Find('-') then
                repeat
                    TempCurrConLine := TempConversionLine;
                    TempCurrConLine.Insert();
                    TempConversionLine.SetSkipVerificationsThatChangeDatabase(true);
                    UpdateExistingLine(
                        ConversionHeader, OldConversionHeader, CurrFieldNo, TempConversionLine,
                        UpdateDueDate, UpdateLocation, UpdateQuantity, UpdateUOM, UpdateQtyToConsume, UpdateDimension);
                until TempConversionLine.Next() = 0;

        if not (FieldNum in [ConversionHeader.FieldNo("Quantity to Convert")//, ConversionHeader.FieldNo("Dimension Set ID")
                ]) then
            if ShowAvailability(false, TempConversionHeader, TempConversionLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError();

        // DoVerificationsSkippedEarlier(
        //     ReplaceLinesFromBOM, TempConversionLine, TempCurrConLine, UpdateDimension, ConversionHeader."Dimension Set ID",
        //     OldConversionHeader."Dimension Set ID");

        ConversionLine.Reset();
        if ReplaceLinesFromBOM then begin
            ConversionHeader.DeleteConversionLines();
            TempConversionLine.Reset();
        end;

        if TempConversionLine.Find('-') then
            repeat
                if not ReplaceLinesFromBOM then
                    ConversionLine.Get(TempConversionLine."Document No.", TempConversionLine."Line No.");
                ConversionLine := TempConversionLine;
                if ReplaceLinesFromBOM then
                    ConversionLine.Insert(true)
                else
                    ConversionLine.Modify(true);
                // OnUpdateAssemblyLinesOnBeforeAutoReserveAsmLine(AssemblyLine, ReplaceLinesFromBOM);
                // ConversionHeader.AutoReserveAsmLine(ConversionLine);
                if ConversionLine."Due Date" < WorkDate() then begin
                    DueDateBeforeWorkDate := true;
                    NewLineDueDate := ConversionLine."Due Date";
                end;
            until TempConversionLine.Next() = 0;

        // if ReplaceLinesFromBOM or UpdateDueDate then
        //     if DueDateBeforeWorkDate then
        //         ShowDueDateBeforeWorkDateMsg(NewLineDueDate);
    end;

    procedure CopyConversionData(FromConversionHeader: Record "FA Conversion Header"; var ToConversionHeader: Record "FA Conversion Header"; var ToConversionLine: Record "FA COnversion Line") NoOfLinesInserted: Integer
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        ToConversionHeader := FromConversionHeader;
        ToConversionHeader.Insert();

        SetLinkToLines(FromConversionHeader, ConversionLine);
        ConversionLine.SetFilter(Type, '%1|%2', ConversionLine.Type::Item, ConversionLine.Type::Resource);
        ToConversionLine.Reset();
        ToConversionLine.DeleteAll();
        if ConversionLine.Find('-') then
            repeat
                ToConversionLine := ConversionLine;
                ToConversionLine.Insert();
                // OnCopyAssemblyDataOnAfterToAssemblyLineInsert(AssemblyLine, ToAssemblyLine);
                NoOfLinesInserted += 1;
            until ConversionLine.Next() = 0;
    end;

    local procedure PreCheckAndConfirmUpdate(ConversionHeader: Record "FA Conversion Header"; OldConversionHeader: Record "FA Conversion Header"; FieldNum: Integer; var ReplaceLinesFromBOM: Boolean; var TempConversionLine: Record "FA Conversion Line" temporary; var UpdateDueDate: Boolean; var UpdateLocation: Boolean; var UpdateQuantity: Boolean; var UpdateUOM: Boolean; var UpdateQtyToConsume: Boolean; var UpdateDimension: Boolean): Boolean
    begin
        UpdateDueDate := false;
        UpdateLocation := false;
        UpdateQuantity := false;
        UpdateUOM := false;
        UpdateQtyToConsume := false;
        UpdateDimension := false;

        case FieldNum of
            ConversionHeader.FieldNo("FA Item No."):
                if ConversionHeader."FA Item No." <> OldConversionHeader."FA Item No." then
                    if LinesExist(ConversionHeader) then
                        if GuiAllowed then
                            if not Confirm(StrSubstNo(Text003, ConversionHeader.FieldCaption("FA Item No."), OldConversionHeader."FA Item No.", ConversionHeader."FA Item No.")) then
                                Error('');
            ConversionHeader.FieldNo("Variant Code"):
                UpdateDueDate := true;
            ConversionHeader.FieldNo("Location Code"):
                begin
                    UpdateDueDate := true;
                    if ConversionHeader."Location Code" <> OldConversionHeader."Location Code" then begin
                        TempConversionLine.SetRange(Type, TempConversionLine.Type::Item);
                        TempConversionLine.SetFilter("Location Code", '<>%1', ConversionHeader."Location Code");
                        if not TempConversionLine.IsEmpty then
                            if GuiAllowed then
                                if Confirm(StrSubstNo(Text001, TempConversionLine.FieldCaption("Location Code")), false) then
                                    UpdateLocation := true;
                        TempConversionLine.SetRange("Location Code");
                        TempConversionLine.SetRange(Type);
                    end;
                end;
            ConversionHeader.FieldNo("Starting Date"):
                UpdateDueDate := true;
            ConversionHeader.FieldNo(Quantity):
                if ConversionHeader.Quantity <> OldConversionHeader.Quantity then begin
                    UpdateQuantity := true;
                    UpdateQtyToConsume := true;
                end;
            ConversionHeader.FieldNo("Unit of Measure Code"):
                if ConversionHeader."Unit of Measure Code" <> OldConversionHeader."Unit of Measure Code" then
                    UpdateUOM := true;
            ConversionHeader.FieldNo("Quantity to Convert"):
                UpdateQtyToConsume := true;
        // ConversionHeader.FieldNo("Dimension Set ID"):
        //     if ConversionHeader."Dimension Set ID" <> OldAsmHeader."Dimension Set ID" then
        //         if LinesExist(ConversionHeader) then begin
        //             UpdateDimension := true;
        //             if GuiAllowed and not HideValidationDialog then
        //                 if not Confirm(Text002) then
        //                     UpdateDimension := false;
        //         end;
        // else
        //     if CalledFromRefreshBOM(ReplaceLinesFromBOM, FieldNum) then
        //         if LinesExist(ConversionHeader) then
        //             if GuiAllowed then
        //                 if not Confirm(Text004, false) then
        //                     ReplaceLinesFromBOM := false;
        end;

        if not (UpdateDueDate or UpdateLocation or UpdateQuantity or UpdateUOM or UpdateQtyToConsume or UpdateDimension) and
           // nothing to update
           not ReplaceLinesFromBOM
        then
            exit(true);
    end;

    local procedure UpdateExistingLine(var ConversionHeader: Record "FA Conversion Header"; OldConversionHeader: Record "FA COnversion Header"; CurrFieldNo: Integer; var ConversionLine: Record "FA COnversion Line"; UpdateDueDate: Boolean; UpdateLocation: Boolean; UpdateQuantity: Boolean; UpdateUOM: Boolean; UpdateQtyToConsume: Boolean; UpdateDimension: Boolean)
    var
        QtyRatio: Decimal;
        QtyToConsume: Decimal;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateExistingLine(
        //     AsmHeader, OldAsmHeader, CurrFieldNo, AssemblyLine, UpdateDueDate, UpdateLocation,
        //     UpdateQuantity, UpdateUOM, UpdateQtyToConsume, UpdateDimension, IsHandled);
        // if IsHandled then
        //     exit;

        if ConversionHeader.IsStatusCheckSuspended() then
            ConversionLine.SuspendStatusCheck(true);

        if UpdateLocation and (ConversionLine.Type = ConversionLine.Type::Item) then
            ConversionLine.Validate("Location Code", ConversionHeader."Location Code");

        if UpdateDueDate then begin
            //     ConversionLine.SetTestReservationDateConflict(CurrFieldNo <> 0);
            //     ConversionLine.ValidateLeadTimeOffset(ConversionHeader, ConversionLine."Lead-Time Offset", false);
        end;

        if UpdateQuantity then begin
            QtyRatio := ConversionHeader.Quantity / OldConversionHeader.Quantity;
            UpdateConversionLineQuantity(ConversionHeader, ConversionLine, QtyRatio);
            ConversionLine.InitQtyToConsume();
        end;

        if UpdateUOM then begin
            QtyRatio := ConversionHeader."Qty. per Unit of Measure" / OldConversionHeader."Qty. per Unit of Measure";
            if ConversionLine.FixedUsage() then
                ConversionLine.Validate("Quantity per")
            else
                ConversionLine.Validate("Quantity per", ConversionLine."Quantity per" * QtyRatio);
            ConversionLine.InitQtyToConsume();
        end;

        if UpdateQtyToConsume then
            if not ConversionLine.FixedUsage() then begin
                ConversionLine.InitQtyToConsume();
                QtyToConsume := ConversionLine.Quantity * ConversionHeader."Quantity to Convert" / ConversionHeader.Quantity;
                ConversionLine.RoundQty(QtyToConsume);
                UpdateQuantityToConsume(ConversionHeader, ConversionLine, QtyToConsume);
            end;

        // if UpdateDimension then
        //     ConversionLine.UpdateDim("Dimension Set ID", OldConversionHeader."Dimension Set ID");

        ConversionLine.Modify(true);
    end;

    local procedure UpdateQuantityToConsume(ConversionHeader: Record "FA Conversion Header"; var ConversionLine: Record "FA Conversion Line"; QtyToConsume: Decimal)
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateQuantityToConsume(AsmHeader, AssemblyLine, QtyToConsume, IsHandled);
        // if IsHandled then
        //     exit;

        if QtyToConsume <= ConversionLine.MaxQtyToConsume() then
            ConversionLine.Validate("Quantity to Consume", QtyToConsume);
    end;

    procedure ShowAvailability(ShowPageEvenIfEnoughComponentsAvailable: Boolean; var TempConversionHeader: Record "FA Conversion Header" temporary; var TempConversionLine: Record "FA Conversion Line" temporary) Rollback: Boolean
    var
        FAItem: Record "FA Item";
        TempConversionLine2: Record "FA Conversion Line" temporary;
        ConversionSetup: Record "FA Conversion Setup";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        // AssemblyAvailability: Page "Assembly Availability";
        Inventory: Decimal;
        GrossRequirement: Decimal;
        ReservedRequirement: Decimal;
        ScheduledReceipts: Decimal;
        ReservedReceipts: Decimal;
        EarliestAvailableDateX: Date;
        QtyAvailToMake: Decimal;
        QtyAvailTooLow: Boolean;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeShowAvailability(TempAssemblyHeader, TempAssemblyLine, ShowPageEvenIfEnoughComponentsAvailable, IsHandled, Rollback, WarningModeOff);
        // if IsHandled then
        //     exit(Rollback);

        ConversionSetup.Get();
        if not GuiAllowed or
           TempConversionLine.IsEmpty() //or
        //    (not ConversionSetup."Stockout Warning" and not ShowPageEvenIfEnoughComponentsAvailable) or
        //    not GetWarningMode()
        then
            exit(false);

        TempConversionHeader.TestField("FA Item No.");
        FAItem.Get(TempConversionHeader."FA Item No.");

        // ItemCheckAvail.AsmOrderCalculate(TempConversionHeader, Inventory,
        //   GrossRequirement, ReservedRequirement, ScheduledReceipts, ReservedReceipts);
        // CopyInventoriableItemAsmLines(TempConversionLine2, TempConversionLine);
        // AvailToPromise(TempConversionHeader, TempConversionLine2, QtyAvailToMake, EarliestAvailableDateX);
        QtyAvailTooLow := QtyAvailToMake < TempConversionHeader."Remaining Quantity";
        // if ShowPageEvenIfEnoughComponentsAvailable or QtyAvailTooLow then begin
        //     AssemblyAvailability.SetData(TempConversionHeader, TempConversionLine2);
        //     AssemblyAvailability.SetHeaderInventoryData(
        //       Inventory, GrossRequirement, ReservedRequirement, ScheduledReceipts, ReservedReceipts,
        //       EarliestAvailableDateX, QtyAvailToMake, QtyAvailTooLow);
        //     Rollback := not (AssemblyAvailability.RunModal() = ACTION::Yes);
        // end;
    end;

    local procedure UpdateConversionLineQuantity(ConversionHeader: Record "FA COnversion Header"; var ConversionLine: Record "FA Conversion Line"; QtyRatio: Decimal)
    var
        IsHandled: Boolean;
        RoundedQty: Decimal;
    begin
        // IsHandled := false;
        // OnBeforeUpdateAssemblyLineQuantity(AsmHeader, AssemblyLine, QtyRatio, IsHandled);
        // if IsHandled then
        //     exit;

        if ConversionLine.FixedUsage() then
            ConversionLine.Validate(Quantity)
        else begin
            RoundedQty := ConversionLine.Quantity * QtyRatio;
            ConversionLine.RoundQty(RoundedQty);
            ConversionLine.Validate(Quantity, RoundedQty);
        end;
    end;

    procedure CompletelyPicked(ConHeader: Record "FA Conversion Header"): Boolean
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        SetLinkToItemLines(ConHeader, ConversionLine);
        if ConversionLine.Find('-') then
            repeat
                if not ConversionLine.CompletelyPicked() then
                    exit(false);
            until ConversionLine.Next() = 0;
        exit(true);
    end;

    procedure CreateWhseItemTrkgForConLines(ConHeader: Record "FA Conversion Header")
    var
        ConversionLine: Record "FA Conversion Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCreateWhseItemTrkgForAsmLines(AsmHeader, IsHandled);
        if IsHandled then
            exit;

        // with ConversionLine do begin
        SetLinkToItemLines(ConHeader, ConversionLine);
        if ConversionLine.FindSet() then
            repeat
                if ItemTrackingMgt.GetWhseItemTrkgSetup(ConversionLine."No.") then
                    ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                        Enum::"Warehouse Worksheet Document Type"::Conversion, ConversionLine."Document No.", ConversionLine."Line No.",
                        Database::"FA Conversion Line", 0, ConversionLine."Document No.", ConversionLine."Line No.", 0);
            until ConversionLine.Next() = 0;
        // end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", OnBeforeGetSourceType, '', false, false)]
    local procedure OnBeforeGetSourceType(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer; var IsHandled: Boolean)
    begin
        case WhseWorksheetLine."Whse. Document Type" of
            WhseWorksheetLine."Whse. Document Type"::Conversion:
                begin
                    SourceType := Database::"FA Conversion Line";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", OnInitTrackingSpecificationOnBeforeCalcWhseItemTrackingLines, '', false, false)]
    local procedure OnInitTrackingSpecificationOnBeforeCalcWhseItemTrackingLines(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    var
        SourceReservEntry: Record "Reservation Entry";
        ItemTrackMgmt: Codeunit "Item Tracking Management";
    begin
        if WhseWorksheetLine."Source Type" = Database::"FA Conversion Line" then begin
            //     SourceReservEntry.SetSourceFilter(WhseWorksheetLine."Source Type", WhseWorksheetLine."Source Subtype",
            //         WhseWorksheetLine."Source No.", WhseWorksheetLine."Source Line No.", true);
            //     SourceReservEntry.SetSourceFilter('', 0);

            //     if SourceReservEntry.FindSet() then
            //         repeat
            //             ItemTrackMgmt.CreateWhseItemTrkgForResEntry(SourceReservEntry, WhseWorksheetLine);
            //         until SourceReservEntry.Next() = 0;
            //     IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", OnBeforeCreateWhseItemTrkgForResEntry, '', false, false)]
    local procedure CreateWhseItemTrkgForFACon(SourceReservEntry: Record "Reservation Entry"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWkshLine: Record "Whse. Worksheet Line")
    begin
        // if WhseWkshLine."Source Type" = Database::"FA Conversion Line" then begin
        //     WhseItemTrackingLine.SetSource(
        //               Database::"FA Conversion Line", WhseWkshLine."Source Subtype", WhseWkshLine."Whse. Document No.",
        //               WhseWkshLine."Whse. Document Line No.", '', 0);
        // end;
    end;
}