namespace TSTChanges.FA.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Warehouse.Structure;
using TSTChanges.FA.FAItem;
using Microsoft.Inventory.Location;
using TSTChanges.FA.Tracking;

table 51223 "FA Direct Trans. Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = "FA Item";
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        // field(10; "Gen. Prod. Posting Group"; Code[20])
        // {
        //     Caption = 'Gen. Prod. Posting Group';
        //     TableRelation = "Gen. Product Posting Group";
        // }
        // field(11; "Inventory Posting Group"; Code[20])
        // {
        //     Caption = 'Inventory Posting Group';
        //     TableRelation = "Inventory Posting Group";
        // }
        field(12; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "FA Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(16; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "FA Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(23; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(24; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "FA Transfer Header";
            ValidateTableRelation = false;
        }
        field(25; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(29; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(30; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(31; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
        }
        field(33; "Item Rcpt. Entry No."; Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        // field(5704; "Item Category Code"; Code[20])
        // {
        //     Caption = 'Item Category Code';
        //     TableRelation = "Item Category";
        // }
        field(7300; "Transfer-from Bin Code"; Code[20])
        {
            Caption = 'Transfer-from Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Transfer-from Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));
        }
        field(7301; "Transfer-To Bin Code"; Code[20])
        {
            Caption = 'Transfer-To Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Transfer-to Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Transfer Order No.", "Item No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        DimMgt: Codeunit DimensionManagement;
        DocumentLineTxt: Label '%1 %2 %3', Locked = true;

    procedure CopyFromTransferLine(FATransferLine: Record "FA Transfer Line")
    begin
        "Line No." := FATransferLine."Line No.";
        "Item No." := FATransferLine."FA Item No.";
        Description := FATransferLine.Description;
        Quantity := FATransferLine."Qty. to Ship";
        "Unit of Measure" := FATransferLine."Unit of Measure";
        "Shortcut Dimension 1 Code" := FATransferLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := FATransferLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := FATransferLine."Dimension Set ID";
        // "Gen. Prod. Posting Group" := FATransferLine."Gen. Prod. Posting Group";
        // "Inventory Posting Group" := FATransferLine."Inventory Posting Group";
        Quantity := FATransferLine.Quantity;
        "Quantity (Base)" := FATransferLine."Quantity (Base)";
        "Qty. per Unit of Measure" := FATransferLine."Qty. per Unit of Measure";
        "Unit of Measure Code" := FATransferLine."Unit of Measure Code";
        // "Gross Weight" := FATransferLine."Gross Weight";
        // "Net Weight" := FATransferLine."Net Weight";
        // "Unit Volume" := FATransferLine."Unit Volume";
        "Variant Code" := FATransferLine."Variant Code";
        // "Units per Parcel" := FATransferLine."Units per Parcel";
        // "Description 2" := FATransferLine."Description 2";
        "Transfer Order No." := FATransferLine."Document No.";
        "Transfer-from Code" := FATransferLine."Transfer-from Code";
        "Transfer-to Code" := FATransferLine."Transfer-to Code";
        "Transfer-from Bin Code" := FATransferLine."Transfer-from Bin Code";
        "Transfer-to Bin Code" := FATransferLine."Transfer-to Bin Code";
        // "Item Category Code" := FATransferLine."Item Category Code";

        OnAfterCopyFromTransferLine(Rec, FATransferLine);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet(
            "Dimension Set ID",
            CopyStr(StrSubstNo(DocumentLineTxt, TableCaption(), "Document No.", "Line No."), 1, 250));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "FA Item Tracking Doc. Mgmt";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"FA Direct Trans. Line", 0, "Document No.", '', 0, "Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTransferLine(var FADirectTransLine: Record "FA Direct Trans. Line"; FATransferLine: Record "FA Transfer Line")
    begin
    end;
}