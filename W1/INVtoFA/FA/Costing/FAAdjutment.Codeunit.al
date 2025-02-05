namespace TSTChanges.FA.Costing;
using Microsoft.Inventory.Costing;
using TSTChanges.FA.FAItem;
using Microsoft.Foundation.AuditCodes;
using Microsoft.FixedAssets.FixedAsset;
using TSTChanges.FA.Ledger;
using TSTChanges.FA.Journal;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 51228 "FA Adjustment"
{
    trigger OnRun()
    begin

    end;

    var
        Text000: Label 'Checking Inv. to FA entries...\\';
        Text001: Label 'Adjmt. Level      #2######\';
        Text002: Label '%1 %2';
        Text003: Label 'Adjust            #3######\';
        Text004: Label 'Cost FW. Level    #4######\';
        Text005: Label 'Entry No.         #5######\';
        Text006: Label 'Remaining Entries #6######';
        Text007: Label 'Applied cost';
        Text008: Label 'Average cost';
        Item: Record "FA Item";
        FilterItem: Record "FA Item";
        TempInvtAdjmtBuf: Record "Inventory Adjustment Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        IsDeletedItem: Boolean;
        IsOnlineAdjmt: Boolean;
        WindowIsOpen: Boolean;
        WindowAdjmtLevel: Integer;
        WindowItem: Code[20];
        WindowAdjust: Text[20];
        WindowFWLevel: Integer;
        WindowEntry: Integer;
        Text010: Label 'Conversion';
        WindowOutbndEntry: Integer;
        PostingDateForClosedPeriod: Date;
        LevelNo: array[3] of Integer;
        MaxLevels: Integer;

    procedure SetProperties(NewIsOnlineAdjmt: Boolean; NewPostToGL: Boolean)
    begin
        IsOnlineAdjmt := NewIsOnlineAdjmt;
        // PostToGL := NewPostToGL;
    end;

    procedure SetFilterItem(var NewItem: Record "FA Item")
    begin
        FilterItem.CopyFilters(NewItem);
    end;

    procedure MakeMultiLevelAdjmt()
    var
        TempFAAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)" temporary;
        TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary;
    begin
        InitializeAdjmt();

        // IsFirstTime := true;
        if ConversionToAdjustExists(TempFAAdjmtEntryOrder) then
            MakeConversionAdjmt(TempFAAdjmtEntryOrder, TempAvgCostAdjmtEntryPoint);
    end;

    local procedure ConversionToAdjustExists(var ToFAAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"): Boolean
    var
        FAAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
    begin
        FAAdjmtEntryOrder.Reset();
        FAAdjmtEntryOrder.SetCurrentKey("Cost is Adjusted", "Allow Online Adjustment");
        FAAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        FAAdjmtEntryOrder.SetRange("Order Type", FAAdjmtEntryOrder."Order Type"::Conversion);
        if IsOnlineAdjmt then
            FAAdjmtEntryOrder.SetRange("Allow Online Adjustment", true);

        CopyOrderAdmtEntryToOrderAdjmt(FAAdjmtEntryOrder, ToFAAdjmtEntryOrder);
        exit(ToFAAdjmtEntryOrder.FindFirst())
    end;

    local procedure CopyOrderAdmtEntryToOrderAdjmt(var FromInventoryAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var ToInventoryAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)")
    begin
        ToInventoryAdjmtEntryOrder.Reset();
        ToInventoryAdjmtEntryOrder.DeleteAll();
        if FromInventoryAdjmtEntryOrder.FindSet() then
            repeat
                ToInventoryAdjmtEntryOrder := FromInventoryAdjmtEntryOrder;
                ToInventoryAdjmtEntryOrder.Insert();
            until FromInventoryAdjmtEntryOrder.Next() = 0;
    end;

    local procedure MakeConversionAdjmt(var SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. FA Adjmt. - Order";
        DoNotSkipItems: Boolean;
    begin
        DoNotSkipItems := FilterItem.GetFilters = '';
        // with SourceInvtAdjmtEntryOrder do
        if SourceInvtAdjmtEntryOrder.FindSet() then
            repeat
                if true in [DoNotSkipItems, ItemInFilteredSetExists(SourceInvtAdjmtEntryOrder."FA Item No.", FilterItem)] then begin
                    GetItem(SourceInvtAdjmtEntryOrder."FA Item No.");
                    UpDateWindow(WindowAdjmtLevel, SourceInvtAdjmtEntryOrder."FA Item No.", Text010, 0, 0, 0);

                    InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
                    // if not Item."Inventory Value Zero" then begin
                    CalcInventoryAdjmtOrder.Calculate(SourceInvtAdjmtEntryOrder, TempInvtAdjmtBuf);
                    PostOutputAdjmtBuf(TempAvgCostAdjmtEntryPoint);
                    // end;

                    if not SourceInvtAdjmtEntryOrder."Completely Invoiced" then begin
                        InvtAdjmtEntryOrder.GetCostsFromItem(1);
                        InvtAdjmtEntryOrder."Completely Invoiced" := true;
                    end;
                    InvtAdjmtEntryOrder."Allow Online Adjustment" := true;
                    InvtAdjmtEntryOrder."Cost is Adjusted" := true;
                    InvtAdjmtEntryOrder.Modify();
                end;
            until SourceInvtAdjmtEntryOrder.Next() = 0;
    end;

    local procedure ItemInFilteredSetExists(ItemNo: Code[20]; var FilteredItem: Record "FA Item"): Boolean
    var
        TempItem: Record "FA Item" temporary;
        Item: Record "FA Item";
    begin
        // with TempItem do begin
        if not Item.Get(ItemNo) then
            exit(false);
        TempItem.CopyFilters(FilteredItem);
        TempItem := Item;
        TempItem.Insert();
        exit(not TempItem.IsEmpty);
        // end;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        IsDeletedItem := ItemNo = '';
        if (Item."No." <> ItemNo) or IsDeletedItem then
            if not IsDeletedItem then
                Item.Get(ItemNo)
            else begin
                Clear(Item);
                Item.Init();
            end;
    end;

    local procedure OpenWindow()
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeOpenWindow(IsHandled, Window, WindowIsOpen);
        // if IsHandled then
        //     exit;

        Window.Open(
          Text000 +
          '#1########################\\' +
          Text001 +
          Text003 +
          Text004 +
          Text005 +
          Text006);
        WindowIsOpen := true;
    end;

    local procedure UpDateWindow(NewWindowAdjmtLevel: Integer; NewWindowItem: Code[20]; NewWindowAdjust: Text[20]; NewWindowFWLevel: Integer; NewWindowEntry: Integer; NewWindowOutbndEntry: Integer)
    var
        IsHandled: Boolean;
    begin
        WindowAdjmtLevel := NewWindowAdjmtLevel;
        WindowItem := NewWindowItem;
        WindowAdjust := NewWindowAdjust;
        WindowFWLevel := NewWindowFWLevel;
        WindowEntry := NewWindowEntry;
        WindowOutbndEntry := NewWindowOutbndEntry;

        // IsHandled := false;
        // OnBeforeUpdateWindow(IsHandled);
        // if IsHandled then
        //     exit;

        if IsTimeForUpdate() then begin
            if not WindowIsOpen then
                OpenWindow();

            // IsHandled := false;
            // OnUpdateWindowOnAfterOpenWindow(IsHandled);
            // if IsHandled then
            //     exit;

            Window.Update(1, StrSubstNo(Text002, TempInvtAdjmtBuf.FieldCaption("Item No."), WindowItem));
            Window.Update(2, WindowAdjmtLevel);
            Window.Update(3, WindowAdjust);
            Window.Update(4, WindowFWLevel);
            Window.Update(5, WindowEntry);
            Window.Update(6, WindowOutbndEntry);
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    local procedure InitializeAdjmt()
    begin
        Clear(LevelNo);
        MaxLevels := 100;
        WindowUpdateDateTime := CurrentDateTime;
        if not IsOnlineAdjmt then
            OpenWindow();

        // Clear(ItemJnlPostLine);
        // ItemJnlPostLine.SetCalledFromAdjustment(true, PostToGL);

        // InvtSetup.Get();
        GLSetup.Get();
        PostingDateForClosedPeriod := GLSetup.FirstAllowedPostingDate();
        // OnInitializeAdjmtOnAfterGetPostingDate(PostingDateForClosedPeriod);

        // GetAddReportingCurrency();

        SourceCodeSetup.Get();

        // ItemCostMgt.SetProperties(true, 0);
        // TempJobToAdjustBuf.DeleteAll();
    end;

    local procedure PostOutputAdjmtBuf(var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    begin
        TempInvtAdjmtBuf.Reset();
        if TempInvtAdjmtBuf.FindSet() then
            repeat
                PostOutput(TempInvtAdjmtBuf, TempAvgCostAdjmtEntryPoint);
            until TempInvtAdjmtBuf.Next() = 0;
        TempInvtAdjmtBuf.DeleteAll();
    end;

    local procedure PostOutput(InvtAdjmtBuf: Record "Inventory Adjustment Buffer"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        OrigItemLedgEntry: Record "FA Item ledger Entry";
        FA: Record "Fixed Asset";
        FAAcq: Codeunit "FA Acquisition mgmt";
    begin
        OrigItemLedgEntry.Get(TempInvtAdjmtBuf."Item Ledger Entry No.");
        FA.Get(OrigItemLedgEntry."FA No.");
        FAAcq.AcquireFA(FA, OrigItemLedgEntry."Posting Date", InvtAdjmtBuf."Cost Amount (Actual)", OrigItemLedgEntry."Document No.");
    end;



    //This section of codeunit is temparory until old entries are compleltly booked
    procedure MakeMultiLevelAdjmtBasedonOutput()
    var
        TempFAAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)" temporary;
        TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary;
    begin
        InitializeAdjmt();

        // IsFirstTime := true;
        if ConversionToAdjustExists(TempFAAdjmtEntryOrder) then
            MakeConversionAdjmtBasedOnOutput(TempFAAdjmtEntryOrder, TempAvgCostAdjmtEntryPoint);
    end;

    Local procedure MakeConversionAdjmtBasedOnOutput(var SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var TempAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point" temporary)
    var
        InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        CalcInventoryAdjmtOrder: Codeunit "Calc. FA Adjmt. - Order";
        DoNotSkipItems: Boolean;
    begin
        DoNotSkipItems := FilterItem.GetFilters = '';
        if SourceInvtAdjmtEntryOrder.FindSet() then
            repeat
                if true in [DoNotSkipItems, ItemInFilteredSetExists(SourceInvtAdjmtEntryOrder."FA Item No.", FilterItem)] then begin
                    GetItem(SourceInvtAdjmtEntryOrder."FA Item No.");
                    UpDateWindow(WindowAdjmtLevel, SourceInvtAdjmtEntryOrder."FA Item No.", Text010, 0, 0, 0);

                    InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
                    // if not Item."Inventory Value Zero" then begin
                    CalcInventoryAdjmtOrder.CalculateBasedOnOutput(SourceInvtAdjmtEntryOrder, TempInvtAdjmtBuf);
                    PostOutputAdjmtBuf(TempAvgCostAdjmtEntryPoint);
                    // end;

                    if not SourceInvtAdjmtEntryOrder."Completely Invoiced" then begin
                        InvtAdjmtEntryOrder.GetCostsFromItem(1);
                        InvtAdjmtEntryOrder."Completely Invoiced" := true;
                    end;
                    InvtAdjmtEntryOrder."Allow Online Adjustment" := true;
                    InvtAdjmtEntryOrder."Cost is Adjusted" := true;
                    InvtAdjmtEntryOrder.Modify();
                end;
            until SourceInvtAdjmtEntryOrder.Next() = 0;
    end;
}