// namespace TSTChanges.FA;

// using Microsoft.Warehouse.Request;
// using TSTChanges.FA.Conversion;
// using Microsoft.Inventory.Item;
// using Microsoft.Warehouse.Activity;
// using Microsoft.Warehouse.Worksheet;
// using Microsoft.Warehouse.Setup;
// using System.Telemetry;
// using Microsoft.Warehouse.Journal;
// using Microsoft.Inventory.Location;

// reportextension 51200 "TST_WhseCreateSurce" extends "Whse.-Source - Create Document"
// {
//     dataset
//     {
//         // Add changes to dataitems and columns here
//         addlast("Assembly Line")
//         {
//             dataitem("FA Conversion Line"; "FA Conversion Line")
//             {
//                 DataItemTableView = sorting("Document No.", Type, "Location Code") where(Type = const(Item));

//                 trigger OnAfterGetRecord()
//                 var
//                     Item: Record Item;
//                     Location: Record Location;
//                     WMSMgt: Codeunit "WMS Management";
//                 begin
//                     if "FA Conversion Line"."Location Code" <> '' then begin
//                         Location.Get("FA Conversion Line"."Location Code");
//                         if not (Location."Asm. Consump. Whse. Handling" in [Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
//                             CurrReport.Skip();
//                     end;

//                     FeatureTelemetry1.LogUsage('0000KT0', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);

//                     Item.Get("No.");
//                     if Item.IsNonInventoriableType() then
//                         CurrReport.Skip();

//                     if not CheckIfAssemblyLineMeetsReservedFromStockSetting("Remaining Quantity (Base)", ReservedFromStock) then
//                         CurrReport.Skip();

//                     WMSMgt.CheckInboundBlockedBin("Location Code", "Bin Code", "No.", "Variant Code", "Unit of Measure Code");

//                     WhseWkshLine1.SetRange("Source Line No.", "Line No.");
//                     if not WhseWkshLine1.FindFirst() then
//                         CreatePick.CreateAssemblyPickLine("FA Conversion Line")
//                     else begin
//                         WhseWkshLineFound := true;
//                         CreatePick.InsertSkippedLinesToCalculationSummary(Database::"FA Conversion Line", "Document No.", "Line No.", "Document Type".AsInteger(), 0, "Location Code", "No.", "Variant Code", "Unit of Measure Code", "Bin Code", Quantity, "Quantity (Base)", WhseWkshLine1.SystemId);
//                     end;
//                 end;

//                 trigger OnPreDataItem()
//                 begin
//                     if WhseDoc1 <> WhseDoc1::Conversion then
//                         CurrReport.Break();

//                     WhseSetup1.Get();

//                     Clear(CreatePickParameters1);
//                     CreatePickParameters1."Assigned ID" := AssignedID;
//                     CreatePickParameters1."Sorting Method" := SortActivity;
//                     CreatePickParameters1."Max No. of Lines" := 0;
//                     CreatePickParameters1."Max No. of Source Doc." := 0;
//                     CreatePickParameters1."Do Not Fill Qty. to Handle" := DoNotFillQtytoHandle;
//                     CreatePickParameters1."Breakbulk Filter" := BreakbulkFilter;
//                     CreatePickParameters1."Per Bin" := false;
//                     CreatePickParameters1."Per Zone" := false;
//                     CreatePickParameters1."Whse. Document" := CreatePickParameters1."Whse. Document"::Assembly;
//                     CreatePickParameters1."Whse. Document Type" := CreatePickParameters1."Whse. Document Type"::Pick;
//                     CreatePick.SetParameters(CreatePickParameters1);
//                     CreatePick.SetSaveSummary(ShowSummary);

//                     SetRange("Document No.", ConversionHeader."No.");
//                     // SetRange("Document Type", AssemblyHeader."Document Type");
//                     SetRange(Type, Type::Item);
//                     SetFilter("Remaining Quantity (Base)", '>0');

//                     WhseWkshLine1.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
//                     WhseWkshLine1.SetRange("Source Type", Database::"FA Conversion Line");
//                     // WhseWkshLine1.SetRange("Source Subtype", ConversionHeader."Document Type");
//                     WhseWkshLine1.SetRange("Source No.", ConversionHeader."No.");
//                 end;
//             }
//         }
//     }

//     requestpage
//     {
//         // Add changes to the requestpage here
//     }

//     // rendering
//     // {
//     //     layout(LayoutName)
//     //     {
//     //         Type = RDLC;
//     //         LayoutFile = 'mylayout.rdl';
//     //     }
//     // }
//     var
//         WhseSetup1: Record "Warehouse Setup";
//         WhseWkshLine1: Record "Whse. Worksheet Line";
//         CreatePickParameters1: Record "Create Pick Parameters";
//         ConversionHeader: Record "FA Conversion Header";
//         WhseDoc1: Option "Whse. Mov.-Worksheet","Posted Receipt","Internal Pick","Internal Put-away",Production,"Put-away Worksheet",Assembly,"Service Order",Job,Conversion;
//         SourceTableCaption1: Text;
//         FeatureTelemetry1: Codeunit "Feature Telemetry";

//     procedure SetConversionOrder(var ConversionHeader2: Record "FA Conversion Header")
//     begin
//         ConversionHeader.Copy(ConversionHeader2);
//         WhseDoc1 := WhseDoc1::Conversion;
//         SourceTableCaption1 := ConversionHeader.TableCaption();
//         // OnAfterSetAssemblyOrder(AssemblyHeader, SortActivity);
//     end;
// }