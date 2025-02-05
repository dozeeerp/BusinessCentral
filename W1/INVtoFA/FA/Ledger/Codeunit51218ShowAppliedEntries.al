namespace TSTChanges.FA.Ledger;

codeunit 51218 "Show Applied FA Entries"
{
    Permissions = TableData "FA Item Ledger Entry" = rim,
                  TableData "FA Item Application Entry" = r;
    TableNo = "FA Item Ledger Entry";

    trigger OnRun()
    var
        TempItemLedgerEntry: Record "FA Item Ledger Entry" temporary;
    begin
        TempItemLedgerEntry.DeleteAll();
        FindAppliedEntries(Rec, TempItemLedgerEntry);
        PAGE.RunModal(PAGE::"Applied FA Item Entries", TempItemLedgerEntry);
    end;

    procedure FindAppliedEntries(FAItemLedgEntry: Record "FA Item Ledger Entry"; var TempItemLedgerEntry: Record "FA Item Ledger Entry" temporary)
    var
        ItemApplnEntry: Record "FA Item Application Entry";
    begin
        // with ItemLedgEntry do
        if FAItemLedgEntry.Positive then begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");//, "Cost Application");
            ItemApplnEntry.SetRange("Inbound Item Entry No.", FAItemLedgEntry."Entry No.");
            ItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
            // ItemApplnEntry.SetRange("Cost Application", true);
            OnFindAppliedEntryOnAfterSetFilters(ItemApplnEntry, FAItemLedgEntry);
            if ItemApplnEntry.Find('-') then
                repeat
                    InsertTempEntry(TempItemLedgerEntry, ItemApplnEntry."Outbound Item Entry No.", ItemApplnEntry.Quantity);
                until ItemApplnEntry.Next() = 0;
        end else begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");//, "Cost Application");
            ItemApplnEntry.SetRange("Outbound Item Entry No.", FAItemLedgEntry."Entry No.");
            ItemApplnEntry.SetRange("Item Ledger Entry No.", FAItemLedgEntry."Entry No.");
            // ItemApplnEntry.SetRange("Cost Application", true);
            OnFindAppliedEntryOnAfterSetFilters(ItemApplnEntry, FAItemLedgEntry);
            if ItemApplnEntry.Find('-') then
                repeat
                    InsertTempEntry(TempItemLedgerEntry, ItemApplnEntry."Inbound Item Entry No.", -ItemApplnEntry.Quantity);
                until ItemApplnEntry.Next() = 0;
        end;
    end;

    local procedure InsertTempEntry(var TempItemLedgerEntry: Record "FA Item Ledger Entry" temporary; EntryNo: Integer; AppliedQty: Decimal)
    var
        ItemLedgEntry: Record "FA Item Ledger Entry";
        IsHandled: Boolean;
    begin
        ItemLedgEntry.Get(EntryNo);

        IsHandled := false;
        OnBeforeInsertTempEntry(ItemLedgEntry, IsHandled, TempItemLedgerEntry, AppliedQty);
        if IsHandled then
            exit;

        if AppliedQty * ItemLedgEntry.Quantity < 0 then
            exit;

        if not TempItemLedgerEntry.Get(EntryNo) then begin
            TempItemLedgerEntry.Init();
            TempItemLedgerEntry := ItemLedgEntry;
            TempItemLedgerEntry.Quantity := AppliedQty;
            TempItemLedgerEntry.Insert();
        end else begin
            TempItemLedgerEntry.Quantity := TempItemLedgerEntry.Quantity + AppliedQty;
            TempItemLedgerEntry.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempEntry(ItemLedgerEntry: Record "FA Item Ledger Entry"; var IsHandled: Boolean; var TempItemLedgerEntry: Record "FA Item Ledger Entry" temporary; AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindAppliedEntryOnAfterSetFilters(var ItemApplicationEntry: Record "FA Item Application Entry"; ItemLedgerEntry: Record "FA Item Ledger Entry")
    begin
    end;
}