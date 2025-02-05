namespace TSTChanges.FA.Ledger;

using TSTChanges.FA.FAItem;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Tracking;
using TSTChanges.FA.Tracking;
using TSTChanges.FA.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.Dimension;
using Microsoft.Utilities;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.Enums;
using Microsoft.FixedAssets.FixedAsset;

table 51201 "FA Item ledger Entry"
{
    DataClassification = CustomerContent;
    Caption = 'FA Item Ledger Entry';
    DrillDownPageID = "FA Item Ledger Entries";
    LookupPageID = "FA Item Ledger Entries";
    Permissions = TableData "FA Item Ledger Entry" = rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(2; "FA Item No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'FA Item No.';
            TableRelation = "FA Item";
        }
        field(3; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(4; "Entry Type"; Enum "FA Item Ledger Entry Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Entry Type';
        }
        field(5; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(6; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(7; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Remaining Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(9; "Applies-to Entry"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Entry';
        }
        field(10; Open; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Open';
        }
        field(11; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
        }
        field(12; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(13; "Employee No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(14; "Serial No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                FAItemTrackingMgt.LookupTrackingNoInfo("FA Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(15; "Lot No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                FAItemTrackingMgt.LookupTrackingNoInfo("FA Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(16; Positive; Boolean)
        {
            Caption = 'Positive';
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "FA Item Unit of Measure".Code where("Item No." = field("FA Item No."));
        }
        field(19; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(20; "Item Tracking"; Enum "Item Tracking Entry Type")
        {
            Caption = 'Item Tracking';
            Editable = false;
        }
        field(21; "Shipped Qty. Not Returned"; Decimal)
        {
            // AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Shipped Qty. Not Returned';
            DecimalPlaces = 0 : 5;
        }
        field(22; "FA No."; Code[50])
        {
            DataClassification = CustomerContent;
            TableRelation = "Fixed Asset";
        }
        field(23; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
        }
        field(24; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) "FA Item";
        }
        field(25; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(26; "Reserved Quantity"; Decimal)
        {
            // AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("FA Reservation Entry"."Quantity (Base)" where("Source ID" = const(''),
                                                                           "Source Ref. No." = field("Entry No."),
                                                                           "Source Type" = const(51201),
                                                                           "Source Subtype" = const("0"),
                                                                           "Source Batch Name" = const(''),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
        }
        field(28; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(29; "Last Invoice Date"; Date)
        {
            Caption = 'Last Invoice Date';
        }
        field(30; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;
        }
        field(31; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
        }
        field(32; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(35; "Customer Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
        }
        field(36; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(37; "Applied Entry to Adjust"; Boolean)
        {
            Caption = 'Applied Entry to Adjust';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "FA Item Variant".Code where("Item No." = field("FA Item No."));
        }
        field(5804; "Book Value(Company)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("FA No."),
                                                            "Depreciation Book Code" = const('COMPANY'),
                                                            "Part of Book Value" = const(true)));
            Caption = 'Book Value (Company)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5805; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnLookup()
            begin
                FAItemTrackingMgt.LookupTrackingNoInfo("FA Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "FA Item No.")
        {
            SumIndexFields = "Invoiced Quantity",
            Quantity;
        }
        key(Key3; "FA Item No.", "Posting Date")
        {
        }
        key(Key4; "Order Type", "Order No.", "Order Line No.", "Entry Type")
        {
            IncludedFields = Quantity, "Posting Date", Positive, "Applies-to Entry";
        }

    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "FA Item No.", "Posting Date", "Entry Type", "Document No.")
        {
        }
        fieldgroup(Brick; "FA Item No.", Description, Quantity, "Document No.")
        { }
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
        IsNotOnInventoryErr: Label 'You have insufficient quantity of Item %1 on inventory.';
        FAItemTrackingMgt: Codeunit "FA Item Tracking Management";
        ItemTrackingType: Enum "Item Tracking Type";

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "FA Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"FA Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"FA Reservation Entries", ReservEntry);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "FA Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        // OnAfterSetTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure TestTrackingEqualToTrackingSpec(TrackingSpecification: Record "FA Tracking Specification")
    begin
        TestField("Serial No.", TrackingSpecification."Serial No.");
        TestField("Lot No.", TrackingSpecification."Lot No.");

        // OnAfterTestTrackingEqualToTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        // OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        // OnAfterClearTrackingFilter(Rec);
    end;

    procedure VerifyOnInventory()
    begin
        VerifyOnInventory(StrSubstNo(IsNotOnInventoryErr, "FA Item No."));
    end;

    procedure VerifyOnInventory(ErrorMessageText: Text)
    var
        FAItem: Record "FA Item";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeVerifyOnInventory(Rec, IsHandled, ErrorMessageText);
        // if IsHandled then
        //     exit;

        if not Open then
            exit;
        if Quantity >= 0 then
            exit;
        case "Entry Type" of
            // "Entry Type"::Consumption, "Entry Type"::"Assembly Consumption", 
            "Entry Type"::Transfer:
                Error(ErrorMessageText);
            else begin
                FAItem.Get("FA Item No.");
                // if FAItem.PreventNegativeInventory() then
                //     Error(ErrorMessageText);
            end;
        end;

        // OnAfterVerifyOnInventory(Rec, ErrorMessageText);
    end;

    procedure UpdateItemTracking()
    var
        ReservEntry: Record "FA Reservation Entry";
    begin
        ReservEntry.CopyTrackingFromItemLedgEntry(Rec);
        "Item Tracking" := ReservEntry.GetItemTrackingEntryType();
    end;

    procedure CopyTrackingFromItemJnlLine(FAItemJnlLine: Record "FA Item Journal Line")
    begin
        "Serial No." := FAItemJnlLine."Serial No.";
        "Lot No." := FAItemJnlLine."Lot No.";

        // OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure SetItemVariantLocationFilters(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; PostingDate: Date)
    begin
        Reset();
        SetCurrentKey("FA Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
        SetRange("FA Item No.", ItemNo);
        SetRange("Variant Code", VariantCode);
        SetRange("Location Code", LocationCode);
        SetRange("Posting Date", 0D, PostingDate);
    end;

    procedure SetReservationEntry(var ReservEntry: Record "FA Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"FA Item Ledger Entry", 0, '', "Entry No.", '', 0);
        ReservEntry.SetItemData("FA Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        Positive := "Remaining Quantity" <= 0;
        if Positive then begin
            ReservEntry."Expected Receipt Date" := DMY2Date(31, 12, 9999);
            ReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
        end else begin
            ReservEntry."Expected Receipt Date" := 0D;
            ReservEntry."Shipment Date" := 0D;
        end;
        // OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    procedure SetReservationFilters(var ReservEntry: Record "FA Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"FA Item Ledger Entry", 0, '', "Entry No.", false);
        ReservEntry.SetSourceFilter('', 0);

        // OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "FA Reservation Entry"; NewPositive: Boolean)
    var
        IsHandled: Boolean;
    begin
        Reset();
        SetCurrentKey("FA Item No.", Open, "Variant Code", Positive, "Location Code");
        SetRange("FA Item No.", ReservationEntry."Item No.");
        SetRange(Open, true);
        IsHandled := false;
        // OnFilterLinesForReservationOnBeforeSetFilterVariantCode(Rec, ReservationEntry, Positive, IsHandled);
        if not IsHandled then
            SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange(Positive, NewPositive);
        SetRange("Location Code", ReservationEntry."Location Code");
        // SetRange("Drop Shipment", false);
        // OnAfterFilterLinesForReservation(Rec, ReservationEntry, NewPositive);
    end;

    procedure FilterLinesForTracking(CalcReservEntry: Record "FA Reservation Entry"; Positive: Boolean)
    var
        FieldFilter: Text;
    begin
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"Lot No.") then
            SetFilter("Lot No.", FieldFilter);
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"Serial No.") then
            SetFilter("Serial No.", FieldFilter);

        // OnAfterFilterLinesForTracking(Rec, CalcReservEntry, Positive);
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyToReserve: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeGetReservationQty(Rec, QtyReserved, QtyToReserve, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Quantity");
        QtyReserved := "Reserved Quantity";
        QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
    end;

    internal procedure CalcReservedQuantity()
    var
        ReservationEntry: Record "FA Reservation Entry";
        IsHandled: Boolean;
    begin
        // OnBeforeCalcReservedQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Serial No." = '' then
            CalcFields("Reserved Quantity")
        else begin
            ReservationEntry.SetCurrentKey("Serial No.", "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
            ReservationEntry.SetRange("Serial No.", "Serial No.");
            ReservationEntry.SetRange("Source ID", '');
            ReservationEntry.SetRange("Source Ref. No.", "Entry No.");
            ReservationEntry.SetRange("Source Type", Database::"FA Item Ledger Entry");
            ReservationEntry.SetRange("Source Subtype", ReservationEntry."Source Subtype"::"0");
            ReservationEntry.SetRange("Source Batch Name", '');
            ReservationEntry.SetRange("Source Prod. Order Line", 0);
            ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
            ReservationEntry.CalcSums("Quantity (Base)");
            "Reserved Quantity" := ReservationEntry."Quantity (Base)"
        end;
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        // OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemLedgEntry(ItemLedgEntry: Record "FA Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");

        // OnAfterSetTrackingFilterFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromNewItemJnlLine(ItemJnlLine: Record "FA Item Journal Line")
    begin
        "Serial No." := ItemJnlLine."New Serial No.";
        "Lot No." := ItemJnlLine."New Lot No.";

        // OnAfterCopyTrackingFromNewItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        // OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, ItemTrackingSetup);
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure SetTrackingFilterBlank()
    begin
        SetRange("Serial No.", '');
        SetRange("Lot No.", '');

        // OnAfterSetTrackingFilterBlank(Rec);
    end;
}