namespace TSTChanges.FA.Ledger;

using System.Security.AccessControl;
using System.Utilities;
using Microsoft.Utilities;

table 51202 "FA Item Application Entry"
{
    Caption = 'FA Item Application Entry';
    Permissions = tabledata "FA Item Application Entry" = rm,
                    tabledata "FA Item App Entry History" = ri;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "FA Item ledger Entry";
        }
        field(3; "Inbound Item Entry No."; Integer)
        {
            Caption = 'Inbound Item Entry No.';
            TableRelation = "FA Item ledger Entry";
        }
        field(4; "Outbound Item Entry No."; Integer)
        {
            Caption = 'Outbound Item Entry No.';
            TableRelation = "FA Item ledger Entry";
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Transferred-from Entry No."; Integer)
        {
            Caption = 'Transferred-from Entry No.';
            TableRelation = "FA Item ledger Entry";
        }
        field(25; "Creation Date"; DateTime)
        {
            Caption = 'Creation Date';
        }
        field(26; "Created By User"; Code[50])
        {
            Caption = 'Created By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(27; "Last Modified Date"; DateTime)
        {
            Caption = 'Last Modified Date';
        }
        field(28; "Last Modified By User"; Code[50])
        {
            Caption = 'Last Modified By User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5800; "Cost Application"; Boolean)
        {
            Caption = 'Cost Application';
        }
        field(5804; "Output Completely Invd. Date"; Date)
        {
            Caption = 'Output Completely Invd. Date';
        }
        field(5805; "Outbound Entry is Updated"; Boolean)
        {
            Caption = 'Outbound Entry is Updated';
            InitValue = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    var
        TempVisitedItemApplnEntry: Record "FA Item Application Entry" temporary;
        TempItemLedgEntryInChainNo: Record Integer temporary;
        TrackChain: Boolean;
        MaxValuationDate: Date;

        Text001: Label 'You have to run the %1 batch job, before you can revalue %2 %3.';

    procedure AppliedOutbndEntryExists(InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean; FilterOnOnlyCostNotAdjusted: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.", "Cost Application");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', InbndItemLedgEntryNo);
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        if IsCostApplication then
            SetRange("Cost Application", true);

        if FilterOnOnlyCostNotAdjusted then
            SetRange("Outbound Entry is Updated", false);

        exit(FindSet());
    end;

    procedure AppliedInbndTransEntryExists(InbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        SetRange("Inbound Item Entry No.", InbndItemLedgEntryNo);
        if IsEmpty() then
            exit(false);

        Reset();
        SetCurrentKey("Transferred-from Entry No.", "Cost Application");
        SetRange("Transferred-from Entry No.", InbndItemLedgEntryNo);
        if IsCostApplication then
            SetRange("Cost Application", true);
        exit(FindSet());
    end;

    procedure AppliedInbndEntryExists(OutbndItemLedgEntryNo: Integer; IsCostApplication: Boolean): Boolean
    begin
        Reset();
        SetCurrentKey(
          "Outbound Item Entry No.", "Item Ledger Entry No.", "Cost Application", "Transferred-from Entry No.");
        SetRange("Outbound Item Entry No.", OutbndItemLedgEntryNo);
        SetFilter("Item Ledger Entry No.", '<>%1', OutbndItemLedgEntryNo);
        SetRange("Transferred-from Entry No.", 0);
        if IsCostApplication then
            SetRange("Cost Application", true);
        exit(FindSet());
    end;

    procedure AppliedFromEntryExists(InbndItemLedgEntryNo: Integer): Boolean
    begin
        Reset();
        SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        SetFilter("Outbound Item Entry No.", '<>%1', 0);
        SetRange("Item Ledger Entry No.", InbndItemLedgEntryNo);
        exit(FindSet());
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure "Fixed"() Result: Boolean
    var
        InboundItemLedgerEntry: Record "FA Item Ledger Entry";
        OutboundItemLedgerEntry: Record "FA Item Ledger Entry";
        IsHandled: Boolean;
    begin
        // OnBeforeFixed(Rec, Result, IsHandled);
        // if IsHandled then
        //     exit(Result);

        if "Outbound Item Entry No." = 0 then
            exit(false);
        InboundItemLedgerEntry.SetLoadFields("Applies-to Entry");
        if not InboundItemLedgerEntry.Get("Inbound Item Entry No.") then
            exit(true);
        if InboundItemLedgerEntry."Applies-to Entry" = "Outbound Item Entry No." then
            exit(true);
        OutboundItemLedgerEntry.SetLoadFields("Applies-to Entry");
        if not OutboundItemLedgerEntry.Get("Outbound Item Entry No.") then
            exit(true);
        if OutboundItemLedgerEntry."Applies-to Entry" = "Inbound Item Entry No." then
            exit(true);
        exit(false);
    end;

    procedure CostReceiver(): Integer
    begin
        if "Outbound Item Entry No." = 0 then
            exit(0);
        if "Item Ledger Entry No." = "Outbound Item Entry No." then
            exit("Outbound Item Entry No.");
        if "Item Ledger Entry No." = "Inbound Item Entry No." then
            exit("Inbound Item Entry No.");
        exit(0);
    end;

    procedure InsertHistory(): Integer
    var
        ItemApplnEntryHistory: Record "FA Item App Entry History";
        EntryNo: Integer;
    begin
        ItemApplnEntryHistory.SetCurrentKey("Primary Entry No.");
        if not ItemApplnEntryHistory.FindLast() then
            EntryNo := 1;
        EntryNo := ItemApplnEntryHistory."Primary Entry No.";
        ItemApplnEntryHistory.TransferFields(Rec, true);
        ItemApplnEntryHistory."Deleted Date" := CurrentDateTime;
        ItemApplnEntryHistory."Deleted By User" := UserId;
        ItemApplnEntryHistory."Primary Entry No." := EntryNo + 1;
        ItemApplnEntryHistory.Insert();
        exit(ItemApplnEntryHistory."Primary Entry No.");
    end;

    procedure CostApplication(): Boolean
    begin
        exit((Quantity > 0) and ("Item Ledger Entry No." = "Inbound Item Entry No."))
    end;

    procedure CheckIsCyclicalLoop(CheckItemLedgEntry: Record "FA Item Ledger Entry"; FromItemLedgEntry: Record "FA Item Ledger Entry"): Boolean
    begin
        if CheckItemLedgEntry."Entry No." = FromItemLedgEntry."Entry No." then
            exit(true);
        TempVisitedItemApplnEntry.DeleteAll();
        TempItemLedgEntryInChainNo.DeleteAll();

        if FromItemLedgEntry.Positive then begin
            if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, FromItemLedgEntry."Entry No.") then
                exit(true);
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry, FromItemLedgEntry."Entry No."));
        end;
        // if FromItemLedgEntry."Entry Type" = FromItemLedgEntry."Entry Type"::Consumption then
        //     if CheckCyclicProdCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then
        //         exit(true);
        // if FromItemLedgEntry."Entry Type" = FromItemLedgEntry."Entry Type"::"Assembly Consumption" then
        //     if CheckCyclicAsmCyclicalLoop(CheckItemLedgEntry, FromItemLedgEntry) then
        //         exit(true);
        exit(CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry, FromItemLedgEntry."Entry No."));
    end;

    local procedure CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry: Record "FA Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "FA Item Application Entry";
    begin
        if ItemApplnEntry.AppliedOutbndEntryExists(EntryNo, false, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry, ItemApplnEntry, EntryNo, true));
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry: Record "FA Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "FA Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndEntryExists(EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry, ItemApplnEntry, EntryNo, false));
        exit(false);
    end;

    local procedure CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry: Record "FA Item Ledger Entry"; EntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "FA Item Application Entry";
    begin
        if ItemApplnEntry.AppliedInbndTransEntryExists(EntryNo, false) then
            exit(CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry, ItemApplnEntry, EntryNo, false));
        exit(false);
    end;

    local procedure CheckCyclicFwdToAppliedEntries(CheckItemLedgEntry: Record "FA Item Ledger Entry"; var ItemApplnEntry: Record "FA Item Application Entry"; FromEntryNo: Integer; IsPositiveToNegativeFlow: Boolean): Boolean
    var
        ToEntryNo: Integer;
    begin
        if EntryIsVisited(FromEntryNo) then
            exit(false);

        repeat
            if IsPositiveToNegativeFlow then
                ToEntryNo := ItemApplnEntry."Outbound Item Entry No."
            else
                ToEntryNo := ItemApplnEntry."Inbound Item Entry No.";

            if CheckLatestItemLedgEntryValuationDate(ItemApplnEntry."Item Ledger Entry No.", MaxValuationDate) then begin
                if TrackChain then begin
                    TempItemLedgEntryInChainNo.Number := ToEntryNo;
                    if TempItemLedgEntryInChainNo.Insert() then;
                end;

                if ToEntryNo = CheckItemLedgEntry."Entry No." then
                    exit(true);

                if not IsPositiveToNegativeFlow then begin
                    if CheckCyclicFwdToAppliedOutbnds(CheckItemLedgEntry, ToEntryNo) then
                        exit(true);
                end else begin
                    if CheckCyclicFwdToAppliedInbnds(CheckItemLedgEntry, ToEntryNo) then
                        exit(true);
                    // if CheckCyclicFwdToProdOutput(CheckItemLedgEntry, ToEntryNo) then
                    //     exit(true);
                    // if CheckCyclicFwdToAsmOutput(CheckItemLedgEntry, ToEntryNo) then
                    //     exit(true);
                end;
            end;
        until ItemApplnEntry.Next() = 0;

        if IsPositiveToNegativeFlow then
            exit(CheckCyclicFwdToInbndTransfers(CheckItemLedgEntry, FromEntryNo));
        exit(false);
    end;

    local procedure EntryIsVisited(EntryNo: Integer): Boolean
    begin
        if TempVisitedItemApplnEntry.Get(EntryNo) then begin
            // This is to take into account quantity flows from an inbound entry to an inbound transfer
            if TempVisitedItemApplnEntry.Quantity = 2 then
                exit(true);
            TempVisitedItemApplnEntry.Quantity := TempVisitedItemApplnEntry.Quantity + 1;
            TempVisitedItemApplnEntry.Modify();
            exit(false);
        end;
        TempVisitedItemApplnEntry.Init();
        TempVisitedItemApplnEntry."Entry No." := EntryNo;
        TempVisitedItemApplnEntry.Quantity := TempVisitedItemApplnEntry.Quantity + 1;
        TempVisitedItemApplnEntry.Insert();
        exit(false);
    end;

    local procedure CheckLatestItemLedgEntryValuationDate(ItemLedgerEntryNo: Integer; MaxDate: Date): Boolean
    var
    // ValueEntry: Record "Value Entry";
    begin
        if MaxDate = 0D then
            exit(true);
        // ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
        // ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        // ValueEntry.SetLoadFields("Valuation Date");
        // ValueEntry.FindLast();
        // exit(ValueEntry."Valuation Date" <= MaxDate);
    end;

    procedure GetVisitedEntries(FromItemLedgEntry: Record "FA Item Ledger Entry"; var ItemLedgEntryInChain: Record "FA Item Ledger Entry"; WithinValuationDate: Boolean)
    var
        ToItemLedgEntry: Record "FA Item Ledger Entry";
        DummyItemLedgEntry: Record "FA Item Ledger Entry";
    // ValueEntry: Record "Value Entry";
    // AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        MaxValuationDate := 0D;
        // if WithinValuationDate then begin
        //     ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Valuation Date");
        //     ValueEntry.SetRange("Item Ledger Entry No.", FromItemLedgEntry."Entry No.");
        //     ValueEntry.SetLoadFields("Valuation Date");
        //     ValueEntry.FindLast();
        //     MaxValuationDate := AvgCostEntryPointHandler.GetMaxValuationDate(FromItemLedgEntry, ValueEntry);
        // end;

        TrackChain := true;
        ItemLedgEntryInChain.Reset();
        ItemLedgEntryInChain.DeleteAll();
        DummyItemLedgEntry.Init();
        DummyItemLedgEntry."Entry No." := -1;
        CheckIsCyclicalLoop(DummyItemLedgEntry, FromItemLedgEntry);
        if TempItemLedgEntryInChainNo.FindSet() then
            repeat
                ToItemLedgEntry.Get(TempItemLedgEntryInChainNo.Number);
                ItemLedgEntryInChain := ToItemLedgEntry;
                ItemLedgEntryInChain.Insert();
            until TempItemLedgEntryInChainNo.Next() = 0;
    end;
}