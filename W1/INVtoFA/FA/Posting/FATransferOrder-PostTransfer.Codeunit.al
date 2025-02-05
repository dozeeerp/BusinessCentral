namespace TSTChanges.FA.Posting;

using TSTChanges.FA.FAItem;
using TSTChanges.FA.Transfer;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.AuditCodes;
using TSTChanges.FA.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using TSTChanges.FA.Journal;
using TSTChanges.FA.Tracking;
using System.Utilities;
using TSTChanges.FA.Conversion;
using Microsoft.Utilities;
using Microsoft.Finance.Dimension;

codeunit 51233 "FATransferOrder-Post Transfer"
{
    Permissions =
                tabledata "FA Item Entry Relation" = i;
    TableNo = "FA Transfer Header";

    trigger OnRun()
    begin
        Error('Unser Development.');
        RunWithCheck(Rec);
    end;

    procedure RunWithCheck(var FATransferHeader2: Record "FA Transfer Header")
    var
        FAItem: Record "FA Item";
        FAItemVariant: Record "FA Item Variant";
        SourceCodeSetup: Record "Source Code Setup";
        //     InvtCommentLine: Record "Inventory Comment Line";
        //     UpdateAnalysisView: Codeunit "Update Analysis View";
        //     UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        RecordLinkManagement: Codeunit "Record Link Management";
        Window: Dialog;
        LineCount: Integer;
    begin
        ReleaseDocument(FATransferHeader2);
        FATransHeader := FATransferHeader2;
        FATransHeader.SetHideValidationDialog(HideValidationDialog);

        //     OnRunOnAfterTransHeaderSetHideValidationDialog(TransHeader, TransferHeader2, HideValidationDialog);

        // FATransHeader.CheckBeforeTransferPost();
        CheckDim();

        //     WhseReference := TransHeader."Posting from Whse. Ref.";
        //     TransHeader."Posting from Whse. Ref." := 0;

        //     WhseShip := TempWhseShptHeader.FindFirst();
        // InvtPickPutaway := WhseReference <> 0;

        FATransLine.Reset();
        FATransLine.SetRange("Document No.", FATransHeader."No.");
        FATransLine.SetRange("Derived From Line No.", 0);
        FATransLine.SetFilter(Quantity, '<>%1', 0);
        //     OnRunOnAfterTransLineSetFiltersForCheckShipmentLines(TransLine, TransHeader, Location, WhseShip);
        if FATransLine.FindSet() then
            repeat
                if not WhseShip then
                    FATransLine.TestField("Qty. to Ship");
                FATransLine.TestField("Quantity Shipped", 0);
                FATransLine.TestField("Quantity Received", 0);
                FATransLine.CheckDirectTransferQtyToShip()
            until FATransLine.Next() = 0
        else
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        GetLocation(FATransHeader."Transfer-from Code");
        if Location."Bin Mandatory" and not (WhseShip or InvtPickPutaway) then
            WhsePosting := true;

        // Require Receipt is not supported here, only Bin Mandatory
        GetLocation(FATransHeader."Transfer-to Code");
        Location.TestField("Require Receive", false);
        if Location."Bin Mandatory" then
            WhseReceive := true;

        Window.Open('#1#################################\\' + PostingLinesMsg);

        Window.Update(1, StrSubstNo(PostingDocumentTxt, FATransHeader."No."));

        SourceCodeSetup.Get();
        SourceCode := sourcecodesetup.Transfer;
        FAConSetup.Get();
        FAConSetup.TestField("Posted Direct Trans. Nos.");

        //     if InventorySetup."Automatic Cost Posting" then begin
        //         GLEntry.LockTable();
        //         if GLEntry.FindLast() then;
        //     end;

        InsertDirectTransHeader(FATransHeader, FADirectTransHeader);
        //     if InventorySetup."Copy Comments Order to Shpt." then begin
        //         InvtCommentLine.CopyCommentLines(
        //             "Inventory Comment Document Type"::"Transfer Order", TransHeader."No.",
        //             "Inventory Comment Document Type"::"Posted Direct Transfer", DirectTransHeader."No.");
        RecordLinkManagement.CopyLinks(FATransferHeader2, FADirectTransHeader);
        //     end;

        //     if WhseShip then begin
        //         WhseShptHeader.Get(TempWhseShptHeader."No.");
        //         WhsePostShipment.CreatePostedShptHeader(PostedWhseShptHeader, WhseShptHeader, DirectTransHeader."No.", TransHeader."Posting Date");
        //     end;

        // Insert shipment lines
        LineCount := 0;
        //     if WhseShip then
        //         PostedWhseShptLine.LockTable();
        //     if InvtPickPutaway then
        //         WhseRqst.LockTable();
        FADirectTransLine.LockTable();
        FATransLine.SetRange(Quantity);
        //     OnRunOnAfterTransLineSetFiltersForInsertShipmentLines(TransLine, TransHeader, Location, WhseShip);
        if FATransLine.FindSet() then
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);

                if FATransLine."FA Item No." <> '' then begin
                    FAItem.Get(FATransLine."FA Item No.");
                    FAItem.TestField(Blocked, false);

                    if FATransLine."Variant Code" <> '' then begin
                        FAItemVariant.Get(FATransLine."FA Item No.", FATransLine."Variant Code");
                        CheckItemVariantNotBlocked(FAItemVariant);
                    end;
                end;

                InsertDirectTransLine(FADirectTransHeader, FATransLine);
            until FATransLine.Next() = 0;

        //     MakeInventoryAdjustment();

        FATransHeader.LockTable();
        //     if WhseShip then
        //         WhseShptLine.LockTable();

        //     if WhseShip then begin
        //         WhsePostShipment.PostUpdateWhseDocuments(WhseShptHeader);
        //         TempWhseShptHeader.Delete();
        //     end;

        FATransHeader."Last Shipment No." := FADirectTransHeader."No.";
        FATransHeader."Last Receipt No." := FADirectTransHeader."No.";
        FATransHeader.Modify();

        FATransLine.SetRange(Quantity);
        if not PreviewMode then
            FATransHeader.DeleteOneTransferOrder(FATransHeader, FATransLine);
        Window.Close();

        //     UpdateAnalysisView.UpdateAll(0, true);
        //     UpdateItemAnalysisView.UpdateAll(0, true);
        FATransferHeader2 := FATransHeader;

        OnAfterTransferOrderPostTransfer(FATransferHeader2, SuppressCommit, FADirectTransHeader, InvtPickPutAway);
    end;

    var
        FADirectTransHeader: Record "FA Direct Trans. Header";
        FADirectTransLine: Record "FA Direct Trans. Line";
        FATransHeader: Record "FA Transfer Header";
        FATransLine: Record "FA Transfer Line";
        Location: Record Location;
        //     InventorySetup: Record "Inventory Setup";
        FAConSetup: Record "FA Conversion Setup";
        ItemJnlLine: Record "FA Item Journal Line";
        //     WhseRqst: Record "Warehouse Request";
        //     PostedWhseShptHeader: Record "Posted Whse. Shipment Header";
        //     PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        //     TempWhseSplitSpecification: Record "Tracking Specification" temporary;
        TempHandlingSpecification: Record "FA Tracking Specification" temporary;
        //     TempWhseShptHeader: Record "Warehouse Shipment Header" temporary;
        //     GLEntry: Record "G/L Entry";
        //     WhseShptHeader: Record "Warehouse Shipment Header";
        //     WhseShptLine: Record "Warehouse Shipment Line";
        ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ReserveTransLine: Codeunit "FA Transfer Line-Reserve";
        //     WhsePostShipment: Codeunit "Whse.-Post Shipment";
        SourceCode: Code[10];
        HideValidationDialog: Boolean;
        InvtPickPutaway: Boolean;
        SuppressCommit: Boolean;
        PreviewMode: Boolean;
        WhseReceive: Boolean;
        WhseShip: Boolean;
        WhsePosting: Boolean;
        WhseReference: Integer;
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        PostingLinesMsg: Label 'Posting transfer lines #2######', Comment = '#2 - line counter';
        PostingDocumentTxt: Label 'Transfer Order %1', Comment = '%1 - document number';
        DimCombBlockedErr: Label 'The combination of dimensions used in transfer order %1 is blocked. %2', Comment = '%1 - document number, %2 - error message';
        DimCombLineBlockedErr: Label 'The combination of dimensions used in transfer order %1, line no. %2 is blocked. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';
        DimInvalidErr: Label 'The dimensions used in transfer order %1, line no. %2 are invalid. %3', Comment = '%1 - document number, %2 = line number, %3 - error message';

    local procedure PostItemJnlLine(var FATransLine3: Record "FA Transfer Line"; FADirectTransHeader2: Record "FA Direct Trans. Header"; FADirectTransLine2: Record "FA Direct Trans. Line")
    // var
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforePostItemJnlLine(DirectTransHeader2, TransLine3, DirectTransLine2, WhseShptHeader, ItemJnlPostLine, WhseShip, IsHandled);
        //     if IsHandled then
        //         exit;

        CreateItemJnlLine(FATransLine3, FADirectTransHeader2, FADirectTransLine2);
        ReserveTransLine.TransferTransferToItemJnlLine(FATransLine3,
          ItemJnlLine, ItemJnlLine."Quantity (Base)", Enum::"Transfer Direction"::Outbound, true);

        //     OnPostItemJnlLineBeforeItemJnlPostLineRunWithCheck(ItemJnlLine, Transline3, DirectTransHeader2, DirectTransLine2, SuppressCommit);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        //     OnAfterPostItemJnlLine(TransLine3, DirectTransHeader2, DirectTransLine2, ItemJnlLine, ItemJnlPostLine);
    end;

    local procedure CreateItemJnlLine(FATransLine3: Record "FA Transfer Line"; FADirectTransHeader2: Record "FA Direct Trans. Header"; FADirectTransLine2: Record "FA Direct Trans. Line")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := FADirectTransHeader2."Posting Date";
        ItemJnlLine."Document Date" := FADirectTransHeader2."Posting Date";
        ItemJnlLine."Document No." := FADirectTransHeader2."No.";
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Direct Transfer";
        ItemJnlLine."Document Line No." := FADirectTransLine2."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Transfer;
        ItemJnlLine."Order No." := FADirectTransHeader2."Transfer Order No.";
        ItemJnlLine."External Document No." := FADirectTransHeader2."External Document No.";
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."FA Item No." := FADirectTransLine2."Item No.";
        ItemJnlLine.Description := FADirectTransLine2.Description;
        ItemJnlLine."Shortcut Dimension 1 Code" := FADirectTransLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."New Shortcut Dimension 1 Code" := FADirectTransLine2."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := FADirectTransLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."New Shortcut Dimension 2 Code" := FADirectTransLine2."Shortcut Dimension 2 Code";
        ItemJnlLine."Dimension Set ID" := FADirectTransLine2."Dimension Set ID";
        ItemJnlLine."New Dimension Set ID" := FADirectTransLine2."Dimension Set ID";
        ItemJnlLine."Location Code" := FADirectTransHeader2."Transfer-from Code";
        ItemJnlLine."New Location Code" := FADirectTransHeader2."Transfer-to Code";
        ItemJnlLine.Quantity := FADirectTransLine2.Quantity;
        ItemJnlLine."Invoiced Quantity" := FADirectTransLine2.Quantity;
        ItemJnlLine."Quantity (Base)" := FADirectTransLine2."Quantity (Base)";
        ItemJnlLine."Invoiced Qty. (Base)" := FADirectTransLine2."Quantity (Base)";
        ItemJnlLine."Source Code" := SourceCode;
        // ItemJnlLine."Gen. Prod. Posting Group" := FADirectTransLine2."Gen. Prod. Posting Group";
        // ItemJnlLine."Inventory Posting Group" := FADirectTransLine2."Inventory Posting Group";
        ItemJnlLine."Unit of Measure Code" := FADirectTransLine2."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := FADirectTransLine2."Qty. per Unit of Measure";
        ItemJnlLine."Variant Code" := FADirectTransLine2."Variant Code";
        ItemJnlLine."Bin Code" := FATransLine3."Transfer-from Bin Code";
        ItemJnlLine."New Bin Code" := FATransLine3."Transfer-To Bin Code";
        ItemJnlLine."Country/Region Code" := FADirectTransHeader2."Trsf.-from Country/Region Code";
        // ItemJnlLine."Item Category Code" := FATransLine3."Item Category Code";

        //     OnAfterCreateItemJnlLine(ItemJnlLine, TransLine3, DirectTransHeader2, DirectTransLine2);
    end;

    local procedure InsertDirectTransHeader(TransferHeader: Record "FA Transfer Header"; var DirectTransHeader: Record "FA Direct Trans. Header")
    var
        NoSeries: Codeunit "No. Series";
    begin
        DirectTransHeader.LockTable();
        DirectTransHeader.Init();
        DirectTransHeader."Transfer-from Code" := TransferHeader."Transfer-from Code";
        DirectTransHeader."Transfer-from Name" := TransferHeader."Transfer-from Name";
        DirectTransHeader."Transfer-from Name 2" := TransferHeader."Transfer-from Name 2";
        DirectTransHeader."Transfer-from Address" := TransferHeader."Transfer-from Address";
        DirectTransHeader."Transfer-from Address 2" := TransferHeader."Transfer-from Address 2";
        DirectTransHeader."Transfer-from Post Code" := TransferHeader."Transfer-from Post Code";
        DirectTransHeader."Transfer-from City" := TransferHeader."Transfer-from City";
        DirectTransHeader."Transfer-from County" := TransferHeader."Transfer-from County";
        DirectTransHeader."Trsf.-from Country/Region Code" := TransferHeader."Trsf.-from Country/Region Code";
        DirectTransHeader."Transfer-from Contact" := TransferHeader."Transfer-from Contact";
        DirectTransHeader."Transfer-to Code" := TransferHeader."Transfer-to Code";
        DirectTransHeader."Transfer-to Name" := TransferHeader."Transfer-to Name";
        DirectTransHeader."Transfer-to Name 2" := TransferHeader."Transfer-to Name 2";
        DirectTransHeader."Transfer-to Address" := TransferHeader."Transfer-to Address";
        DirectTransHeader."Transfer-to Address 2" := TransferHeader."Transfer-to Address 2";
        DirectTransHeader."Transfer-to Post Code" := TransferHeader."Transfer-to Post Code";
        DirectTransHeader."Transfer-to City" := TransferHeader."Transfer-to City";
        DirectTransHeader."Transfer-to County" := TransferHeader."Transfer-to County";
        DirectTransHeader."Trsf.-to Country/Region Code" := TransferHeader."Trsf.-to Country/Region Code";
        DirectTransHeader."Transfer-to Contact" := TransferHeader."Transfer-to Contact";
        DirectTransHeader."Transfer Order Date" := TransferHeader."Posting Date";
        DirectTransHeader."Posting Date" := TransferHeader."Posting Date";
        DirectTransHeader."Shortcut Dimension 1 Code" := TransferHeader."Shortcut Dimension 1 Code";
        DirectTransHeader."Shortcut Dimension 2 Code" := TransferHeader."Shortcut Dimension 2 Code";
        DirectTransHeader."Dimension Set ID" := TransferHeader."Dimension Set ID";
        DirectTransHeader."Transfer Order No." := TransferHeader."No.";
        DirectTransHeader."External Document No." := TransferHeader."External Document No.";
        DirectTransHeader."No. Series" := FAConSetup."Posted Direct Trans. Nos.";
        OnInsertDirectTransHeaderOnBeforeGetNextNo(DirectTransHeader, TransferHeader);
        DirectTransHeader."No." :=
            NoSeries.GetNextNo(DirectTransHeader."No. Series", TransferHeader."Posting Date");
        OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert(DirectTransHeader, TransferHeader);
        DirectTransHeader.Insert();

        OnAfterInsertDirectTransHeader(DirectTransHeader, TransferHeader);
    end;

    local procedure InsertDirectTransLine(FADirectTransHeader: Record "FA Direct Trans. Header"; FATransLine: Record "FA Transfer Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeInsertDirectTransLine(FATransLine);
        FADirectTransLine.Init();
        FADirectTransLine."Document No." := FADirectTransHeader."No.";
        FADirectTransLine.CopyFromTransferLine(FATransLine);

        OnInsertDirectTransLineOnAfterPopulateDirectTransLine(FADirectTransLine, FADirectTransHeader, FATransLine);
        if FATransLine.Quantity > 0 then begin
            OriginalQuantity := FATransLine.Quantity;
            OriginalQuantityBase := FATransLine."Quantity (Base)";
            PostItemJnlLine(FATransLine, FADirectTransHeader, FADirectTransLine);
            FADirectTransLine."Item Shpt. Entry No." := InsertShptEntryRelation(FADirectTransLine);
            // if WhseShip then begin
            //             WhseShptLine.SetCurrentKey("No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
            //             WhseShptLine.SetRange("No.", WhseShptHeader."No.");
            //             WhseShptLine.SetRange("Source Type", DATABASE::"Transfer Line");
            //             WhseShptLine.SetRange("Source No.", TransLine."Document No.");
            //             WhseShptLine.SetRange("Source Line No.", TransLine."Line No.");
            //             if WhseShptLine.FindFirst() then begin
            //                 WhseShptLine.TestField("Qty. to Ship", TransLine.Quantity);
            //                 WhsePostShipment.CreatePostedShptLine(
            //                     WhseShptLine, PostedWhseShptHeader, PostedWhseShptLine, TempWhseSplitSpecification);
            //             end;
            // end;
            //         if WhsePosting then
            //             PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, 0);
            //         if WhseReceive then
            //             PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, 1);
        end;
        IsHandled := false;
        OnInsertDirectTransLineOnBeforeDirectTransHeaderInsert(FADirectTransHeader, FATransLine, IsHandled);
        if not IsHandled then
            FADirectTransLine.Insert();
        OnAfterInsertDirectTransLine(FADirectTransLine, FADirectTransHeader, FATransLine)
    end;

    local procedure CheckItemVariantNotBlocked(var FAItemVariant: Record "FA Item Variant")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemVariantNotBlocked(FATransLine, FAItemVariant, FATransHeader, Location, WhseShip, WhseReceive, IsHandled);
        if IsHandled then
            exit;

        FAItemVariant.TestField(Blocked, false);
    end;

    local procedure CheckDim()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDim(FATransHeader, FATransLine);
        if IsHandled then
            exit;

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
                Error(DimCombBlockedErr, FATransHeader."No.", DimMgt.GetDimCombErr())
            else
                if not DimMgt.CheckDimIDComb(FATransferLine."Dimension Set ID") then
                    Error(DimCombLineBlockedErr, FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimCombErr());
    end;

    local procedure CheckDimValuePosting(FATransferHeader: Record "FA Transfer Header"; FATransferLine: Record "FA Transfer Line")
    var
        TableIDArr: array[10] of Integer;
        NumberArr: array[10] of Code[20];
    begin
        TableIDArr[1] := DATABASE::"FA Item";
        NumberArr[1] := FATransferLine."FA Item No.";
        if FATransferLine."Line No." = 0 then
            if not DimMgt.CheckDimValuePosting(TableIDArr, NumberArr, FATransferHeader."Dimension Set ID") then
                Error(DimInvalidErr, FATransHeader."No.", FATransferLine."Line No.", DimMgt.GetDimValuePostingErr());
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure InsertShptEntryRelation(var FADirectTransLine: Record "FA Direct Trans. Line") Result: Integer
    var
        TempHandlingSpecification2: Record "FA Tracking Specification" temporary;
        ItemEntryRelation: Record "FA Item Entry Relation";
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";
    //     WhseSplitSpecification: Boolean;
    begin
        //     if WhsePosting then begin
        //         TempWhseSplitSpecification.Reset();
        //         TempWhseSplitSpecification.DeleteAll();
        //     end;

        TempHandlingSpecification2.Reset();
        if ItemJnlPostLine.CollectTrackingSpecification(TempHandlingSpecification2) then begin
            TempHandlingSpecification2.SetRange("Buffer Status", 0);
            if TempHandlingSpecification2.Find('-') then begin
                repeat
                    // WhseSplitSpecification := WhsePosting or WhseShip or InvtPickPutaway;
                    // if WhseSplitSpecification then
                    //     if ItemTrackingMgt.GetWhseItemTrkgSetup(DirectTransLine."Item No.") then begin
                    //         TempWhseSplitSpecification := TempHandlingSpecification2;
                    //         TempWhseSplitSpecification."Source Type" := DATABASE::"Transfer Line";
                    //         TempWhseSplitSpecification."Source ID" := TransLine."Document No.";
                    //         TempWhseSplitSpecification."Source Ref. No." := TransLine."Line No.";
                    //         TempWhseSplitSpecification.Insert();
                    //     end;

                    ItemEntryRelation.Init();
                    ItemEntryRelation.InitFromTrackingSpec(TempHandlingSpecification2);
                    ItemEntryRelation.TransferFieldsDirectTransLine(FADirectTransLine);
                    ItemEntryRelation.Insert();
                    TempHandlingSpecification := TempHandlingSpecification2;
                    TempHandlingSpecification.SetSource(
                        DATABASE::"FA Transfer Line", 0, FADirectTransLine."Document No.", FADirectTransLine."Line No.", '', FADirectTransLine."Line No.");
                    TempHandlingSpecification."Buffer Status" := TempHandlingSpecification."Buffer Status"::MODIFY;
                    TempHandlingSpecification.Insert();
                until TempHandlingSpecification2.Next() = 0;
                Result := 0;
            end;
        end else
            Result := ItemJnlLine."Item Shpt. Entry No.";

        OnAfterInsertShptEntryRelation(ItemEntryRelation, FADirectTransLine, Result);
    end;

    // procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal)
    // var
    //     DummySpecification: Record "Tracking Specification";
    //     IsHandled: Boolean;
    // begin
    //     IsHandled := false;
    //     OnBeforeTransferTracking(FromTransLine, ToTransLine, TransferQty, IsHandled);
    //     if IsHandled then
    //         exit;

    //     TempHandlingSpecification.Reset();
    //     TempHandlingSpecification.SetRange("Source Prod. Order Line", ToTransLine."Derived From Line No.");
    //     if TempHandlingSpecification.Find('-') then begin
    //         repeat
    //             ReserveTransLine.TransferTransferToTransfer(
    //               FromTransLine, ToTransLine, -TempHandlingSpecification."Quantity (Base)", Enum::"Transfer Direction"::Inbound, TempHandlingSpecification);
    //             TransferQty += TempHandlingSpecification."Quantity (Base)";
    //         until TempHandlingSpecification.Next() = 0;
    //         TempHandlingSpecification.DeleteAll();
    //     end;

    //     if TransferQty > 0 then
    //         ReserveTransLine.TransferTransferToTransfer(
    //           FromTransLine, ToTransLine, TransferQty, Enum::"Transfer Direction"::Inbound, DummySpecification);
    // end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    // procedure SetWhseShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    // begin
    //     WhseShptHeader := WhseShptHeader2;
    //     TempWhseShptHeader := WhseShptHeader;
    //     TempWhseShptHeader.Insert();
    // end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    // local procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary; Direction: Integer)
    // var
    //     WhseJnlLine: Record "Warehouse Journal Line";
    //     TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
    //     ItemTrackingMgt: Codeunit "Item Tracking Management";
    //     WMSMgmt: Codeunit "WMS Management";
    //     WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
    //     IsHandled: Boolean;
    // begin
    //     IsHandled := false;
    //     OnBeforePostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempHandlingSpecification, Direction, IsHandled);
    //     if IsHandled then
    //         exit;

    //     ItemJnlLine.Quantity := OriginalQuantity;
    //     ItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
    //     if Direction = 0 then
    //         GetLocation(ItemJnlLine."Location Code")
    //     else
    //         GetLocation(ItemJnlLine."New Location Code");
    //     if Location."Bin Mandatory" then
    //         if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, 1, WhseJnlLine, Direction = 1) then begin
    //             WMSMgmt.SetTransferLine(TransLine, WhseJnlLine, Direction, DirectTransHeader."No.");
    //             WhseJnlLine."Source No." := DirectTransHeader."No.";
    //             if Direction = 1 then
    //                 WhseJnlLine."To Bin Code" := ItemJnlLine."New Bin Code";
    //             OnPostWhseJnlLineOnBeforeSplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine2);
    //             ItemTrackingMgt.SplitWhseJnlLine(
    //               WhseJnlLine, TempWhseJnlLine2, TempHandlingSpecification, true);
    //             if TempWhseJnlLine2.Find('-') then
    //                 repeat
    //                     WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine2, 1, 0, Direction = 1);
    //                     WhseJnlPostLine.Run(TempWhseJnlLine2);
    //                 until TempWhseJnlLine2.Next() = 0;
    //         end;
    // end;

    // local procedure MakeInventoryAdjustment()
    // var
    //     InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    // begin
    //     if InventorySetup.AutomaticCostAdjmtRequired() then
    //         InvtAdjmtHandler.MakeInventoryAdjustment(true, InventorySetup."Automatic Cost Posting");
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", 'OnAfterValidateQtyToShip', '', false, false)]
    // local procedure WarehouseShipmentLineOnValidateQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    // begin
    //     if WarehouseShipmentLine."Qty. to Ship (Base)" <> 0 then
    //         CheckDirectTransferQtyToShip(WarehouseShipmentLine);
    // end;

    // local procedure CheckDirectTransferQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    // begin
    //     if WarehouseShipmentLine."Source Type" <> Database::"Transfer Line" then
    //         exit;

    //     if WarehouseShipmentLine.CheckDirectTransfer(false, false) then
    //         WarehouseShipmentLine.TestField("Qty. to Ship (Base)", WarehouseShipmentLine."Qty. Outstanding (Base)");
    // end;

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

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterCreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; TransLine: Record "Transfer Line"; DirectTransHeader: Record "Direct Trans. Header"; DirectTransLine: Record "Direct Trans. Line")
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDirectTransHeader(var FADirectTransHeader: Record "FA Direct Trans. Header"; FATransferHeader: Record "FA Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDirectTransLine(var FADirectTransLine: Record "FA Direct Trans. Line"; FADirectTransHeader: Record "FA Direct Trans. Header"; FATransLine: Record "FA Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertShptEntryRelation(var FAItemEntryRelation: Record "FA Item Entry Relation"; var FADirectTransLine: Record "FA Direct Trans. Line"; var Result: Integer)
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterPostItemJnlLine(var TransferLine3: Record "Transfer Line"; DirectTransHeader2: Record "Direct Trans. Header"; DirectTransLine2: Record "Direct Trans. Line"; ItemJournalLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDim(var FATransferHeader: Record "FA Transfer Header"; var FATransferLife: Record "FA Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDirectTransLine(FATransferLine: Record "FA Transfer Line")
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforePostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary; Direction: Integer; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeTransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; TransferQty: Decimal; var IsHandled: Boolean)
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransLineOnAfterPopulateDirectTransLine(var FADirectTransLine: Record "FA Direct Trans. Line"; FADirectTransHeader: Record "FA Direct Trans. Header"; FATransLine: Record "FA Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert(var FADirectTransHeader: Record "FA Direct Trans. Header"; FATransferHeader: Record "FA Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransHeaderOnBeforeGetNextNo(var FADirectTransHeader: Record "FA Direct Trans. Header"; FATransferHeader: Record "FA Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertDirectTransLineOnBeforeDirectTransHeaderInsert(var FADirectTransHeader: Record "FA Direct Trans. Header"; FATransLine: Record "FA Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnPostWhseJnlLineOnBeforeSplitWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; var TempWhseJnlLine2: Record "Warehouse Journal Line" temporary)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnRunOnAfterTransHeaderSetHideValidationDialog(var TransHeader: Record "Transfer Header"; var Rec: Record "Transfer Header"; var HideValidationDialog: Boolean);
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferOrderPostTransfer(var FATransferHeader: Record "FA Transfer Header"; var SuppressCommit: Boolean; var FADirectTransHeader: Record "FA Direct Trans. Header"; InvtPickPutAway: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemVariantNotBlocked(FATransLine: Record "FA Transfer Line"; FAItemVariant: Record "FA Item Variant"; FATransHeader: Record "FA Transfer Header"; Location: Record Location; WhseShip: Boolean; WhseReceive: Boolean; var IsHandled: Boolean)
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnPostItemJnlLineBeforeItemJnlPostLineRunWithCheck(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; DirectTransHeader: Record "Direct Trans. Header"; DirectTransLine: Record "Direct Trans. Line"; CommitIsSuppressed: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforePostItemJnlLine(var DirectTransHeader: Record "Direct Trans. Header"; var TransferLine: Record "Transfer Line"; DirectTransLine: Record "Direct Trans. Line"; WhseShptHeader: Record "Warehouse Shipment Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; WhseShip: Boolean; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnRunOnAfterTransLineSetFiltersForCheckShipmentLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnRunOnAfterTransLineSetFiltersForInsertShipmentLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseShip: Boolean)
    // begin
    // end;
}