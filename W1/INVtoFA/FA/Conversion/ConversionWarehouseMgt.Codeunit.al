namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;
using TSTChanges.Warehouse;
using Microsoft.Warehouse.Journal;

codeunit 51201 "Conversion Warehouse Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        MS_WMSManagement: Codeunit "WMS Management";
        TST_WMSManagement: Codeunit "TST WMS Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        ConversionLine: Record "FA Conversion Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"FA Conversion Line" then begin
            // ConversionLine.SetRange("Document Type", SourceSubType);
            ConversionLine.SetRange("Document No.", SourceNo);
            ConversionLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
#if not CLEAN23
            // MS_WMSManagement.RunOnShowSourceDocLineOnBeforeShowAssemblyLines(ConversionLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
#endif
            // OnBeforeShowAssemblyLines(AssemblyLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                PAGE.RunModal(PAGE::"FA Conversion Lines", ConversionLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        ConversionHeader: Record "FA Conversion Header";
    begin
        if SourceType = Database::"FA Conversion Line" then
            if ConversionHeader.Get(SourceNo) then begin
                // ConversionHeader.SetRange("Document Type", SourceSubType);
                PAGE.RunModal(PAGE::"FA Conversion Order", ConversionHeader);
            end;
    end;

    procedure ConversionLineVerifyChange(var NewConversionLine: Record "FA Conversion Line"; var OldConversionLine: Record "FA COnversion Line")
    var
        Location: Record Location;
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
    begin
        if OldConversionLine.Type <> OldConversionLine.Type::Item then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"FA Conversion Line", //NewConversionLine."Document Type".AsInteger()
             0, NewConversionLine."Document No.",
             NewConversionLine."Line No.", 0, NewConversionLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewConversionLine);
        OldRecordRef.GetTable(OldConversionLine);

        // with NewConversionLine do begin
        //     // WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo("Document Type"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Document No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Unit of Measure Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Due Date"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo(Quantity));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Quantity per"));
        if Location.Get(NewConversionLine."Location Code") and not Location."Require Shipment" then
            WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewConversionLine.FieldNo("Quantity to Consume"));
        // end;

        // OnAfterAssemblyLineVerifyChange(NewRecordRef, OldRecordRef);
        // #if not CLEAN23
        //         WhseValidateSourceLine.RunOnAfterAssemblyLineVerifyChange(NewRecordRef, OldRecordRef);
    end;

    procedure ConversionLineDelete(var ConversionLine: Record "FA Conversion Line")
    begin
        if ConversionLine.Type <> ConversionLine.Type::Item then
            exit;

        if WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"FA Conversion Line", 0,//ConversionLine."Document Type".AsInteger(), 
                ConversionLine."Document No.", ConversionLine."Line No.", 0, ConversionLine.Quantity)
        then
            RaiseCannotBeDeletedErr(ConversionLine.TableCaption());

        // OnAfterAssemblyLineDelete(ConversionLine);
#if not CLEAN23
        // WhseValidateSourceLine.RunOnAfterAssemblyLineDelete(ConversionLine);
#endif
    end;

    internal procedure RaiseCannotBeDeletedErr(SourceTableCaption: Text)
    var
        Text001: Label 'The %1 cannot be deleted when a related %2 exists.';
        TableCaptionValue: Text;
    begin
        Error(Text001, SourceTableCaption, TableCaptionValue);
    end;

}