namespace TSTChanges.FA;

using TSTChanges.FA.Setup;
using Microsoft.Utilities;
using TSTChanges.FA.FAItem;
using Microsoft.Foundation.NoSeries;

codeunit 51209 TSTDocumentNoVisibility
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        MSDocNoVisibility: Codeunit DocumentNoVisibility;
        IsFATransferOrdNoInitialized: Boolean;
        IsFAItemNoInitialized: Boolean;
        FATransferOrdNoVisible: Boolean;
        ItemNoVisible: Boolean;

    procedure FATransferOrderNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        // OnBeforeTransferOrderNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsFATransferOrdNoInitialized then
            exit(FATransferOrdNoVisible);
        IsFATransferOrdNoInitialized := true;

        NoSeriesCode := DetermineFATransferOrderSeriesNo();
        FATransferOrdNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(FATransferOrdNoVisible);
    end;

    local procedure DetermineFATransferOrderSeriesNo(): Code[20]
    var
        FAConversionSetup: Record "FA Conversion Setup";
    begin
        FAConversionSetup.Get();
        exit(FAConversionSetup."FA Transfer Order Nos.");
    end;

    procedure ForceShowNoSeriesForDocNo(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SeriesDate: Date;
    begin
        if not NoSeries.Get(NoSeriesCode) then
            exit(true);

        SeriesDate := WorkDate();
        NoSeriesRelationship.SetRange(Code, NoSeriesCode);
        if not NoSeriesRelationship.IsEmpty() then
            exit(true);

        if NoSeries."Manual Nos." or (NoSeries."Default Nos." = false) then
            exit(true);

        exit(NoSeriesBatch.GetNextNo(NoSeriesCode, SeriesDate, true) = '');
    end;

    procedure ItemNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        // OnBeforeItemNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsFAItemNoInitialized then
            exit(ItemNoVisible);
        IsFAItemNoInitialized := true;

        NoSeriesCode := DetermineItemSeriesNo();
        ItemNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ItemNoVisible);
    end;

    local procedure DetermineItemSeriesNo(): Code[20]
    var
        FAConSetup: Record "FA Conversion Setup";
    begin
        FAConSetup.Get();
        exit(FAConSetup."FA Item Nos.");
    end;

    procedure ItemNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineItemSeriesNo()) then begin
            exit(NoSeries."Default Nos.");
        end;
        exit(false);
    end;
}