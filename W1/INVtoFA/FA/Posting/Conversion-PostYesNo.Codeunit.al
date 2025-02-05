namespace TSTChanges.FA.Posting;

using TSTChanges.FA.Conversion;
using Microsoft.Finance.GeneralLedger.Preview;

codeunit 51203 "Conversion-Post (Yes/No)"
{
    TableNo = "FA Conversion Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        ConversionHeader.Copy(Rec);
        Code();
        Rec := ConversionHeader;
    end;

    var
        ConversionHeader: Record "FA Conversion Header";
        Text000: Label 'Do you want to post the %1?';

    local procedure Code()
    begin
        if not Confirm(Text000, false, ConversionHeader.TableCaption) then
            exit;

        Codeunit.Run(CODEUNIT::"Conversion-Post", ConversionHeader)
    end;

    procedure Preview(var ConversionHeaderToPreview: Record "FA Conversion Header")
    var
        ConversionPostYesNo: Codeunit "Conversion-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(ConversionPostYesNo);
        GenJnlPostPreview.Preview(ConversionPostYesNo, ConversionHeaderToPreview);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        ConversionHeaderToPreview: Record "FA Conversion Header";
        ConversionPost: Codeunit "Conversion-Post";
    begin
        ConversionHeaderToPreview.Copy(RecVar);
        ConversionPost.SetSuppressCommit(true);
        ConversionPost.SetPreviewMode(true);
        Result := ConversionPost.Run(ConversionHeaderToPreview);
    end;
}