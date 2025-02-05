namespace TSTChanges.FA.Costing;

using TSTChanges.FA.FAItem;
using Microsoft.FixedAssets.Ledger;
using TSTChanges.FA.Ledger;
using Microsoft.Inventory.Ledger;

report 51201 "FA Acquire - Inventory"
{
    Permissions = tabledata "Item Ledger Entry" = rimd,
                  tabledata "FA Item ledger Entry" = rimd,
                  tabledata "FA Ledger Entry" = rimd;
    ApplicationArea = All;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FilterItemNo; ItemNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item No. Filter';
                        Editable = FilterItemNoEditable;
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain items. You can leave this field blank to run the batch job for all items.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemList: Page "FA Item List";
                        begin
                            ItemList.LookupMode := true;
                            if ItemList.RunModal() = ACTION::LookupOK then
                                Text := ItemList.GetSelectionFilter()
                            else
                                exit(false);

                            exit(true);
                        end;
                    }
                    field(BasedOnOutput; BasedOnOutput)
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;

                        trigger OnValidate()
                        begin
                            if UserId <> 'ADMIN' then
                                Error('Only ADMIN can use this option.');
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
        // ClientTypeManagement: Codeunit "Client Type Management";
        begin
            // FilterItemCategoryEditable := true;
            FilterItemNoEditable := true;
            // PostEnable := true;
            // if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then begin
            //     InvtSetup.Get();
            //     PostToGL := InvtSetup."Automatic Cost Posting";
            // end;
        end;

        trigger OnOpenPage()
        begin
            // InvtSetup.Get();
            // PostToGL := InvtSetup."Automatic Cost Posting";
            // PostEnable := PostToGL;
            BasedOnOutput := false;
        end;
    }

    trigger OnPreReport()
    var
        FAItem: Record "FA Item";
    begin
        // OnBeforePreReport(ItemNoFilter, ItemCategoryFilter, PostToGL, Item);

        if not LockTables() then
            CurrReport.Quit();

        // if (ItemNoFilter <> '') and (ItemCategoryFilter <> '') then
        //     Error(ItemOrCategoryFilterErr);

        if ItemNoFilter <> '' then
            FAItem.SetFilter("No.", ItemNoFilter);
        // if ItemCategoryFilter <> '' then
        //     Item.SetFilter("Item Category Code", ItemCategoryFilter);

        // InvtSetup.Get();
        // if InvtSetup."Cost Adjustment Logging" <> InvtSetup."Cost Adjustment Logging"::Disabled then
        //     RunCostAdjustmentWithLogging(Item)
        // else
        RunCostAdjustment(FAItem);

        // OnAfterPreReport();
    end;

    var
        FilterItemNoEditable: Boolean;
        BasedOnOutput: Boolean;
        FAAdjutment: Codeunit "FA Adjustment";

        ItemOrCategoryFilterErr: Label 'You must not use Item No. Filter and Item Category Filter at the same time.';

    protected var
        ItemNoFilter: Text[250];

    local procedure LockTables(): Boolean
    var
        // ItemLedgerEntry: Record "Item Ledger Entry";
        // ValueEntry: Record "Value Entry";
        // ItemApplicationEntry: Record "Item Application Entry";
        // AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        FAItemAppEntry: Record "FA Item Application Entry";
        FAILE: Record "FA Item ledger Entry";
    begin
        // ItemApplicationEntry.LockTable();
        // if ItemApplicationEntry.GetLastEntryNo() = 0 then
        //     exit(false);
        FAItemAppEntry.LockTable();
        if FAItemAppEntry.GetLastEntryNo() = 0 then
            exit(false);

        // ItemLedgerEntry.LockTable();
        // if ItemLedgerEntry.GetLastEntryNo() = 0 then
        //     exit(false);
        FAILE.LockTable();
        if FAILE.GetLastEntryNo() = 0 then
            exit(false);

        // ValueEntry.LockTable();
        // if ValueEntry.GetLastEntryNo() = 0 then
        //     exit(false);

        // AvgCostEntryPointHandler.LockBuffer();

        exit(true);
    end;

    local procedure RunCostAdjustment(var FAItem: Record "FA Item")
    var
    // UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    // UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        FAAdjutment.SetFilterItem(FAItem);
        // FAAdjutment.MakeInventoryAdjustment(false, PostToGL);
        if not BasedOnOutput then
            FAAdjutment.MakeMultiLevelAdjmt()
        else
            FAAdjutment.MakeMultiLevelAdjmtBasedonOutput();

        // if PostToGL then
        //     UpdateAnalysisView.UpdateAll(0, true);
        // UpdateItemAnalysisView.UpdateAll(0, true);
    end;
}