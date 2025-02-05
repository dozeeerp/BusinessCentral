namespace TSTChanges.FA.Posting;

using TSTChanges.FA.FAItem;
using TSTChanges.FA.Journal;
using Microsoft.Warehouse.History;
using TSTChanges.Warehouse;
using Microsoft.Inventory.Analysis;
using Microsoft.Finance.Analysis;
using TSTChanges.FA.Setup;
using Microsoft.Foundation.AuditCodes;
using TSTChanges.FA.Conversion;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Warehouse.Journal;
using Microsoft.Utilities;
using Microsoft.Finance.Dimension;
using System.Automation;
using TSTChanges.FA.Tracking;
using Microsoft.Warehouse.Request;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Document;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.Enums;
using TSTChanges.FA.Transfer;

codeunit 51225 "FATransferOrder-Post Shipment"
{
    Permissions = TableData "FA Item Entry Relation" = i;
    TableNo = "FA Transfer Header";
    trigger OnRun()
    begin
        RunWithCheck(Rec);
    end;

    internal procedure RunWithCheck(var FATransferHeader2: Record "FA Transfer Header")
    var
        FAItem: Record "FA Item";
        SourceCodeSetup: Record "Source Code Setup";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        FAItemVariant: Record "FA Item Variant";
        window: Dialog;
        LineCount: Integer;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(FATransferHeader2, HideValidationDialog, SuppressCommit, IsHandled);
        if not IsHandled then begin
            ReleaseDocument(FATransferHeader2);
            FATransHeader := FATransferHeader2;
            FATransHeader.SetHideValidationDialog(HideValidationDialog);

            FATransHeader.CheckBeforePost();

            // WhseReference := "Posting from Whse. Ref.";
            // "Posting from Whse. Ref." := 0;

            CheckShippingAdvice(FATransHeader);

            CheckDim();
            CheckLines(FATransHeader, FATransLine);

            WhseShip := TempWhseShptHeader.FindFirst();
            InvtPickPutaway := WhseReference <> 0;
            CheckItemInInventoryAndWarehouse(FATransLine, not (WhseShip or InvtPickPutaway));

            FATransHeader.CheckTransferLines(true);

            GetLocation(FATransHeader."Transfer-from Code");
            if Location."Bin Mandatory" and not (WhseShip or InvtPickPutaway) then
                WhsePosting := true;

            if GuiAllowed then begin
                Window.Open(
                  '#1#################################\\' +
                  Text003);

                Window.Update(1, StrSubstNo(Text004, FATransHeader."No."));
            end;

            SourceCodeSetup.Get();
            SourceCode := SourceCodeSetup.Transfer;
            FAConversionSetup.Get();
            FAConversionSetup.TestField("Posted Transfer Shpt. Nos.");

            LockTables(InvtSetup."Automatic Cost Posting");

            // Insert shipment header
            PostedWhseShptHeader.LockTable();
            FATransShptHeader.LockTable();
            InsertTransShptHeader(FATransShptHeader, FATransHeader, FAConversionSetup."Posted Transfer Shpt. Nos.");

            // if InvtSetup."Copy Comments Order to Shpt." then begin
            //     InvtCommentLine.CopyCommentLines(
            //         "Inventory Comment Document Type"::"Transfer Order", "No.",
            //         "Inventory Comment Document Type"::"Posted Transfer Shipment", TransShptHeader."No.");
            //     RecordLinkManagement.CopyLinks(TransferHeader2, TransShptHeader);
            // end;

            if WhseShip then begin
                WhseShptHeader.Get(TempWhseShptHeader."No.");
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, FATransShptHeader."No.", FATransHeader."Posting Date");
            end;

            LineCount := 0;
            if WhseShip then
                PostedWhseShptLine.LockTable();
            if InvtPickPutaway then
                WhseRqst.LockTable();
            FATransShptLine.LockTable();
            FATransLine.SetRange(Quantity);
            FATransLine.SetRange("Qty. to Ship");
            if FATransLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    if GuiAllowed then
                        Window.Update(2, LineCount);

                    if (FATransLine."FA Item No." <> '') and (FATransLine."Qty. to Ship" <> 0) then begin
                        FAItem.Get(FATransLine."FA Item No.");
                        CheckItemNotBlocked(FAItem);

                        if FATransLine."Variant Code" <> '' then begin
                            FAItemVariant.Get(FATransLine."FA Item No.", FATransLine."Variant Code");
                            CheckItemVariantNotBlocked(FAItemVariant);
                        end;
                    end;

                    // OnCheckTransLine(TransLine, TransHeader, Location, WhseShip, TransShptLine, InvtPickPutaway, WhsePosting);

                    InsertTransShptLine(FATransShptHeader);
                until FATransLine.Next() = 0;

            MakeInventoryAdjustment();

            if WhseShip then
                WhseShptLine.LockTable();
            FATransLine.LockTable();

            // OnBeforeCopyTransLines(TransHeader);

            FATransLine.SetFilter(Quantity, '<>0');
            FATransLine.SetFilter("Qty. to Ship", '<>0');
            // OnAfterSetFilterTransferLine(TransLine);
            if FATransLine.Find('-') then begin
                NextLineNo := AssignLineNo(FATransLine."Document No.");
                repeat
                // IsHandled := false;
                // OnBeforeTransLineModify(TransLine, IsHandled);
                // if not IsHandled then 
                begin
                    CopyTransLine(FATransLine2, FATransLine, NextLineNo, FATransHeader);
                    TransferTracking(FATransLine, FATransLine2, FATransLine."Qty. to Ship (Base)");
                    FATransLine.Validate("Quantity Shipped", FATransLine."Quantity Shipped" + FATransLine."Qty. to Ship");
                    SetDerivedNoOnTransShptLine(FATransLine, FATransLine2);

                    // OnBeforeUpdateWithWarehouseShipReceive(TransLine);
                    FATransLine.UpdateWithWarehouseShipReceive();
                    FATransLine.Modify();
                end;
                // OnAfterTransLineModify(TransLine, TransHeader);
                until FATransLine.Next() = 0;
            end;

            // OnRunOnBeforeLockTables(ItemJnlPostLine);
            if WhseShip then
                WhseShptLine.LockTable();
            FATransHeader.LockTable();
            if WhseShip then begin
                WhsePostShpt.PostUpdateWhseDocuments(WhseShptHeader);
                TempWhseShptHeader.Delete();
            end;

            FATransHeader."Last Shipment No." := FATransShptHeader."No.";
            FATransHeader.Modify();

            FinalizePosting(FATransHeader, FATransLine);

            // OnRunOnBeforeCommit(TransHeader, TransShptHeader, PostedWhseShptHeader, SuppressCommit);
            if not (InvtPickPutaway or FATransHeader."Direct Transfer" or SuppressCommit or PreviewMode) then begin
                Commit();
                UpdateAnalysisView.UpdateAll(0, true);
                UpdateItemAnalysisView.UpdateAll(0, true);
            end;
            Clear(WhsePostShpt);

            if GuiAllowed() then
                Window.Close();
            // end;

            FATransferHeader2 := FATransHeader;
        end;
        OnAfterTransferOrderPostShipment(FATransferHeader2, SuppressCommit, FATransShptHeader, InvtPickPutaway);
    end;

    var
        Text002: Label 'Warehouse handling is required for Transfer order = %1, %2 = %3.';
        Text003: Label 'Posting transfer lines     #2######';
        Text004: Label 'Transfer Order %1';
        Text005: Label 'The combination of dimensions used in transfer order %1 is blocked. %2';
        Text006: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3';
        Text007: Label 'The dimensions that are used in transfer order %1, line no. %2 are not valid. %3.';
        InvtSetup: Record "Inventory Setup";
        FAConversionSetup: Record "FA Conversion Setup";
        FATransShptHeader: Record "FA Transfer Shipment Header";
        FATransShptLine: Record "FA Transfer Shipment Line";
        FATransHeader: Record "FA Transfer Header";
        FATransLine: Record "FA Transfer Line";
        FATransLine2: Record "FA Transfer Line";
        Location: Record Location;
        FAItemJnlLine: Record "FA Item Journal Line";
        WhseRqst: Record "Warehouse Request";
        WhseShptHeader: Record "Warehouse Shipment Header";
        TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        WhseShptLine: Record "Warehouse Shipment Line";
        PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        TempWhseSplitSpecification: Record "FA Tracking Specification" temporary;
        TempHandlingSpecification: Record "FA Tracking Specification" temporary;
        ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        // WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        ReserveTransLine: Codeunit "FA Transfer Line-Reserve";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SourceCode: Code[10];
        WhseShip: Boolean;
        WhsePosting: Boolean;
        InvtPickPutaway: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        Text008: Label 'This order must be a complete shipment.';
        Text009: Label 'Item %1 is not in inventory.';
        SuppressCommit: Boolean;
        HideValidationDialog: Boolean;
        PreviewMode: Boolean;

    local procedure PostItem(var FATransferLine: Record "FA Transfer Line"; FATransShptHeader2: Record "FA Transfer Shipment Header"; FATransShptLine2: Record "FA Transfer Shipment Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        // OnBeforePostItem(TransShptHeader2, IsHandled, TransferLine, TransShptLine2, WhseShip, WhseShptHeader2, ItemJnlPostLine, WhseJnlRegisterLine);
        // if IsHandled then
        //     exit;

        CreateItemJnlLine(FAItemJnlLine, FATransferLine, FATransShptHeader2, FATransShptLine2);
        ReserveItemJnlLine(FAItemJnlLine, FATransferLine, WhseShip, WhseShptHeader2);

        // OnBeforePostItemJournalLine(ItemJnlLine, TransferLine, TransShptHeader2, TransShptLine2, SuppressCommit);
        ItemJnlPostLine.RunWithCheck(FAItemJnlLine);
    end;

    local procedure CreateItemJnlLine(var FAItemJnlLine: Record "FA Item Journal Line"; FATransferLine: Record "FA Transfer Line"; FATransShptHeader2: Record "FA Transfer Shipment Header"; FATransShptLine2: Record "FA Transfer Shipment Line")
    begin
        // with ItemJnlLine do begin
        FAItemJnlLine.Init();
        FAItemJnlLine.CopyDocumentFields(
          FAItemJnlLine."Document Type"::"Transfer Shipment", FATransShptHeader2."No.", FATransShptHeader2."External Document No.", SourceCode, '');
        FAItemJnlLine."Posting Date" := FATransShptHeader2."Posting Date";
        FAItemJnlLine."Document Date" := FATransShptHeader2."Posting Date";
        FAItemJnlLine."Document Line No." := FATransShptLine2."Line No.";
        FAItemJnlLine."Order Type" := FAItemJnlLine."Order Type"::Transfer;
        FAItemJnlLine."Order No." := FATransShptHeader2."Transfer Order No.";
        FAItemJnlLine."Order Line No." := FATransferLine."Line No.";
        FAItemJnlLine."Entry Type" := FAItemJnlLine."Entry Type"::Transfer;
        FAItemJnlLine."FA Item No." := FATransShptLine2."FA Item No.";
        FAItemJnlLine."Variant Code" := FATransShptLine2."Variant Code";
        FAItemJnlLine.Description := FATransShptLine2.Description;
        FAItemJnlLine."Location Code" := FATransShptHeader2."Transfer-from Code";
        FAItemJnlLine."Customer No." := FATransShptHeader2."Transfer-from Customer";
        FAItemJnlLine."New Location Code" := FATransHeader."In-Transit Code";
        FAItemJnlLine."Bin Code" := FATransLine."Transfer-from Bin Code";
        FAItemJnlLine."Shortcut Dimension 1 Code" := FATransShptLine2."Shortcut Dimension 1 Code";
        FAItemJnlLine."New Shortcut Dimension 1 Code" := FATransShptLine2."Shortcut Dimension 1 Code";
        FAItemJnlLine."Shortcut Dimension 2 Code" := FATransShptLine2."Shortcut Dimension 2 Code";
        FAItemJnlLine."New Shortcut Dimension 2 Code" := FATransShptLine2."Shortcut Dimension 2 Code";
        FAItemJnlLine."Dimension Set ID" := FATransShptLine2."Dimension Set ID";
        FAItemJnlLine."New Dimension Set ID" := FATransShptLine2."Dimension Set ID";
        FAItemJnlLine.Quantity := FATransShptLine2.Quantity;
        FAItemJnlLine."Invoiced Quantity" := FATransShptLine2.Quantity;
        FAItemJnlLine."Quantity (Base)" := FATransShptLine2."Quantity (Base)";
        FAItemJnlLine."Invoiced Qty. (Base)" := FATransShptLine2."Quantity (Base)";
        // FAItemJnlLine."Gen. Prod. Posting Group" := TransShptLine2."Gen. Prod. Posting Group";
        // FAItemJnlLine."Inventory Posting Group" := TransShptLine2."Inventory Posting Group";
        FAItemJnlLine."Unit of Measure Code" := FATransShptLine2."Unit of Measure Code";
        FAItemJnlLine."Qty. per Unit of Measure" := FATransShptLine2."Qty. per Unit of Measure";
        FAItemJnlLine."Country/Region Code" := FATransShptHeader2."Trsf.-from Country/Region Code";
        FAItemJnlLine."Transaction Type" := FATransShptHeader2."Transaction Type";
        FAItemJnlLine."Transport Method" := FATransShptHeader2."Transport Method";
        FAItemJnlLine."Entry/Exit Point" := FATransShptHeader2."Entry/Exit Point";
        FAItemJnlLine.Area := FATransShptHeader2.Area;
        FAItemJnlLine."Transaction Specification" := FATransShptHeader2."Transaction Specification";
        // FAItemJnlLine."Item Category Code" := FATransferLine."Item Category Code";
        FAItemJnlLine."Applies-to Entry" := FATransferLine."Appl.-to Item Entry";
        FAItemJnlLine."Shpt. Method Code" := FATransShptHeader2."Shipment Method Code";
        FAItemJnlLine."Direct Transfer" := FATransferLine."Direct Transfer";
        // end;

        // OnAfterCreateItemJnlLine(ItemJnlLine, TransferLine, TransShptHeader2, TransShptLine2);
    end;

    local procedure SetDerivedNoOnTransShptLine(FATransferLine: Record "FA Transfer Line"; DerivedTransferLine: Record "FA Transfer Line")
    var
        TransShptLineLocal: Record "FA Transfer Shipment Line";
    begin
        TransShptLineLocal.SetLoadFields("Trans. Order Line No.", "Derived Trans. Order Line No.");
        TransShptLineLocal.SetRange("Document No.", FATransShptHeader."No.");
        TransShptLineLocal.SetRange("Trans. Order Line No.", FATransferLine."Line No.");
        if TransShptLineLocal.FindFirst() then begin
            TransShptLineLocal."Derived Trans. Order Line No." := DerivedTransferLine."Line No.";
            TransShptLineLocal.Modify();
        end;
    end;

    local procedure CheckItemNotBlocked(var Item: Record "FA Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckItemNotBlocked(TransLine, Item, Transheader, Location, WhseShip, IsHandled);
        if IsHandled then
            exit;

        Item.TestField(Blocked, false);
    end;

    local procedure CheckItemVariantNotBlocked(var ItemVariant: Record "FA Item Variant")
    var
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckItemVariantNotBlocked(TransLine, ItemVariant, Transheader, Location, WhseShip, IsHandled);
        // if IsHandled then
        //     exit;

        ItemVariant.TestField(Blocked, false);
    end;

    local procedure ReserveItemJnlLine(var FAItemJnlLine: Record "FA Item Journal Line"; var FATransferLine: Record "FA Transfer Line"; WhseShip: Boolean; WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        GetLocation(FATransferLine."Transfer-from Code");
        if WhseShip and (WhseShptHeader2."Document Status" = WhseShptHeader2."Document Status"::"Partially Picked") and
           Location."Bin Mandatory"
        then
            ReserveTransLine.TransferWhseShipmentToItemJnlLine(
              FATransferLine, FAItemJnlLine, WhseShptHeader2, FAItemJnlLine."Quantity (Base)")
        else
            ReserveTransLine.TransferTransferToItemJnlLine(
              FATransferLine, FAItemJnlLine, FAItemJnlLine."Quantity (Base)", Enum::"Transfer Direction"::Outbound);
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
    begin
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
        NumberArr[2] := FATransferLine."Transfer-from Code";
        if FATransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FATransferHeader."Dimension Set ID") then
                Error(Text007, FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimValuePostingErr());

        if FATransferLine."Line No." <> 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FATransferLine."Dimension Set ID") then
                Error(Text007, FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    local procedure FinalizePosting(var FATransHeader: Record "FA Transfer Header"; var FATransLine: Record "FA Transfer Line")
    var
        DeleteOne: Boolean;
    begin
        // OnBeforeFinalizePosting(TransHeader, PostedWhseShptHeader, WhseShip);
        FATransLine.SetRange(Quantity);
        FATransLine.SetRange("Qty. to Ship");
        DeleteOne := FATransHeader.ShouldDeleteOneTransferOrder(FATransLine);
        // OnBeforeDeleteOneTransferOrder(TransHeader, DeleteOne);
        if DeleteOne then
            FATransHeader.DeleteOneTransferOrder(FATransHeader, FATransLine)
        else begin
            // WhseTransferRelease.Release(FaTransHeader);
            ReserveTransLine.UpdateItemTrackingAfterPosting(FATransHeader, Enum::"Transfer Direction"::Outbound);
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure AssignLineNo(FromDocNo: Code[20]): Integer
    var
        FATransLine3: Record "FA Transfer Line";
    begin
        FATransLine3.SetRange("Document No.", FromDocNo);
        if FATransLine3.FindLast() then
            exit(FATransLine3."Line No." + 10000);
    end;

    local procedure InsertShptEntryRelation(var FATransShptLine: Record "FA Transfer Shipment Line") Result: Integer
    var
        TempHandlingSpecification2: Record "FA Tracking Specification" temporary;
        ItemEntryRelation: Record "FA Item Entry Relation";
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        WhseSplitSpecification: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeInsertShptEntryRelation(TransShptLine, TransLine, ItemJnlLine, WhsePosting, ItemJnlPostLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if WhsePosting then begin
            TempWhseSplitSpecification.Reset();
            TempWhseSplitSpecification.DeleteAll();
        end;

        TempHandlingSpecification2.Reset();
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
            TempHandlingSpecification2.SetRange("Buffer Status", 0);
            if TempHandlingSpecification2.Find('-') then begin
                repeat
                    WhseSplitSpecification := WhsePosting or WhseShip or InvtPickPutaway;
                    // OnInsertShptEntryRelationOnAfterCalcWhseSplitSpecification(
                    //     FATransLine, TransShptLine, TempHandlingSpecification2, TempWhseSplitSpecification, WhsePosting, WhseShip, InvtPickPutaway, WhseSplitSpecification);
                    if WhseSplitSpecification then begin
                        if ItemTrackingMgt.GetWhseItemTrkgSetup(FATransShptLine."FA Item No.") then begin
                            TempWhseSplitSpecification := TempHandlingSpecification2;
                            TempWhseSplitSpecification."Source Type" := DATABASE::"FA Transfer Line";
                            TempWhseSplitSpecification."Source ID" := FATransLine."Document No.";
                            TempWhseSplitSpecification."Source Ref. No." := FATransLine."Line No.";
                            TempWhseSplitSpecification.Insert();
                        end;
                    end;

                    ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                    ItemEntryRelation.TransferFieldsTransShptLine(FATransShptLine);
                    ItemEntryRelation.Insert();
                    TempHandlingSpecification := TempHandlingSpecification2;
                    TempHandlingSpecification."Source Prod. Order Line" := FATransShptLine."Line No.";
                    TempHandlingSpecification."Buffer Status" := TempHandlingSpecification."Buffer Status"::MODIFY;
                    TempHandlingSpecification.Insert();
                until TempHandlingSpecification2.Next() = 0;
                // OnAfterInsertShptEntryRelation(FATransLine, WhseShip, 0, SuppressCommit);
                exit(0);
            end;
        end else begin
            // OnAfterInsertShptEntryRelation(FATransLine, WhseShip, FAItemJnlLine."Item Shpt. Entry No.", SuppressCommit);
            exit(FAItemJnlLine."Item Shpt. Entry No.");
        end;
    end;

    local procedure InsertTransShptHeader(var FATransShptHeader: Record "FA Transfer Shipment Header"; var FATransHeader: Record "FA Transfer Header"; NoSeries: Code[20])
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        FATransShptHeader.Init();
        FATransShptHeader.CopyFromTransferHeader(FATransHeader);
        FATransShptHeader."No. Series" := NoSeries;
        // OnBeforeGenNextNo(TransShptHeader, TransHeader);
        if FATransShptHeader."No." = '' then
            FATransShptHeader."No." := NoSeriesCodeunit.GetNextNo(FATransShptHeader."No. Series", FATransHeader."Posting Date");
        // OnBeforeInsertTransShptHeader(TransShptHeader, TransHeader, SuppressCommit);
        FATransShptHeader.Insert();
        ApprovalsMgmt.PostApprovalEntries(FATransHeader.RecordId, FATransShptHeader.RecordId, FATransShptHeader."No.");
        // OnAfterInsertTransShptHeader(TransHeader, TransShptHeader);
    end;

    local procedure InsertTransShptLine(FATransShptHeader: Record "FA Transfer Shipment Header")
    var
        TransShptLine: Record "FA Transfer Shipment Line";
        IsHandled: Boolean;
        ShouldRunPosting: Boolean;
    begin
        // OnBeforeInsertTransShipmentLine(TransLine);

        TransShptLine.Init();
        TransShptLine."Document No." := FATransShptHeader."No.";
        TransShptLine.CopyFromTransferLine(FATransLine);
        if FATransLine."Qty. to Ship" > 0 then begin
            OriginalQuantity := FATransLine."Qty. to Ship";
            OriginalQuantityBase := FATransLine."Qty. to Ship (Base)";
            PostItem(FATransLine, FATransShptHeader, TransShptLine, WhseShip, WhseShptHeader);
            TransShptLine."Item Shpt. Entry No." := InsertShptEntryRelation(TransShptLine);
            if WhseShip then begin
                WhseShptLine.SetCurrentKey(
                  "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
                WhseShptLine.SetRange("No.", WhseShptHeader."No.");
                WhseShptLine.SetRange("Source Type", DATABASE::"FA Transfer Line");
                WhseShptLine.SetRange("Source No.", FATransLine."Document No.");
                WhseShptLine.SetRange("Source Line No.", FATransLine."Line No.");
                if WhseShptLine.FindFirst() then
                    CreatePostedShptLineFromWhseShptLine(TransShptLine);
            end;
            ShouldRunPosting := WhsePosting;
            // OnInsertTransShptLineOnBeforePostWhseJnlLine(TransShptLine, TransLine, SuppressCommit, WhsePosting, ShouldRunPosting);
            if ShouldRunPosting then
                PostWhseJnlLine(FAItemJnlLine, OriginalQuantity, OriginalQuantityBase);
        end;

        IsHandled := false;
        // OnBeforeInsertTransShptLine(TransShptLine, TransLine, SuppressCommit, IsHandled, TransShptHeader);
        if IsHandled then
            exit;

        TransShptLine.Insert();
        // OnAfterInsertTransShptLine(TransShptLine, TransLine, SuppressCommit, TransShptHeader);
    end;

    local procedure CreatePostedShptLineFromWhseShptLine(var TransferShipmentLine: Record "FA Transfer Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCreatePostedShptLineFromWhseShptLine(TransferShipmentLine, WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification, IsHandled, WhseJnlRegisterLine, WhsePostShpt);
        if IsHandled then
            exit;

        WhseShptLine.TestField("Qty. to Ship", TransferShipmentLine.Quantity);
        // WhsePostShpt.CreatePostedShptLine(
        //   WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);

        // OnInsertTransShptLineOnAfterCreatePostedShptLine(WhseShptLine, PostedWhseShptLine);
    end;

    local procedure TransferTracking(var FAFromTransLine: Record "FA Transfer Line"; var FAToTransLine: Record "FA Transfer Line"; TransferQty: Decimal)
    var
        DummySpecification: Record "FA Tracking Specification";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeTransferTracking(FromTransLine, ToTransLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        TempHandlingSpecification.Reset();
        TempHandlingSpecification.SetRange("Source Prod. Order Line", FAToTransLine."Derived From Line No.");
        if TempHandlingSpecification.Find('-') then begin
            repeat
                ReserveTransLine.TransferTransferToTransfer(
                 FAFromTransLine, FAToTransLine, -TempHandlingSpecification."Quantity (Base)", Enum::"Transfer Direction"::Inbound, TempHandlingSpecification);
                TransferQty += TempHandlingSpecification."Quantity (Base)";
            until TempHandlingSpecification.Next() = 0;
            TempHandlingSpecification.DeleteAll();
        end;

        // OnTransferTrackingOnBeforeReserveTransferToTransfer(FromTransLine, ToTransLine, TransferQty);

        if TransferQty > 0 then
            ReserveTransLine.TransferTransferToTransfer(
              FAFromTransLine, FAToTransLine, TransferQty, Enum::"Transfer Direction"::Inbound, DummySpecification);
    end;

    local procedure CheckWarehouse(FATransLine: Record "FA Transfer Line")
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShowError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckWarehouse(TransLine, IsHandled);
        if IsHandled then
            exit;

        GetLocation(FATransLine."Transfer-from Code");
        if Location."Require Pick" or Location."Require Shipment" then begin
            if Location."Bin Mandatory" then
                ShowError := true
            else
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"FA Transfer Line",
                     0,// Out
                     FATransLine."Document No.",
                     FATransLine."Line No.",
                     0,
                     FATransLine.Quantity)
                then
                    ShowError := true;

            if ShowError then
                Error(
                  Text002,
                  FATransLine."Document No.",
                  FATransLine.FieldCaption("Line No."),
                  FATransLine."Line No.");
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure PostWhseJnlLine(FAItemJnlLine: Record "FA Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
        WMSMgmt: Codeunit "TST WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, IsHandled);
        if IsHandled then
            exit;

        // with FAItemJnlLine do begin
        FAItemJnlLine.Quantity := OriginalQuantity;
        FAItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(FAItemJnlLine."Location Code");
        if Location."Bin Mandatory" then
            if WMSMgmt.CreateWhseJnlLine(FAItemJnlLine, 1, WhseJnlLine, false) then begin
                // WMSMgmt.SetTransferLine(FATransLine, WhseJnlLine, 0, FATransShptHeader."No.");
                // OnPostWhseJnlLineOnBeforeSplitWhseJnlLine();
                // ItemTrackingMgt.SplitWhseJnlLine(
                //   WhseJnlLine, TempWhseJnlLine2, TempWhseSplitSpecification, true);
                // if TempWhseJnlLine2.Find('-') then
                //     repeat
                //         WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, true);
                //         WhseJnlRegisterLine.RegisterWhseJnlLine(TempWhseJnlLine2);
                //     until TempWhseJnlLine2.Next() = 0;
            end;
        // end;
    end;

    procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        WhseShptHeader := WhseShptHeader2;
        TempWhseShptHeader := WhseShptHeader;
        TempWhseShptHeader.Insert();
    end;

    local procedure GetShippingAdvice(): Boolean
    var
        FATransLine: Record "FA Transfer Line";
    begin
        FATransLine.SetRange("Document No.", FATransHeader."No.");
        if FATransLine.Find('-') then
            repeat
                if FATransLine."Quantity (Base)" <>
                   FATransLine."Qty. to Ship (Base)" + FATransLine."Qty. Shipped (Base)"
                then
                    exit(false);
            until FATransLine.Next() = 0;
        exit(true);
    end;

    local procedure CheckItemInInventory(FATransLine: Record "FA Transfer Line")
    var
        Item: Record "FA Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckItemInInventory(TransLine, IsHandled);
        if IsHandled then
            exit;

        // with Item do begin
        Item.Get(FATransLine."fa Item No.");
        Item.SetRange("Variant Filter", FATransLine."Variant Code");
        Item.SetRange("Location Filter", FATransLine."Transfer-from Code");
        Item.CalcFields(Inventory);
        if Item.Inventory <= 0 then
            Error(Text009, FATransLine."FA Item No.");
        // end;
    end;

    local procedure CheckItemInInventoryAndWarehouse(var FATransLine: Record "FA Transfer Line"; NeedCheckWarehouse: Boolean)
    var
        FATransLine2: Record "FA Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckItemInInventoryAndWarehouse(TransLine, NeedCheckWarehouse, IsHandled);
        if IsHandled then
            exit;

        FATransLine2.CopyFilters(FATransLine);
        FATransLine2.FindSet();
        repeat
            CheckItemInInventory(FATransLine2);
            if NeedCheckWarehouse then
                CheckWarehouse(FATransLine2);
        until FATransLine2.Next() = 0;
    end;

    local procedure CheckLines(FATransHeader: Record "FA Transfer Header"; var FATransLine: Record "FA Transfer Line")
    begin
        FATransLine.Reset();
        FATransLine.SetRange("Document No.", FATransHeader."No.");
        FATransLine.SetRange("Derived From Line No.", 0);
        FATransLine.SetFilter(Quantity, '<>0');
        FATransLine.SetFilter("Qty. to Ship", '<>0');
        if FATransLine.IsEmpty() then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    local procedure CheckShippingAdvice(var FATransferHeader: Record "FA Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckHeaderShippingAdvice(TransferHeader, IsHandled);
        if IsHandled then
            exit;

        if FATransferHeader."Shipping Advice" = FATransferHeader."Shipping Advice"::Complete then
            if not GetShippingAdvice() then
                Error(Text008);
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

    local procedure CopyTransLine(var NewTransferLine: Record "FA Transfer Line"; TransferLine: Record "FA Transfer Line"; var NextLineNo: Integer; TransferHeader: Record "FA Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCopyTransLine(NewTransferLine, TransferLine, NextLineNo, TransferHeader, IsHandled);
        if IsHandled then
            exit;

        NewTransferLine.Init();
        NewTransferLine := TransferLine;
        if TransferHeader."In-Transit Code" <> '' then
            NewTransferLine."Transfer-from Code" := TransferLine."In-Transit Code";
        NewTransferLine."In-Transit Code" := '';
        NewTransferLine."Derived From Line No." := TransferLine."Line No.";
        NewTransferLine."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        NewTransferLine.Quantity := TransferLine."Qty. to Ship";
        NewTransferLine."Quantity (Base)" := TransferLine."Qty. to Ship (Base)";
        NewTransferLine."Qty. to Ship" := NewTransferLine.Quantity;
        NewTransferLine."Qty. to Ship (Base)" := NewTransferLine."Quantity (Base)";
        NewTransferLine."Qty. to Receive" := NewTransferLine.Quantity;
        NewTransferLine."Qty. to Receive (Base)" := NewTransferLine."Quantity (Base)";
        NewTransferLine.ResetPostedQty();
        NewTransferLine."Outstanding Quantity" := NewTransferLine.Quantity;
        NewTransferLine."Outstanding Qty. (Base)" := NewTransferLine."Quantity (Base)";
        // OnBeforeNewTransferLineInsert(NewTransferLine, TransferLine, NextLineNo);
        NewTransferLine.Insert();
        // OnAfterCopyTransLine(NewTransferLine, TransferLine);
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

    local procedure MakeInventoryAdjustment()
    var
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then begin
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
            // OnAfterInvtAdjmt(TransHeader, TransShptHeader);
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var FATransferHeader: Record "FA Transfer Header"; var HideValidationDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostShipment(var TransferHeader: Record "FA Transfer Header"; CommitIsSuppressed: Boolean; var TransferShipmentHeader: Record "FA Transfer Shipment Header"; InvtPickPutaway: Boolean)
    begin
    end;
}