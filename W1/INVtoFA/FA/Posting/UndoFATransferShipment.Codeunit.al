namespace TSTChanges.FA.Posting;

using TSTChanges.FA.Transfer;
using TSTChanges.FA.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.History;
using Microsoft.Foundation.AuditCodes;
using TSTChanges.FA.Journal;
using TSTChanges.FA.FAItem;

codeunit 51230 "Undo FA Transfer Shipment"
{
    Permissions = TableData "FA Transfer Line" = rimd,
                  TableData "FA Transfer Shipment Line" = rimd,
                  TableData "FA Item Application Entry" = rmd,
                  TableData "FA Item Entry Relation" = ri;
    TableNo = "FA Transfer Shipment Line";
    trigger OnRun()
    begin
        if not HideDialog then
            if not Confirm(ReallyUndoQst) then
                exit;

        FATransShptLine.Copy(Rec);
        Code();
        Rec := FATransShptLine;
    end;

    var
        FATransShptLine: Record "FA Transfer Shipment Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        FAItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
        UndoPostingMgt: Codeunit "TST Undo Posting Management";
        TempGlobalItemLedgEntry: Record "FA Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "FA Item Entry Relation" temporary;
        ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
        // WhseUndoQty: Codeunit "Whse. Undo Quantity";
        HideDialog: Boolean;
        NextLineNo: Integer;

        ReallyUndoQst: Label 'Do you really want to undo the selected Shipment lines?';
        NotEnoughLineSpaceErr: Label 'There is not enough space to insert correction lines.';
        UndoQtyMsg: Label 'Undo quantity posting...';
        AlreadyReversedErr: Label 'This shipment has already been reversed.';
        AlreadyReceivedErr: Label 'This shipment has already been received. Undo Shipment can only be applied to posted, but not received Transfer Lines.';
        NoDerivedTransOrderLineNoErr: Label 'The Transfer Shipment Line is missing a value in the field Derived Trans. Order Line No. This is automatically populated when posting new Transfer Shipments';
        CheckingLinesMsg: Label 'Checking lines...';
        NoTransOrderLineNoErr: Label 'The Transfer Shipment Line is missing a value in the field Trans. Order Line No. This is automatically populated when posting new Transfer Shipments';

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure Code()
    var
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        Window: Dialog;
        FATransferLine: Record "FA Transfer Line";
        ItemShptEntryNo: Integer;
        DocLineNo: Integer;
        Direction: Enum "Transfer Direction";
        PostedWhseShptLineFound: Boolean;
    begin
        Clear(FAItemJnlPostLine);
        FATransShptLine.SetCurrentKey("Item Shpt. Entry No.");
        FATransShptLine.SetFilter(Quantity, '<>0');
        FATransShptLine.SetRange("Correction Line", false);

        if FATransShptLine.IsEmpty() then
            Error(AlreadyReversedErr);
        FATransShptLine.FindSet();
        repeat
            if not HideDialog then
                Window.Open(CheckingLinesMsg);
            CheckTransferShptLine(FATransShptLine);
        until FATransShptLine.Next() = 0;

        FATransShptLine.FindSet();
        repeat
            if FATransShptLine."Trans. Order Line No." = 0 then
                Error(NoTransOrderLineNoErr);
            FATransferLine.Get(FATransShptLine."Transfer Order No.", FATransShptLine."Trans. Order Line No.");
            if FATransferLine."Qty. Received (Base)" > 0 then
                Error(AlreadyReceivedErr);
            if FATransShptLine."Derived Trans. Order Line No." = 0 then
                Error(NoDerivedTransOrderLineNoErr);

            TempGlobalItemLedgEntry.Reset();
            if not TempGlobalItemLedgEntry.IsEmpty() then
                TempGlobalItemLedgEntry.DeleteAll();
            TempGlobalItemEntryRelation.Reset();
            if not TempGlobalItemEntryRelation.IsEmpty() then
                TempGlobalItemEntryRelation.DeleteAll();

            if not HideDialog then
                Window.Open(UndoQtyMsg);

            // PostedWhseShptLineFound :=
            //  WhseUndoQty.FindPostedWhseShptLine(
            //      PostedWhseShptLine, Database::"FA Transfer Shipment Line", FATransShptLine."Document No.",
            //      Database::"FA Transfer Line", Direction::Outbound.AsInteger(), FATransShptLine."Transfer Order No.", FATransShptLine."Line No.");

            // Undo derived transfer line and move tracking to current line
            UndoPostingMgt.UpdateDerivedTransferLine(FATransferLine, FATransShptLine);

            Clear(ItemJnlPostLine);
            ItemShptEntryNo := PostItemJnlLine(FATransShptLine, DocLineNo);
            InsertNewShipmentLine(FATransShptLine, ItemShptEntryNo, DocLineNo);

            // if PostedWhseShptLineFound then
            //     WhseUndoQty.UndoPostedWhseShptLine(PostedWhseShptLine);

            // TempWhseJnlLine.SetRange("Source Line No.", TransShptLine."Line No.");
            // WhseUndoQty.PostTempWhseJnlLineCache(TempWhseJnlLine, WhseJnlRegisterLine);

            UpdateOrderLine(FATransShptLine);
            // if PostedWhseShptLineFound then
            // WhseUndoQty.UpdateShptSourceDocLines(PostedWhseShptLine);

            FATransShptLine."Correction Line" := true;
            // OnBeforeModifyTransShptLine(TransShptLine);
            FATransShptLine.Modify();

        until FATransShptLine.Next() = 0
    end;

    local procedure CheckTransferShptLine(FATransShptLine: Record "FA Transfer Shipment Line")
    var
        TempItemLedgEntry: Record "FA Item Ledger Entry" temporary;
    begin
        if FATransShptLine."Correction Line" then
            Error(AlreadyReversedErr);

        UndoPostingMgt.TestFATransferShptLine(FATransShptLine);

        UndoPostingMgt.CollectItemLedgEntries(
            TempItemLedgEntry, Database::"FA Transfer Shipment Line", FATransShptLine."Document No.", FATransShptLine."Line No.", FATransShptLine."Quantity (Base)", FATransShptLine."Item Shpt. Entry No.");
        UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, FATransShptLine."Line No.", false);
    end;

    procedure GetCorrectionLineNo(TransferShptLine: Record "FA Transfer Shipment Line") Result: Integer;
    var
        TransferShptLine2: Record "FA Transfer Shipment Line";
        LineSpacing: Integer;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeGetCorrectionLineNo(TransferShptLine, Result, IsHandled);
        // if IsHandled then
        //     exit(Result);

        TransferShptLine2.SetRange("Document No.", TransferShptLine."Document No.");
        TransferShptLine2.SetFilter("Line No.", '>%1', TransferShptLine."Line No.");
        if TransferShptLine2.FindFirst() then begin
            LineSpacing := (TransferShptLine2."Line No." - TransferShptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(NotEnoughLineSpaceErr);
        end else
            LineSpacing := 10000;

        Result := TransferShptLine."Line No." + LineSpacing;
        // OnAfterGetCorrectionLineNo(TransferShptLine, Result);
    end;

    local procedure PostItemJnlLine(FATransShptLine: Record "FA Transfer Shipment Line"; var DocLineNo: Integer): Integer
    var
        ItemJnlLine: Record "FA Item Journal Line";
        TransShptHeader: Record "FA Transfer Shipment Header";
        SourceCodeSetup: Record "Source Code Setup";
        Direction: Enum "Transfer Direction";
        FAItemLedgEntry: Record "FA Item Ledger Entry";
        TempApplyToEntryList: Record "FA Item Ledger Entry" temporary;
        TempDummyItemEntryRelation: Record "FA Item Entry Relation" temporary;
    begin
        DocLineNo := GetCorrectionLineNo(FATransShptLine);

        SourceCodeSetup.Get();
        TransShptHeader.Get(FATransShptLine."Document No.");

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."FA Item No." := FATransShptLine."FA Item No.";
        ItemJnlLine."Posting Date" := TransShptHeader."Posting Date";
        ItemJnlLine."Document No." := FATransShptLine."Document No.";
        ItemJnlLine."Document Line No." := DocLineNo;
        // ItemJnlLine."Gen. Prod. Posting Group" := TransShptLine."Gen. Prod. Posting Group";
        // ItemJnlLine."Inventory Posting Group" := TransShptLine."Inventory Posting Group";
        ItemJnlLine."Location Code" := FATransShptLine."Transfer-from Code";
        ItemJnlLine."Source Code" := SourceCodeSetup.Transfer;
        ItemJnlLine.Correction := true;
        ItemJnlLine."Variant Code" := FATransShptLine."Variant Code";
        ItemJnlLine."Bin Code" := FATransShptLine."Transfer-from Bin Code";
        ItemJnlLine."Document Date" := TransShptHeader."Shipment Date";
        ItemJnlLine."Unit of Measure Code" := FATransShptLine."Unit of Measure Code";

        // WhseUndoQty.InsertTempWhseJnlLine(
        //         ItemJnlLine,
        //         Database::"FA Transfer Line", Direction::Outbound.AsInteger(), FATransShptLine."Transfer Order No.", FATransShptLine."Line No.",
        //         TempWhseJnlLine."Reference Document"::"Posted T. Shipment".AsInteger(), TempWhseJnlLine, NextLineNo);

        if GetShptEntries(FATransShptLine, FAItemLedgEntry) then begin
            FAItemLedgEntry.SetTrackingFilterBlank();
            if FAItemLedgEntry.FindSet() then begin
                // First undo In-Transit item ledger entries
                FAItemLedgEntry.SetRange("Location Code", TransShptHeader."In-Transit Code");
                FAItemLedgEntry.FindSet();
                PostCorrectiveItemLedgEntries(ItemJnlLine, FAItemLedgEntry);

                // Then undo from-location item ledger entries
                FAItemLedgEntry.SetRange("Location Code", TransShptHeader."Transfer-from Code");
                FAItemLedgEntry.FindSet();
                PostCorrectiveItemLedgEntries(ItemJnlLine, FAItemLedgEntry);

                exit(ItemJnlLine."Item Shpt. Entry No.");
            end else begin
                FAItemLedgEntry.ClearTrackingFilter();
                FAItemLedgEntry.FindSet();
                MoveItemLedgerEntriesToTempRec(FAItemLedgEntry, TempApplyToEntryList);
                // First undo In-Transit item ledger entries
                TempApplyToEntryList.SetRange("Location Code", TransShptHeader."In-Transit Code");
                TempApplyToEntryList.FindSet();
                //Pass dummy ItemEntryRelation because, these are not used for In-Transit location
                UndoPostingMgt.PostItemJnlLineAppliedToList(
                    ItemJnlLine, TempApplyToEntryList, FATransShptLine.Quantity, FATransShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempDummyItemEntryRelation, false);

                // Then undo from-location item ledger entries
                TempApplyToEntryList.SetRange("Location Code", TransShptHeader."Transfer-from Code");
                TempApplyToEntryList.FindSet();
                UndoPostingMgt.PostItemJnlLineAppliedToList(
                    ItemJnlLine, TempApplyToEntryList, FATransShptLine.Quantity, FATransShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation, false);
            end;
        end;
        exit(0);
    end;

    local procedure MoveItemLedgerEntriesToTempRec(var ItemLedgerEntry: Record "FA Item Ledger Entry"; var TempItemLedgerEntry: Record "FA Item Ledger Entry" temporary)
    begin
        if ItemLedgerEntry.FindSet() then
            repeat
                TempItemLedgerEntry.TransferFields(ItemLedgerEntry);
                TempItemLedgerEntry.Insert();
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure PostCorrectiveItemLedgEntries(var ItemJnlLine: Record "FA Item Journal Line"; var ItemLedgEntry: Record "FA Item Ledger Entry")
    begin
        repeat
            ItemJnlLine."Applies-to Entry" := ItemLedgEntry."Entry No.";
            ItemJnlLine."Location Code" := ItemLedgEntry."Location Code";
            ItemJnlLine.Quantity := ItemLedgEntry.Quantity;
            ItemJnlLine."Quantity (Base)" := ItemLedgEntry.Quantity;
            ItemJnlLine."Invoiced Quantity" := ItemLedgEntry."Invoiced Quantity";
            ItemJnlLine."Invoiced Qty. (Base)" := ItemLedgEntry."Invoiced Quantity";
            // OnPostCorrectiveItemLedgEntriesOnBeforeRun(ItemJnlLine, ItemLedgEntry);
            ItemJnlPostLine.Run(ItemJnlLine);
        until ItemLedgEntry.Next() = 0;
    end;

    local procedure InsertNewShipmentLine(OldTransShptLine: Record "FA Transfer Shipment Line"; ItemShptEntryNo: Integer; DocLineNo: Integer)
    var
        NewTransShptLine: Record "FA Transfer Shipment Line";
    begin
        NewTransShptLine.Init();
        NewTransShptLine.Copy(OldTransShptLine);
        NewTransShptLine."Derived Trans. Order Line No." := 0;
        NewTransShptLine."Line No." := DocLineNo;
        NewTransShptLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewTransShptLine.Quantity := -OldTransShptLine.Quantity;
        NewTransShptLine."Quantity (Base)" := -OldTransShptLine."Quantity (Base)";
        NewTransShptLine."Correction Line" := true;
        NewTransShptLine."Dimension Set ID" := OldTransShptLine."Dimension Set ID";
        // OnBeforeInsertNewTransShptLine(NewTransShptLine, OldTransShptLine);
        NewTransShptLine.Insert();

        InsertItemEntryRelation(TempGlobalItemEntryRelation, NewTransShptLine, OldTransShptLine."Trans. Order Line No.");
    end;

    procedure UpdateOrderLine(TransShptLine: Record "FA Transfer Shipment Line")
    var
        TransferLine: Record "FA Transfer Line";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateOrderLine(TransShptLine, IsHandled);
        // if IsHandled then
        //     exit;

        TransferLine.Get(TransShptLine."Transfer Order No.", TransShptLine."Line No.");
        UndoPostingMgt.UpdateTransLine(
            TransferLine, TransShptLine.Quantity,
            TransShptLine."Quantity (Base)",
            TempGlobalItemLedgEntry);
        // OnAfterUpdateOrderLine(TransferLine, TransShptLine);
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "FA Item Entry Relation" temporary; NewTransShptLine: Record "FA Transfer Shipment Line"; OrderLineNo: Integer)
    var
        ItemEntryRelation: Record "FA Item Entry Relation";
    begin
        if TempItemEntryRelation.FindFirst() then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                ItemEntryRelation.TransferFieldsTransShptLine(NewTransShptLine);
                ItemEntryRelation."Order Line No." := OrderLineNo;
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
    end;

    local procedure GetShptEntries(TransShptLine: Record "FA Transfer Shipment Line"; var ItemLedgEntry: Record "FA Item Ledger Entry"): Boolean
    begin
        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Transfer Shipment");
        ItemLedgEntry.SetRange("Document No.", TransShptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", TransShptLine."Line No.");
        exit(ItemLedgEntry.FindSet());
    end;
}