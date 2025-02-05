namespace TSTChanges.FA.Posting;

using TSTChanges.FA.History;
using TSTChanges.FA.Conversion;

codeunit 51232 "Pstd. Conversion-Undo (Yes/No)"
{
    TableNo = "Posted Conversion Header";

    trigger OnRun()
    begin
        PostedConHeader := Rec;
        Code();
        Rec := PostedConHeader;
    end;

    var
        PostedConHeader: Record "Posted Conversion Header";
        Text000: Label 'Do you want to undo posting of the posted conversion order?';
        Text001: Label 'Do you want to recreate the conversion order from the posted conversion order?';

    local procedure Code()
    var
        ConHeader: Record "FA Conversion Header";
        ConPost: Codeunit "Conversion-Post";
        DoRecreateConOrder: Boolean;
    begin
        if not Confirm(Text000, false) then
            exit;

        if not ConHeader.Get(PostedConHeader."Order No.") then
            DoRecreateConOrder := Confirm(Text001);

        ConPost.Undo(PostedConHeader, DoRecreateConOrder);
        Commit();
    end;
}