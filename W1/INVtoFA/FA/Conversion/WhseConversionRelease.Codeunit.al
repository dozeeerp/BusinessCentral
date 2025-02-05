namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Location;
using Microsoft.Assembly.Document;
using Microsoft.Warehouse.Request;

codeunit 51207 "Whse.-Conversion Release"
{
    trigger OnRun()
    begin

    end;

    var
        WhseRqst: Record "Warehouse Request";
        WhsePickRqst: Record "Whse. Pick Request";

    procedure Release(ConversionHeader: Record "FA Conversion Header")
    var
        ConversionLine: Record "FA Conversion Line";
        LocationOutput: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;
    begin
        if ConversionHeader."Location Code" <> '' then begin
            LocationOutput.SetLoadFields("Directed Put-away and Pick");
            if LocationOutput.Get(ConversionHeader."Location Code") then
                if LocationOutput."Directed Put-away and Pick" then
                    ConversionHeader.TestField("Unit of Measure Code");
        end;

        OldLocationCode := '';
        FilterConversionLine(ConversionLine, ConversionHeader."No.");
        if ConversionLine.Find('-') then begin
            First := true;
            repeat
                if First or (ConversionLine."Location Code" <> OldLocationCode) then
                    CreateWhseRqst(ConversionHeader, ConversionLine);

                First := false;
                OldLocationCode := ConversionLine."Location Code";
            until ConversionLine.Next() = 0;
        end;

        WhseRqst.Reset();
        WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseRqst.SetRange(Type, WhseRqst.Type);
        WhseRqst.SetRange("Source Type", DATABASE::"FA Conversion Line");
        WhseRqst.SetRange("Source Subtype", 0);//"Document Type");
        WhseRqst.SetRange("Source No.", ConversionHeader."No.");
        WhseRqst.SetRange("Document Status", ConversionHeader.Status::Open);
        WhseRqst.DeleteAll(true);
    end;

    procedure Reopen(ConversionHeader: Record "FA Conversion Header")
    begin
        WhseRqst.Type := WhseRqst.Type::Outbound;

        WhseRqst.Reset();
        WhseRqst.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseRqst.SetRange(Type, WhseRqst.Type);
        WhseRqst.SetRange("Source Type", DATABASE::"FA Conversion Line");
        WhseRqst.SetRange("Source Subtype", 0);//"Document Type");
        WhseRqst.SetRange("Source No.", ConversionHeader."No.");
        WhseRqst.SetRange("Document Status", ConversionHeader.Status::Released);
        WhseRqst.LockTable();
        if not WhseRqst.IsEmpty() then
            WhseRqst.ModifyAll("Document Status", WhseRqst."Document Status"::Open);

        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
        WhsePickRqst.SetRange("Document No.", ConversionHeader."No.");
        WhsePickRqst.SetRange(Status, ConversionHeader.Status::Released);
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.ModifyAll(Status, WhsePickRqst.Status::Open);
    end;

    local procedure CreateWhseRqst(Var ConversionHeader: Record "FA Conversion Header"; var ConversionLine: Record "FA Conversion Line")
    var
        ConversionLine2: Record "FA Conversion Line";
        Location: Record Location;
    begin
        GetLocation(Location, ConversionLine."Location Code");
        If Location."Asm. Consump. Whse. Handling" = Enum::"Asm. Consump. Whse. Handling"::"No Warehouse Handling" then
            exit;

        ConversionLine2.Copy(ConversionLine);
        ConversionLine2.SetRange("Location Code", ConversionLine."Location Code");
        ConversionLine2.SetRange("Unit of Measure Code", '');
        if ConversionLine2.FindFirst() then
            ConversionLine2.TestField("Unit of Measure Code");

        Case Location."Asm. Consump. Whse. Handling" of
            Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)",
            Enum::"Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)":
                begin
                    WhsePickRqst.Init();
                    WhsePickRqst."Document Type" := WhsePickRqst."Document Type"::Assembly;
                    WhsePickRqst."Document Subtype" := 0;//AssemblyLine."Document Type".AsInteger();
                    WhsePickRqst."Document No." := ConversionLine."Document No.";
                    WhsePickRqst.Status := WhsePickRqst.Status::Released;
                    WhsePickRqst."Location Code" := ConversionLine."Location Code";
                    WhsePickRqst."Completely Picked" := ConversionHeader.CompletelyPicked();
                    if WhsePickRqst."Completely Picked" and (not ConversionLine.CompletelyPicked()) then
                        WhsePickRqst."Completely Picked" := false;
                    if not WhsePickRqst.Insert() then
                        WhsePickRqst.Modify();
                end;
            Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement":
                begin
                    WhseRqst.Init();
                    // case ConversionHeader."Document Type" of
                    //     ConversionHeader."Document Type"::Order:
                    WhseRqst.Type := WhseRqst.Type::Outbound;
                    // end;
                    WhseRqst."Source Document" := WhseRqst."Source Document"::"Assembly Consumption";
                    WhseRqst."Source Type" := DATABASE::"FA Conversion Line";
                    WhseRqst."Source Subtype" := 0;//ConversionLine."Document Type".AsInteger();
                    WhseRqst."Source No." := ConversionLine."Document No.";
                    WhseRqst."Document Status" := WhseRqst."Document Status"::Released;
                    WhseRqst."Location Code" := ConversionLine."Location Code";
                    WhseRqst."Destination Type" := WhseRqst."Destination Type"::Item;
                    WhseRqst."Destination No." := ConversionHeader."FA Item No.";
                    WhseRqst."Completely Handled" := ConversionCompletelyHandled(ConversionHeader, ConversionLine."Location Code");
                    // OnBeforeWhseRequestInsert(WhseRqst, AssemblyLine, AssemblyHeader);
                    if not WhseRqst.Insert() then
                        WhseRqst.Modify();
                end;
        End;
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then begin
                Location.GetLocationSetup(LocationCode, Location);
                Location.Code := '';
            end else
                Location.Get(LocationCode);
    end;

    local procedure FilterConversionLine(var ConversionLine: Record "FA Conversion Line"; DocumentNo: Code[20])
    begin
        ConversionLine.SetCurrentKey("Document No.", Type, "Location Code");
        ConversionLine.SetRange("Document No.", DocumentNo);
        ConversionLine.SetRange(Type, ConversionLine.Type::Item);
    end;

    local procedure ConversionCompletelyHandled(ConversionHeader: Record "FA Conversion Header"; LocationCode: Code[10]): Boolean
    var
        ConversionLine: Record "FA Conversion Line";
    begin
        FilterConversionLine(ConversionLine, ConversionHeader."No.");
        ConversionLine.SetRange("Location Code", LocationCode);
        ConversionLine.SetFilter("Remaining Quantity", '<>0');
        exit(not ConversionLine.Find('-'));
    end;

    procedure DeleteLine(ConversionLine: Record "FA Conversion Line")
    var
        ConversionLine2: Record "FA Conversion Line";
        Location: Record Location;
        KeepWhseRqst: Boolean;
    begin
        // with ConversionLine do begin
        if ConversionLine.Type <> ConversionLine.Type::Item then
            exit;
        KeepWhseRqst := false;
        if Location.Get(ConversionLine."Location Code") then;
        FilterConversionLine(ConversionLine2, ConversionLine."Document No.");
        ConversionLine2.SetFilter("Line No.", '<>%1', ConversionLine."Line No.");
        ConversionLine2.SetRange("Location Code", ConversionLine."Location Code");
        ConversionLine2.SetFilter("Remaining Quantity", '<>0');
        if ConversionLine2.Find('-') then
            // Other lines for same location exist in the order.
            repeat
                if (not ConversionLine2.CompletelyPicked()) or
                   (not (Location."Require Pick" and Location."Require Shipment"))
                then
                    KeepWhseRqst := true; // if lines are incompletely picked.
            until (ConversionLine2.Next() = 0) or KeepWhseRqst;

        // OnDeleteLineOnBeforeDeleteWhseRqst(AssemblyLine2, KeepWhseRqst);

        if not KeepWhseRqst then
            if Location."Require Shipment" then
                DeleteWhsePickRqst(ConversionLine, false)
            else
                DeleteWhseRqst(ConversionLine, false);
        // end;
    end;

    local procedure DeleteWhsePickRqst(ConversionLine: Record "FA Conversion Line"; DeleteAllWhsePickRqst: Boolean)
    begin
        // with ConversionLine do begin
        WhsePickRqst.SetRange("Document Type", WhsePickRqst."Document Type"::Assembly);
        WhsePickRqst.SetRange("Document No.", ConversionLine."Document No.");
        if not DeleteAllWhsePickRqst then begin
            // WhsePickRqst.SetRange("Document Subtype", "Document Type");
            WhsePickRqst.SetRange("Location Code", ConversionLine."Location Code");
        end;
        if not WhsePickRqst.IsEmpty() then
            WhsePickRqst.DeleteAll(true);
        // end;
    end;

    local procedure DeleteWhseRqst(ConversionLine: Record "FA Conversion Line"; DeleteAllWhseRqst: Boolean)
    var
        WhseRqst: Record "Warehouse Request";
    begin
        // with ConversionLine do begin
        if not DeleteAllWhseRqst then
            case true of
                ConversionLine."Remaining Quantity" > 0:
                    WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
                ConversionLine."Remaining Quantity" < 0:
                    WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
                ConversionLine."Remaining Quantity" = 0:
                    exit;
            end;
        WhseRqst.SetRange("Source Type", DATABASE::"FA Conversion Line");
        WhseRqst.SetRange("Source No.", ConversionLine."Document No.");
        if not DeleteAllWhseRqst then begin
            // WhseRqst.SetRange("Source Subtype", "Document Type");
            WhseRqst.SetRange("Location Code", ConversionLine."Location Code");
        end;
        if not WhseRqst.IsEmpty() then
            WhseRqst.DeleteAll(true);
        // end;
    end;
}