namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Tracking;
using TSTChanges.Automation;
using System.Automation;
using Microsoft.Warehouse.Request;
using TSTChanges.FA.Tracking;
using Microsoft.Foundation.UOM;
using TSTChanges.FA.FAItem;
using TSTChanges.FA.Setup;
using Microsoft.Foundation.NoSeries;

table 51204 "FA Conversion Header"
{
    DataClassification = CustomerContent;
    Caption = 'FA Conversion Header';
    DataCaptionFields = "No.", Description;
    DrillDownPageId = "FA Conversion Orders";
    LookupPageId = "FA Conversion Orders";
    Permissions = tabledata "FA Conversion Line" = d;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                TestStatusOpen();
                if "No." <> xRec."No." then begin
                    FAConversionSetup.Get();
                    NoSeries.TestManual(FAConversionSetup."Conversion Order No.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "FA Item No."; Code[20])
        {
            Caption = 'FA Item No.';
            DataClassification = CustomerContent;
            TableRelation = "FA Item";

            trigger OnValidate()
            begin
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("FA Item No."));

                if "FA Item No." <> xRec."FA Item No." then
                    "Variant Code" := '';

                if "FA Item No." <> '' then begin
                    SetDescriptionsFromItem();
                    Validate("Unit of Measure Code", FAItem."Base Unit of Measure");
                    // ValidateDates(FieldNo("Due Date"), true);
                    // GetDefaultBin();
                end;
                ConversionLineMgt.UpdateConversionLines(Rec, xRec, FieldNo("FA Item No."), true, CurrFieldNo, CurrentFieldNum);
                ConversionHeaderReserve.VerifyChange(Rec, xRec);
                ClearCurrentFieldNum(FieldNo("FA Item No."));
            end;
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(5; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(7; "Due Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                // ValidateDueDate("Due Date", true);
            end;
        }
        field(8; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                // ValidateStartDate("Starting Date", true);
            end;
        }
        field(9; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                // ValidateEndDate("Ending Date", true);
            end;
        }
        field(10; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo(Quantity));
                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                // "Cost Amount" := Round(Quantity * "Unit Cost");
                if Quantity < "Converted Quantity" then
                    Error(Text002, FieldCaption(Quantity), FieldCaption("Converted Quantity"), "Converted Quantity");

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption("Quantity (Base)"), FieldCaption(Quantity));
                InitRemainingQty();
                InitQtyToConvert();
                Validate("Quantity to Convert");

                UpdateConversionLinesAndVerifyReserveQuantity();

                ClearCurrentFieldNum(FieldNo(Quantity));
            end;
        }
        field(11; "Quantity (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(12; "Remaining Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(13; "Remaining Quantity (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(14; "Converted Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Converted Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; "Converted Quantity (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Converted Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Quantity to Convert"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity to Convert';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                // ATOLink: Record "Assemble-to-Order Link";
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                SetCurrentFieldNum(FieldNo("Quantity to Convert"));

                "Quantity to Convert" := UOMMgt.RoundAndValidateQty("Quantity to Convert", "Qty. Rounding Precision", FieldCaption("Quantity to Convert"));
                if "Quantity to Convert" > "Remaining Quantity" then
                    Error(Text003,
                      FieldCaption("Quantity to Convert"), FieldCaption("Remaining Quantity"), "Remaining Quantity");

                // if "Quantity to Convert" <> xRec."Quantity to Convert" then
                //     ATOLink.CheckQtyToAsm(Rec);

                Validate(
                    "Quantity to Convert (Base)",
                    CalcBaseQty("Quantity to Convert", FieldCaption("Quantity to Convert (Base)"), FieldCaption("Quantity to Convert"))
                );

                ConversionLineMgt.UpdateConversionLines(Rec, xRec, FieldNo("Quantity to Convert"), false, CurrFieldNo, CurrentFieldNum);
                ClearCurrentFieldNum(FieldNo("Quantity to Convert"));
            end;
        }
        field(17; "Quantity to Convert (Base)"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity to Convert (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Posting No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Posting No.';
            Editable = false;
        }
        // field(19; "Unit of Measure"; Code[50])
        // {
        //     DataClassification = CustomerContent;
        // }
        field(20; "Qty. per Unit of Measure"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(21; Status; Enum "Conversion Document Status")
        {
            Caption = 'Status';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Location Code"));
                // ValidateDates(FieldNo("Due Date"), true);
                ConversionLineMgt.UpdateConversionLines(Rec, xRec, FieldNo("Location Code"), false, CurrFieldNo, CurrentFieldNum);
                ConversionHeaderReserve.VerifyChange(Rec, xRec);
                // GetDefaultBin();
                // Validate("Unit Cost", GetUnitCost());
                ClearCurrentFieldNum(FieldNo("Location Code"));
                // CreateDimFromDefaultDim();
            end;
        }
        field(23; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "FA Item Unit of Measure".Code where("Item No." = field("FA Item No."));

            trigger OnValidate()
            begin
                TestField("Converted Quantity", 0);
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Unit of Measure Code"));

                "Qty. per Unit of Measure" := 1;//UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := 1;//UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := 1;//UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                // "Unit Cost" := GetUnitCost();
                // "Overhead Rate" := Item."Overhead Rate";

                ConversionLineMgt.UpdateConversionLines(Rec, xRec, FieldNo("Unit of Measure Code"),
                                                        //ReplaceLinesFromBOM(),
                                                        False, CurrFieldNo, CurrentFieldNum);
                ClearCurrentFieldNum(FieldNo("Unit of Measure Code"));

                Validate(Quantity);
            end;
        }
        field(24; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(25; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                ConversionHeader: Record "FA Conversion Header";
                NoSeries: Codeunit "No. Series";
            begin
                ConversionHeader := Rec;
                FAConversionSetup.Get();
                TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(FAConversionSetup."Posted Conversion Order No.", ConversionHeader."Posting No. Series") then
                    ConversionHeader.Validate("Posting No. Series");
                Rec := ConversionHeader;
            end;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                TestStatusOpen();
                if "Posting No. Series" <> '' then begin
                    FAConversionSetup.Get();
                    TestNoSeries();
                    NoSeries.TestAreRelated(FAConversionSetup."Posted Conversion Order No.", "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }

        field(26; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(27; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(28; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "FA Item Variant".Code where("Item No." = field("FA Item No."),
                                                       Code = field("Variant Code"));

            trigger OnValidate()
            var
                ItemVariant: Record "FA Item Variant";
                IsHandled: Boolean;
            begin
                // CheckIsNotAsmToOrder();
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Variant Code"));
                if Rec."Variant Code" = '' then
                    SetDescriptionsFromItem()
                else begin
                    ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                    ItemVariant.Get("FA Item No.", "Variant Code");
                    ItemVariant.TestField(Blocked, false);
                    Description := ItemVariant.Description;
                    // "Description 2" := ItemVariant."Description 2";
                end;
                // IsHandled := false;
                // OnValidateVariantCodeOnBeforeValidateDates(Rec, xRec, IsHandled);
                // if not IsHandled then
                // ValidateDates(FieldNo("Due Date"), true);

                IsHandled := false;
                // OnValidateVariantCodeOnBeforeUpdateAssemblyLines(Rec, xRec, CurrFieldNo, CurrentFieldNum, IsHandled);
                if not IsHandled then
                    ConversionLineMgt.UpdateConversionLines(Rec, xRec, FieldNo("Variant Code"), false, CurrFieldNo, CurrentFieldNum);
                ConversionHeaderReserve.VerifyChange(Rec, xRec);
                // GetDefaultBin();
                // Validate("Unit Cost", GetUnitCost());
                ClearCurrentFieldNum(FieldNo("Variant Code"));
            end;
        }
        field(29; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if (Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                     "Item No." = field("FA Item No."),
                                                                                     "Variant Code" = field("Variant Code"))
            else
            Bin.Code where("Location Code" = field("Location Code"));
        }
        field(30; "Reserved Quantity"; Decimal)
        {
            CalcFormula = sum("FA Reservation Entry".Quantity where("Source ID" = field("No."),
                                                                  "Source Type" = const(51204),
#pragma warning disable AL0603
                                                                  "Source Subtype" = const("0"),//field("Document Type"),
#pragma warning restore
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("FA Reservation Entry"."Quantity (Base)" where("Source ID" = field("No."),
                                                                           "Source Type" = const(51204),
#pragma warning disable AL0603
                                                                           "Source Subtype" = Const("0"),
#pragma warning restore
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "FA Item No.", "Variant Code", "Location Code", "Due Date")
        {
            IncludedFields = "Remaining Quantity (Base)";
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        FAConversionSetup.Get();

        if "No." = '' then begin
            TestNoSeries();
            if NoSeries.AreRelated(FAConversionSetup."Conversion Order No.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := FAConversionSetup."Conversion Order No.";
            "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
        end;

        InitRecord();

        if GetFilter("FA Item No.") <> '' then
            if GetRangeMin("FA Item No.") = GetRangeMax("FA Item No.") then
                Validate("FA Item No.", GetRangeMin("FA Item No."));
    end;

    trigger OnModify()
    begin
        ConversionHeaderReserve.VerifyChange(Rec, xRec);
    end;

    trigger OnDelete()
    begin
        ConversionHeaderReserve.DeleteLine(Rec);
        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
        ApprovalsMgt.OnDeleteRecordInApprovalRequest(RecordId);

        DeleteConversionLines()
    end;

    trigger OnRename()
    begin
        Error(Text009, TableCaption);
    end;

    var
        ConversionLine: Record "FA Conversion Line";
        FAConversionSetup: Record "FA Conversion Setup";
        FAItem: record "FA Item";
        ConversionLineMgt: Codeunit "Conversion Line Management";
        CurrentFieldNum: Integer;
        ApprovalsMgt: Codeunit "Approvals Mgmt.";
        ConversionHeaderReserve: Codeunit "Conversion Header-Reserve";
        Text001: Label 'Conversion order %1 cannot be created, because it already exists or has been posted.', Comment = '%1 = No.';
        Text002: Label '%1 cannot be lower than the %2, which is %3.';
        Text003: Label '%1 cannot be higher than the %2, which is %3.';
        Text007: Label 'Nothing to handle. The assembly line items are completely picked.';
        Text009: Label 'You cannot rename an %1.';

    protected var
        StatusCheckSuspended: Boolean;
        HideValidationDialog: Boolean;

    procedure InitRecord()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if ("No. Series" <> '') and
        (FAConversionSetup."Conversion Order No." = FAConversionSetup."Posted Conversion Order No.")
        then
            "Posting No. Series" := "No. Series"
        else
            if NoSeries.IsAutomatic(FAConversionSetup."Posted Conversion Order No.") then
                "Posting No. Series" := FAConversionSetup."Posted Conversion Order No.";

        "Creation Date" := WorkDate();
        if "Due Date" = 0D then
            "Due Date" := WorkDate();
        "Posting Date" := WorkDate();
        if "Starting Date" = 0D then
            "Starting Date" := WorkDate();
        if "Ending Date" = 0D then
            "Ending Date" := WorkDate();

        SetDefaultLocation();
    end;

    local procedure SetDefaultLocation()
    var
        FAConversionSetup: Record "FA Conversion Setup";
    begin
        if FAConversionSetup.Get() then
            if FAConversionSetup."Default Location for Orders" <> '' then
                if "Location Code" = '' then
                    Validate("Location Code", FAConversionSetup."Default Location for Orders");
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;
        TestField(Status, Status::Open);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure IsStatusCheckSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    procedure AssistEdit(OldConversionHeader: Record "FA Conversion Header"): Boolean
    var
        ConversionHeader: Record "FA Conversion Header";
        NoSeries: Codeunit "No. Series";
        DefaultSelectedNoSeries: Code[20];
    begin
        FAConversionSetup.Get();
        TestNoSeries();
        if "No. Series" <> '' then
            DefaultSelectedNoSeries := "No. Series"
        else
            DefaultSelectedNoSeries := OldConversionHeader."No. Series";

        if NoSeries.LookupRelatedNoSeries(FAConversionSetup."Conversion Order No.", DefaultSelectedNoSeries, "No. Series") then begin
            "No." := NoSeries.GetNextNo("No. Series");
            if ConversionHeader.Get("No.") then
                Error(Text001, ConversionHeader."No.");
            exit(true)
        end;
    end;

    local procedure TestNoSeries()
    begin
        FAConversionSetup.Get();
        FAConversionSetup.TestField("Conversion Order No.");
        FAConversionSetup.TestField("Posted Conversion Order No.");
    end;

    local procedure SetDescriptionsFromItem()
    begin
        GetItem();
        Description := FAItem.Description;
        // "Description 2" := Item."Description 2";
    end;

    local procedure GetItem()
    begin
        TestField("FA Item No.");
        if FAItem."No." <> "FA Item No." then
            FAItem.Get("FA Item No.");
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteConversionLines()
    var
        ConversionLine: Record "FA Conversion Line";
        ReservMgt: Codeunit "Reservation Management";
    begin
        ConversionLine.SetRange("Document No.", "No.");
        if ConversionLine.Find('-') then begin
            ReservMgt.DeleteDocumentReservation(DATABASE::"FA Conversion Line", //"Document Type".AsInteger()
                0, "No.", HideValidationDialog);
            repeat
                ConversionLine.SuspendStatusCheck(true);
                ConversionLine.Delete(true);
            until ConversionLine.Next() = 0;
        end;
    end;

    procedure UpdateWarningOnLines()
    begin
        ConversionLineMgt.UpdateWarningOnLines(Rec);
    end;

    local procedure SetCurrentFieldNum(NewCurrentFieldNum: Integer): Boolean
    begin
        if CurrentFieldNum = 0 then begin
            CurrentFieldNum := NewCurrentFieldNum;
            exit(true);
        end;
        exit(false);
    end;

    local procedure ClearCurrentFieldNum(NewCurrentFieldNum: Integer)
    begin
        if CurrentFieldNum = NewCurrentFieldNum then
            CurrentFieldNum := 0;
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName, Result, IsHandled);
        // if IsHandled then
        //     exit(Result);

        exit(UOMMgt.CalcBaseQty(
            "FA Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure InitRemainingQty()
    begin
        "Remaining Quantity" := Quantity - "Converted Quantity";
        "Remaining Quantity (Base)" := "Quantity (Base)" - "Converted Quantity (Base)";

        // OnAfterInitRemaining(Rec, CurrFieldNo);
    end;

    procedure InitQtyToConvert()
    var
    // ATOLink: Record "Assemble-to-Order Link";
    begin
        "Quantity to Convert" := "Remaining Quantity";
        "Quantity to Convert (Base)" := "Remaining Quantity (Base)";
        // ATOLink.InitQtyToAsm(Rec, "Quantity to Assemble", "Quantity to Assemble (Base)");

        // OnAfterInitQtyToAssemble(Rec, CurrFieldNo);
    end;

    local procedure UpdateConversionLinesAndVerifyReserveQuantity()
    var
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateAssemblyLinesAndVerifyReserveQuantity(Rec, xRec, CurrFieldNo, CurrentFieldNum, IsHandled);
        // if IsHandled then
        //     exit;

        ConversionLineMgt.UpdateConversionLines(Rec, xRec, FieldNo(Quantity),
                                                //ReplaceLinesFromBOM(), 
                                                false, CurrFieldNo, CurrentFieldNum);
        ConversionHeaderReserve.VerifyQuantity(Rec, xRec);
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckConversionReleaseRestrictions()
    begin
    end;

    procedure CheckConversionReleaseRestrictions()
    var
        TSTApprovalsMgmt: Codeunit "TST Approvals Mgmt";
    begin
        OnCheckConversionReleaseRestrictions;
        TSTApprovalsMgmt.PrePostApprovalCheckConversion(Rec);
    end;

    [IntegrationEvent(true, false)]
    procedure OnCheckConversionPostRestrictions()
    begin
    end;

    procedure CheckConversionPostRestrictions()
    begin
        OnCheckConversionPostRestrictions();
    end;

    procedure ConversionLinesExists(): Boolean
    begin
        ConversionLine.Reset();
        ConversionLine.SetRange("Document No.", "No.");
        exit(not ConversionLine.IsEmpty)
    end;

    procedure PerformManualRelease()
    var
        ReleaseConversionDoc: Codeunit "Release Conversion Document";
    begin
        If Status <> Status::Released then begin
            ReleaseConversionDoc.PerformManualCheckAndRelease(Rec);
            Commit();
        end;
    end;

    procedure CompletelyPicked(): Boolean
    begin
        exit(ConversionLineMgt.CompletelyPicked(Rec));
    end;

    procedure OpenItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        // if IsHandled then
        //     exit;

        TestField("No.");
        TestField("Quantity (Base)");
        ConversionHeaderReserve.CallItemTracking(Rec);
    end;

    procedure IsInbound(): Boolean
    begin
        // if "Document Type" in ["Document Type"::Order, "Document Type"::Quote, "Document Type"::"Blanket Order"] then
        exit("Quantity (Base)" > 0);

        // exit(false);
    end;

    procedure GetSourceCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2', "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "FA Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"FA Conversion Header", 0,//"Document Type".AsInteger(), 
            "No.", 0, '', 0);
        ReservEntry.SetItemData("FA Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "FA Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"FA Conversion Header", 0,//"Document Type".AsInteger(), 
            "No.", 0, false);
        ReservEntry.SetSourceFilter('', 0);

        // OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "FA Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "FA Reservation Entry";
    begin
        TestField("FA Item No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"FA Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"FA Reservation Entries", ReservEntry);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "FA Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey("FA Item No.", "Variant Code", "Location Code", "Due Date");
        // SetRange("Document Type", DocumentType);
        SetRange("FA Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Quantity (Base)", '>0')
        else
            SetFilter("Remaining Quantity (Base)", '<0');

        // OnAfterFilterLinesForReservation(Rec, ReservationEntry, DocumentType, AvailabilityFilter, Positive);
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Quantity";
        QtyToReserveBase := "Remaining Quantity (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure CreatePick(ShowRequestPage: Boolean; AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    begin
        Error('Advance warehouse Not yet developed, please use normal warehouse');
        ConversionLineMgt.CreateWhseItemTrkgForConLines(Rec);
        Commit();

        TestField(Status, Status::Released);
        if CompletelyPicked() then
            Error(Text007);

        RunWhseSourceCreateDocument(ShowRequestPage, AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument);
    end;

    local procedure RunWhseSourceCreateDocument(ShowRequestPage: Boolean; AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    var
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeRunWhseSourceCreateDocument(Rec, ShowRequestPage, AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument, IsHandled);
        // if not IsHandled then begin
        // WhseSourceCreateDocument.SetConversionOrder(Rec);
        // if not ShowRequestPage then
        //     WhseSourceCreateDocument.Initialize(
        //         AssignedUserID, Enum::"Whse. Activity Sorting Method".FromInteger(SortingMethod), PrintDocument, DoNotFillQtyToHandle, SetBreakBulkFilter);
        // WhseSourceCreateDocument.UseRequestPage(ShowRequestPage);
        // WhseSourceCreateDocument.RunModal();
        // WhseSourceCreateDocument.GetResultMessage(2);
        // Clear(WhseSourceCreateDocument);
        // end;

        // OnAfterRunWhseSourceCreateDocument(Rec, ShowRequestPage, AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument);
    end;
}