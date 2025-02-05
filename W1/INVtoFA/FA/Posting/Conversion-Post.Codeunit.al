namespace TSTChanges.FA.Posting;

using TSTChanges.FA.Conversion;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Finance.GeneralLedger.Journal;
using TSTChanges.FA.Journal;
using TSTChanges.FA.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using Microsoft.Foundation.NoSeries;
using Microsoft.Warehouse.Request;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Journal;
using Microsoft.Projects.Resources.Journal;
using TSTChanges.FA.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Foundation.UOM;
using TSTChanges.FA.FAItem;
using TSTChanges.FA.History;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Finance.GeneralLedger.Preview;
using System.Automation;

codeunit 51204 "Conversion-Post"
{
    Permissions = TableData "Posted Conversion Header" = rim,
                  TableData "Posted Conversion Line" = rim,
                  TableData "Item Entry Relation" = ri,
                  TableData "FA Item Entry Relation" = ri;
    TableNo = "FA Conversion Header";

    trigger OnRun()
    var
        ConversionHeader: Record "FA Conversion Header";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        SavedSuppressCommit: Boolean;
        SavedPreviewMode: Boolean;
    begin
        OnBeforeOnRun(Rec, SuppressCommit);

        // Replace posting date if called from batch posting
        ValidatePostingDate(Rec);

        SavedSuppressCommit := SuppressCommit;
        SavedPreviewMode := PreviewMode;
        ClearAll();
        SuppressCommit := SavedSuppressCommit;
        PreviewMode := SavedPreviewMode;

        ConversionHeader := Rec;

        ConversionHeader.CheckConversionPostRestrictions();

        OpenWindow();
        Window.Update(1, StrSubstNo('%1 %2', Rec.TableCaption, Rec."No."));

        InitPost(ConversionHeader);
        Post(ConversionHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine, false);
        FinalizePost(ConversionHeader);
        if not (SuppressCommit or PreviewMode) then
            Commit();

        Window.Close();
        Rec := ConversionHeader;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    var
        GLEntry: Record "G/L Entry";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        ConvertedItem: Record "FA Item";
        MSUndoPostingMgt: Codeunit "Undo Posting Management";
        TSTUndoPostingMgt: Codeunit "TST Undo Posting Management";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempFAItemLedgEntry: Record "FA Item ledger Entry" temporary;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PostingDateExists: Boolean;
        ReplacePostingDate: Boolean;
        PostingDate: Date;
        SuppressCommit: Boolean;
        PreviewMode: Boolean;
        Window: Dialog;
        ShowProgress: Boolean;
        SourceCode: Code[10];
        Text001: Label 'is not within your range of allowed posting dates.', Comment = 'starts with "Posting Date"';
        Text007: Label 'Posting lines              #2######';
        Text008: Label 'Posting %1';
        Text009: Label '%1 should be blank for comment text: %2.';
        Text010: Label 'Undoing %1';
        Text011: Label 'Posted conversion order %1 cannot be restored because the number of lines in conversion order %2 has changed.', Comment = '%1=Posted Conversion Order No. field value,%2=FA Conversion Header Document No field value';

    local procedure InitPost(var ConversionHeader: Record "FA Conversion Header")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        NoSeries: Codeunit "No. Series";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        ConversionHeader.TestField("Posting Date");
        PostingDate := ConversionHeader."Posting Date";
        if GenJnlCheckLine.DateNotAllowed(ConversionHeader."Posting Date") then
            ConversionHeader.FieldError(ConversionHeader."Posting Date", Text001);
        ConversionHeader.TestField("FA Item No.");
        // CheckDim(AssemblyHeader);
        if not IsOrderPostable(ConversionHeader) then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        if ConversionHeader."Posting No." = '' then Begin
            // if "Document Type" = "Document Type"::Order then begin
            ConversionHeader.TestField("Posting No. Series");
            ConversionHeader."Posting No." := NoSeries.GetNextNo(ConversionHeader."Posting No. Series", ConversionHeader."Posting Date", true);
            ConversionHeader.Modify();
            if not GenJnlPostPreview.IsActive() and not (SuppressCommit or PreviewMode) then
                Commit();
        end;

        // if ConversionHeader.Status = ConversionHeader.Status::Open then begin
        //     CODEUNIT.Run(CODEUNIT::"Release Conversion Document", ConversionHeader);
        //     ConversionHeader.TestField(Status, ConversionHeader.Status::Released);
        //     ConversionHeader.Status := ConversionHeader.Status::Open;
        //     if not GenJnlPostPreview.IsActive() then begin
        //         ConversionHeader.Modify();
        //         if not (SuppressCommit or PreviewMode) then
        //             Commit();
        //     end;
        //     ConversionHeader.Status := ConversionHeader.Status::Released;
        // end;
        ReleaseDocument(ConversionHeader);

        GetSourceCode();//IsAsmToOrder());
    end;

    local procedure ReleaseDocument(var ConversionHeader: Record "FA Conversion Header")
    var
        ReleaseConversionDocument: Codeunit "Release Conversion Document";
        SavedStatus: Enum "Conversion Document Status";
    begin
        if ConversionHeader.Status <> ConversionHeader.Status::Open then
            exit;

        SavedStatus := ConversionHeader.Status;
        ReleaseConversionDocument.ReleaseConversionHeader(ConversionHeader, PreviewMode);
        ConversionHeader.Status := SavedStatus;
        if not (SuppressCommit or PreviewMode) then begin
            ConversionHeader.Modify();
            Commit();
        end;
        ConversionHeader.Status := ConversionHeader.Status::Released;
    end;

    local procedure Post(var ConversionHeader: Record "FA Conversion Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
                        var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
                        NeedUpdateUnitCost: Boolean)
    var
        ConversionLine: Record "FA Conversion Line";
        PostedConversionHeader: Record "Posted Conversion Header";
    begin
        ConversionHeader.SuspendStatusCheck(true);
        LockTables(ConversionLine, ConversionHeader);

        // Insert posted assembly header
        begin
            PostedConversionHeader.Init();
            PostedConversionHeader.TransferFields(ConversionHeader);

            PostedConversionHeader."No." := ConversionHeader."Posting No.";
            PostedConversionHeader."Order No." := ConversionHeader."No.";
            PostedConversionHeader."No. Series" := ConversionHeader."No. Series";
            PostedConversionHeader."Source Code" := SourceCode;
            PostedConversionHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PostedConversionHeader."User ID"));
            PostedConversionHeader.Insert();
        end;

        ApprovalsMgmt.PostApprovalEntries(ConversionHeader.RecordId, PostedConversionHeader.RecordId, PostedConversionHeader."No.");

        ConvertedItem.Get(ConversionHeader."FA Item No.");
        PostLines(ConversionHeader, ConversionLine, PostedConversionHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
        PostHeader(ConversionHeader, PostedConversionHeader, ItemJnlPostLine, WhseJnlRegisterLine, NeedUpdateUnitCost);
    end;

    local procedure FinalizePost(ConversionHeader: Record "FA Conversion Header")
    begin
        //     OnBeforeFinalizePost(AssemblyHeader);

        MakeInvtAdjmt();

        if not PreviewMode then
            DeleteConversionDocument(ConversionHeader);

        //     OnAfterFinalizePost(AssemblyHeader);
    end;

    local procedure DeleteConversionDocument(ConversionHeader: Record "FA Conversion Header")
    var
        ConversionLine: Record "FA Conversion Line";
        //     AssemblyCommentLine: Record "Assembly Comment Line";
        ConversionLineReserve: Codeunit "Conversion Line-Reserve";
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeDeleteAssemblyDocument(AssemblyHeader, IsHandled);
        //     if not IsHandled then
        //         with AssemblyHeader do begin
        // Delete header and lines
        ConversionLine.Reset();
        // AssemblyLine.SetRange("Document Type", "Document Type");
        ConversionLine.SetRange("Document No.", ConversionHeader."No.");
        if ConversionHeader."Remaining Quantity (Base)" = 0 then begin
            if ConversionHeader.HasLinks then
                ConversionHeader.DeleteLinks();
            ApprovalsMgmt.DeleteApprovalEntries(ConversionHeader.RecordId);
            DeleteWhseRequest(ConversionHeader);
            // OnDeleteAssemblyDocumentOnBeforeDeleteAssemblyHeader(AssemblyHeader, AssemblyLine);
            ConversionHeader.Delete();
            // OnDeleteAssemblyDocumentOnAfterDeleteAssemblyHeader(AssemblyHeader, AssemblyLine);
            if ConversionLine.Find('-') then
                repeat
                    if ConversionLine.HasLinks then
                        ConversionLine.DeleteLinks();
                    ConversionLineReserve.SetDeleteItemTracking(true);
                    ConversionLineReserve.DeleteLine(ConversionLine);
                until ConversionLine.Next() = 0;
            // OnDeleteAssemblyDocumentOnBeforeDeleteAssemblyLines(AssemblyHeader, AssemblyLine);
            ConversionLine.DeleteAll();
            //     AssemblyCommentLine.SetCurrentKey("Document Type", "Document No.");
            //     AssemblyCommentLine.SetRange("Document Type", "Document Type");
            //     AssemblyCommentLine.SetRange("Document No.", "No.");
            //     if not AssemblyCommentLine.IsEmpty() then
            //         AssemblyCommentLine.DeleteAll();
            // end;
        end;

        // OnAfterDeleteAssemblyDocument(AssemblyHeader);
    end;

    local procedure OpenWindow()
    var
        ConHeader: Record "FA Conversion Header";
    begin
        // ConHeader."Document Type" := DocType;
        // if ConHeader."Document Type" = ConHeader."Document Type"::Order then
        Window.Open(
          '#1#################################\\' +
          Text007 + '\\' +
          StrSubstNo(Text008, ConHeader.TableCaption));
        ShowProgress := true;
    end;

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewPostingDate: Date)
    begin
        PostingDateExists := true;
        ReplacePostingDate := NewReplacePostingDate;
        PostingDate := NewPostingDate;
    end;

    local procedure ValidatePostingDate(var ConversionHeader: Record "FA Conversion Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        if not PostingDateExists then
            PostingDateExists :=
              BatchProcessingMgt.GetBooleanParameter(
                ConversionHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate) and
              BatchProcessingMgt.GetDateParameter(
                  ConversionHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);

        if PostingDateExists and (ReplacePostingDate or (ConversionHeader."Posting Date" = 0D)) then
            ConversionHeader."Posting Date" := PostingDate;
    end;

    local procedure IsOrderPostable(ConversionHeader: Record "FA Conversion Header"): Boolean
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        // if ConversionHeader."Document Type" <> ConversionHeader."Document Type"::Order then
        //     exit(false);

        if ConversionHeader."Quantity to Convert" = 0 then
            exit(false);

        ConversionLine.SetCurrentKey("Document No.", Type);
        // AssemblyLine.SetRange("Document Type", ConversionHeader."Document Type");
        ConversionLine.SetRange("Document No.", ConversionHeader."No.");

        ConversionLine.SetFilter(Type, '<>%1', ConversionLine.Type::" ");
        if ConversionLine.IsEmpty() then
            exit(false);

        ConversionLine.SetFilter("Quantity to Consume", '<>0');
        exit(not ConversionLine.IsEmpty);
    end;

    local procedure LockTables(var ConversionLine: Record "FA Conversion Line"; var ConversionHeader: Record "FA Conversion Header")
    var
        InvSetup: Record "Inventory Setup";
    begin
        ConversionLine.LockTable();
        ConversionHeader.LockTable();
        if not InvSetup.OptimGLEntLockForMultiuserEnv() then begin
            GLEntry.LockTable();
            if GLEntry.FindLast() then;
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure SortLines(var ConversionLine: Record "FA Conversion Line")
    var
        InvSetup: Record "Inventory Setup";
    begin
        if InvSetup.OptimGLEntLockForMultiuserEnv() then
            ConversionLine.SetCurrentKey("Document No.", Type, "No.")
        else
            ConversionLine.SetCurrentKey("Document No.", "Line No.");
    end;

    local procedure SortPostedLines(var PostedConLine: Record "Posted Conversion Line")
    var
        InvSetup: Record "Inventory Setup";
    begin
        if InvSetup.OptimGLEntLockForMultiuserEnv() then
            PostedConLine.SetCurrentKey(Type, "No.")
        else
            PostedConLine.SetCurrentKey("Document No.", "Line No.");
    end;

    local procedure GetLineQtys(var LineQty: Decimal; var LineQtyBase: Decimal; ConversionLine: Record "FA Conversion Line")
    begin
        LineQty := RoundQuantity(ConversionLine."Quantity to Consume", ConversionLine."Qty. Rounding Precision");
        LineQtyBase := RoundQuantity(ConversionLine."Quantity to Consume (Base)", ConversionLine."Qty. Rounding Precision (Base)");
    end;

    local procedure GetHeaderQtys(var HeaderQty: Decimal; var HeaderQtyBase: Decimal; ConversionHeader: Record "FA Conversion Header")
    begin
        HeaderQty := RoundQuantity(ConversionHeader."Quantity to Convert", ConversionHeader."Qty. Rounding Precision");
        HeaderQtyBase := RoundQuantity(ConversionHeader."Quantity to Convert (Base)", ConversionHeader."Qty. Rounding Precision (Base)");
    end;

    local procedure RoundQuantity(Qty: Decimal; QtyRoundingPrecision: Decimal): Decimal
    begin
        if QtyRoundingPrecision = 0 then
            QtyRoundingPrecision := UOMMgt.QtyRndPrecision();

        exit(Round(Qty, QtyRoundingPrecision))
    end;

    local procedure PostLines(ConversionHeader: Record "FA Conversion Header"; var ConversionLine: Record "FA Conversion Line";
                    PostedConversionHeader: Record "Posted Conversion Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
                    var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedConversionLine: Record "Posted Conversion Line";
        LineCounter: Integer;
        QtyToConsume: Decimal;
        QtyToConsumeBase: Decimal;
        ItemLedgEntryNo: Integer;
    begin
        ConversionLine.Reset();
        ConversionLine.SetRange("Document No.", ConversionHeader."No.");
        SortLines(ConversionLine);

        LineCounter := 0;

        if ConversionLine.FindSet() then
            repeat
                if (ConversionLine."No." = '') and
                    (ConversionLine.Description <> '') and
                    (ConversionLine.Type <> ConversionLine.Type::" ")
                then
                    Error(Text009, ConversionLine.FieldCaption(Type), ConversionLine.Description);

                LineCounter += 1;
                if ShowProgress then
                    Window.Update(2, LineCounter);

                GetLineQtys(QtyToConsume, QtyToConsumeBase, ConversionLine);

                ItemLedgEntryNo := 0;
                if QtyToConsumeBase <> 0 then begin
                    case ConversionLine.Type of
                        ConversionLine.Type::Item:
                            ItemLedgEntryNo :=
                              PostItemConsumption(
                                ConversionHeader,
                                ConversionLine,
                                ConversionHeader."Posting No. Series",
                                QtyToConsume,
                                QtyToConsumeBase, ItemJnlPostLine, WhseJnlRegisterLine, ConversionHeader."Posting No.", false, 0);
                    // ConversionLine.Type::Resource:
                    //     PostResourceConsumption(
                    //       ConversionHeader,
                    //       ConversionLine,
                    //       ConversionHeader."Posting No. Series",
                    //       QtyToConsume,
                    //       QtyToConsumeBase, ResJnlPostLine, ItemJnlPostLine, ConversionHeader."Posting No.", false);
                    end;

                    // modify the lines
                    ConversionLine."Consumed Quantity" := ConversionLine."Consumed Quantity" + QtyToConsume;
                    ConversionLine."Consumed Quantity (Base)" := ConversionLine."Consumed Quantity (Base)" + QtyToConsumeBase;
                    // Update Qty. Pick for location with optional warehouse pick.
                    UpdateQtyPickedForOptionalWhsePick(ConversionLine, ConversionLine."Consumed Quantity");
                    ConversionLine.InitRemainingQty();
                    ConversionLine.InitQtyToConsume();
                    // OnBeforeAssemblyLineModify(AssemblyLine, QtyToConsumeBase);
                    ConversionLine.Modify();
                end;

                // Insert posted assembly lines
                PostedConversionLine.Init();
                PostedConversionLine.TransferFields(ConversionLine);
                PostedConversionLine."Document No." := PostedConversionHeader."No.";
                PostedConversionLine.Quantity := QtyToConsume;
                PostedConversionLine."Quantity (Base)" := QtyToConsumeBase;
                PostedConversionLine."Cost Amount" := Round(PostedConversionLine.Quantity * ConversionLine."Unit Cost");
                PostedConversionLine."Order No." := ConversionLine."Document No.";
                PostedConversionLine."Order Line No." := ConversionLine."Line No.";
                InsertLineItemEntryRelation(PostedConversionLine, ItemJnlPostLine, ItemLedgEntryNo);
                // OnBeforePostedAssemblyLineInsert(PostedAssemblyLine, AssemblyLine);
                PostedConversionLine.Insert();
            // OnAfterPostedAssemblyLineInsert(PostedAssemblyLine, AssemblyLine);
            until ConversionLine.Next() = 0;
    end;

    local procedure PostHeader(var ConversionHeader: Record "FA Conversion Header"; var PostedConversionHeader: Record "Posted Conversion Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; NeedUpdateUnitCost: Boolean)
    var
        WhseConversionRelease: Codeunit "Whse.-Conversion Release";
        FAItemLedgEntryNo: Integer;
        QtyToOutput: Decimal;
        QtyToOutputBase: Decimal;
        FAItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
    begin
        // with AssemblyHeader do begin
        GetHeaderQtys(QtyToOutput, QtyToOutputBase, ConversionHeader);
        //     if NeedUpdateUnitCost then
        //         if not IsStandardCostItem() then
        //             UpdateUnitCost();

        //     OnPostHeaderOnBeforePostItemOutput(AssemblyHeader, QtyToOutput, QtyToOutputBase);
        FAItemLedgEntryNo :=
          PostItemOutput(
            ConversionHeader, ConversionHeader."Posting No. Series",
            QtyToOutput, QtyToOutputBase,
            FAItemJnlPostLine, WhseJnlRegisterLine, ConversionHeader."Posting No.", false, 0);
        // OnPostHeaderOnAfterPostItemOutput(AssemblyHeader, QtyToOutput, QtyToOutputBase);

        // modify the header
        ConversionHeader."Converted Quantity" := ConversionHeader."Converted Quantity" + QtyToOutput;
        ConversionHeader."Converted Quantity (Base)" := ConversionHeader."Converted Quantity (Base)" + QtyToOutputBase;
        ConversionHeader.InitRemainingQty();
        ConversionHeader.InitQtyToConvert();
        ConversionHeader.Validate("Quantity to Convert");
        ConversionHeader."Posting No." := '';
        ConversionHeader.Modify();

        WhseConversionRelease.Release(ConversionHeader);

        // modify the posted assembly header
        PostedConversionHeader.Quantity := QtyToOutput;
        PostedConversionHeader."Quantity (Base)" := QtyToOutputBase;
        // PostedConversionHeader."Cost Amount" := Round(PostedConversionHeader.Quantity * "Unit Cost");

        InsertHeaderItemEntryRelation(PostedConversionHeader, FAItemJnlPostLine, FAItemLedgEntryNo);
        PostedConversionHeader.Modify();
        //     OnAfterPostedAssemblyHeaderModify(PostedAssemblyHeader, AssemblyHeader, ItemLedgEntryNo);
        // end;
    end;

    local procedure PostItemConsumption(ConversionHeader: Record "FA Conversion Header"; var ConversionLine: Record "FA Conversion Line"; PostingNoSeries: Code[20]; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer) Result: Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        ConversionLineReserve: Codeunit "Conversion Line-Reserve";
    // IsHandled: Boolean;
    begin
        ConversionLine.TestField(Type, ConversionLine.Type::Item);
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";//"Assembly Consumption";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::" ";//"Posted Assembly";
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine."Document Date" := PostingDate;
        ItemJnlLine."Document Line No." := ConversionLine."Line No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Conversion;//" ";
        ItemJnlLine."Order No." := ConversionLine."Document No.";
        ItemJnlLine."Order Line No." := ConversionLine."Line No.";
        ItemJnlLine."Shortcut Dimension 1 Code" := ConversionLine."Shortcut Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ConversionLine."Shortcut Dimension 2 Code";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Source No." := ConvertedItem."No.";

        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Posting No. Series" := PostingNoSeries;
        ItemJnlLine.Type := ItemJnlLine.Type::" ";
        ItemJnlLine."Item No." := ConversionLine."No.";
        ItemJnlLine."Gen. Prod. Posting Group" := ConversionLine."Gen. Prod. Posting Group";
        ItemJnlLine."Inventory Posting Group" := ConversionLine."Inventory Posting Group";

        ItemJnlLine."Unit of Measure Code" := ConversionLine."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := ConversionLine."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := ConversionLine."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := ConversionLine."Qty. Rounding Precision (Base)";
        ItemJnlLine.Quantity := QtyToConsume;
        ItemJnlLine."Quantity (Base)" := QtyToConsumeBase;
        ItemJnlLine."Variant Code" := ConversionLine."Variant Code";
        ItemJnlLine.Description := ConversionLine.Description;
        ItemJnlLine.Validate("Location Code", ConversionLine."Location Code");
        ItemJnlLine.Validate("Dimension Set ID", ConversionLine."Dimension Set ID");
        ItemJnlLine."Bin Code" := ConversionLine."Bin Code";
        ItemJnlLine."Unit Cost" := ConversionLine."Unit Cost";
        ItemJnlLine.Correction := IsCorrection;
        ItemJnlLine."Applies-to Entry" := ConversionLine."Appl.-to Item Entry";
        UpdateItemCategoryAndGroupCode(ItemJnlLine);

        if IsCorrection then
            PostCorrectionItemJnLine(
              ItemJnlLine, ConversionHeader, ItemJnlPostLine, WhseJnlRegisterLine, DATABASE::"Posted Conversion Line", ApplyToEntryNo)
        else begin
            ConversionLineReserve.TransferConLineToItemJnlLine(ConversionLine, ItemJnlLine, ItemJnlLine."Quantity (Base)", false);
            PostItemJnlLine(ItemJnlLine, ItemJnlPostLine);
            // OnPostItemConsumptionOnAfterPostItemJnlLine(ItemJnlPostLine, AssemblyLine);
            ConversionLineReserve.UpdateItemTrackingAfterPosting(ConversionLine);
            PostWhseJnlLine(ConversionHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
        end;
        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostItemOutput(var ConversionHeader: Record "FA Conversion Header"; PostingNoSeries: Code[20]; QtyToOutput: Decimal; QtyToOutputBase: Decimal; var FAItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; DocumentNo: Code[20]; IsCorrection: Boolean; ApplyToEntryNo: Integer) Result: Integer
    var
        ItemJnlLine: Record "FA Item Journal Line";
        ConversionHeaderReserve: Codeunit "Conversion Header-Reserve";
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Conversion Output";
        ItemJnlLine."Source Code" := SourceCode;
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Posted Assembly";
        ItemJnlLine."Document No." := DocumentNo;
        ItemJnlLine."Document Date" := PostingDate;
        ItemJnlLine."Document Line No." := 0;
        ItemJnlLine."Order No." := ConversionHeader."No.";
        ItemJnlLine."Order Type" := ItemJnlLine."Order Type"::Conversion;
        // ItemJnlLine."Shortcut Dimension 1 Code" := ConversionHeader."Shortcut Dimension 1 Code";
        // ItemJnlLine."Shortcut Dimension 2 Code" := ConversionHeader."Shortcut Dimension 2 Code";
        ItemJnlLine."Order Line No." := 0;
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Source No." := ConvertedItem."No.";

        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Posting No. Series" := PostingNoSeries;
        // ItemJnlLine.Type := ItemJnlLine.Type::" ";
        ItemJnlLine."FA Item No." := ConversionHeader."FA Item No.";
        // ItemJnlLine."Gen. Prod. Posting Group" := ConversionHeader."Gen. Prod. Posting Group";
        // ItemJnlLine."Inventory Posting Group" := ConversionHeader."Inventory Posting Group";

        ItemJnlLine."Unit of Measure Code" := ConversionHeader."Unit of Measure Code";
        ItemJnlLine."Qty. per Unit of Measure" := ConversionHeader."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := ConversionHeader."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := ConversionHeader."Qty. Rounding Precision (Base)";
        ItemJnlLine.Quantity := QtyToOutput;
        ItemJnlLine."Invoiced Quantity" := QtyToOutput;
        ItemJnlLine."Quantity (Base)" := QtyToOutputBase;
        ItemJnlLine."Invoiced Qty. (Base)" := QtyToOutputBase;
        ItemJnlLine."Variant Code" := ConversionHeader."Variant Code";
        ItemJnlLine.Description := ConversionHeader.Description;
        ItemJnlLine.Validate("Location Code", ConversionHeader."Location Code");
        // ItemJnlLine.Validate("Dimension Set ID", ConversionHeader."Dimension Set ID");
        ItemJnlLine."Bin Code" := ConversionHeader."Bin Code";
        // ItemJnlLine."Indirect Cost %" := "Indirect Cost %";
        // ItemJnlLine."Overhead Rate" := "Overhead Rate";
        // ItemJnlLine."Unit Cost" := "Unit Cost";
        // ItemJnlLine.Validate("Unit Amount",
        //   Round(("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100),
        //     GLSetup."Unit-Amount Rounding Precision"));
        ItemJnlLine.Correction := IsCorrection;
        // UpdateItemCategoryAndGroupCode(ItemJnlLine);

        if IsCorrection then
            PostCorrectionFAItemJnLine(
              ItemJnlLine, ConversionHeader, FAItemJnlPostLine, WhseJnlRegisterLine, DATABASE::"Posted Conversion Header", ApplyToEntryNo)
        else begin
            ConversionHeaderReserve.TransferConHeaderToItemJnlLine(ConversionHeader, ItemJnlLine, ItemJnlLine."Quantity (Base)", false);
            PostFAItemJnlLine(ItemJnlLine, FAItemJnlPostLine);
            ConversionHeaderReserve.UpdateItemTrackingAfterPosting(ConversionHeader);
            // PostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
        end;
        exit(ItemJnlLine."Item Shpt. Entry No.");
    end;

    local procedure PostFAItemJnlLine(var FAItemJnlLine: Record "FA Item Journal Line"; FAItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line")
    var
        OrigFAItemJnlLine: Record "FA Item Journal Line";
        FAItemShptEntry: Integer;
    begin
        OrigFAItemJnlLine := FAItemJnlLine;
        FAItemJnlPostLine.RunWithCheck(FAItemJnlLine);
        FAItemShptEntry := FAItemJnlLine."Item Shpt. Entry No.";
        FAItemJnlLine := OrigFAItemJnlLine;
        FAItemJnlLine."Item Shpt. Entry No." := FAItemShptEntry;
    end;

    local procedure UpdateItemCategoryAndGroupCode(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        ItemJnlLine."Item Category Code" := Item."Item Category Code";
    end;

    local procedure PostItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line")
    var
        OrigItemJnlLine: Record "Item Journal Line";
        ItemShptEntry: Integer;
    begin
        OrigItemJnlLine := ItemJnlLine;
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        ItemShptEntry := ItemJnlLine."Item Shpt. Entry No.";
        ItemJnlLine := OrigItemJnlLine;
        ItemJnlLine."Item Shpt. Entry No." := ItemShptEntry;
    end;

    local procedure PostCorrectionItemJnLine(var ItemJnlLine: Record "Item Journal Line"; ConversionHeader: Record "FA Conversion Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; SourceType: Integer; ApplyToEntry: Integer)
    var
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
        //     ATOLink: Record "Assemble-to-Order Link";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
        ItemApplnEntry: Record "Item Application Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        EntriesExist: Boolean;
    begin
        MSUndoPostingMgt.CollectItemLedgEntries(
          TempItemLedgEntry2, SourceType, ItemJnlLine."Document No.", ItemJnlLine."Document Line No.",
          Abs(ItemJnlLine."Quantity (Base)"), ApplyToEntry);

        if TempItemLedgEntry2.FindSet() then
            repeat
                TempItemLedgEntry2."Expiration Date" :=
                  ItemTrackingMgt.ExistingExpirationDate(TempItemLedgEntry2, false, EntriesExist);
                TempItemLedgEntry := TempItemLedgEntry2;
                TempItemLedgEntry.Insert();

                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt." then begin
                    ItemJnlLine.Quantity :=
                      Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    ItemJnlLine."Quantity (Base)" := TempItemLedgEntry.Quantity;

                    ItemJnlLine."Applies-from Entry" := TempItemLedgEntry."Entry No.";
                end else begin
                    ItemJnlLine.Quantity :=
                      -Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    ItemJnlLine."Quantity (Base)" := -TempItemLedgEntry.Quantity;

                    // if (ItemJnlLine."Order Type" = ItemJnlLine."Order Type"::Assembly) and
                    //    ATOLink.Get(ATOLink."Assembly Document Type"::Order, ItemJnlLine."Order No.")
                    // then begin
                    //     TempItemLedgEntryInChain.Reset();
                    //     TempItemLedgEntryInChain.DeleteAll();
                    //     ItemApplnEntry.GetVisitedEntries(TempItemLedgEntry, TempItemLedgEntryInChain, true);

                    //     ItemJnlLine."Applies-to Entry" := FindAppliesToATOUndoEntry(TempItemLedgEntryInChain);
                    // end else
                    ItemJnlLine."Applies-to Entry" := TempItemLedgEntry."Entry No.";
                end;
                ItemJnlLine."Invoiced Quantity" := ItemJnlLine.Quantity;
                ItemJnlLine."Invoiced Qty. (Base)" := ItemJnlLine."Quantity (Base)";

                ItemJnlLine.CopyTrackingFromItemLedgEntry(TempItemLedgEntry);
                ItemJnlLine."Warranty Date" := TempItemLedgEntry."Warranty Date";
                ItemJnlLine."Item Expiration Date" := TempItemLedgEntry."Expiration Date";
                ItemJnlLine."Item Shpt. Entry No." := 0;

                // OnBeforePostCorrectionItemJnLine(ItemJnlLine, TempItemLedgEntry);

                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                PostWhseJnlLine(ConversionHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
            until TempItemLedgEntry2.Next() = 0;
    end;

    local procedure PostCorrectionFAItemJnLine(var ItemJnlLine: Record "FA Item Journal Line"; ConversionHeader: Record "FA Conversion Header";
                var ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line"; SourceType: Integer; ApplyToEntry: Integer)
    var
        TempFAItemLedgEntry2: Record "FA Item ledger Entry" temporary;
        TempItemLedgEntryInChain: Record "FA Item Ledger Entry" temporary;
        ItemApplnEntry: Record "FA Item Application Entry";
    begin
        TSTUndoPostingMgt.CollectItemLedgEntries(
                  TempFAItemLedgEntry2, SourceType, ItemJnlLine."Document No.", ItemJnlLine."Document Line No.",
                  Abs(ItemJnlLine."Quantity (Base)"), ApplyToEntry);

        if TempFAItemLedgEntry2.FindSet() then
            repeat
                // TempFAItemLedgEntry2."Expiration Date" :=
                //       ItemTrackingMgt.ExistingExpirationDate(TempFAItemLedgEntry2, false, EntriesExist);
                TempFAItemLedgEntry := TempFAItemLedgEntry2;
                TempFAItemLedgEntry.Insert();

                // if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Assembly Consumption" then begin
                //     ItemJnlLine.Quantity :=
                //       Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                //     ItemJnlLine."Quantity (Base)" := TempItemLedgEntry.Quantity;

                //     ItemJnlLine."Applies-from Entry" := TempItemLedgEntry."Entry No.";
                // end else 
                begin
                    ItemJnlLine.Quantity :=
                      -Round(TempItemLedgEntry.Quantity * TempItemLedgEntry."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    ItemJnlLine."Quantity (Base)" := -TempItemLedgEntry.Quantity;

                    // if (ItemJnlLine."Order Type" = ItemJnlLine."Order Type"::Assembly) and
                    //    ATOLink.Get(ATOLink."Assembly Document Type"::Order, ItemJnlLine."Order No.")
                    // then begin
                    //     TempItemLedgEntryInChain.Reset();
                    //     TempItemLedgEntryInChain.DeleteAll();
                    //     ItemApplnEntry.GetVisitedEntries(TempFAItemLedgEntry, TempItemLedgEntryInChain, true);

                    //     ItemJnlLine."Applies-to Entry" := FindAppliesToATOUndoEntry(TempItemLedgEntryInChain);
                    // end else
                    ItemJnlLine."Applies-to Entry" := TempItemLedgEntry."Entry No.";
                end;
                ItemJnlLine."Invoiced Quantity" := ItemJnlLine.Quantity;
                ItemJnlLine."Invoiced Qty. (Base)" := ItemJnlLine."Quantity (Base)";

                ItemJnlLine.CopyTrackingFromItemLedgEntry(TempFAItemLedgEntry);
                // ItemJnlLine."Warranty Date" := TempItemLedgEntry."Warranty Date";
                // ItemJnlLine."Item Expiration Date" := TempItemLedgEntry."Expiration Date";
                ItemJnlLine."Item Shpt. Entry No." := 0;

                // OnBeforePostCorrectionItemJnLine(ItemJnlLine, TempItemLedgEntry);

                ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            // PostWhseJnlLine(ConversionHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine);
            until TempFAItemLedgEntry2.Next() = 0;
    end;

    local procedure GetLocation(LocationCode: Code[10]; var Location: Record Location)
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure PostWhseJnlLine(ConversionHeader: Record "FA Conversion Header"; ItemJnlLine: Record "Item Journal Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        Location: Record Location;
        Item: Record Item;
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempWhseJnlLine2: Record "Warehouse Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        if Item.Get(ItemJnlLine."Item No.") then
            if Item.IsNonInventoriableType() then
                exit;

        // IsHandled := false;
        // OnBeforePostWhseJnlLine(AssemblyHeader, ItemJnlLine, ItemJnlPostLine, WhseJnlRegisterLine, Location, SourceCode, IsHandled);
        // if IsHandled then
        //     exit;

        GetLocation(ItemJnlLine."Location Code", Location);
        if not Location."Bin Mandatory" then
            exit;

        // IsHandled := false;
        // OnPostWhseJnlLineOnBeforeGetWhseItemTrkgSetup(ItemJnlLine, IsHandled);
        // if not IsHandled then
        if ItemTrackingMgt.GetWhseItemTrkgSetup(ItemJnlLine."Item No.") then
            if ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification) then
                if TempTrackingSpecification.FindSet() then
                    repeat
                        // case ItemJnlLine."Entry Type" of
                        //     ItemJnlLine."Entry Type"::"Assembly Consumption":
                        TempTrackingSpecification."Source Type" := DATABASE::"FA Conversion Line";
                        // ItemJnlLine."Entry Type"::"Assembly Output":
                        //     TempTrackingSpecification."Source Type" := DATABASE::"Assembly Header";
                        // end;
                        TempTrackingSpecification."Source Subtype" := 0;//ConversionHeader."Document Type".AsInteger();
                        TempTrackingSpecification."Source ID" := ConversionHeader."No.";
                        TempTrackingSpecification."Source Batch Name" := '';
                        TempTrackingSpecification."Source Prod. Order Line" := 0;
                        TempTrackingSpecification."Source Ref. No." := ItemJnlLine."Order Line No.";
                        TempTrackingSpecification.Modify();
                    until TempTrackingSpecification.Next() = 0;

        CreateWhseJnlLine(Location, TempWhseJnlLine, ConversionHeader, ItemJnlLine);
        ItemTrackingMgt.SplitWhseJnlLine(TempWhseJnlLine, TempWhseJnlLine2, TempTrackingSpecification, false);
        if TempWhseJnlLine2.FindSet() then
            repeat
                WhseJnlRegisterLine.Run(TempWhseJnlLine2);
            until TempWhseJnlLine2.Next() = 0;
    end;

    local procedure CreateWhseJnlLine(Location: Record Location; var WhseJnlLine: Record "Warehouse Journal Line"; ConversionHeader: Record "FA Conversion Header"; ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        WhseMgt: Codeunit "Whse. Management";
        isHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCreateWhseJnlLine(Location, WhseJnlLine, AssemblyHeader, ItemJnlLine, IsHandled);
        // if not IsHandled then
        //     with ItemJnlLine do begin
        // case ItemJnlLine."Entry Type" of
        //     ItemJnlLine."Entry Type"::"Assembly Consumption":
        WMSManagement.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
        //     ItemJnlLine."Entry Type"::"Assembly Output":
        //         WMSManagement.CheckAdjmtBin(Location, ItemJnlLine.Quantity, false);
        // end;

        WMSManagement.CreateWhseJnlLine(ItemJnlLine, 0, WhseJnlLine, false);

        // case ItemJnlLine."Entry Type" of
        //     ItemJnlLine."Entry Type"::"Assembly Consumption":
        WhseJnlLine."Source Type" := DATABASE::"FA Conversion Line";
        //     ItemJnlLine."Entry Type"::"Assembly Output":
        //         WhseJnlLine."Source Type" := DATABASE::"Assembly Header";
        // end;
        WhseJnlLine."Source Subtype" := 0;//AssemblyHeader."Document Type".AsInteger();
        WhseJnlLine."Source Code" := SourceCode;
        WhseJnlLine."Source Document" := WhseMgt.GetWhseJnlSourceDocument(WhseJnlLine."Source Type", WhseJnlLine."Source Subtype");
        // TestField("Order Type", "Order Type"::Assembly);
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Conversion);
        WhseJnlLine."Source No." := ItemJnlLine."Order No.";
        WhseJnlLine."Source Line No." := ItemJnlLine."Order Line No.";
        WhseJnlLine."Reason Code" := ItemJnlLine."Reason Code";
        WhseJnlLine."Registering No. Series" := ItemJnlLine."Posting No. Series";
        WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";//Assembly;
        WhseJnlLine."Whse. Document No." := ItemJnlLine."Order No.";
        WhseJnlLine."Whse. Document Line No." := ItemJnlLine."Order Line No.";
        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::" ";//Assembly;
        WhseJnlLine."Reference No." := ItemJnlLine."Document No.";
        if Location."Directed Put-away and Pick" then
            WMSManagement.CalcCubageAndWeight(
              ItemJnlLine."Item No.", ItemJnlLine."Unit of Measure Code", WhseJnlLine."Qty. (Absolute)",
              WhseJnlLine.Cubage, WhseJnlLine.Weight);
        //     end;
        // OnAfterCreateWhseJnlLineFromItemJnlLine(WhseJnlLine, ItemJnlLine);
        CheckWhseJnlLine(WhseJnlLine, ItemJnlLine);
    end;

    local procedure CheckWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line"; ItemJnlLine: Record "Item Journal Line")
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckWhseJnlLine(WhseJnlLine, ItemJnlLine, IsHandled);
        // if IsHandled then
        //     exit;

        WMSManagement.CheckWhseJnlLine(WhseJnlLine, 0, 0, false);
    end;

    local procedure GetSourceCode()//IsATO: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        // if IsATO then
        //     SourceCode := SourceCodeSetup.Sales
        // else
        SourceCode := SourceCodeSetup."FA Conversion";
    end;

    local procedure MakeInvtAdjmt()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
    end;

    local procedure DeleteWhseRequest(ConversionHeader: Record "FA Conversion Header")
    var
        WhseRqst: Record "Warehouse Request";
    begin
        // with WhseRqst do begin
        WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseRqst.SetRange("Source Type", DATABASE::"FA Conversion Line");
        WhseRqst.SetRange("Source Subtype", 0);//AssemblyHeader."Document Type");
        WhseRqst.SetRange("Source No.", ConversionHeader."No.");
        if not WhseRqst.IsEmpty() then
            WhseRqst.DeleteAll(true);
        // end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Posting To G/L", OnBeforeSetAccNo, '', false, false)]
#pragma warning disable AL0432
    local procedure OnBeforeSetAccNo(AccType: Option; BalAccType: Option; CalledFromItemPosting: Boolean; ValueEntry: Record "Value Entry"; var InvtPostBuf: Record "Invt. Posting Buffer"; var IsHandled: Boolean)
#pragma warning restore AL0432
    var
        ConversionSetup: Record "FA Conversion Setup";
    begin
        GetSourceCode();
        if ValueEntry."Source Code" = SourceCode then begin
            ConversionSetup.Get();
            case InvtPostBuf."Account Type" of
                "Invt. Posting Buffer Account Type"::"Inventory Adjmt.":
                    begin
                        if CalledFromItemPosting then
                            InvtPostBuf."Account No." := ConversionSetup."Inventory Adjmt. Account"//GenPostingSetup.GetInventoryAdjmtAccount()
                        else
                            InvtPostBuf."Account No." := '';//GenPostingSetup."Inventory Adjmt. Account";
                        IsHandled := true;
                    end;
            end;
        end else
            if ValueEntry."Order Type" = ValueEntry."Order Type"::Conversion then begin
                ConversionSetup.Get();
                case InvtPostBuf."Account Type" of
                    "Invt. Posting Buffer Account Type"::"Inventory Adjmt.":
                        begin
                            if CalledFromItemPosting then
                                InvtPostBuf."Account No." := ConversionSetup."Inventory Adjmt. Account"//GenPostingSetup.GetInventoryAdjmtAccount()
                            else
                                InvtPostBuf."Account No." := '';//GenPostingSetup."Inventory Adjmt. Account";
                            IsHandled := true;
                        end;
                end;
            end;
    end;

    local procedure UpdateQtyPickedForOptionalWhsePick(var ConversionLine: Record "FA Conversion Line"; QtyPosted: Decimal)
    var
        Location: Record Location;
    begin
        GetLocation(ConversionLine."Location Code", Location);
        if not (Location."Require Pick" and Location."Require Shipment") then
            if ConversionLine."Qty. Picked" < QtyPosted then
                ConversionLine.Validate("Qty. Picked", QtyPosted);
    end;

    local procedure InsertLineItemEntryRelation(var PostedConversionLine: Record "Posted Conversion Line"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; ItemLedgEntryNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
    begin
        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    // ItemEntryRelation.TransferFieldsPostedAsmLine(PostedAssemblyLine);
                    ItemEntryRelation.SetSource(DATABASE::"Posted Conversion Line", 0, PostedConversionLine."Document No.", PostedConversionLine."Line No.");
                    ItemEntryRelation.SetOrderInfo(PostedConversionLine."Order No.", PostedConversionLine."Order Line No.");
                    ItemEntryRelation.Insert();
                until TempItemEntryRelation.Next() = 0;
        end else
            PostedConversionLine."Item Shpt. Entry No." := ItemLedgEntryNo;
    end;

    local procedure InsertHeaderItemEntryRelation(var PostedConversionHeader: Record "Posted Conversion Header"; var ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line"; ItemLedgEntryNo: Integer)
    var
        ItemEntryRelation: Record "FA Item Entry Relation";
        TempItemEntryRelation: Record "FA Item Entry Relation" temporary;
    begin
        if ItemJnlPostLine.CollectItemEntryRelation(TempItemEntryRelation) then begin
            if TempItemEntryRelation.Find('-') then
                repeat
                    ItemEntryRelation := TempItemEntryRelation;
                    ItemEntryRelation.TransferFieldsPostedConHeader(PostedConversionHeader);
                    ItemEntryRelation.Insert();
                // OnInsertHeaderItemEntryRelationOnAfterInsertItemEntryRelation(ItemEntryRelation, PostedAssemblyHeader);
                until TempItemEntryRelation.Next() = 0;
        end else
            PostedConversionHeader."Item Rcpt. Entry No." := ItemLedgEntryNo;
    end;

    procedure Undo(var PostedConHeader: Record "Posted Conversion Header"; RecreateConOrder: Boolean)
    var
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
    begin
        ClearAll();

        Window.Open(
          '#1#################################\\' +
          Text007 + '\\' +
          StrSubstNo(Text010, PostedConHeader."No."));

        ShowProgress := true;
        Window.Update(1, StrSubstNo('%1 %2', PostedConHeader.TableCaption(), PostedConHeader."No."));

        // PostedConHeader.CheckIsNotAsmToOrder();

        UndoInitPost(PostedConHeader);
        UndoPost(PostedConHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);
        UndoFinalizePost(PostedConHeader, RecreateConOrder);

        if not (SuppressCommit or PreviewMode) then
            Commit();

        Window.Close();
    end;

    local procedure UndoInitPost(var PostedConHeader: Record "Posted Conversion Header")
    begin
        // with PostedAsmHeader do begin
        PostingDate := PostedConHeader."Posting Date";

        CheckPossibleToUndo(PostedConHeader);

        GetSourceCode();//IsAsmToOrder());

        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();
        // end;

        // OnAfterUndoInitPost(PostedAsmHeader);
    end;

    local procedure UndoFinalizePost(var PostedConHeader: Record "Posted Conversion Header"; RecreateAsmOrder: Boolean)
    var
        ConHeader: Record "FA Conversion Header";
    begin
        MakeInvtAdjmt();

        if ConHeader.Get(PostedConHeader."Order No.") then
            UpdateAsmOrderWithUndo(PostedConHeader)
        // else
        //     if RecreateAsmOrder then
        //         RecreateAsmOrderWithUndo(PostedConHeader);
    end;

    local procedure UndoPost(var PostedConHeader: Record "Posted Conversion Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        FAItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line";
    begin
        ConvertedItem.Get(PostedConHeader."FA Item No.");
        UndoPostHeader(PostedConHeader, FAItemJnlPostLine, WhseJnlRegisterLine);
        UndoPostLines(PostedConHeader, ItemJnlPostLine, ResJnlPostLine, WhseJnlRegisterLine);

        // OnAfterUndoPost(PostedAsmHeader, SuppressCommit);
    end;

    local procedure UndoPostLines(PostedConHeader: Record "Posted Conversion Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        PostedConLine: Record "Posted Conversion Line";
        ConHeader: Record "FA Conversion Header";
        ConLine: Record "FA Conversion Line";
        LineCounter: Integer;
    begin
        ConHeader.TransferFields(PostedConHeader);
        // AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        ConHeader."No." := PostedConHeader."Order No.";

        // with PostedConLine do begin
        PostedConLine.Reset();
        PostedConLine.SetRange("Document No.", PostedConHeader."No.");
        // OnUndoPostLinesOnBeforeSortPostedLines(PostedAsmHeader, PostedAsmLine);
        SortPostedLines(PostedConLine);

        LineCounter := 0;
        if PostedConLine.FindSet() then
            repeat
                ConLine.TransferFields(PostedConLine);
                // OnUndoPostLinesOnAfterTransferFields(AsmLine, AsmHeader, PostedAsmHeader);
                // AsmLine."Document Type" := AsmHeader."Document Type"::Order;
                ConLine."Document No." := PostedConHeader."Order No.";

                LineCounter := LineCounter + 1;
                if ShowProgress then
                    Window.Update(2, LineCounter);

                if PostedConLine."Quantity (Base)" <> 0 then begin
                    case PostedConLine.Type of
                        PostedConLine.Type::Item:
                            PostItemConsumption(
                              ConHeader,
                              ConLine,
                              PostedConHeader."No. Series",
                              -PostedConLine.Quantity,
                              -PostedConLine."Quantity (Base)", ItemJnlPostLine, WhseJnlRegisterLine, PostedConLine."Document No.", true,
                              PostedConLine."Item Shpt. Entry No.");
                    // Type::Resource:
                    //     PostResourceConsumption(
                    //       AsmHeader,
                    //       AsmLine,
                    //       PostedAsmHeader."No. Series",
                    //       -Quantity,
                    //       -"Quantity (Base)",
                    //       ResJnlPostLine, ItemJnlPostLine, "Document No.", true);
                    end;
                    InsertLineItemEntryRelation(PostedConLine, ItemJnlPostLine, 0);

                    PostedConLine.Modify();
                end;
            until PostedConLine.Next() = 0;
        // end;
    end;

    local procedure UndoPostHeader(var PostedConHeader: Record "Posted Conversion Header"; var ItemJnlPostLine: Codeunit "FA Item Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        ConHeader: Record "FA Conversion Header";
    begin
        // with PostedConHeader do begin
        ConHeader.TransferFields(PostedConHeader);
        // OnUndoPostHeaderOnAfterTransferFields(ConHeader, PostedConHeader);
        // ConHeader."Document Type" := ConHeader."Document Type"::Order;
        ConHeader."No." := PostedConHeader."Order No.";

        PostItemOutput(
          ConHeader, PostedConHeader."No. Series", -PostedConHeader.Quantity, -PostedConHeader."Quantity (Base)", ItemJnlPostLine, WhseJnlRegisterLine, PostedConHeader."No.", true, PostedConHeader."Item Rcpt. Entry No.");
        InsertHeaderItemEntryRelation(PostedConHeader, ItemJnlPostLine, 0);

        PostedConHeader.Reversed := true;
        PostedConHeader.Modify();
        // end;
    end;

    // local procedure SumCapQtyPosted(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    // var
    //     CapLedgEntry: Record "Capacity Ledger Entry";
    // begin
    //     with CapLedgEntry do begin
    //         SetCurrentKey("Order Type", "Order No.", "Order Line No.");
    //         SetRange("Order Type", "Order Type"::Assembly);
    //         SetRange("Order No.", OrderNo);
    //         SetRange("Order Line No.", OrderLineNo);
    //         CalcSums(Quantity);
    //         exit(Quantity);
    //     end;
    // end;

    // local procedure SumItemQtyPosted(OrderNo: Code[20]; OrderLineNo: Integer): Decimal
    // var
    //     ItemLedgEntry: Record "Item Ledger Entry";
    // begin
    //     with ItemLedgEntry do begin
    //         SetCurrentKey("Order Type", "Order No.", "Order Line No.");
    //         SetRange("Order Type", "Order Type"::Assembly);
    //         SetRange("Order No.", OrderNo);
    //         SetRange("Order Line No.", OrderLineNo);
    //         CalcSums(Quantity);
    //         exit(Quantity);
    //     end;
    // end;

    local procedure UpdateAsmOrderWithUndo(var PostedConHeader: Record "Posted Conversion Header")
    var
        ConHeader: Record "FA Conversion Header";
        ConLine: Record "FA Conversion Line";
        PostedConLine: Record "Posted Conversion Line";
    begin
        // with ConHeader do begin
        ConHeader.Get(PostedConHeader."Order No.");
        ConHeader."Converted Quantity" -= PostedConHeader.Quantity;
        ConHeader."Converted Quantity (Base)" -= PostedConHeader."Quantity (Base)";
        ConHeader."Converted Quantity (Base)" -= PostedConHeader."Quantity (Base)";
        ConHeader.InitRemainingQty();
        ConHeader.InitQtyToConvert();
        ConHeader.Modify();

        RestoreItemTracking(TempItemLedgEntry, ConHeader."No.", 0, DATABASE::"FA Conversion Header", 0, ConHeader."Due Date", 0D);
        VerifyConHeaderReservAfterUndo(ConHeader);
        // end;

        PostedConLine.SetRange("Document No.", PostedConHeader."No.");
        PostedConLine.SetFilter("Quantity (Base)", '<>0');
        if PostedConLine.FindSet() then
            repeat
                // with ConLine do begin
                ConLine.Get(ConHeader."No.", PostedConLine."Line No.");
                ConLine."Consumed Quantity" -= PostedConLine.Quantity;
                ConLine."Consumed Quantity (Base)" -= PostedConLine."Quantity (Base)";
                if ConLine."Qty. Picked (Base)" <> 0 then begin
                    ConLine."Qty. Picked" -= PostedConLine.Quantity;
                    ConLine."Qty. Picked (Base)" -= PostedConLine."Quantity (Base)";
                end;

                ConLine.InitRemainingQty();
                ConLine.InitQtyToConsume();
                ConLine.Modify();

                RestoreItemTracking(TempItemLedgEntry, ConLine."Document No.", ConLine."Line No.", DATABASE::"FA Conversion Line", 0, 0D, ConLine."Due Date");
                VerifyConLineReservAfterUndo(ConLine);
            // end;
            until PostedConLine.Next() = 0;

        // OnAfterUpdateAsmOrderWithUndo(PostedAsmHeader, AsmHeader);
    end;

    // local procedure RecreateConOrderWithUndo(var PostedConHeader: Record "Posted Conversion Header")
    // var
    //     AsmHeader: Record "Assembly Header";
    //     AsmLine: Record "Assembly Line";
    //     PostedAsmLine: Record "Posted Assembly Line";
    //     AsmCommentLine: Record "Assembly Comment Line";
    // begin
    //     with AsmHeader do begin
    //         Init();
    //         TransferFields(PostedAsmHeader);
    //         "Document Type" := "Document Type"::Order;
    //         "No." := PostedAsmHeader."Order No.";

    //         "Assembled Quantity (Base)" := SumItemQtyPosted("No.", 0);
    //         "Assembled Quantity" := Round("Assembled Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
    //         Quantity := PostedAsmHeader.Quantity + "Assembled Quantity";
    //         "Quantity (Base)" := PostedAsmHeader."Quantity (Base)" + "Assembled Quantity (Base)";
    //         InitRemainingQty();
    //         InitQtyToAssemble();

    //         OnBeforeRecreatedAsmHeaderInsert(AsmHeader, PostedAsmHeader);
    //         Insert();

    //         CopyCommentLines(
    //           AsmCommentLine."Document Type"::"Posted Assembly", "Document Type",
    //           PostedAsmHeader."No.", "No.");

    //         RestoreItemTracking(TempItemLedgEntry, "No.", 0, DATABASE::"Assembly Header", "Document Type".AsInteger(), "Due Date", 0D);
    //         VerifyAsmHeaderReservAfterUndo(AsmHeader);
    //     end;

    //     PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
    //     if PostedAsmLine.FindSet() then
    //         repeat
    //             with AsmLine do begin
    //                 Init();
    //                 TransferFields(PostedAsmLine);
    //                 "Document Type" := "Document Type"::Order;
    //                 "Document No." := PostedAsmLine."Order No.";
    //                 "Line No." := PostedAsmLine."Order Line No.";

    //                 if PostedAsmLine."Quantity (Base)" <> 0 then begin
    //                     if Type = Type::Item then
    //                         "Consumed Quantity (Base)" := -SumItemQtyPosted("Document No.", "Line No.")
    //                     else
    //                         "Consumed Quantity (Base)" := SumCapQtyPosted("Document No.", "Line No.");

    //                     "Consumed Quantity" := Round("Consumed Quantity (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
    //                     Quantity := PostedAsmLine.Quantity + "Consumed Quantity";
    //                     "Quantity (Base)" := PostedAsmLine."Quantity (Base)" + "Consumed Quantity (Base)";
    //                     "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
    //                     if Type = Type::Item then begin
    //                         "Qty. Picked" := "Consumed Quantity";
    //                         "Qty. Picked (Base)" := "Consumed Quantity (Base)";
    //                     end;
    //                     InitRemainingQty();
    //                     InitQtyToConsume();
    //                 end;
    //                 Insert();

    //                 RestoreItemTracking(TempItemLedgEntry, "Document No.", "Line No.", DATABASE::"Assembly Line", "Document Type".AsInteger(), 0D, "Due Date");
    //                 VerifyAsmLineReservAfterUndo(AsmLine);
    //             end;
    //         until PostedAsmLine.Next() = 0;

    //     OnAfterRecreateAsmOrderWithUndo(PostedAsmHeader, AsmHeader);
    // end;

    local procedure VerifyConHeaderReservAfterUndo(var ConHeader: Record "FA Conversion Header")
    var
        xConHeader: Record "FA Conversion Header";
        ConHeaderReserve: Codeunit "Conversion Header-Reserve";
    begin
        xConHeader := ConHeader;
        xConHeader."Quantity (Base)" := 0;
        ConHeaderReserve.VerifyQuantity(ConHeader, xConHeader);
    end;

    local procedure VerifyConLineReservAfterUndo(var ConLine: Record "FA Conversion Line")
    var
        xConLine: Record "FA Conversion Line";
        ConLineReserve: Codeunit "Conversion Line-Reserve";
    begin
        xConLine := ConLine;
        xConLine."Quantity (Base)" := 0;
        ConLineReserve.VerifyQuantity(ConLine, xConLine);
    end;

    local procedure CheckPossibleToUndo(PostedConHeader: Record "Posted Conversion Header"): Boolean
    var
        ConHeader: Record "FA Conversion Header";
        PostedConLine: Record "Posted Conversion Line";
        ConLine: Record "FA Conversion Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempFAItemLedgEntry: Record "FA Item ledger Entry" temporary;
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeCheckPossibleToUndo(PostedAsmHeader, IsHandled);
        //     if IsHandled then
        //         exit;

        //     with PostedAsmHeader do begin
        PostedConHeader.TestField(Reversed, false);
        TSTUndoPostingMgt.TestConHeader(PostedConHeader);
        TSTUndoPostingMgt.CollectItemLedgEntries(
          TempFAItemLedgEntry, DATABASE::"Posted Conversion Header", PostedConHeader."No.", 0, PostedConHeader."Quantity (Base)", PostedConHeader."Item Rcpt. Entry No.");
        TSTUndoPostingMgt.CheckItemLedgEntries(TempFAItemLedgEntry, 0);
        //     end;

        //     with PostedAsmLine do begin
        PostedConLine.SetRange("Document No.", PostedConHeader."No.");
        repeat
            if (PostedConLine.Type = PostedConLine.Type::Item) and (PostedConLine."Item Shpt. Entry No." <> 0) then begin
                TSTUndoPostingMgt.TestConLine(PostedConLine);
                MSUndoPostingMgt.CollectItemLedgEntries(
                  TempItemLedgEntry, DATABASE::"Posted Conversion Line", PostedConLine."Document No.", PostedConLine."Line No.", PostedConLine."Quantity (Base)", PostedConLine."Item Shpt. Entry No.");
                MSUndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, PostedConLine."Line No.");
            end;
        until PostedConLine.Next() = 0;
        // end;

        if not ConHeader.Get(PostedConHeader."Order No.") then
            exit(true);

        //     with AsmHeader do begin
        ConHeader.TestField("Variant Code", PostedConHeader."Variant Code");
        ConHeader.TestField("Location Code", PostedConHeader."Location Code");
        // ConHeader.TestField("Bin Code", PostedConHeader."Bin Code");
        //     end;

        // with ConLine do begin
        // SetRange("Document Type", ConHeader."Document Type");
        ConLine.SetRange("Document No.", ConHeader."No.");

        if PostedConLine.Count <> ConLine.Count then
            Error(Text011, PostedConHeader."No.", ConHeader."No.");

        ConLine.FindSet();
        PostedConLine.FindSet();
        repeat
            ConLine.TestField(Type, PostedConLine.Type);
            ConLine.TestField("No.", PostedConLine."No.");
            ConLine.TestField("Variant Code", PostedConLine."Variant Code");
            ConLine.TestField("Location Code", PostedConLine."Location Code");
            ConLine.TestField("Bin Code", PostedConLine."Bin Code");
        until (PostedConLine.Next() = 0) and (ConLine.Next() = 0);
        // end;
    end;

    local procedure RestoreItemTracking(var ItemLedgEntry: Record "Item Ledger Entry"; OrderNo: Code[20]; OrderLineNo: Integer; SourceType: Integer; DocType: Option; RcptDate: Date; ShptDate: Date)
    var
        ConHeader: Record "FA Conversion Header";
        ReservEntry: Record "Reservation Entry";
        // ATOLink: Record "Assemble-to-Order Link";
        // SalesLine: Record "Sales Line";
        FromTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        // IsATOHeader: Boolean;
        ReservStatus: Enum "Reservation Status";
    // IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeRestoreItemTracking(ItemLedgEntry, OrderNo, OrderLineNo, SourceType, DocType, RcptDate, ShptDate, IsHandled);
        //     if not IsHandled then
        // with ItemLedgEntry do begin
        ConHeader.Get(OrderNo);
        // IsATOHeader := (OrderLineNo = 0) and ConHeader.IsConToOrder();

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Assembly);
        ItemLedgEntry.SetRange("Order No.", OrderNo);
        ItemLedgEntry.SetRange("Order Line No.", OrderLineNo);
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry.TrackingExists() then begin
                    CreateReservEntry.SetDates(ItemLedgEntry."Warranty Date", ItemLedgEntry."Expiration Date");
                    CreateReservEntry.SetQtyToHandleAndInvoice(ItemLedgEntry.Quantity, ItemLedgEntry.Quantity);
                    CreateReservEntry.SetItemLedgEntryNo(ItemLedgEntry."Entry No.");
                    ReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                    CreateReservEntry.CreateReservEntryFor(
                      SourceType, DocType, ItemLedgEntry."Order No.", '', 0, ItemLedgEntry."Order Line No.",
                      ItemLedgEntry."Qty. per Unit of Measure", 0, Abs(ItemLedgEntry.Quantity), ReservEntry);

                    // if IsATOHeader then begin
                    //     ATOLink.Get(ConHeader."Document Type", ConHeader."No.");
                    //     ATOLink.TestField(Type, ATOLink.Type::Sale);
                    //     SalesLine.Get(ATOLink."Document Type", ATOLink."Document No.", ATOLink."Document Line No.");

                    //     CreateReservEntry.SetDisallowCancellation(true);
                    //     CreateReservEntry.SetBinding("Reservation Binding"::"Order-to-Order");

                    //     FromTrackingSpecification.InitFromSalesLine(SalesLine);
                    //     FromTrackingSpecification."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
                    //     FromTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                    //     CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
                    //     ReservStatus := ReservStatus::Reservation;
                    // end else
                    ReservStatus := ReservStatus::Surplus;
                    CreateReservEntry.CreateEntry(
                      ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code", ItemLedgEntry."Location Code", '', RcptDate, ShptDate, 0, ReservStatus);
                end;
            until ItemLedgEntry.Next() = 0;
        ItemLedgEntry.DeleteAll();
        // end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnItemQtyPostingOnAfterInsertTransferEntry, '', false, false)]
    local procedure OnItemQtyPostingOnAfterInsertTransferEntry(var ItemJnlLine: Record "Item Journal Line"; GlobalItemLedgEntry: Record "Item Ledger Entry";
                var TempItemEntryRelation: Record "Item Entry Relation")
    begin
        GetSourceCode();
        if (ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::"Negative Adjmt."]) and (ItemJnlLine."Source Code" = SourceCode) then
            InsertConItemEntryRelation(GlobalItemLedgEntry, TempItemEntryRelation);
    end;

    local procedure InsertConItemEntryRelation(ItemLedgerEntry: Record "Item Ledger Entry"; var TempItemEntryRelation: Record "Item Entry Relation")
    var
        Item: Record Item;
    begin
        Item.Get(ItemLedgerEntry."Item No.");
        // GetItem(ItemLedgerEntry."Item No.", true);
        if Item."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := ItemLedgerEntry."Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
            // OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemLedgerEntry);
            TempItemEntryRelation.Insert();
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnRun(var ConversionHeader: Record "FA Conversion Header"; SuppressCommit: Boolean)
    begin
    end;


    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", OnAfterValidateEvent, Quantity, false, false)]
    local procedure CheckWhseValidSourceLine(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line")
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        Item: Record Item;
    begin
        GetSourceCode();
        // enable after testing
        // if Rec."Source Code" = SourceCode then begin
        //     Item.Get(rec."Item No.");
        //     if Item.IsInventoriableType() then
        //         WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
        // end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", OnAfterItemLineVerifyChange, '', false, false)]
    local procedure OnAfterItemLineVerifyChange(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line")
    var
        ConversionLine: Record "FA Conversion Line";
        Location: Record Location;
        QtyChecked: Boolean;
        QtyRemainingToBePicked: Decimal;
        LinesExist: Boolean;
        Text002: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.';
    begin
        GetSourceCode();
        // enable after testing
        // if NewItemJnlLine."Source Code" = SourceCode then
        //     Case NewItemJnlLine."Entry Type" of
        //         "Item Ledger Entry Type"::"Negative Adjmt.":
        //             begin
        //                 if Location.Get(NewItemJnlLine."Location Code") and (Location."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then
        //                     if ConversionLine.Get(NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.") and
        //                        (NewItemJnlLine.Quantity >= 0)
        //                     then begin
        //                         QtyRemainingToBePicked := NewItemJnlLine.Quantity - ConversionLine."Qty. Picked";
        //                         QtyChecked := true;
        //                     end;

        //                 LinesExist := false;
        //             end;
        //     end;

        // if QtyRemainingToBePicked > 0 then
        //     Error(Text002, NewItemJnlLine."Order No.", QtyRemainingToBePicked);
    end;
}