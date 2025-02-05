namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Planning;

codeunit 51202 "Conversion Line-Reserve"
{
    Permissions = TableData "Reservation Entry" = rimd;
    trigger OnRun()
    begin
    end;

    var
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservationManagement: Codeunit "Reservation Management";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        DeleteItemTracking: Boolean;
        SummaryTypeTxt: Label '%1, %2', Locked = true;

        Text000Err: Label 'Reserved quantity cannot be greater than %1.', Comment = '%1 - quantity';
        Text001Err: Label 'Codeunit is not initialized correctly.';
        Text002Err: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Due Date"';
        Text003Err: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';

    procedure CreateReservation(ConversionLine: Record "FA Conversion Line"; Description: Text[100]; ExpectedReceiptDate: Date; Quantity: Decimal; QuantityBase: Decimal; ForReservationEntry: Record "Reservation Entry")
    var
        ShipmentDate: Date;
    begin
        if FromTrackingSpecification."Source Type" = 0 then
            Error(Text001Err);

        ConversionLine.TestField(Type, ConversionLine.Type::Item);
        ConversionLine.TestField("No.");
        ConversionLine.TestField("Due Date");

        ConversionLine.CalcFields("Reserved Qty. (Base)");
        if Abs(ConversionLine."Remaining Quantity (Base)") < Abs(ConversionLine."Reserved Qty. (Base)") + QuantityBase then
            Error(
                Text000Err,
                Abs(ConversionLine."Remaining Quantity (Base)") - Abs(ConversionLine."Reserved Qty. (Base)"));

        ConversionLine.TestField("Variant Code", FromTrackingSpecification."Variant Code");
        ConversionLine.TestField("Location Code", FromTrackingSpecification."Location Code");

        if QuantityBase * SignFactor(ConversionLine) < 0 then
            ShipmentDate := ConversionLine."Due Date"
        else begin
            ShipmentDate := ExpectedReceiptDate;
            ExpectedReceiptDate := ConversionLine."Due Date";
        end;

        CreateReservEntry.CreateReservEntryFor(
          Database::"FA Conversion Line", //AssemblyLine."Document Type".AsInteger(),
          0, ConversionLine."Document No.", '', 0, ConversionLine."Line No.", ConversionLine."Qty. per Unit of Measure",
          Quantity, QuantityBase, ForReservationEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
        CreateReservEntry.CreateReservEntry(
          ConversionLine."No.", ConversionLine."Variant Code", ConversionLine."Location Code",
          Description, ExpectedReceiptDate, ShipmentDate, 0);

        FromTrackingSpecification."Source Type" := 0;
    end;

    procedure CreateReservationSetFrom(TrackingSpecification: Record "Tracking Specification")
    begin
        FromTrackingSpecification := TrackingSpecification;
    end;

    local procedure SignFactor(ConversionLine: Record "FA Conversion Line"): Integer
    begin
        // if ConversionLine."Document Type".AsInteger() in [2, 3, 5] then
        //     Error(Text001Err);

        exit(-1);
    end;

    procedure FindReservEntry(ConversionLine: Record "FA Conversion Line"; var ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ConversionLine.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    local procedure AssignForPlanning(var ConversionLine: Record "FA COnversion Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        // if ConversionLine."Document Type" <> ConversionLine."Document Type"::Order then
        //     exit;

        if ConversionLine.Type <> ConversionLine.Type::Item then
            exit;

        if ConversionLine."No." <> '' then
            PlanningAssignment.ChkAssignOne(ConversionLine."No.", ConversionLine."Variant Code", ConversionLine."Location Code", WorkDate());
    end;

    procedure ReservEntryExist(ConversionLine: Record "FA Conversion Line"): Boolean
    begin
        exit(ConversionLine.ReservEntryExist());
    end;

    procedure DeleteLine(var ConversionLine: Record "FA Conversion Line")
    begin
        ReservationManagement.SetReservSource(ConversionLine);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        ReservationManagement.ClearActionMessageReferences();
        ConversionLine.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(ConversionLine);
    end;

    procedure SetDeleteItemTracking(AllowDirectDeletion: Boolean)
    begin
        DeleteItemTracking := AllowDirectDeletion;
    end;

    procedure VerifyChange(var NewConversionLine: Record "FA Conversion Line"; var OldConversionLine: Record "FA Conversion Line")
    var
        ConversionLine: Record "FA Conversion Line";
        ReservationEntry: Record "Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        if (NewConversionLine.Type <> NewConversionLine.Type::Item) and (OldConversionLine.Type <> OldConversionLine.Type::Item) then
            exit;

        if NewConversionLine."Line No." = 0 then
            if not ConversionLine.Get(NewConversionLine."Document No.", NewConversionLine."Line No.") then
                exit;

        NewConversionLine.CalcFields("Reserved Qty. (Base)");
        ShowError := NewConversionLine."Reserved Qty. (Base)" <> 0;

        if NewConversionLine."Due Date" = 0D then begin
            if ShowError then
                NewConversionLine.FieldError("Due Date", Text002Err);
            HasError := true;
        end;

        if NewConversionLine.Type <> OldConversionLine.Type then begin
            if ShowError then
                NewConversionLine.FieldError(Type, Text003Err);
            HasError := true;
        end;

        if NewConversionLine."No." <> OldConversionLine."No." then begin
            if ShowError then
                NewConversionLine.FieldError("No.", Text003Err);
            HasError := true;
        end;

        if NewConversionLine."Location Code" <> OldConversionLine."Location Code" then begin
            if ShowError then
                NewConversionLine.FieldError("Location Code", Text003Err);
            HasError := true;
        end;

        // OnVerifyChangeOnBeforeHasError(NewConversionLine, OldConversionLine, HasError, ShowError);

        if (NewConversionLine.Type = NewConversionLine.Type::Item) and (OldConversionLine.Type = OldConversionLine.Type::Item) and
           (NewConversionLine."Bin Code" <> OldConversionLine."Bin Code")
        then
            if not ReservationManagement.CalcIsAvailTrackedQtyInBin(
                 NewConversionLine."No.", NewConversionLine."Bin Code",
                 NewConversionLine."Location Code", NewConversionLine."Variant Code",
                 Database::"FA Conversion Line", //NewConversionLine."Document Type".AsInteger(),
                 0, NewConversionLine."Document No.", '', 0, NewConversionLine."Line No.")
            then begin
                if ShowError then
                    NewConversionLine.FieldError("Bin Code", Text003Err);
                HasError := true;
            end;

        if NewConversionLine."Variant Code" <> OldConversionLine."Variant Code" then begin
            if ShowError then
                NewConversionLine.FieldError("Variant Code", Text003Err);
            HasError := true;
        end;

        if NewConversionLine."Line No." <> OldConversionLine."Line No." then
            HasError := true;

        if HasError then
            if (NewConversionLine."No." <> OldConversionLine."No.") or
               FindReservEntry(NewConversionLine, ReservationEntry)
            then begin
                if NewConversionLine."No." <> OldConversionLine."No." then begin
                    ReservationManagement.SetReservSource(OldConversionLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewConversionLine);
                end else begin
                    ReservationManagement.SetReservSource(NewConversionLine);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewConversionLine."Remaining Quantity (Base)");
            end;

        if HasError or (NewConversionLine."Due Date" <> OldConversionLine."Due Date") then begin
            AssignForPlanning(NewConversionLine);
            if (NewConversionLine."No." <> OldConversionLine."No.") or
               (NewConversionLine."Variant Code" <> OldConversionLine."Variant Code") or
               (NewConversionLine."Location Code" <> OldConversionLine."Location Code")
            then
                AssignForPlanning(OldConversionLine);
        end;
    end;

    procedure VerifyQuantity(var NewConversionLine: Record "FA Conversion Line"; var OldConversionLine: Record "FA Conversion Line")
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if NewConversionLine.Type <> NewConversionLine.Type::Item then
            exit;
        if NewConversionLine."Line No." = OldConversionLine."Line No." then
            if NewConversionLine."Remaining Quantity (Base)" = OldConversionLine."Remaining Quantity (Base)" then
                exit;
        if NewConversionLine."Line No." = 0 then
            if not ConversionLine.Get(NewConversionLine."Document No.", NewConversionLine."Line No.") then
                exit;

        ReservationManagement.SetReservSource(NewConversionLine);
        if NewConversionLine."Qty. per Unit of Measure" <> OldConversionLine."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        ReservationManagement.DeleteReservEntries(false, NewConversionLine."Remaining Quantity (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewConversionLine."Remaining Quantity (Base)");
        AssignForPlanning(NewConversionLine);
    end;

    procedure Caption(ConversionLine: Record "FA Conversion Line") CaptionText: Text
    begin
        CaptionText := ConversionLine.GetSourceCaption();
    end;

    procedure CallItemTracking(var ConversionLine: Record "FA Conversion Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingLines: Page "Item Tracking Lines";
    begin
        InitFromConversionLine(ConversionLine, TrackingSpecification);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ConversionLine."Due Date");
        ItemTrackingLines.SetInbound(ConversionLine.IsInbound());
        // OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(ConversionLine, ItemTrackingLines);
        ItemTrackingLines.RunModal();
    end;

    procedure DeleteLineConfirm(var ConversionLine: Record "FA Conversion Line"): Boolean
    begin
        if not ConversionLine.ReservEntryExist() then
            exit(true);

        ReservationManagement.SetReservSource(ConversionLine);
        if ReservationManagement.DeleteItemTrackingConfirm() then
            DeleteItemTracking := true;

        exit(DeleteItemTracking);
    end;

    procedure UpdateItemTrackingAfterPosting(ConversionLine: Record "FA Conversion Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        ReservationEntry.InitSortingAndFilters(false);
        ReservationEntry.SetRange("Source Type", Database::"FA Conversion Line");
        ReservationEntry.SetRange("Source Subtype", 0);//AssemblyLine."Document Type");
        ReservationEntry.SetRange("Source ID", ConversionLine."Document No.");
        ReservationEntry.SetRange("Source Batch Name", '');
        ReservationEntry.SetRange("Source Prod. Order Line", 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(ReservationEntry);
    end;

    procedure TransferConLineToItemJnlLine(var ConversionLine: Record "FA Conversion Line"; var ItemJournalLine: Record "Item Journal Line"; TransferQty: Decimal; CheckApplFromItemEntry: Boolean): Decimal
    var
        OldReservationEntry: Record "Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;

        if not FindReservEntry(ConversionLine, OldReservationEntry) then
            exit(TransferQty);

        ItemJournalLine.TestField("Item No.", ConversionLine."No.");
        ItemJournalLine.TestField("Variant Code", ConversionLine."Variant Code");
        ItemJournalLine.TestField("Location Code", ConversionLine."Location Code");

        OldReservationEntry.Lock();
        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestField("Item No.", ConversionLine."No.");
                OldReservationEntry.TestField("Variant Code", ConversionLine."Variant Code");
                OldReservationEntry.TestField("Location Code", ConversionLine."Location Code");

                if CheckApplFromItemEntry then begin
                    OldReservationEntry.TestField("Appl.-from Item Entry");
                    CreateReservEntry.SetApplyFromEntryNo(OldReservationEntry."Appl.-from Item Entry");
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(
                    Database::"Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplFromItemEntry := false;
        end;
        exit(TransferQty);
    end;

    procedure InitFromConversionLine(var ConversionLine: Record "FA Conversion Line"; var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.Init();
        TrackingSpecification.SetItemData(
            ConversionLine."No.", ConversionLine.Description, ConversionLine."Location Code", ConversionLine."Variant Code", ConversionLine."Bin Code",
            ConversionLine."Qty. per Unit of Measure");
        TrackingSpecification."Qty. Rounding Precision (Base)" := ConversionLine."Qty. Rounding Precision (Base)";
        TrackingSpecification.SetSource(
            Database::"FA Conversion Line", //ConversionLine."Document Type".AsInteger(), 
                0, ConversionLine."Document No.", ConversionLine."Line No.", '', 0);
        TrackingSpecification.SetQuantities(
            ConversionLine."Quantity (Base)", ConversionLine."Quantity to Consume", ConversionLine."Quantity to Consume (Base)",
            ConversionLine."Quantity to Consume", ConversionLine."Quantity to Consume (Base)",
            ConversionLine."Consumed Quantity (Base)", ConversionLine."Consumed Quantity (Base)");

        // OnAfterInitFromAsmLine(Rec, AsmLine);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::Reservation, 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ConversionLine);
            ConversionLine.Find();
            QtyPerUOM := ConversionLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        SourceRecordRef.SetTable(ConversionLine);
        ConversionLine.TestField(Type, ConversionLine.Type::Item);
        ConversionLine.TestField("Due Date");

        ConversionLine.SetReservationEntry(ReservationEntry);

        CaptionText := ConversionLine.GetSourceCaption();
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        // exit(EntryNo in [Enum::"Reservation Summary Type"::"Assembly Quote Line".AsInteger(),
        //                  Enum::"Reservation Summary Type"::"Assembly Order Line".AsInteger()]);
        exit(EntryNo in [Enum::"Reservation Summary Type"::"FA Converion Order Line".AsInteger()])
    end;

    local procedure EntryStartNo(): Integer
    begin
        exit(Enum::"Reservation Summary Type"::"FA Converion Order Line".AsInteger());
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"FA Conversion Line");
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
    //     AvailableAssemblyLines: page "Available - Assembly Lines";
    begin
        if MatchThisEntry(EntrySummary."Entry No.") then begin

        end;
        if EntrySummary."Entry No." in [151, 152] then begin
            //         Clear(AvailableAssemblyLines);
            //         AvailableAssemblyLines.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
            //         AvailableAssemblyLines.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            //         AvailableAssemblyLines.RunModal();
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"FA Conversion Line");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Reservation, 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"FA Conversion Line") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ConversionLine);
            CreateReservation(ConversionLine, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupDocument', '', false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if MatchThisTable(SourceType) then begin
            ConversionHeader.Reset();
            // ConversionHeader.SetRange("Document Type", SourceSubtype);
            ConversionHeader.SetRange("No.", SourceID);
            case SourceSubtype of
                0:
                    ;
                1:
                    PAGE.RunModal(PAGE::"FA Conversion Order", ConversionHeader);
                5:
                    ;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if MatchThisTable(SourceType) then begin
            ConversionLine.Reset();
            // ConversionLine.SetRange("Document Type", SourceSubtype);
            ConversionLine.SetRange("Document No.", SourceID);
            ConversionLine.SetRange("Line No.", SourceRefNo);
            PAGE.Run(PAGE::"FA Conversion Lines", ConversionLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var CaptionText: Text)
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ConversionLine);
            ConversionLine.SetReservationFilters(ReservEntry);
            CaptionText := ConversionLine.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ConversionLine);
            ConversionLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        ConversionLine.Get(ReservationEntry."Source ID", ReservationEntry."Source Ref. No.");
        SourceRecordRef.GetTable(ConversionLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ConversionLine."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ConversionLine."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; ReturnOption: Option; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ConversionLine: Record "FA Conversion Line";
        AvailabilityFilter: Text;
    begin
        if not ConversionLine.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ConversionLine.FilterLinesForReservation(CalcReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if ConversionLine.FindSet() then
            repeat
                ConversionLine.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" -= ConversionLine."Reserved Qty. (Base)";
                TotalQuantity += ConversionLine."Remaining Quantity (Base)";
            until ConversionLine.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if TotalQuantity < 0 = Positive then begin
            TempEntrySummary."Table ID" := Database::"FA COnversion Line";
            TempEntrySummary."Summary Type" := CopyStr(StrSubstNo(SummaryTypeTxt, ConversionLine.TableCaption()),// ConversionLine."Document Type"),
                1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := -TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [151, 152] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 151, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "Reservation Entry")
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        // ConversionLine.SetRange("Document Type", ReservationEntry."Source Subtype");
        ConversionLine.SetRange("Document No.", ReservationEntry."Source ID");
        ConversionLine.SetRange("Line No.", ReservationEntry."Source Ref. No.");
        PAGE.RunModal(Page::"FA Conversion Lines", ConversionLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnAfterSignFactor', '', false, false)]
    local procedure OnAfterSignFactorofCreateResrvEntry(ReservationEntry: Record "Reservation Entry"; var Sign: Integer)
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            Sign := -1;
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"Reservation Management", OnSetReservSource, '', false, false)]
    local procedure OnSetReservSourceCalcReservEntry(Direction: Enum "Transfer Direction"; sender: Codeunit "Reservation Management"; SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry")
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ConversionLine);
            ConversionLine.SetReservationEntry(ReservEntry);
            sender.UpdateReservation((CreateReservEntry.SignFactor(ReservEntry) * ConversionLine."Remaining Quantity (Base)") <= 0);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", OnAfterCreateText, '', false, false)]
    local procedure OnAfterCreateText(ReservationEntry: Record "Reservation Entry"; var SourceTypeText: Text)
    var
        SourceDoc3Txt: Label '%1 %2 %3', Locked = true;
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            SourceTypeText := (StrSubstNo(SourceDoc3Txt, 'FA Conversion Line',
                                '', ReservationEntry."Source ID"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Ledger Entry-Reserve", OnDrillDownTotalQuantityElseCase, '', false, false)]
    local procedure OnDrillDownTotalQuantityElseCase(EntrySummary: Record "Entry Summary" temporary; Location: Record Location; MaxQtyToReserve: Decimal; ReservEntry: Record "Reservation Entry"; SourceRecRef: RecordRef)
    var
        AvailableItemLedgEntries: Page "Available - Item Ledg. Entries";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            AvailableItemLedgEntries.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
            AvailableItemLedgEntries.SetTotalAvailQty(EntrySummary."Total Available Quantity");
            AvailableItemLedgEntries.SetMaxQtyToReserve(MaxQtyToReserve);
            AvailableItemLedgEntries.RunModal();
        end;
    end;
}