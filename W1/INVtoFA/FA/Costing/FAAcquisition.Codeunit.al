namespace TSTChanges.FA.Costing;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Foundation.Enums;
using TSTChanges.FA.Conversion;
using Microsoft.Inventory.Posting;
using TSTChanges.FA.Setup;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Journal;

codeunit 51227 "FA Acquisition mgmt"
{
    trigger OnRun()
    begin

    end;

    var
    // FAJnlLine: Record "FA Journal Line";

    procedure AcquireFA(FA: Record "Fixed Asset"; PostingDate: Date; Amount: decimal; DocNo: Code[20])
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        GLPost: Boolean;
        SalvageValue: Decimal;
    begin
        // FA.CalcFields(Acquired);
        if FA.Acquired then
            exit;

        SalvageValue := Amount * 0.05;

        FASetup.Get();
        FADeprBook.SetRange("FA No.", FA."No.");

        if FADeprBook.Count = 1 then
            InitGenJnlLine(PostingDate, FA, FADeprBook."Depreciation Book Code", Amount, SalvageValue, DocNo)
        else
            if FADeprBook.FindSet() then begin
                repeat
                    DeprBook.Get(FADeprBook."Depreciation Book Code");
                    if DeprBook."G/L Integration - Acq. Cost" and not GLPost then begin
                        InitGenJnlLine(PostingDate, FA, FADeprBook."Depreciation Book Code", Amount, SalvageValue, DocNo);
                        GLPost := true
                    end else
                        InitFAJnlLine(PostingDate, FA, FADeprBook."Depreciation Book Code", Amount, SalvageValue, DocNo);
                until FADeprBook.Next() = 0;
            end;
    end;

    local procedure InitGenJnlLine(PostingDate: Date; FA: Record "Fixed Asset"; DeprBookCode: code[10]; Amount: Decimal; SalvageValue: Decimal; DocNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GlEntryNo: Integer;
        FAConSetup: Record "FA Conversion Setup";
    begin
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Document No." := DocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Fixed Asset";
        GenJnlLine.Validate("Account No.", FA."No.");
        GenJnlLine.validate(Amount, Amount);

        GenJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type"::"Acquisition Cost";
        GenJnlLine."Depreciation Book Code" := DeprBookCode;
        GenJnlLine."Salvage Value" := -SalvageValue;

        FAConSetup.Get();
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        FAConSetup.TestField("Inventory Capitalize Account");
        GenJnlLine."Bal. Account No." := FAConSetup."Inventory Capitalize Account";
        GenJnlLine."System-Created Entry" := true;

        GLEntryNo := GenJnlPostLine.RunWithCheck(GenJnlLine)
    end;

    local procedure InitFAJnlLine(PostingDate: Date; FA: Record "Fixed Asset"; DeprBookCode: code[10]; Amount: Decimal; SalvageValue: Decimal; DocNo: Code[20])
    var
        FAJnlLine: Record "FA Journal Line";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
    begin
        FAJnlLine.Init();
        FAJnlLine."FA Posting Date" := PostingDate;
        FAJnlLine."Document No." := DocNo;
        FAJnlLine.Validate("FA No.", FA."No.");
        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Acquisition Cost";
        FAJnlLine.Validate(Amount, Amount);

        FAJnlPostLine.FAJnlPostLine(FAJnlLine, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnBeforeSetOrderAdjmtProperties, '', false, false)]
    local procedure SetConversionAdjmtProperties(OriginalPostingDate: Date; var IsHandled: Boolean; OrderNo: Code[20]; OrderType: Option; OrderLineNo: Integer)
    var
        FAAdjmtEntryOrder: Record "FA Adjmt. Entry (Order)";
        FAConHeader: Record "FA Conversion Header";
        ModifyOrderAdjmt: Boolean;
    begin
        if not (OrderType = "Inventory order Type"::Conversion.AsInteger()) then
            exit;

        if not FAAdjmtEntryOrder.Get(OrderType, OrderNo, OrderLineNo) then begin
            if OrderLineNo = 0 then begin
                FAConHeader.Get(OrderNo);
                FAAdjmtEntryOrder.SetConOrder(FAConHeader);
            end;
            SetConversionAdjmtProperties(OriginalPostingDate, IsHandled, OrderNo, OrderType, 0);
        end else
            if FAAdjmtEntryOrder."Allow Online Adjustment" or FAAdjmtEntryOrder."Cost is Adjusted" then begin
                FAAdjmtEntryOrder.LockTable();
                if FAAdjmtEntryOrder."Cost is Adjusted" then begin
                    FAAdjmtEntryOrder."Cost is Adjusted" := false;
                    ModifyOrderAdjmt := true;
                end;

                if FAAdjmtEntryOrder."Allow Online Adjustment" then begin
                    FAAdjmtEntryOrder."Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                    ModifyOrderAdjmt := ModifyOrderAdjmt or not FAAdjmtEntryOrder."Allow Online Adjustment";
                end;
                if ModifyOrderAdjmt then
                    FAAdjmtEntryOrder.Modify();
            end;
        IsHandled := true;
    end;

    procedure AllowAdjmtOnPosting(TheDate: Date): Boolean
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();

        case InvtSetup."Automatic Cost Adjustment" of
            InvtSetup."Automatic Cost Adjustment"::Never:
                exit(false);
            InvtSetup."Automatic Cost Adjustment"::Day:
                exit(TheDate >= CalcDate('<-1D>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Week:
                exit(TheDate >= CalcDate('<-1W>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Month:
                exit(TheDate >= CalcDate('<-1M>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Quarter:
                exit(TheDate >= CalcDate('<-1Q>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Year:
                exit(TheDate >= CalcDate('<-1Y>', WorkDate()));
            else
                exit(true);
        end;
    end;
}