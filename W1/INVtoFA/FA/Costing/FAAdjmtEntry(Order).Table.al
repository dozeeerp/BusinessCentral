namespace TSTChanges.FA.Costing;

using TSTChanges.FA.FAItem;
using Microsoft.Finance.GeneralLedger.Setup;
using TSTChanges.FA.History;
using Microsoft.Finance.Currency;
using TSTChanges.FA.Conversion;
using Microsoft.Foundation.Enums;

table 51220 "FA Adjmt. Entry (Order)"
{
    DataClassification = CustomerContent;
    Caption = 'FA Adjmt Entry (Order)';
    Permissions = TableData "FA Adjmt. Entry (Order)" = i;

    fields
    {
        field(1; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
        }
        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(3; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(4; "FA Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = "FA Item";
        }
        field(29; "Cost is Adjusted"; Boolean)
        {
            Caption = 'Cost is Adjusted';
            InitValue = true;
        }
        field(30; "Allow Online Adjustment"; Boolean)
        {
            Caption = 'Allow Online Adjustment';
            InitValue = true;
        }
        field(41; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(42; "Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Cost';
        }
        field(43; "Indirect Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Indirect Cost';
        }
        field(44; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Cost';
        }
        field(52; "Direct Cost (ACY)"; Decimal)
        {
            Caption = 'Direct Cost (ACY)';
        }
        field(53; "Indirect Cost (ACY)"; Decimal)
        {
            Caption = 'Indirect Cost (ACY)';
        }
        field(54; "Single-Lvl Material Cost (ACY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Lvl Material Cost (ACY)';
        }
        field(61; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
        }
        field(62; "Is Finished"; Boolean)
        {
            Caption = 'Is Finished';
        }
    }

    keys
    {
        key(Key1; "Order Type", "Order No.", "Order Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Cost is Adjusted", "Allow Online Adjustment")
        {
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
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;
        AmtRndgPrec: Decimal;
        AmtRndgPrecACY: Decimal;
        UnitAmtRndgPrec: Decimal;
        UnitAmtRndgPrecACY: Decimal;

    procedure RoundCosts(ShareOfTotalCost: Decimal)
    begin
        GetRoundingPrecision(AmtRndgPrec, AmtRndgPrecACY);
        RoundAmounts(AmtRndgPrec, AmtRndgPrecACY, ShareOfTotalCost);
    end;

    local procedure RoundUnitCosts()
    begin
        GetUnitAmtRoundingPrecision(UnitAmtRndgPrec, UnitAmtRndgPrecACY);
        RoundAmounts(UnitAmtRndgPrec, UnitAmtRndgPrecACY, 1);
    end;

    local procedure RoundAmounts(RndPrecLCY: Decimal; RndPrecACY: Decimal; ShareOfTotalCost: Decimal)
    var
        RndResLCY: Decimal;
        RndResACY: Decimal;
    begin
        "Direct Cost" := RoundCost("Direct Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Indirect Cost" := RoundCost("Indirect Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Single-Level Material Cost" := RoundCost("Single-Level Material Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        // "Single-Level Capacity Cost" := RoundCost("Single-Level Capacity Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        // "Single-Level Subcontrd. Cost" := RoundCost("Single-Level Subcontrd. Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        // "Single-Level Cap. Ovhd Cost" := RoundCost("Single-Level Cap. Ovhd Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        // "Single-Level Mfg. Ovhd Cost" := RoundCost("Single-Level Mfg. Ovhd Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);

        // "Direct Cost (ACY)" := RoundCost("Direct Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        // "Indirect Cost (ACY)" := RoundCost("Indirect Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Single-Lvl Material Cost (ACY)" := RoundCost("Single-Lvl Material Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        // "Single-Lvl Capacity Cost (ACY)" := RoundCost("Single-Lvl Capacity Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        // "Single-Lvl Subcontrd Cost(ACY)" := RoundCost("Single-Lvl Subcontrd Cost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        // "Single-Lvl Cap. Ovhd Cost(ACY)" := RoundCost("Single-Lvl Cap. Ovhd Cost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        // "Single-Lvl Mfg. Ovhd Cost(ACY)" := RoundCost("Single-Lvl Mfg. Ovhd Cost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);

        // OnAfterRoundAmounts(Rec, RndPrecLCY, RndPrecACY, ShareOfTotalCost);
    end;

    procedure CalcOvhdCost(OutputQty: Decimal)
    begin
        GetRoundingPrecision(AmtRndgPrec, AmtRndgPrecACY);

        // "Single-Level Mfg. Ovhd Cost" :=
        //   (("Single-Level Material Cost" + "Single-Level Capacity Cost" +
        //     "Single-Level Subcontrd. Cost" + "Single-Level Cap. Ovhd Cost") *
        //    "Indirect Cost %" / 100) +
        //   ("Overhead Rate" * OutputQty);
        // "Single-Level Mfg. Ovhd Cost" := Round("Single-Level Mfg. Ovhd Cost", AmtRndgPrec);

        // "Single-Lvl Mfg. Ovhd Cost(ACY)" :=
        //   (("Single-Lvl Material Cost (ACY)" + "Single-Lvl Capacity Cost (ACY)" +
        //     "Single-Lvl Subcontrd Cost(ACY)" + "Single-Lvl Cap. Ovhd Cost(ACY)") *
        //    "Indirect Cost %" / 100) +
        //   ("Overhead Rate" * OutputQty * CalcCurrencyFactor());
        // "Single-Lvl Mfg. Ovhd Cost(ACY)" := Round("Single-Lvl Mfg. Ovhd Cost(ACY)", AmtRndgPrecACY);

        // OnAfterCalcOvhdCost(xRec, Rec, GLSetup, OutputQty, AmtRndgPrec, AmtRndgPrecACY, CalcCurrencyFactor());
    end;

    procedure SetConOrder(ConversionHeader: Record "FA Conversion Header")
    begin
        SetConversionDoc(COnversionHeader."No.", ConversionHeader."FA Item No.");
    end;

    procedure SetPostedConOrder(PostedAssemblyHeader: Record "Posted Conversion Header")
    begin
        SetConversionDoc(PostedAssemblyHeader."Order No.", PostedAssemblyHeader."FA Item No.");
    end;

    local procedure SetConversionDoc(OrderNo: Code[20]; ItemNo: Code[20])
    begin
        Init();
        "Order Type" := "Order Type"::Conversion;
        "Order No." := OrderNo;
        "FA Item No." := ItemNo;
        "Cost is Adjusted" := false;
        "Is Finished" := true;
        GetCostsFromItem(1);
        if not Insert() then;
    end;

    procedure GetCostsFromItem(OutputQty: Decimal)
    begin
        GetUnroundedCostsFromItem();
        RoundCosts(OutputQty);
        CalcCostFromCostShares();
    end;

    local procedure GetUnroundedCostsFromItem()
    var
    // Item: Record Item;
    begin
        // Item.Get("FA Item No.");
        // OnGetUnroundedCostsFromItemOnAfterGetItem(Item, Rec);

        // "Indirect Cost %" := Item."Indirect Cost %";
        // "Overhead Rate" := Item."Overhead Rate";

        // GetSingleLevelCosts();
    end;

    local procedure CalcCostFromCostShares()
    begin
        CalcDirectCostFromCostShares();
        CalcIndirectCostFromCostShares();
        CalcUnitCost();
    end;

    procedure CalcUnitCost()
    begin
        "Unit Cost" := "Direct Cost" + "Indirect Cost";
    end;

    local procedure GetRoundingPrecision(var AmtRndingPrecLCY: Decimal; var AmtRndingPrecACY: Decimal)
    var
        Currency: Record Currency;
    begin
        if not GLSetupRead then
            GLSetup.Get();
        AmtRndingPrecLCY := GLSetup."Amount Rounding Precision";
        AmtRndingPrecACY := Currency."Amount Rounding Precision";
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.CheckAmountRoundingPrecision();
            AmtRndingPrecACY := Currency."Amount Rounding Precision"
        end;
        GLSetupRead := true;
    end;

    local procedure GetUnitAmtRoundingPrecision(var UnitAmtRndingPrecLCY: Decimal; var UnitAmtRndingPrecACY: Decimal)
    var
        Currency: Record Currency;
    begin
        if not GLSetupRead then
            GLSetup.Get();
        UnitAmtRndingPrecLCY := GLSetup."Unit-Amount Rounding Precision";
        UnitAmtRndingPrecACY := Currency."Unit-Amount Rounding Precision";
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.CheckAmountRoundingPrecision();
            UnitAmtRndingPrecACY := Currency."Unit-Amount Rounding Precision"
        end;
        GLSetupRead := true;
    end;

    local procedure RoundCost(Cost: Decimal; ShareOfTotal: Decimal; var RndRes: Decimal; AmtRndgPrec: Decimal): Decimal
    var
        UnRoundedCost: Decimal;
    begin
        if Cost <> 0 then begin
            UnRoundedCost := Cost * ShareOfTotal + RndRes;
            Cost := Round(UnRoundedCost, AmtRndgPrec);
            RndRes := UnRoundedCost - Cost;
            exit(Cost);
        end;
    end;

    procedure AddSingleLvlMaterialCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        // OnBeforeAddSingleLvlMaterialCost(Rec, CostAmtLCY, CostAmtACY);

        "Single-Level Material Cost" += CostAmtLCY;
        "Single-Lvl Material Cost (ACY)" += CostAmtACY;

        // OnAfterAddSingleLvlMaterialCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure CalcDirectCostFromCostShares()
    begin
        "Direct Cost" :=
          "Single-Level Material Cost";// +
        //   "Single-Level Capacity Cost" +
        //   "Single-Level Subcontrd. Cost" +
        //   "Single-Level Cap. Ovhd Cost";
        // "Direct Cost (ACY)" :=
        //   "Single-Lvl Material Cost (ACY)" +
        //   "Single-Lvl Capacity Cost (ACY)" +
        //   "Single-Lvl Subcontrd Cost(ACY)" +
        //   "Single-Lvl Cap. Ovhd Cost(ACY)";

        // OnAfterCalcDirectCostFromCostShares(Rec);
    end;

    procedure CalcIndirectCostFromCostShares()
    begin
        // "Indirect Cost" := "Single-Level Mfg. Ovhd Cost";
        // "Indirect Cost (ACY)" := "Single-Lvl Mfg. Ovhd Cost(ACY)";
    end;

    procedure CalcDiff(var InvtAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)"; OnlyCostShares: Boolean)
    begin
        if not OnlyCostShares then begin
            "Direct Cost" := InvtAdjmtEntryOrder."Direct Cost" - "Direct Cost";
            "Indirect Cost" := InvtAdjmtEntryOrder."Indirect Cost" - "Indirect Cost";
        end;
        "Single-Level Material Cost" := InvtAdjmtEntryOrder."Single-Level Material Cost" - "Single-Level Material Cost";
        // "Single-Level Capacity Cost" := InvtAdjmtEntryOrder."Single-Level Capacity Cost" - "Single-Level Capacity Cost";
        // "Single-Level Subcontrd. Cost" := InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost" - "Single-Level Subcontrd. Cost";
        // "Single-Level Cap. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost" - "Single-Level Cap. Ovhd Cost";
        // "Single-Level Mfg. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost" - "Single-Level Mfg. Ovhd Cost";

        if not OnlyCostShares then begin
            // "Direct Cost (ACY)" := InvtAdjmtEntryOrder."Direct Cost (ACY)" - "Direct Cost (ACY)";
            // "Indirect Cost (ACY)" := InvtAdjmtEntryOrder."Indirect Cost (ACY)" - "Indirect Cost (ACY)";
        end;
        "Single-Lvl Material Cost (ACY)" := InvtAdjmtEntryOrder."Single-Lvl Material Cost (ACY)" - "Single-Lvl Material Cost (ACY)";
        // "Single-Lvl Capacity Cost (ACY)" := InvtAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)" - "Single-Lvl Capacity Cost (ACY)";
        // "Single-Lvl Subcontrd Cost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)" - "Single-Lvl Subcontrd Cost(ACY)";
        // "Single-Lvl Cap. Ovhd Cost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)" - "Single-Lvl Cap. Ovhd Cost(ACY)";
        // "Single-Lvl Mfg. Ovhd Cost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)" - "Single-Lvl Mfg. Ovhd Cost(ACY)";

        // OnAfterCalcDiff(Rec, InvtAdjmtEntryOrder, OnlyCostShares);
    end;

    procedure AddDirectCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        "Direct Cost" += CostAmtLCY;
        "Direct Cost (ACY)" += CostAmtACY;
    end;

    procedure AddIndirectCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        "Indirect Cost" += CostAmtLCY;
        "Indirect Cost (ACY)" += CostAmtACY;
    end;

    procedure AddSingleLvlCapacityCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        // OnBeforeAddSingleLvlCapacityCost(Rec, CostAmtLCY, CostAmtACY);

        // "Single-Level Capacity Cost" += CostAmtLCY;
        // "Single-Lvl Capacity Cost (ACY)" += CostAmtACY;

        // OnAfterAddSingleLvlCapacityCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlSubcontrdCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        // OnBeforeAddSingleLvlSubcontrdCost(Rec, CostAmtLCY, CostAmtACY);

        // "Single-Level Subcontrd. Cost" += CostAmtLCY;
        // "Single-Lvl Subcontrd Cost(ACY)" += CostAmtACY;

        // OnAfterAddSingleLvlSubcontrdCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlCapOvhdCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        // OnBeforeAddSingleLvlCapOvhdCost(Rec, CostAmtLCY, CostAmtACY);

        // "Single-Level Cap. Ovhd Cost" += CostAmtLCY;
        // "Single-Lvl Cap. Ovhd Cost(ACY)" += CostAmtACY;

        // OnAfterAddSingleLvlCapOvhdCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlMfgOvhdCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        // OnBeforeAddSingleLvlMfgOvhdCost(Rec, CostAmtLCY, CostAmtACY);

        // "Single-Level Mfg. Ovhd Cost" += CostAmtLCY;
        // "Single-Lvl Mfg. Ovhd Cost(ACY)" += CostAmtACY;

        // OnAfterAddSingleLvlMfgOvhdCost(Rec, CostAmtLCY, CostAmtACY);
    end;
}