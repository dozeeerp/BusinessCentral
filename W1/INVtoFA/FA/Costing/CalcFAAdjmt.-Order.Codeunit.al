namespace TSTChanges.FA.Costing;

using Microsoft.Inventory.Costing;
using TSTChanges.FA.History;
using TSTChanges.FA.FAItem;
using Microsoft.Inventory.Ledger;
using Microsoft.FixedAssets.Ledger;
using TSTChanges.FA.Ledger;

codeunit 51229 "Calc. FA Adjmt. - Order"
{
    trigger OnRun()
    begin
    end;

    var
        Item: Record "FA Item";

    procedure Calculate(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        ActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        OutputQty: Decimal;
    begin
        if not Item.Get(SourceInvtAdjmtEntryOrder."FA Item No.") then
            Item.Init();

        // OnCalculateOnAfterGetItem(Item, SourceInvtAdjmtEntryOrder);

        OutputQty := CalcOutputQty(SourceInvtAdjmtEntryOrder, false);
        CalcActualUsageCosts(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
        CalcActualVariances(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
        CalcOutputEntryCostAdjmts(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder, InvtAdjmtBuf);
    end;

    procedure CalcActualUsageCosts(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OutputQty: Decimal; var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)")
    begin
        InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
        InvtAdjmtEntryOrder.RoundCosts(0);

        CalcActualMaterialCosts(InvtAdjmtEntryOrder);
        // CalcActualCapacityCosts(InvtAdjmtEntryOrder);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcOvhdCost(OutputQty);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcDirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcIndirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcUnitCost();
    end;

    local procedure CalcOutputEntryCostAdjmts(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OutputQty: Decimal; ActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        TempItemLedgEntry: Record "FA Item Ledger Entry" temporary;
        OldActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        NewActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        NewNegActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        RemActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        RemNegActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        ActNegInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        RemOutputQty: Decimal;
        RemNegOutputQty: Decimal;
        GrossOutputQty: Decimal;
        ReversedQty: Decimal;
        IsPositiveOutputs: Boolean;
    begin
        OutputItemLedgEntryExist(SourceInvtAdjmtEntryOrder, TempItemLedgEntry);
        GrossOutputQty := CalcOutputQty(SourceInvtAdjmtEntryOrder, true);
        if GrossOutputQty <> OutputQty then begin
            ActNegInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
            if OutputQty = 0 then
                ActNegInvtAdjmtEntryOrder.RoundCosts(-1)
            else
                ActNegInvtAdjmtEntryOrder.RoundCosts(-(GrossOutputQty - OutputQty) / OutputQty);
        end;

        for IsPositiveOutputs := true downto false do
            if TempItemLedgEntry.Find('-') then begin
                if IsPositiveOutputs then begin
                    RemOutputQty := OutputQty;
                    RemActInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
                    RemNegOutputQty := -(GrossOutputQty - OutputQty);
                    RemNegActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                end else begin
                    RemOutputQty := -(GrossOutputQty - OutputQty);
                    RemActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                    RemNegOutputQty := 0;
                end;

                repeat
                    if TempItemLedgEntry.Positive = IsPositiveOutputs then begin
                        ReversedQty := CalcExactCostReversingQty(TempItemLedgEntry);

                        OldActInvtAdjmtEntryOrder.Init();
                        CalcActualOutputCosts(OldActInvtAdjmtEntryOrder, TempItemLedgEntry."FA No.");

                        NewActInvtAdjmtEntryOrder := RemActInvtAdjmtEntryOrder;

                        // OnCalcOutputEntryCostAdjmtsOnBeforeCalculateCostForGrossOutput(NewActInvtAdjmtEntryOrder, RemOutputQty, OutputQty);

                        if RemOutputQty * (TempItemLedgEntry.Quantity + ReversedQty) <> 0 then begin
                            // Calculate cost for gross output
                            NewActInvtAdjmtEntryOrder.RoundCosts((TempItemLedgEntry.Quantity + ReversedQty) / RemOutputQty);

                            RemOutputQty -= (TempItemLedgEntry.Quantity + ReversedQty);
                            RemActInvtAdjmtEntryOrder.CalcDiff(NewActInvtAdjmtEntryOrder, false);
                            RemActInvtAdjmtEntryOrder.RoundCosts(-1);
                        end else
                            NewActInvtAdjmtEntryOrder.RoundCosts(0);

                        if RemNegOutputQty * ReversedQty <> 0 then begin
                            // Calculate cost for negative output
                            NewNegActInvtAdjmtEntryOrder := RemNegActInvtAdjmtEntryOrder;
                            NewNegActInvtAdjmtEntryOrder.RoundCosts(ReversedQty / RemNegOutputQty);

                            RemNegOutputQty -= ReversedQty;
                            RemNegActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                            RemNegActInvtAdjmtEntryOrder.RoundCosts(-1);

                            // Gross + Negative Outputs
                            NewActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                            NewActInvtAdjmtEntryOrder.RoundCosts(-1);
                        end;

                        // Compute difference to post
                        NewActInvtAdjmtEntryOrder.CalcDiff(OldActInvtAdjmtEntryOrder, false);
                        NewActInvtAdjmtEntryOrder.RoundCosts(-1);

                        UpdateOutputAdjmtBuf(TempItemLedgEntry, NewActInvtAdjmtEntryOrder, InvtAdjmtBuf);
                        TempItemLedgEntry.Delete();
                    end;
                until TempItemLedgEntry.Next() = 0;
            end;
    end;

    local procedure UpdateOutputAdjmtBuf(ItemLedgerEntry: Record "FA Item Ledger Entry"; InventoryAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
        // OnBeforeUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder, ItemLedgerEntry, InventoryAdjustmentBuffer);

        // with InventoryAdjmtEntryOrder do begin
        if HasNewCost(InventoryAdjmtEntryOrder."Direct Cost", InventoryAdjmtEntryOrder."Direct Cost (ACY)") or not InventoryAdjmtEntryOrder."Completely Invoiced" then
            InventoryAdjustmentBuffer.AddCost(
              ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Direct Cost", "Cost Variance Type"::" ", InventoryAdjmtEntryOrder."Direct Cost", InventoryAdjmtEntryOrder."Direct Cost (ACY)");
        if HasNewCost(InventoryAdjmtEntryOrder."Indirect Cost", InventoryAdjmtEntryOrder."Indirect Cost (ACY)") then
            InventoryAdjustmentBuffer.AddCost(
              ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Indirect Cost", "Cost Variance Type"::" ", InventoryAdjmtEntryOrder."Indirect Cost", InventoryAdjmtEntryOrder."Indirect Cost (ACY)");

        // if Item."Costing Method" <> Item."Costing Method"::Standard then
        //     exit;

        if HasNewCost(InventoryAdjmtEntryOrder."Single-Level Material Cost", InventoryAdjmtEntryOrder."Single-Lvl Material Cost (ACY)") then
            InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
              InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Material,
              InventoryAdjmtEntryOrder."Single-Level Material Cost", InventoryAdjmtEntryOrder."Single-Lvl Material Cost (ACY)");

        // if HasNewCost("Single-Level Capacity Cost", "Single-Lvl Capacity Cost (ACY)") then
        //     InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
        //       InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Capacity,
        //       "Single-Level Capacity Cost", "Single-Lvl Capacity Cost (ACY)");

        // if HasNewCost("Single-Level Cap. Ovhd Cost", "Single-Lvl Cap. Ovhd Cost(ACY)") then
        //     InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
        //       InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Capacity Overhead",
        //       "Single-Level Cap. Ovhd Cost", "Single-Lvl Cap. Ovhd Cost(ACY)");

        // if HasNewCost("Single-Level Mfg. Ovhd Cost", "Single-Lvl Mfg. Ovhd Cost(ACY)") then
        //     InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
        //       InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Manufacturing Overhead",
        //       "Single-Level Mfg. Ovhd Cost", "Single-Lvl Mfg. Ovhd Cost(ACY)");

        // if HasNewCost("Single-Level Subcontrd. Cost", "Single-Lvl Subcontrd Cost(ACY)") then
        //     InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
        //       InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Subcontracted,
        //       "Single-Level Subcontrd. Cost", "Single-Lvl Subcontrd Cost(ACY)");
        // end;

        // OnAfterUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder, ItemLedgerEntry, InventoryAdjustmentBuffer);
    end;

    local procedure CalcActualVariances(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OutputQty: Decimal; var VarianceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)")
    var
        StdCostInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
    begin
        StdCostInvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;

        // if Item."Costing Method" = Item."Costing Method"::Standard then begin
        //     CalcStandardCost(StdCostInvtAdjmtEntryOrder, OutputQty);
        //     VarianceInvtAdjmtEntryOrder.CalcDiff(StdCostInvtAdjmtEntryOrder, true);
        // end else
        VarianceInvtAdjmtEntryOrder.CalcDiff(VarianceInvtAdjmtEntryOrder, true);
    end;

    local procedure CalcActualOutputCosts(var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; FANo: Code[20])
    var
        // OutputValueEntry: Record "Value Entry";
        // IsHandled: Boolean;
        OutputFAEntry: Record "FA Ledger Entry";
    begin
        // IsHandled := false;
        // OnBeforeAddCosts(InvtAdjmtEntryOrder, ItemLedgerEntryNo, IsHandled);
        // if IsHandled then
        //     exit;

        // OutputValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        // OutputValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        // OutputValueEntry.SetLoadFields("Entry Type", "Variance Type", "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        // if OutputValueEntry.FindSet() then
        //     repeat
        //         case OutputValueEntry."Entry Type" of
        //             OutputValueEntry."Entry Type"::"Direct Cost":
        //                 InvtAdjmtEntryOrder.AddDirectCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //             OutputValueEntry."Entry Type"::"Indirect Cost":
        //                 InvtAdjmtEntryOrder.AddIndirectCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //             OutputValueEntry."Entry Type"::Variance:
        //                 case OutputValueEntry."Variance Type" of
        //                     OutputValueEntry."Variance Type"::Material:
        //                         InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //                     OutputValueEntry."Variance Type"::Capacity:
        //                         InvtAdjmtEntryOrder.AddSingleLvlCapacityCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //                     OutputValueEntry."Variance Type"::"Capacity Overhead":
        //                         InvtAdjmtEntryOrder.AddSingleLvlCapOvhdCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //                     OutputValueEntry."Variance Type"::"Manufacturing Overhead":
        //                         InvtAdjmtEntryOrder.AddSingleLvlMfgOvhdCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //                     OutputValueEntry."Variance Type"::Subcontracted:
        //                         InvtAdjmtEntryOrder.AddSingleLvlSubcontrdCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
        //                 end;
        //         end;
        //     until OutputValueEntry.Next() = 0;
        OutputFAEntry.SetCurrentKey("FA No.", "FA Posting Type", "Depreciation Book Code");
        OutputFAEntry.SetRange("FA No.", FANo);
        OutputFAEntry.SetRange("FA Posting Type", OutputFAEntry."FA Posting Type"::"Acquisition Cost");
        OutputFAEntry.SetRange("Depreciation Book Code", 'COMPANY');
        OutputFAEntry.SetLoadFields(Amount);
        if OutputFAEntry.FindSet() then
            repeat
                InvtAdjmtEntryOrder.AddDirectCost(OutputFAEntry.Amount, 0);
            until OutputFAEntry.Next() = 0;
    end;

    local procedure CalcActualMaterialCosts(var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CalcActualMaterialCostQuery: Query "Calc. Actual Material Cost";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCalcActualMaterialCosts(InvtAdjmtEntryOrder, IsHandled);
        // if IsHandled then
        //     exit;

        CalcActualMaterialCostQuery.SetRange(Order_Type, InvtAdjmtEntryOrder."Order Type");
        CalcActualMaterialCostQuery.SetRange(Order_No_, InvtAdjmtEntryOrder."Order No.");
        // CalcActualMaterialCostQuery.SetFilter(Entry_Type, '%1|%2',
        //         ItemLedgEntry."Entry Type"::Consumption,
        //         ItemLedgEntry."Entry Type"::"Assembly Consumption");
        CalcActualMaterialCostQuery.SetFilter(Entry_Type, '%1', ItemLedgEntry."Entry Type"::"Negative Adjmt.");

        CalcActualMaterialCostQuery.SetFilter(Value_Entry_Type, '<>%1', "Cost Entry Type"::Rounding);
        CalcActualMaterialCostQuery.SetRange(Inventoriable, true);

        if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
            CalcActualMaterialCostQuery.SetRange(Order_Line_No_, InvtAdjmtEntryOrder."Order Line No.");
        CalcActualMaterialCostQuery.Open();

        // OnCalcActualMaterialCostsOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder, CalcActualMaterialCostQuery, IsHandled);
        if not IsHandled then
            while CalcActualMaterialCostQuery.Read() do begin
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual_,
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual___ACY_
                );
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl__,
                    -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl___ACY_
                );

                if CalcActualMaterialCostQuery.Positive then
                    AdjustForRevNegCon(InvtAdjmtEntryOrder, CalcActualMaterialCostQuery.Entry_No_);
            end;
    end;

    local procedure AdjustForRevNegCon(var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(ValueEntry."Cost Amount (Actual)", ValueEntry."Cost Amount (Actual) (ACY)");
    end;

    procedure CalcOutputQty(InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OnlyInbounds: Boolean) OutputQty: Decimal
    var
        ItemLedgEntry: Record "FA Item ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type");
        ItemLedgEntry.SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
        ItemLedgEntry.SetFilter("Entry Type", '%1',
        //   ItemLedgEntry."Entry Type"::Output,
          ItemLedgEntry."Entry Type"::"Conversion Output");
        // if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
        //     ItemLedgEntry.SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
        if OnlyInbounds then
            ItemLedgEntry.SetRange(Positive, true);
        // OnCalcOutputQtyOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder);
        ItemLedgEntry.CalcSums(Quantity);
        OutputQty := ItemLedgEntry.Quantity;
    end;

    local procedure CopyILEToILE(var FromItemLedgEntry: Record "FA Item Ledger Entry"; var ToItemLedgEntry: Record "FA Item Ledger Entry")
    begin
        ToItemLedgEntry.Reset();
        ToItemLedgEntry.DeleteAll();
        if FromItemLedgEntry.FindSet() then
            repeat
                ToItemLedgEntry := FromItemLedgEntry;
                ToItemLedgEntry.Insert();
            until FromItemLedgEntry.Next() = 0;
    end;

    local procedure OutputItemLedgEntryExist(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var ToItemLedgEntry: Record "FA Item Ledger Entry")
    var
        FromItemLedgEntry: Record "FA Item Ledger Entry";
    begin
        FromItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        FromItemLedgEntry.SetRange("Order Type", SourceInvtAdjmtEntryOrder."Order Type");
        FromItemLedgEntry.SetRange("Order No.", SourceInvtAdjmtEntryOrder."Order No.");
        // FromItemLedgEntry.SetFilter("Entry Type", '%1|%2', FromItemLedgEntry."Entry Type"::Output, FromItemLedgEntry."Entry Type"::"Assembly Output");
        FromItemLedgEntry.SetFilter("Entry Type", '%1', FromItemLedgEntry."Entry Type"::"Conversion Output");
        if SourceInvtAdjmtEntryOrder."Order Type" = SourceInvtAdjmtEntryOrder."Order Type"::Production then
            FromItemLedgEntry.SetRange("Order Line No.", SourceInvtAdjmtEntryOrder."Order Line No.");
        // OnOutputItemLedgEntryExistOnAfterSetFilters(FromItemLedgEntry, SourceInvtAdjmtEntryOrder);
        CopyILEToILE(FromItemLedgEntry, ToItemLedgEntry);
    end;

    local procedure CalcExactCostReversingQty(ItemLedgEntry: Record "FA Item Ledger Entry") Qty: Decimal
    var
        OutbndItemLedgEntry: Record "FA Item Ledger Entry";
        ItemApplnEntry: Record "FA Item Application Entry";
        TempItemLedgEntryInChain: Record "FA Item Ledger Entry" temporary;
    begin
        OutbndItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        OutbndItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type");
        OutbndItemLedgEntry.SetRange("Order No.", ItemLedgEntry."Order No.");
        OutbndItemLedgEntry.SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
        OutbndItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type");
        OutbndItemLedgEntry.SetRange(Positive, false);
        OutbndItemLedgEntry.SetFilter("Applies-to Entry", '<>0');
        if OutbndItemLedgEntry.IsEmpty() then
            exit(0);

        ItemApplnEntry.GetVisitedEntries(ItemLedgEntry, TempItemLedgEntryInChain, true);
        TempItemLedgEntryInChain.SetRange("Order Type", ItemLedgEntry."Order Type");
        TempItemLedgEntryInChain.SetRange("Order No.", ItemLedgEntry."Order No.");
        TempItemLedgEntryInChain.SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
        TempItemLedgEntryInChain.SetRange("Entry Type", ItemLedgEntry."Entry Type");
        TempItemLedgEntryInChain.SetRange(Positive, false);
        TempItemLedgEntryInChain.SetFilter("Applies-to Entry", '<>0');
        TempItemLedgEntryInChain.CalcSums(Quantity);
        Qty := TempItemLedgEntryInChain.Quantity;
    end;

    local procedure HasNewCost(NewCost: Decimal; NewCostACY: Decimal): Boolean
    begin
        exit((NewCost <> 0) or (NewCostACY <> 0));
    end;


    //This section of codeunit is temparory until old entries are compleltly booked
    procedure CalculateBasedOnOutput(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        ActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        OutputQty: Decimal;
        PostedConOrder: Record "Posted Conversion Header";
    begin
        if not Item.Get(SourceInvtAdjmtEntryOrder."FA Item No.") then
            Item.Init();

        // OnCalculateOnAfterGetItem(Item, SourceInvtAdjmtEntryOrder);
        PostedConOrder.Reset();
        PostedConOrder.SetRange("Order No.", SourceInvtAdjmtEntryOrder."Order No.");
        if PostedConOrder.FindSet() then
            repeat
                OutputQty := CalcOutputQtyBasedOnOutput(PostedConOrder, false);
                CalcActualUsageCostsBasedOnOutput(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder, PostedConOrder);
                CalcActualVariances(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
                CalcOutputEntryCostAdjmtsBasedOnActual(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder, InvtAdjmtBuf, PostedConOrder);
            until PostedConOrder.Next() = 0;
    end;

    procedure CalcOutputQtyBasedOnOutput(PostedConOrder: Record "Posted Conversion Header"; OnlyInbounds: Boolean) OutputQty: Decimal
    var
        ItemLedgEntry: Record "FA Item ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Document No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Conversion);
        ItemLedgEntry.SetRange("Document No.", PostedConOrder."No.");
        ItemLedgEntry.SetFilter("Entry Type", '%1',
        //   ItemLedgEntry."Entry Type"::Output,
          ItemLedgEntry."Entry Type"::"Conversion Output");
        // if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
        //     ItemLedgEntry.SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
        if OnlyInbounds then
            ItemLedgEntry.SetRange(Positive, true);
        // OnCalcOutputQtyOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder);
        ItemLedgEntry.CalcSums(Quantity);
        OutputQty := ItemLedgEntry.Quantity;
    end;

    procedure CalcActualUsageCostsBasedOnOutput(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OutputQty: Decimal; var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; PostedConOrder: Record "Posted Conversion Header")
    begin
        InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
        InvtAdjmtEntryOrder.RoundCosts(0);

        CalcActualMaterialCostsBasedOnOutput(InvtAdjmtEntryOrder, PostedConOrder);
        // CalcActualCapacityCosts(InvtAdjmtEntryOrder);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcOvhdCost(OutputQty);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcDirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcIndirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcUnitCost();
    end;

    local procedure CalcActualMaterialCostsBasedOnOutput(var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; PostedConOrder: Record "Posted Conversion Header")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CalcActualMaterialCostQuery: Query "Calc. Actual Material Cost";
        IsHandled: Boolean;
    begin
        CalcActualMaterialCostQuery.SetRange(Order_Type, ItemLedgEntry."Order Type"::Conversion);
        CalcActualMaterialCostQuery.SetRange(Document_No_, PostedConOrder."No.");
        CalcActualMaterialCostQuery.SetFilter(Entry_Type, '%1', ItemLedgEntry."Entry Type"::"Negative Adjmt.");
        CalcActualMaterialCostQuery.SetFilter(Value_Entry_Type, '<>%1', "Cost Entry Type"::Rounding);
        CalcActualMaterialCostQuery.SetRange(Inventoriable, true);

        CalcActualMaterialCostQuery.Open();
        if not IsHandled then
            while CalcActualMaterialCostQuery.Read() do begin
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual_,
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual___ACY_
                );
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl__,
                    -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl___ACY_
                );

                // if CalcActualMaterialCostQuery.Positive then
                //     AdjustForRevNegCon(InvtAdjmtEntryOrder, CalcActualMaterialCostQuery.Entry_No_);
            end;
    end;

    local procedure CalcOutputEntryCostAdjmtsBasedOnActual(SourceInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OutputQty: Decimal; ActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer"; PostedConOrder: Record "Posted Conversion Header")
    var
        TempItemLedgEntry: Record "FA Item Ledger Entry" temporary;
        OldActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        NewActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        NewNegActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        RemActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        RemNegActInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        ActNegInvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        RemOutputQty: Decimal;
        RemNegOutputQty: Decimal;
        GrossOutputQty: Decimal;
        ReversedQty: Decimal;
        IsPositiveOutputs: Boolean;
    begin
        OutputItemLedgEntryExistBasedOnOutput(TempItemLedgEntry, PostedConOrder);
        GrossOutputQty := CalcOutputQtyBasedOnOutput(PostedConOrder, true);
        if GrossOutputQty <> OutputQty then begin
            ActNegInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
            if OutputQty = 0 then
                ActNegInvtAdjmtEntryOrder.RoundCosts(-1)
            else
                ActNegInvtAdjmtEntryOrder.RoundCosts(-(GrossOutputQty - OutputQty) / OutputQty);
        end;

        for IsPositiveOutputs := true downto false do
            if TempItemLedgEntry.Find('-') then begin
                if IsPositiveOutputs then begin
                    RemOutputQty := OutputQty;
                    RemActInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
                    RemNegOutputQty := -(GrossOutputQty - OutputQty);
                    RemNegActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                end else begin
                    RemOutputQty := -(GrossOutputQty - OutputQty);
                    RemActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                    RemNegOutputQty := 0;
                end;

                repeat
                    if TempItemLedgEntry.Positive = IsPositiveOutputs then begin
                        ReversedQty := CalcExactCostReversingQty(TempItemLedgEntry);

                        OldActInvtAdjmtEntryOrder.Init();
                        CalcActualOutputCosts(OldActInvtAdjmtEntryOrder, TempItemLedgEntry."FA No.");

                        NewActInvtAdjmtEntryOrder := RemActInvtAdjmtEntryOrder;

                        // OnCalcOutputEntryCostAdjmtsOnBeforeCalculateCostForGrossOutput(NewActInvtAdjmtEntryOrder, RemOutputQty, OutputQty);

                        if RemOutputQty * (TempItemLedgEntry.Quantity + ReversedQty) <> 0 then begin
                            // Calculate cost for gross output
                            NewActInvtAdjmtEntryOrder.RoundCosts((TempItemLedgEntry.Quantity + ReversedQty) / RemOutputQty);

                            RemOutputQty -= (TempItemLedgEntry.Quantity + ReversedQty);
                            RemActInvtAdjmtEntryOrder.CalcDiff(NewActInvtAdjmtEntryOrder, false);
                            RemActInvtAdjmtEntryOrder.RoundCosts(-1);
                        end else
                            NewActInvtAdjmtEntryOrder.RoundCosts(0);

                        if RemNegOutputQty * ReversedQty <> 0 then begin
                            // Calculate cost for negative output
                            NewNegActInvtAdjmtEntryOrder := RemNegActInvtAdjmtEntryOrder;
                            NewNegActInvtAdjmtEntryOrder.RoundCosts(ReversedQty / RemNegOutputQty);

                            RemNegOutputQty -= ReversedQty;
                            RemNegActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                            RemNegActInvtAdjmtEntryOrder.RoundCosts(-1);

                            // Gross + Negative Outputs
                            NewActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                            NewActInvtAdjmtEntryOrder.RoundCosts(-1);
                        end;

                        // Compute difference to post
                        NewActInvtAdjmtEntryOrder.CalcDiff(OldActInvtAdjmtEntryOrder, false);
                        NewActInvtAdjmtEntryOrder.RoundCosts(-1);

                        UpdateOutputAdjmtBuf(TempItemLedgEntry, NewActInvtAdjmtEntryOrder, InvtAdjmtBuf);
                        TempItemLedgEntry.Delete();
                    end;
                until TempItemLedgEntry.Next() = 0;
            end;
    end;

    local procedure OutputItemLedgEntryExistBasedOnOutput(var ToItemLedgEntry: Record "FA Item Ledger Entry"; PostedConOrder: Record "Posted Conversion Header")
    var
        FromItemLedgEntry: Record "FA Item Ledger Entry";
    begin
        FromItemLedgEntry.SetCurrentKey("Order Type", "Document No.", "Entry Type");
        FromItemLedgEntry.SetRange("Order Type", FromItemLedgEntry."Order Type"::Conversion);
        FromItemLedgEntry.SetRange("Document No.", PostedConOrder."No.");
        // FromItemLedgEntry.SetFilter("Entry Type", '%1|%2', FromItemLedgEntry."Entry Type"::Output, FromItemLedgEntry."Entry Type"::"Assembly Output");
        FromItemLedgEntry.SetFilter("Entry Type", '%1', FromItemLedgEntry."Entry Type"::"Conversion Output");
        CopyILEToILE(FromItemLedgEntry, ToItemLedgEntry);
    end;
}