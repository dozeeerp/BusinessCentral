namespace TSTChanges.FA.Conversion;

using TSTChanges.FA.Tracking;
using TSTChanges.FA.Ledger;
using TSTChanges.FA.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;

codeunit 51206 "Conversion Header-Reserve"
{
    Permissions = tabledata "FA Reservation Entry" = rimd;
    trigger OnRun()
    begin

    end;

    var
        CreateReservEntry: Codeunit "FA Create Reserv. Entry";
        ReservationEngineMgt: Codeunit "FA Reservation Engine Mgt.";
        ReservationManagement: Codeunit "FA Reservation Management";
        DeleteItemTracking: Boolean;

        Text002: Label 'must be filled in when a quantity is reserved', Comment = 'starts with "Due Date"';
        Text003: Label 'must not be changed when a quantity is reserved', Comment = 'starts with some field name';
        ConversionTxt: Label 'Conversion';

    procedure FindReservEntry(ConversionHeader: Record "FA Conversion Header"; var ReservationEntry: Record "FA Reservation Entry"): Boolean
    begin
        ReservationEntry.InitSortingAndFilters(false);
        ConversionHeader.SetReservationFilters(ReservationEntry);
        exit(ReservationEntry.FindLast());
    end;

    local procedure AssignForPlanning(var ConversionHeader: Record "FA Conversion Header")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        // if ConversionHeader."Document Type" <> ConversionHeader."Document Type"::Order then
        //     exit;

        if ConversionHeader."FA Item No." <> '' then
            PlanningAssignment.ChkAssignOne(ConversionHeader."FA Item No.", ConversionHeader."Variant Code", ConversionHeader."Location Code", WorkDate());
    end;

    procedure ReservEntryExist(ConversionHeader: Record "FA Conversion Header"): Boolean
    begin
        exit(ConversionHeader.ReservEntryExist());
    end;

    procedure DeleteLine(var ConversionHeader: Record "FA Conversion Header")
    begin
        // OnBeforeDeleteLine(ConversionHeader);

        ReservationManagement.SetReservSource(ConversionHeader);
        if DeleteItemTracking then
            ReservationManagement.SetItemTrackingHandling(1); // Allow Deletion
        ReservationManagement.DeleteReservEntries(true, 0);
        ReservationManagement.ClearActionMessageReferences();
        ConversionHeader.CalcFields("Reserved Qty. (Base)");
        AssignForPlanning(ConversionHeader);
    end;

    procedure VerifyChange(var NewConversionHeader: Record "FA Conversion Header"; var OldConversionHeader: Record "FA Conversion Header")
    var
        ReservationEntry: Record "FA Reservation Entry";
        ShowError: Boolean;
        HasError: Boolean;
    begin
        NewConversionHeader.CalcFields("Reserved Qty. (Base)");
        ShowError := NewConversionHeader."Reserved Qty. (Base)" <> 0;

        if NewConversionHeader."Due Date" = 0D then begin
            if ShowError then
                NewConversionHeader.FieldError("Due Date", Text002);
            HasError := true;
        end;

        if NewConversionHeader."FA Item No." <> OldConversionHeader."FA Item No." then begin
            if ShowError then
                NewConversionHeader.FieldError("FA Item No.", Text003);
            HasError := true;
        end;

        if NewConversionHeader."Location Code" <> OldConversionHeader."Location Code" then begin
            if ShowError then
                NewConversionHeader.FieldError("Location Code", Text003);
            HasError := true;
        end;

        if NewConversionHeader."Variant Code" <> OldConversionHeader."Variant Code" then begin
            if ShowError then
                NewConversionHeader.FieldError("Variant Code", Text003);
            HasError := true;
        end;

        // OnVerifyChangeOnBeforeHasError(NewConversionHeader, OldConversionHeader, HasError, ShowError);

        if HasError then
            if (NewConversionHeader."FA Item No." <> OldConversionHeader."FA Item No.") or
               FindReservEntry(NewConversionHeader, ReservationEntry)
            then begin
                if NewConversionHeader."FA Item No." <> OldConversionHeader."FA Item No." then begin
                    ReservationManagement.SetReservSource(OldConversionHeader);
                    ReservationManagement.DeleteReservEntries(true, 0);
                    ReservationManagement.SetReservSource(NewConversionHeader);
                end else begin
                    ReservationManagement.SetReservSource(NewConversionHeader);
                    ReservationManagement.DeleteReservEntries(true, 0);
                end;
                ReservationManagement.AutoTrack(NewConversionHeader."Remaining Quantity (Base)");
            end;

        if HasError or (NewConversionHeader."Due Date" <> OldConversionHeader."Due Date") then begin
            AssignForPlanning(NewConversionHeader);
            if (NewConversionHeader."FA Item No." <> OldConversionHeader."FA Item No.") or
               (NewConversionHeader."Variant Code" <> OldConversionHeader."Variant Code") or
               (NewConversionHeader."Location Code" <> OldConversionHeader."Location Code")
            then
                AssignForPlanning(OldConversionHeader);
        end;
    end;

    procedure VerifyQuantity(var NewConversionHeader: Record "FA Conversion Header"; var OldConversionHeader: Record "FA Conversion Header")
    begin
        if NewConversionHeader."Quantity (Base)" = OldConversionHeader."Quantity (Base)" then
            exit;

        ReservationManagement.SetReservSource(NewConversionHeader);
        if NewConversionHeader."Qty. per Unit of Measure" <> OldConversionHeader."Qty. per Unit of Measure" then
            ReservationManagement.ModifyUnitOfMeasure();
        ReservationManagement.DeleteReservEntries(false, NewConversionHeader."Remaining Quantity (Base)");
        ReservationManagement.ClearSurplus();
        ReservationManagement.AutoTrack(NewConversionHeader."Remaining Quantity (Base)");
        AssignForPlanning(NewConversionHeader);
    end;

    procedure Caption(ConversionHeader: Record "FA Conversion Header") CaptionText: Text
    begin
        CaptionText := ConversionHeader.GetSourceCaption();
    end;

    procedure CallItemTracking(var ConversionHeader: Record "FA Conversion Header")
    var
        TrackingSpecification: Record "FA Tracking Specification";
        ItemTrackingLines: Page "FA Item Tracking Lines";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCallItemTracking(AssemblyHeader, IsHandled);
        // if not IsHandled then begin
        TrackingSpecification.InitFromConHeader(ConversionHeader);
        ItemTrackingLines.SetSourceSpec(TrackingSpecification, ConversionHeader."Due Date");
        ItemTrackingLines.SetInbound(ConversionHeader.IsInbound());
        // OnCallItemTrackingOnBeforeItemTrackingLinesRunModal(AssemblyHeader, ItemTrackingLines);
        ItemTrackingLines.RunModal();
        // end;
    end;

    procedure UpdateItemTrackingAfterPosting(ConversionHeader: Record "FA Conversion Header")
    var
        FAReservationEntry: Record "FA Reservation Entry";
    begin
        // Used for updating Quantity to Handle and Quantity to Invoice after posting
        FAReservationEntry.InitSortingAndFilters(false);
        FAReservationEntry.SetSourceFilter(
          Database::"FA Conversion Header", 0,//ConversionHeader."Document Type".AsInteger(), 
          ConversionHeader."No.", -1, false);
        FAReservationEntry.SetSourceFilter('', 0);
        CreateReservEntry.UpdateItemTrackingAfterPosting(FAReservationEntry);
    end;

    procedure TransferConHeaderToItemJnlLine(var ConversionHeader: Record "FA Conversion Header"; var ItemJournalLine: Record "FA Item Journal Line"; TransferQty: Decimal; CheckApplToItemEntry: Boolean): Decimal
    var
        OldReservationEntry: Record "FA Reservation Entry";
        OldReservationEntry2: Record "FA Reservation Entry";
    begin
        if TransferQty = 0 then
            exit;
        if not FindReservEntry(ConversionHeader, OldReservationEntry) then
            exit(TransferQty);
        // ConversionHeader.CalcFields("Assemble to Order");

        ItemJournalLine.TestItemFields(ConversionHeader."FA Item No.", ConversionHeader."Variant Code", ConversionHeader."Location Code");

        OldReservationEntry.Lock();

        if ReservationEngineMgt.InitRecordSet(OldReservationEntry) then begin
            repeat
                OldReservationEntry.TestItemFields(ConversionHeader."FA Item No.", ConversionHeader."Variant Code", ConversionHeader."Location Code");
                if CheckApplToItemEntry and
                   (OldReservationEntry."Reservation Status" = OldReservationEntry."Reservation Status"::Reservation)
                then begin
                    OldReservationEntry2.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                    OldReservationEntry2.TestField("Source Type", Database::"FA Item ledger Entry");
                end;

                if //ConversionHeader."Assemble to Order" and
                   (OldReservationEntry.Binding = OldReservationEntry.Binding::"Order-to-Order")
                then begin
                    OldReservationEntry2.Get(OldReservationEntry."Entry No.", not OldReservationEntry.Positive);
                    if Abs(OldReservationEntry2."Qty. to Handle (Base)") < Abs(OldReservationEntry."Qty. to Handle (Base)") then begin
                        OldReservationEntry."Qty. to Handle (Base)" := Abs(OldReservationEntry2."Qty. to Handle (Base)");
                        OldReservationEntry."Qty. to Invoice (Base)" := Abs(OldReservationEntry2."Qty. to Invoice (Base)");
                    end;
                end;

                TransferQty := CreateReservEntry.TransferReservEntry(
                    Database::"FA Item Journal Line",
                    ItemJournalLine."Entry Type".AsInteger(), ItemJournalLine."Journal Template Name",
                    ItemJournalLine."Journal Batch Name", 0, ItemJournalLine."Line No.",
                    ItemJournalLine."Qty. per Unit of Measure", OldReservationEntry, TransferQty);

            until (ReservationEngineMgt.NEXTRecord(OldReservationEntry) = 0) or (TransferQty = 0);
            CheckApplToItemEntry := false;
        end;
        exit(TransferQty);
    end;

    [EventSubscriber(ObjectType::Page, PAGE::"FA Reservation", 'OnGetQtyPerUOMFromSourceRecRef', '', false, false)]
    local procedure OnGetQtyPerUOMFromSourceRecRef(SourceRecRef: RecordRef; var QtyPerUOM: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal)
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ConversionHeader);
            ConversionHeader.Find();
            QtyPerUOM := ConversionHeader.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
        end;
    end;

    local procedure SignFactor(ConversionHeader: Record "FA Conversion Header"): Integer
    begin
        // if AssemblyHeader."Document Type".AsInteger() in [2, 3, 5] then
        //     Error(Text001);

        exit(1);
    end;

    local procedure SetReservSourceFor(SourceRecordRef: RecordRef; var ReservationEntry: Record "FA Reservation Entry"; var CaptionText: Text)
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        SourceRecordRef.SetTable(ConversionHeader);
        ConversionHeader.TestField("Due Date");

        ConversionHeader.SetReservationEntry(ReservationEntry);

        CaptionText := ConversionHeader.GetSourceCaption();
    end;


    local procedure EntryStartNo(): Integer
    begin
        // exit(Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger());
    end;

    local procedure MatchThisEntry(EntryNo: Integer): Boolean
    begin
        // exit(EntryNo in [Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger(),
        //  Enum::"Reservation Summary Type"::"Assembly Order Header".AsInteger()]);
    end;

    local procedure MatchThisTable(TableID: Integer): Boolean
    begin
        exit(TableID = Database::"FA Conversion Header");
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnSetReservSource', '', false, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "FA Reservation Entry"; var CaptionText: Text)
    begin
        if MatchThisTable(SourceRecRef.Number) then
            SetReservSourceFor(SourceRecRef, ReservEntry, CaptionText);
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnDrillDownTotalQuantity', '', false, false)]
    local procedure OnDrillDownTotalQuantity(SourceRecRef: RecordRef; ReservEntry: Record "FA Reservation Entry"; EntrySummary: Record "Entry Summary"; Location: Record Location; MaxQtyToReserve: Decimal)
    var
    // AvailableAssemblyHeaders: page "Available - Assembly Headers";
    begin
        // if EntrySummary."Entry No." in [141, 142] then begin
        //     Clear(AvailableAssemblyHeaders);
        //     AvailableAssemblyHeaders.SetCurrentSubType(EntrySummary."Entry No." - EntryStartNo());
        //     AvailableAssemblyHeaders.SetSource(SourceRecRef, ReservEntry, ReservEntry.GetTransferDirection());
        //     AvailableAssemblyHeaders.RunModal();
        // end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnFilterReservEntry', '', false, false)]
    local procedure OnFilterReservEntry(var FilterReservEntry: Record "FA Reservation Entry"; ReservEntrySummary: Record "Entry Summary")
    begin
        if MatchThisEntry(ReservEntrySummary."Entry No.") then begin
            FilterReservEntry.SetRange("Source Type", Database::"FA Conversion Header");
            FilterReservEntry.SetRange("Source Subtype", ReservEntrySummary."Entry No." - EntryStartNo());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation", 'OnAfterRelatesToSummEntry', '', false, false)]
    local procedure OnRelatesToEntrySummary(var FilterReservEntry: Record "FA Reservation Entry"; FromEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
        if MatchThisEntry(FromEntrySummary."Entry No.") then
            IsHandled :=
                (FilterReservEntry."Source Type" = Database::"FA Conversion Header") and
                (FilterReservEntry."Source Subtype" = FromEntrySummary."Entry No." - EntryStartNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnCreateReservation', '', false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "FA Tracking Specification"; ForReservEntry: Record "FA Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal)
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if MatchThisTable(ForReservEntry."Source Type") then begin
            // CreateReservationSetFrom(TrackingSpecification);
            SourceRecRef.SetTable(ConversionHeader);
            // CreateReservation(ConversionHeader, Description, ExpectedDate, Quantity, QuantityBase, ForReservEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnLookupDocument', '', false, false)]
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
                    PAGE.RunModal(PAGE::"FA Conversion Order", ConversionHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnLookupLine', '', false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20])
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if MatchThisTable(SourceType) then begin
            ConversionHeader.Reset();
            // ConversionHeader.SetRange("Document Type", SourceSubtype);
            ConversionHeader.SetRange("No.", SourceID);
            PAGE.Run(PAGE::"FA Conversion Orders", ConversionHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnFilterReservFor', '', false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "FA Reservation Entry"; var CaptionText: Text)
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if MatchThisTable(SourceRecRef.Number) then begin
            SourceRecRef.SetTable(ConversionHeader);
            ConversionHeader.SetReservationFilters(ReservEntry);
            CaptionText := ConversionHeader.GetSourceCaption();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnCalculateRemainingQty', '', false, false)]
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "FA Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if MatchThisTable(ReservEntry."Source Type") then begin
            SourceRecRef.SetTable(ConversionHeader);
            ConversionHeader.GetRemainingQty(RemainingQty, RemainingQtyBase);
        end;
    end;

    local procedure GetSourceValue(ReservationEntry: Record "FA Reservation Entry"; var SourceRecordRef: RecordRef; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        ConversionHeader.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID");
        SourceRecordRef.GetTable(ConversionHeader);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ConversionHeader."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ConversionHeader."Quantity (Base)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnGetSourceRecordValue', '', false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "FA Reservation Entry"; ReturnOption: Option; SetAsCurrent: Boolean; var IsHandled: Boolean; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
        if MatchThisTable(ReservEntry."Source Type") then
            ReturnQty := GetSourceValue(ReservEntry, SourceRecRef, ReturnOption);
    end;

    local procedure UpdateStatistics(CalcReservationEntry: Record "FA Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; DocumentType: Option; Positive: Boolean; var TotalQuantity: Decimal)
    var
        ConversionHeader: Record "FA Conversion Header";
        AvailabilityFilter: Text;
    begin
        if not ConversionHeader.ReadPermission then
            exit;

        AvailabilityFilter := CalcReservationEntry.GetAvailabilityFilter(AvailabilityDate, Positive);
        ConversionHeader.FilterLinesForReservation(CalcReservationEntry, DocumentType, AvailabilityFilter, Positive);
        if ConversionHeader.FindSet() then
            repeat
                ConversionHeader.CalcFields("Reserved Qty. (Base)");
                TempEntrySummary."Total Reserved Quantity" += ConversionHeader."Reserved Qty. (Base)";
                TotalQuantity += ConversionHeader."Remaining Quantity (Base)";
            until ConversionHeader.Next() = 0;

        if TotalQuantity = 0 then
            exit;

        if (TotalQuantity > 0) = Positive then begin
            TempEntrySummary."Table ID" := Database::"FA Conversion Header";
            TempEntrySummary."Summary Type" :=
                CopyStr(StrSubstNo('%1', ConversionTxt), 1, MaxStrLen(TempEntrySummary."Summary Type"));
            TempEntrySummary."Total Quantity" := TotalQuantity;
            TempEntrySummary."Total Available Quantity" := TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
            if not TempEntrySummary.Insert() then
                TempEntrySummary.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Reservation Management", 'OnUpdateStatistics', '', false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "FA Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
        if ReservSummEntry."Entry No." in [141, 142] then
            UpdateStatistics(
                CalcReservEntry, ReservSummEntry, AvailabilityDate, ReservSummEntry."Entry No." - 141, Positive, TotalQuantity);
    end;

    [EventSubscriber(ObjectType::Page, Page::"FA Reservation Entries", 'OnLookupReserved', '', false, false)]
    local procedure OnLookupReserved(var ReservationEntry: Record "FA Reservation Entry")
    begin
        if MatchThisTable(ReservationEntry."Source Type") then
            ShowSourceLines(ReservationEntry);
    end;

    local procedure ShowSourceLines(var ReservationEntry: Record "FA Reservation Entry")
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        // ConversionHeader.SetRange("Document Type", ReservationEntry."Source Subtype");
        ConversionHeader.SetRange("No.", ReservationEntry."Source ID");
        PAGE.RunModal(Page::"FA Conversion Orders", ConversionHeader);
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnAfterSignFactor', '', false, false)]
    // local procedure OnAfterSignFactorofCreateResrvEntry(ReservationEntry: Record "Reservation Entry"; var Sign: Integer)
    // begin
    //     if MatchThisTable(ReservationEntry."Source Type") then
    //         Sign := 1;
    // end;
}