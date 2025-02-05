namespace TSTChanges.FA.Posting;

using TSTChanges.FA.Transfer;
using TSTChanges.FA.Conversion;
using TSTChanges.FA.FAItem;
using TSTChanges.FA.Journal;
using TSTChanges.FA.Tracking;
using TSTChanges.FA.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using TSTChanges.FA.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.History;
using TSTChanges.Warehouse;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Document;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Finance.Dimension;
using System.Automation;
using Microsoft.Inventory.Location;

codeunit 51226 "FATransferOrder-Post Receipt"
{
    Permissions = TableData "FA Item Entry Relation" = i;
    TableNo = "FA Transfer Header";
    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, HideValidationDialog, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        RunWithCheck(Rec);
    end;

    internal procedure RunWithCheck(var FATransferHeader2: Record "FA Transfer Header")
    var
        Item: Record "FA Item";
        FAItemLedgEntry: Record "FA Item ledger Entry";
        FAItemApplnEntry: Record "FA Item Application Entry";
        SourceCodeSetup: Record "Source Code Setup";
        ReservMgt: Codeunit "FA Reservation Management";
        FAItemVariant: Record "FA Item Variant";
        Window: Dialog;
        LineCount: Integer;
        DeleteOne: Boolean;
    begin
        ReleaseDocument(FATransferHeader2);
        FATransHeader := FATransferHeader2;
        FATransHeader.SetHideValidationDialog(HideValidationDialog);

        FATransHeader.CheckBeforePost();

        SaveAndClearPostingFromWhseRef();

        CheckDim();
        CheckLines(FATransHeader, FATransLine);

        WhseReceive := TempWhseRcptHeader.FindFirst();
        InvtPickPutaway := WhseReference <> 0;
        if not (WhseReceive or InvtPickPutaway) then
            CheckWarehouse(FATransLine);

        WhsePosting := IsWarehousePosting(FATransHeader."Transfer-to Code");

        FATransHeader.CheckTransferLines(false);

        if GuiAllowed then begin
            Window.Open(
              '#1#################################\\' +
              Text003);

            Window.Update(1, StrSubstNo(Text004, FATransHeader."No."));
        end;

        SourceCodeSetup.Get();
        SourceCode := SourceCodeSetup.Transfer;
        FAConSetup.Get();
        FAConSetup.TestField("Posted Transfer Rcpt. Nos.");

        // LockTables(InvtSetup."Automatic Cost Posting");

        if WhseReceive then
            PostedWhseRcptHeader.LockTable();
        FATransRcptHeader.LockTable();
        InsertTransRcptHeader(FATransRcptHeader, FATransHeader, FAConSetup."Posted Transfer Rcpt. Nos.");

        // if InvtSetup."Copy Comments Order to Rcpt." then begin
        //     InvtCommentLine.CopyCommentLines(
        //         "Inventory Comment Document Type"::"Transfer Order", "No.",
        //         "Inventory Comment Document Type"::"Posted Transfer Receipt", TransRcptHeader."No.");
        //     RecordLinkManagement.CopyLinks(TransferHeader2, TransRcptHeader);
        // end;

        if WhseReceive then begin
            WhseRcptHeader.Get(TempWhseRcptHeader."No.");
            WhsePostRcpt.CreatePostedRcptHeader(PostedWhseRcptHeader, WhseRcptHeader, FATransRcptHeader."No.", FATransHeader."Posting Date");
        end;

        // Insert receipt lines
        LineCount := 0;
        if WhseReceive then
            PostedWhseRcptLine.LockTable();
        if InvtPickPutaway then
            WhseRqst.LockTable();
        FATransRcptLine.LockTable();
        FATransLine.SetRange(Quantity);
        FATransLine.SetRange("Qty. to Receive");
        if FATransLine.Find('-') then
            repeat
                LineCount := LineCount + 1;
                if GuiAllowed then
                    Window.Update(2, LineCount);

                if (FATransLine."FA Item No." <> '') and (FATransLine."Qty. to Receive" <> 0) then begin
                    Item.Get(FATransLine."FA Item No.");
                    // IsHandled := false;
                    // OnRunOnBeforeCheckItemBlocked(TransLine, Item, TransHeader, Location, WhseReceive, IsHandled);
                    // if not IsHandled then
                    Item.TestField(Blocked, false);

                    if FATransLine."Variant Code" <> '' then begin
                        FAItemVariant.Get(FATransLine."FA Item No.", FATransLine."Variant Code");
                        CheckItemVariantNotBlocked(FAItemVariant);
                    end;
                end;

                // OnCheckTransLine(TransLine, TransHeader, Location, WhseReceive);

                InsertTransRcptLine(FATransRcptHeader, FATransRcptLine, FATransLine);
            until FaTransLine.Next() = 0;

        // MakeInventoryAdjustment();

        // ValueEntry.LockTable();
        FAItemLedgEntry.LockTable();
        FAItemApplnEntry.LockTable();
        // ItemReg.LockTable();
        FATransLine.LockTable();
        if WhsePosting then
            WhseEntry.LockTable();

        FATransLine.SetFilter(Quantity, '<>0');
        FATransLine.SetFilter("Qty. to Receive", '<>0');
        if FATransLine.Find('-') then
            repeat
                FATransLine.Validate("Quantity Received", FATransLine."Quantity Received" + FATransLine."Qty. to Receive");
                // OnRunOnBeforeUpdateWithWarehouseShipReceive(TransLine);
                FATransLine.UpdateWithWarehouseShipReceive();
                ReservMgt.SetReservSource(FAItemJnlLine);
                ReservMgt.SetItemTrackingHandling(1); // Allow deletion
                ReservMgt.DeleteReservEntries(true, 0);
                FATransLine.Modify();
            // OnAfterTransLineUpdateQtyReceived(TransLine, SuppressCommit);
            until FATransLine.Next() = 0;

        // OnRunOnBeforePostUpdateDocumens(ItemJnlPostLine);

        if WhseReceive then
            WhseRcptLine.LockTable();
        FATransHeader.LockTable();
        if WhseReceive then begin
            WhsePostRcpt.PostUpdateWhseDocuments(WhseRcptHeader);
            TempWhseRcptHeader.Delete();
        end;

        FATransHeader."Last Receipt No." := FATransRcptHeader."No.";
        // OnRunWithCheckOnBeforeModifyTransferHeader(TransHeader);
        FATransHeader.Modify();

        FATransLine.SetRange(Quantity);
        FATransLine.SetRange("Qty. to Receive");
        if not PreviewMode then
            DeleteOne := FATransHeader.ShouldDeleteOneTransferOrder(FATransLine);
        // OnBeforeDeleteOneTransferHeader(FATransHeader, DeleteOne, FATransRcptHeader);
        if DeleteOne then
            FATransHeader.DeleteOneTransferOrder(FATransHeader, FATransLine)
        else begin
            // WhseTransferRelease.Release(FATransHeader);
            ReserveFATransLine.UpdateItemTrackingAfterPosting(FATransHeader, Enum::"Transfer Direction"::Inbound);
        end;

        // OnRunOnBeforeCommit(TransHeader, TransRcptHeader, PostedWhseRcptHeader, SuppressCommit);
        if not (InvtPickPutaway or SuppressCommit or PreviewMode) then begin
            Commit();
            // UpdateAnalysisView.UpdateAll(0, true);
            // UpdateItemAnalysisView.UpdateAll(0, true);
        end;
        Clear(WhsePostRcpt);
        if GuiAllowed() then
            Window.Close();

        FATransferHeader2 := FATransHeader;

        OnAfterTransferOrderPostReceipt(FATransferHeader2, SuppressCommit, FATransRcptHeader);
    end;

    var
        Text002: Label 'Warehouse handling is required for Transfer order = %1, %2 = %3.', Comment = '1%=TransLine2."Document No."; 2%=TransLine2.FIELDCAPTION("Line No."); 3%=TransLine2."Line No.");';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2.';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3.';
        Text007: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid. %3.';
        Text008: Label 'Base Qty. to Receive must be 0.';
        FAConSetup: Record "FA Conversion Setup";
        FATransRcptHeader: Record "FA Transfer Receipt Header";
        FATransRcptLine: Record "FA Transfer Receipt Line";
        FATransHeader: Record "FA Transfer Header";
        FATransLine: Record "FA Transfer Line";
        FAItemJnlLine: Record "FA Item Journal Line";
        Location: Record Location;
        NewLocation: Record Location;
        WhseRqst: Record "Warehouse Request";
        WhseRcptHeader: Record "Warehouse Receipt Header";
        TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary;
        WhseRcptLine: Record "Warehouse Receipt Line";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        TempWhseSplitSpecification: Record "FA Tracking Specification" temporary;
        WhseEntry: Record "Warehouse Entry";
        TempItemEntryRelation2: Record "FA Item Entry Relation" temporary;
        FAItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        ReserveFATransLine: Codeunit "FA Transfer Line-Reserve";
        WhsePostRcpt: Codeunit "Whse.-Post Receipt";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SourceCode: Code[10];
        WhsePosting: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        WhseReceive: Boolean;
        InvtPickPutaway: Boolean;
        SuppressCommit: Boolean;
        CalledBy: Integer;
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;

    local procedure PostItemJnlLine(var FATransLine3: Record "FA Transfer Line"; FATransRcptHeader2: Record "FA Transfer Receipt Header"; FATransRcptLine2: Record "FA Transfer Receipt Line")
    var
        IsHandled: Boolean;
    begin
        // OnBeforePostItemJnlLine(TransRcptHeader2, IsHandled, TransRcptLine2);
        // if IsHandled then
        //     exit;

        FAItemJnlLine.Init();
        FAItemJnlLine."Posting Date" := FATransRcptHeader2."Posting Date";
        FAItemJnlLine."Document Date" := FATransRcptHeader2."Posting Date";
        FAItemJnlLine."Document No." := FATransRcptHeader2."No.";
        FAItemJnlLine."Document Type" := FAItemJnlLine."Document Type"::"Transfer Receipt";
        FAItemJnlLine."Document Line No." := FATransRcptLine2."Line No.";
        FAItemJnlLine."Order Type" := FAItemJnlLine."Order Type"::Transfer;
        FAItemJnlLine."Order No." := FATransRcptHeader2."Transfer Order No.";
        FAItemJnlLine."Order Line No." := FATransLine3."Line No.";
        FAItemJnlLine."External Document No." := FATransRcptHeader2."External Document No.";
        FAItemJnlLine."Entry Type" := FAItemJnlLine."Entry Type"::Transfer;
        FAItemJnlLine."FA Item No." := FATransRcptLine2."Item No.";
        FAItemJnlLine.Description := FATransRcptLine2.Description;
        FAItemJnlLine."Shortcut Dimension 1 Code" := FATransRcptLine2."Shortcut Dimension 1 Code";
        FAItemJnlLine."New Shortcut Dimension 1 Code" := FATransRcptLine2."Shortcut Dimension 1 Code";
        FAItemJnlLine."Shortcut Dimension 2 Code" := FATransRcptLine2."Shortcut Dimension 2 Code";
        FAItemJnlLine."New Shortcut Dimension 2 Code" := FATransRcptLine2."Shortcut Dimension 2 Code";
        FAItemJnlLine."Dimension Set ID" := FATransRcptLine2."Dimension Set ID";
        FAItemJnlLine."New Dimension Set ID" := FATransRcptLine2."Dimension Set ID";
        FAItemJnlLine."Location Code" := FATransHeader."In-Transit Code";
        FAItemJnlLine."New Location Code" := FATransRcptHeader2."Transfer-to Code";
        FAItemJnlLine."Customer No." := FATransRcptHeader2."Transfer-to Customer";
        FAItemJnlLine.Quantity := FATransRcptLine2.Quantity;
        FAItemJnlLine."Invoiced Quantity" := FATransRcptLine2.Quantity;
        FAItemJnlLine."Quantity (Base)" := FATransRcptLine2."Quantity (Base)";
        FAItemJnlLine."Invoiced Qty. (Base)" := FATransRcptLine2."Quantity (Base)";
        FAItemJnlLine."Source Code" := SourceCode;
        // FAItemJnlLine."Gen. Prod. Posting Group" := TransRcptLine2."Gen. Prod. Posting Group";
        // FAItemJnlLine."Inventory Posting Group" := TransRcptLine2."Inventory Posting Group";
        FAItemJnlLine."Unit of Measure Code" := FATransRcptLine2."Unit of Measure Code";
        FAItemJnlLine."Qty. per Unit of Measure" := FATransRcptLine2."Qty. per Unit of Measure";
        FAItemJnlLine."Variant Code" := FATransRcptLine2."Variant Code";
        FAItemJnlLine."New Bin Code" := FATransLine."Transfer-To Bin Code";
        // FAItemJnlLine."Item Category Code" := TransLine."Item Category Code";
        if FATransHeader."In-Transit Code" <> '' then begin
            if NewLocation.Code <> FATransHeader."In-Transit Code" then
                NewLocation.Get(FATransHeader."In-Transit Code");
            FAItemJnlLine."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        FAItemJnlLine."Transaction Type" := FATransRcptHeader2."Transaction Type";
        FAItemJnlLine."Transport Method" := FATransRcptHeader2."Transport Method";
        FAItemJnlLine."Entry/Exit Point" := FATransRcptHeader2."Entry/Exit Point";
        FAItemJnlLine.Area := FATransRcptHeader2.Area;
        FAItemJnlLine."Transaction Specification" := FATransRcptHeader2."Transaction Specification";
        FAItemJnlLine."Shpt. Method Code" := FATransRcptHeader2."Shipment Method Code";
        FAItemJnlLine."Direct Transfer" := FATransLine."Direct Transfer";
        WriteDownDerivedLines(FATransLine3);
        FAItemJnlPostLine.SetPostponeReservationHandling(true);

        // OnBeforePostItemJournalLine(FAItemJnlLine, TransLine3, TransRcptHeader2, TransRcptLine2, SuppressCommit, TransLine, PostedWhseRcptHeader);
        FAItemJnlPostLine.RunWithCheck(FAItemJnlLine);

        // OnAfterPostItemJnlLine(FAItemJnlLine, TransLine3, TransRcptHeader2, TransRcptLine2, ItemJnlPostLine);
    end;

    local procedure CheckItemVariantNotBlocked(var ItemVariant: Record "FA Item Variant")
    var
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckItemVariantNotBlocked(TransLine, ItemVariant, Transheader, Location, WhseReceive, IsHandled);
        // if IsHandled then
        //     exit;

        ItemVariant.TestField(Blocked, false);
    end;

    local procedure CheckDim()
    begin
        FATransLine."Line No." := 0;
        CheckDimComb(FATransHeader, FATransLine);
        CheckDimValuePosting(FATransHeader, FATransLine);

        FATransLine.SetRange("Document No.", FATransHeader."No.");
        if FATransLine.FindFirst() then begin
            CheckDimComb(FATransHeader, FATransLine);
            CheckDimValuePosting(FATransHeader, FATransLine);
        end;
    end;

    local procedure CheckDimComb(FATransferHeader: Record "FA Transfer Header"; FATransferLine: Record "FA Transfer Line")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckDimComb(TransferHeader, TransferLine, IsHandled);
        // if IsHandled then
        //     exit;

        if FATransferLine."Line No." = 0 then
            if not DimMgt.CheckDimIDComb(FATransferHeader."Dimension Set ID") then
                Error(
                  Text005,
                  FATransHeader."No.", DimMgt.GetDimCombErr());
        if FATransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimIDComb(FATransferLine."Dimension Set ID") then
                Error(
                  Text006,
                  FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimCombErr());

        // OnAfterCheckDimComb(TransferHeader, TransferLine);
    end;

    local procedure CheckDimValuePosting(FATransferHeader: Record "FA Transfer Header"; FATransferLine: Record "FA Transfer Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        // OnBeforeCheckDimValuePosting(TransferHeader, TransferLine, IsHandled);
        // if IsHandled then
        //     exit;

        TableIDArr[1] := DATABASE::"FA Item";
        NumberArr[1] := FATransferLine."FA Item No.";
        TableIDArr[2] := DATABASE::Location;
        NumberArr[2] := FATransferLine."Transfer-to Code";
        if FATransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FATransferHeader."Dimension Set ID") then
                Error(
                  Text007,
                  FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimValuePostingErr());

        if FATransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FATransferLine."Dimension Set ID") then
                Error(
                  Text007,
                  FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure SaveAndClearPostingFromWhseRef()
    begin
        WhseReference := FATransHeader."Posting from Whse. Ref.";
        FATransHeader."Posting from Whse. Ref." := 0;

        // OnAfterSaveAndClearPostingFromWhseRef(TransHeader, Location);
    end;

    local procedure WriteDownDerivedLines(var TransLine3: Record "FA Transfer Line")
    var
        TransLine4: Record "FA Transfer Line";
        T337: Record "FA Reservation Entry";
        TempDerivedSpecification: Record "FA Tracking Specification" temporary;
        TransShptLine: Record "FA Transfer Shipment Line";
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        QtyToReceive: Decimal;
        BaseQtyToReceive: Decimal;
        TrackingSpecificationExists: Boolean;
    begin
        TransLine4.SetRange("Document No.", TransLine3."Document No.");
        TransLine4.SetRange("Derived From Line No.", TransLine3."Line No.");
        if TransLine4.Find('-') then begin
            QtyToReceive := TransLine3."Qty. to Receive";
            BaseQtyToReceive := TransLine3."Qty. to Receive (Base)";

            T337.SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            T337.SetRange("Source ID", TransLine3."Document No.");
            T337.SetRange("Source Ref. No.");
            T337.SetRange("Source Type", DATABASE::"FA Transfer Line");
            T337.SetRange("Source Subtype", 1);
            T337.SetRange("Source Batch Name", '');
            T337.SetRange("Source Prod. Order Line", TransLine3."Line No.");
            T337.SetFilter("Qty. to Handle (Base)", '<>0');

            TrackingSpecificationExists :=
              ItemTrackingMgt.SumUpItemTracking(T337, TempDerivedSpecification, true, false);

            repeat
                if TrackingSpecificationExists then begin
                    TempDerivedSpecification.SetRange("Source Ref. No.", TransLine4."Line No.");
                    if TempDerivedSpecification.FindFirst() then begin
                        TransLine4."Qty. to Receive (Base)" := TempDerivedSpecification."Qty. to Handle (Base)";
                        TransLine4."Qty. to Receive" := TempDerivedSpecification."Qty. to Handle";
                    end else begin
                        TransLine4."Qty. to Receive (Base)" := 0;
                        TransLine4."Qty. to Receive" := 0;
                    end;
                end;
                if TransLine4."Qty. to Receive (Base)" <= BaseQtyToReceive then begin
                    ReserveFATransLine.TransferTransferToItemJnlLine(
                      TransLine4, FAItemJnlLine, TransLine4."Qty. to Receive (Base)", Enum::"Transfer Direction"::Inbound);
                    TransLine4."Quantity (Base)" :=
                      TransLine4."Quantity (Base)" - TransLine4."Qty. to Receive (Base)";
                    TransLine4.Quantity :=
                      TransLine4.Quantity - TransLine4."Qty. to Receive";
                    BaseQtyToReceive := BaseQtyToReceive - TransLine4."Qty. to Receive (Base)";
                    QtyToReceive := QtyToReceive - TransLine4."Qty. to Receive";
                end else begin
                    ReserveFATransLine.TransferTransferToItemJnlLine(
                      TransLine4, FAItemJnlLine, BaseQtyToReceive, Enum::"Transfer Direction"::Inbound);
                    TransLine4.Quantity := TransLine4.Quantity - QtyToReceive;
                    TransLine4."Quantity (Base)" := TransLine4."Quantity (Base)" - BaseQtyToReceive;
                    BaseQtyToReceive := 0;
                    QtyToReceive := 0;
                end;
                if TransLine4."Quantity (Base)" = 0 then begin
                    // Update any TransShptLines pointing to this derived line before deleting
                    TransShptLine.SetRange("Transfer Order No.", TransLine4."Document No.");
                    TransShptLine.SetRange("Derived Trans. Order Line No.", TransLine4."Line No.");
                    if not TransShptLine.IsEmpty() then
                        TransShptLine.ModifyAll("Derived Trans. Order Line No.", 0);
                    TransLine4.Delete()
                end else begin
                    TransLine4."Qty. to Ship" := TransLine4.Quantity;
                    TransLine4."Qty. to Ship (Base)" := TransLine4."Quantity (Base)";
                    TransLine4."Qty. to Receive" := TransLine4.Quantity;
                    TransLine4."Qty. to Receive (Base)" := TransLine4."Quantity (Base)";
                    TransLine4.ResetPostedQty();
                    TransLine4."Outstanding Quantity" := TransLine4.Quantity;
                    TransLine4."Outstanding Qty. (Base)" := TransLine4."Quantity (Base)";

                    // OnWriteDownDerivedLinesOnBeforeTransLineModify(TransLine4, TransLine3);
                    TransLine4.Modify();
                end;
            until (TransLine4.Next() = 0) or (BaseQtyToReceive = 0);
        end;

        if BaseQtyToReceive <> 0 then
            Error(Text008);
    end;

    local procedure InsertRcptEntryRelation(var TransRcptLine: Record "FA Transfer Receipt Line") Result: Integer
    var
        ItemEntryRelation: Record "FA Item Entry Relation";
        TempItemEntryRelation: Record "FA Item Entry Relation" temporary;
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeInsertRcptEntryRelation(TransRcptLine, ItemJnlLine, ItemJnlPostLine, Result, IsHandled);
        //     if IsHandled then
        //         exit(Result);

        TempItemEntryRelation2.Reset();
        TempItemEntryRelation2.DeleteAll();

        if FAItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then begin
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsTransRcptLine(TransRcptLine);
                    ItemEntryRelation.Insert();
                    TempItemEntryRelation2 := TempItemEntryRelation;
                    TempItemEntryRelation2.Insert();
                until TempItemEntryRelation.Next() = 0;
                exit(0);
            end;
        end else
            exit(FAItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure InsertTransRcptHeader(var FATransRcptHeader: Record "FA Transfer Receipt Header"; FATransHeader: Record "FA Transfer Header"; NoSeries: Code[20])
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    //     Handled: Boolean;
    begin
        //     OnBeforeInsertTransRcptHeader(TransRcptHeader, TransHeader, SuppressCommit, Handled);
        //     if Handled then
        //         exit;

        FATransRcptHeader.Init();
        FATransRcptHeader.CopyFromTransferHeader(FATransHeader);
        FATransRcptHeader."No. Series" := NoSeries;
        // OnInsertTransRcptHeaderOnBeforeGetNextNo(TransRcptHeader, TransHeader);
        if FATransRcptHeader."No." = '' then
            FATransRcptHeader."No." := NoSeriesCodeunit.GetNextNo(FATransRcptHeader."No. Series", FATransHeader."Posting Date");
        OnBeforeFATransRcptHeaderInsert(FATransRcptHeader, FATransHeader);
        FATransRcptHeader.Insert();

        ApprovalsMgmt.PostApprovalEntries(FATransHeader.RecordId, FATransRcptHeader.RecordId, FATransRcptHeader."No.");
        // OnAfterInsertTransRcptHeader(TransRcptHeader, TransHeader);
    end;

    local procedure InsertTransRcptLine(TransferReceiptHeader: Record "FA Transfer Receipt Header"; var TransRcptLine: Record "FA Transfer Receipt Line"; FATransLine: Record "FA Transfer Line")
    var
        //     IsHandled: Boolean;
        ShouldRunPosting: Boolean;
    begin
        TransRcptLine.Init();
        TransRcptLine."Document No." := TransferReceiptHeader."No.";
        TransRcptLine.CopyFromTransferLine(FATransLine);
        // IsHandled := false;
        //     OnBeforeInsertTransRcptLine(TransRcptLine, TransLine, SuppressCommit, IsHandled, TransferReceiptHeader);
        //     if IsHandled then
        //         exit;

        TransRcptLine.Insert();
        //     OnAfterInsertTransRcptLine(TransRcptLine, TransLine, SuppressCommit, TransferReceiptHeader);

        if FATransLine."Qty. to Receive" > 0 then begin
            OriginalQuantity := FATransLine."Qty. to Receive";
            OriginalQuantityBase := FATransLine."Qty. to Receive (Base)";
            PostItemJnlLine(FATransLine, FaTransRcptHeader, TransRcptLine);
            TransRcptLine."Item Rcpt. Entry No." := InsertRcptEntryRelation(TransRcptLine);
            TransRcptLine.Modify();
            SaveTempWhseSplitSpec(FaTransLine);
            if WhseReceive then begin
                WhseRcptLine.SetCurrentKey(
                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
                WhseRcptLine.SetRange("Source Type", DATABASE::"FA Transfer Line");
                WhseRcptLine.SetRange("Source No.", FATransLine."Document No.");
                WhseRcptLine.SetRange("Source Line No.", FATransLine."Line No.");
                // OnInsertTransRcptLineOnAfterWhseRcptLineSetFilters(TransLine, TransRcptLine, WhseRcptLine);
                if WhseRcptLine.FindFirst() then
                    CreatePostedRcptLineFromWhseRcptLine(TransRcptLine);
            end;
            ShouldRunPosting := WhsePosting;
            // OnInsertTransRcptLineOnBeforePostWhseJnlLine(TransRcptLine, TransLine, SuppressCommit, WhsePosting, ShouldRunPosting);
            if ShouldRunPosting then
                PostWhseJnlLine(FAItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempWhseSplitSpecification);
            // OnAfterTransRcptLineModify(TransRcptLine, TransLine, SuppressCommit);
        end;
    end;

    local procedure CreatePostedRcptLineFromWhseRcptLine(var TransferReceiptLine: Record "FA Transfer Receipt Line")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCreatePostedRcptLineFromWhseRcptLine(TransferReceiptLine, WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification, IsHandled, WhsePostRcpt, TempItemEntryRelation2);
        // if IsHandled then
        //     exit;

        WhseRcptLine.TestField("Qty. to Receive", TransferReceiptLine.Quantity);
        // WhsePostRcpt.SetItemEntryRelation(PostedWhseRcptHeader, PostedWhseRcptLine, TempItemEntryRelation2);
        // WhsePostRcpt.CreatePostedRcptLine(
        //   WhseRcptLine, PostedWhseRcptHeader, PostedWhseRcptLine, TempWhseSplitSpecification);
    end;

    local procedure CheckLines(FATransHeader: Record "FA Transfer Header"; var FATransLine: Record "FA Transfer Line")
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckLines(TransHeader, TransLine, IsHandled);
        // if IsHandled then
        //     exit;

        // with TransHeader do begin
        FATransLine.Reset();
        FATransLine.SetRange("Document No.", FATransHeader."No.");
        FATransLine.SetRange("Derived From Line No.", 0);
        FATransLine.SetFilter(Quantity, '<>0');
        FATransLine.SetFilter("Qty. to Receive", '<>0');
        if not FATransLine.Find('-') then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        // end;
    end;

    local procedure CheckWarehouse(var FATransLine: Record "FA Transfer Line")
    var
        FATransLine2: Record "FA Transfer Line";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckWarehouse(TransLine, IsHandled);
        // If IsHandled then
        //     exit;

        FATransLine2.Copy(FATransLine);
        if FATransLine2.Find('-') then
            repeat
                GetLocation(FATransLine2."Transfer-to Code");
                if Location."Require Receive" or Location."Require Put-away" then begin
                    if Location."Bin Mandatory" then
                        ShowError := true
                    else
                        if WhseValidateSourceLine.WhseLinesExist(
                             DATABASE::"FA Transfer Line",
                             1,// In
                             FATransLine2."Document No.",
                             FATransLine2."Line No.",
                             0,
                             FATransLine2.Quantity)
                        then
                            ShowError := true;

                    if ShowError then
                        Error(
                          Text002,
                          FATransLine2."Document No.",
                          FATransLine2.FieldCaption("Line No."),
                          FATransLine2."Line No.");
                end;
            until FATransLine2.Next() = 0;
    end;

    local procedure SaveTempWhseSplitSpec(FATransLine: Record "FA Transfer Line")
    var
        TempHandlingSpecification: Record "FA Tracking Specification" temporary;
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeSaveTempWhseSplitSpec(TransLine, ItemJnlPostLine, IsHandled);
        //     if IsHandled then
        //         exit;

        TempWhseSplitSpecification.Reset();
        TempWhseSplitSpecification.DeleteAll();
        if FAItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification) then
            if TempHandlingSpecification.Find('-') then
                repeat
                    TempWhseSplitSpecification := TempHandlingSpecification;
                    TempWhseSplitSpecification."Entry No." := TempHandlingSpecification."Transfer Item Entry No.";
                    TempWhseSplitSpecification."Source Type" := DATABASE::"FA Transfer Line";
                    TempWhseSplitSpecification."Source Subtype" := 1;
                    TempWhseSplitSpecification."Source ID" := FATransLine."Document No.";
                    TempWhseSplitSpecification."Source Ref. No." := FATransLine."Line No.";
                    TempWhseSplitSpecification.Insert();
                until TempHandlingSpecification.Next() = 0;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure IsWarehousePosting(LocationCode: Code[10]): Boolean
    begin
        GetLocation(LocationCode);
        if Location."Bin Mandatory" and not (WhseReceive or InvtPickPutaway) then
            exit(true);
        exit(false);
    end;

    local procedure PostWhseJnlLine(FAItemJnlLine: Record "FA Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "FA Tracking Specification" temporary)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        TST_WMSMgmt: Codeunit "TST WMS Management";
        MS_WMSMgmt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, IsHandled);
        // if IsHandled then
        //     exit;

        FAItemJnlLine.Quantity := OriginalQuantity;
        FAItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(FAItemJnlLine."New Location Code");
        if Location."Bin Mandatory" then
            if TST_WMSMgmt.CreateWhseJnlLine(FAItemJnlLine, 1, WhseJnlLine, true) then begin
                TST_WMSMgmt.SetTransferLine(FATransLine, WhseJnlLine, 1, FATransRcptHeader."No.");
                // OnPostWhseJnlLineOnBeforeSplitWhseJnlLine();
                ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, true);
                if TempWhseJnlLine2.Find('-') then
                    repeat
                        MS_WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, true);
                        WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
                    until TempWhseJnlLine2.Next() = 0;
            end;
    end;

    procedure SetWhseRcptHeader(var WhseRcptHeader2: Record "Warehouse Receipt Header")
    begin
        WhseRcptHeader := WhseRcptHeader2;
        TempWhseRcptHeader := WhseRcptHeader;
        TempWhseRcptHeader.Insert();
    end;

    local procedure LockTables(AutoCostPosting: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if AutoCostPosting then begin
            GLEntry.LockTable();
            if GLEntry.FindLast() then;
        end;
    end;

    local procedure ReleaseDocument(var FATransferHeader: Record "FA Transfer Header")
    var
        ReleaseTransferDocument: Codeunit "Release FA Transfer Document";
        SavedStatus: Enum "Conversion Document Status";
    begin
        // OnBeforeReleaseDocument(TransferHeader);

        if not (FATransferHeader.Status = FATransferHeader.Status::Open) then
            exit;

        SavedStatus := FATransferHeader.Status;
        ReleaseTransferDocument.ReleaseFATransferHeader(FATransferHeader, PreviewMode);
        FATransferHeader.Status := SavedStatus;
        if not (SuppressCommit or PreviewMode) then begin
            FATransferHeader.Modify();
            Commit();
        end;
        FATransferHeader.Status := FATransferHeader.Status::Released;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetCalledBy(NewCalledBy: Integer)
    begin
        CalledBy := NewCalledBy;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var FATransferHeader2: Record "FA Transfer Header"; var HideValidationDialog: Boolean; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostReceipt(var TransferHeader: Record "FA Transfer Header"; CommitIsSuppressed: Boolean; var TransferReceiptHeader: Record "FA Transfer Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFATransRcptHeaderInsert(var FATransferReceiptHeader: Record "FA Transfer Receipt Header"; FATransferHeader: Record "FA Transfer Header")
    begin
    end;
}