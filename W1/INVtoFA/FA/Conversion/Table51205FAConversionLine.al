namespace TSTChanges.FA.Conversion;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Warehouse.Activity;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;

table 51205 "FA Conversion Line"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "FA Conversion Lines";
    LookupPageId = "FA Conversion Lines";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
            TableRelation = "FA Conversion Header"."No.";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; Type; Enum "BOM Component Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                TestField("Consumed Quantity", 0);
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                "No." := '';
                "Variant Code" := '';
                "Location Code" := '';
                "Bin Code" := '';
                InitResourceUsageType();
                "Inventory Posting Group" := '';
                "Gen. Prod. Posting Group" := '';
                // Clear("Lead-Time Offset");
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item where(Type = filter(Inventory | "Non-Inventory"))
            else
            if (Type = const(Resource)) Resource;

            trigger OnValidate()
            begin
                "Location Code" := '';
                TestField("Consumed Quantity", 0);
                CalcFields("Reserved Quantity");
                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);
                if "No." <> '' then
                    CheckItemAvailable(FieldNo("No."));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                if "No." <> xRec."No." then begin
                    "Variant Code" := '';
                    InitResourceUsageType();
                end;

                if "No." = '' then
                    Init()
                else begin
                    GetHeader();
                    "Due Date" := ConversionHeader."Starting Date";
                    case Type of
                        Type::Item:
                            CopyFromItem();
                        Type::Resource:
                            CopyFromResource();
                    end
                end;
            end;
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Code = field("Variant Code"));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                TestField(Type, Type::Item);
                TestField("Consumed Quantity", 0);
                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);
                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);
                CheckItemAvailable(FieldNo("Variant Code"));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                if Rec."Variant Code" = '' then begin
                    GetItemResource();
                    Description := Item.Description;
                    // "Description 2" := Item."Description 2"
                end else begin
                    ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                    ItemVariant.Get("No.", "Variant Code");
                    Description := ItemVariant.Description;
                    // "Description 2" := ItemVariant."Description 2";
                end;

                GetDefaultBin();
                "Unit Cost" := GetUnitCost();
                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);

                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);
                CheckItemAvailable(FieldNo("Location Code"));
                VerifyReservationChange(Rec, xRec);
                TestStatusOpen();

                GetDefaultBin();

                "Unit Cost" := GetUnitCost();
                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
                // CreateDimFromDefaultDim(AssemblyHeader."Dimension Set ID");
            end;
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                // OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec, CurrFieldNo);
                InitRemainingQty();
                InitQtyToConsume();

                CheckItemAvailable(FieldNo(Quantity));
                VerifyReservationQuantity(Rec, xRec);

                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(9; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            var
            // IsHandled: Boolean;
            begin
                // IsHandled := false;
                // OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                // if IsHandled then
                //     exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(10; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(11; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(12; "Consumed Quantity"; Decimal)
        {
            Caption = 'Consumed Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Consumed Quantity (Base)" := CalcBaseQty("Consumed Quantity", FieldCaption("Consumed Quantity"), FieldCaption("Consumed Quantity (Base)"));
                InitRemainingQty();
            end;
        }
        field(13; "Consumed Quantity (Base)"; Decimal)
        {
            Caption = 'Consumed Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(14; "Quantity to Consume"; Decimal)
        {
            Caption = 'Quantity to Consume';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            // IsHandled: Boolean;
            begin
                // IsHandled := false;
                // OnBeforeValidateQuantitytoConsume(Rec, xRec, CurrFieldNo, IsHandled);
                // if IsHandled then
                //     exit;

                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);

                "Quantity to Consume" := UOMMgt.RoundAndValidateQty("Quantity to Consume", "Qty. Rounding Precision", FieldCaption("Quantity to Consume"));

                RoundQty("Remaining Quantity");
                if "Quantity to Consume" > "Remaining Quantity" then
                    Error(Text003,
                      FieldCaption("Quantity to Consume"), FieldCaption("Remaining Quantity"), "Remaining Quantity");

                Validate(
                    "Quantity to Consume (Base)",
                    CalcBaseQty("Quantity to Consume", FieldCaption("Quantity to Consume"), FieldCaption("Quantity to Consume (Base)"))
                );
            end;
        }
        field(15; "Quantity to Consume (Base)"; Decimal)
        {
            Caption = 'Quantity to Consume (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(16; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(51205),
#pragma warning disable AL0603
                                                                    "Source Subtype" = const(0),//field("Document Type"),
#pragma warning restore
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(51205),
#pragma warning disable AL0603
                                                                            "Source Subtype" = const(0),//field("Document Type"),
#pragma warning restore
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Avail. Warning"; Boolean)
        {
            Caption = 'Avail. Warning';
            Editable = false;
        }
        field(19; "Substitution Available"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "Substitute Type" = const(Item),
                                                           "No." = field("No."),
                                                           "Variant Code" = field("Variant Code")));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                GetHeader();
                //     ValidateDueDate(AssemblyHeader, "Due Date", true);
            end;
        }
        field(21; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';

            trigger OnValidate()
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                end;

                CalcFields("Reserved Qty. (Base)");
                if Reserve = Reserve::Never then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItemResource();
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(22; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                // IsHandled := false;
                // OnBeforeValidateQuantityPer(Rec, xRec, IsHandled);
                // if IsHandled then
                //     exit;

                TestStatusOpen();
                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);
                if Type = Type::" " then
                    Error(Text99000002, FieldCaption("Quantity per"), FieldCaption(Type), Type::" ");
                RoundQty("Quantity per");
                // OnValidateQuantityPerOnAfterRoundQty(Rec);

                GetHeader();
                Validate(Quantity, CalcQuantity("Quantity per", ConversionHeader.Quantity));
                Validate(
                  "Quantity to Consume",
                  MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", ConversionHeader."Quantity to Convert")));
            end;
        }
        field(23; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(24; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);
                TestStatusOpen();

                GetItemResource();
                case Type of
                    Type::Item:
                        begin
                            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                        end;
                    Type::Resource:
                        "Qty. per Unit of Measure" := UOMMgt.GetResQtyPerUnitOfMeasure(Resource, "Unit of Measure Code");
                    else
                        "Qty. per Unit of Measure" := 1;
                end;

                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                "Unit Cost" := GetUnitCost();
                Validate(Quantity);
            end;
        }
        field(25; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = filter(<> "Put-away"),
                                                                                  "Source Type" = const(51205),
#pragma warning disable AL0603
                                                                                  //   "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                  "Source No." = field("Document No."),
                                                                                  "Source Line No." = field("Line No."),
                                                                                  "Source Subline No." = const(0),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Place),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Breakbulk No." = const(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = filter(<> "Put-away"),
                                                                                         "Source Type" = const(51205),
#pragma warning disable AL0603
                                                                                         //  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                         "Source No." = field("Document No."),
                                                                                         "Source Line No." = field("Line No."),
                                                                                         "Source Subline No." = const(0),
                                                                                         "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                         "Action Type" = filter(" " | Place),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Breakbulk No." = const(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" := CalcBaseQty("Qty. Picked", FieldCaption("Qty. Picked"), FieldCaption("Qty. Picked (Base)"));
            end;
        }
        field(28; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            OptionCaption = ' ,Direct,Fixed';
            OptionMembers = " ",Direct,"Fixed";

            trigger OnValidate()
            begin
                if "Resource Usage Type" = xRec."Resource Usage Type" then
                    exit;

                if Type = Type::Resource then
                    TestField("Resource Usage Type")
                else
                    TestField("Resource Usage Type", "Resource Usage Type"::" ");

                GetHeader();
                Validate(Quantity, CalcQuantity("Quantity per", ConversionHeader.Quantity));
            end;
        }
        field(30; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(31; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(32; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField(Type, Type::Item);
                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
            //     WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestStatusOpen();
                TestField(Type, Type::Item);
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Item.Get("No.");
                    Item.TestField(Type, Item.Type::Inventory);
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    //         WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Assembly Line",
                    //           FieldCaption("Bin Code"),
                    //           "Location Code",
                    //           "Bin Code", 0);
                    // CheckBin();
                end;
            end;
        }
        field(33; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                // Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(34; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                // Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(35; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(36; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(37; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                SkuItemUnitCost: Decimal;
            begin
                TestField("No.");
                GetItemResource();
                if Type = Type::Item then begin
                    SkuItemUnitCost := GetUnitCost();
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        if "Unit Cost" <> SkuItemUnitCost then
                            Error(
                              Text99000002,
                              FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                end;

                "Cost Amount" := CalcCostAmount(Quantity, "Unit Cost");
            end;
        }
        field(38; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(39; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                // Rec.ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(40; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-to Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    TestField(Type, Type::Item);
                    TestField(Quantity);
                    if Quantity < 0 then
                        FieldError(Quantity, Text029);
                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    "Location Code" := ItemLedgEntry."Location Code";
                    // OnValidateApplToItemEntryOnBeforeShowNotOpenItemLedgerEntryMessage(Rec, xRec, ItemLedgEntry, CurrFieldNo);
                    if not ItemLedgEntry.Open then
                        Message(Text042, "Appl.-to Item Entry");
                end;
            end;
        }
        field(41; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", Type, "Location Code")
        {
            IncludedFields = Quantity, "No.";
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin
        TestStatusOpen();
        VerifyReservationQuantity(Rec, xRec);
    end;

    trigger OnModify()
    begin
        ConversionWarehouseMgt.ConversionLineVerifyChange(Rec, xRec);
        VerifyReservationChange(Rec, xRec);
    end;

    trigger OnDelete()
    var
        WhseConversionRelease: Codeunit "Whse.-Conversion Release";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TestStatusOpen();
        ConversionWarehouseMgt.ConversionLineDelete(Rec);
        WhseConversionRelease.DeleteLine(Rec);
        ConversionLineReserve.DeleteLine(Rec);
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          DATABASE::"FA Conversion Line", //"Document Type".AsInteger(), 
          0, "Document No.", '', 0, "Line No.", "Location Code", true);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
        Item: Record Item;
        Resource: Record Resource;
        ConversionHeader: Record "FA Conversion Header";
        ConversionWarehouseMgt: Codeunit "Conversion Warehouse Mgt.";
        ConversionLineReserve: Codeunit "Conversion Line-Reserve";
        GLSetup: Record "General Ledger Setup";
        StockkeepingUnit: Record "Stockkeeping Unit";
        SkipVerificationsThatChangeDatabase: Boolean;
        GLSetupRead: Boolean;
        Text001: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        Text002: Label 'You cannot rename an %1.';
        Text003: Label '%1 cannot be higher than the %2, which is %3.';
        Text029: Label 'must be positive', Comment = 'starts with "Quantity"';
        Text042: Label 'When posting the Applied to Ledger Entry, %1 will be opened first.';
        Text99000002: Label 'You cannot change %1 when %2 is ''%3''.';

    protected var
        StatusCheckSuspended: Boolean;

    procedure InitRemainingQty()
    begin
        "Remaining Quantity" := MaxValue(Quantity - "Consumed Quantity", 0);
        "Remaining Quantity (Base)" := MaxValue("Quantity (Base)" - "Consumed Quantity (Base)", 0);

        // OnAfterInitRemainingQty(Rec, xRec, CurrFieldNo);
    end;

    procedure InitQtyToConsume()
    begin
        // OnBeforeInitQtyToConsume(Rec, xRec, CurrFieldNo);

        GetHeader();
        "Quantity to Consume" :=
          MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", ConversionHeader."Quantity to Convert"));
        RoundQty("Quantity to Consume");
        if MaxQtyToConsumeBase() <> 0 then
            "Quantity to Consume (Base)" := MinValue(MaxQtyToConsumeBase(), CalcBaseQty("Quantity to Consume", FieldCaption("Quantity to Consume"), FieldCaption("Quantity to Consume (Base)")))
        else
            "Quantity to Consume (Base)" := 0;

        // OnAfterInitQtyToConsume(Rec, xRec, CurrFieldNo);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure SetSkipVerificationsThatChangeDatabase(State: Boolean)
    begin
        SkipVerificationsThatChangeDatabase := State;
    end;

    procedure GetSkipVerificationsThatChangeDatabase(): Boolean
    begin
        exit(SkipVerificationsThatChangeDatabase);
    end;

    procedure UpdateAvailWarning() Result: Boolean
    var
        ConversionLineMgt: Codeunit "Conversion Line Management";
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeUpdateAvailWarning(Rec, Result, IsHandled);
        // if IsHandled then
        //     exit(Result);

        "Avail. Warning" := false;
        if Type = Type::Item then
            "Avail. Warning" := ConversionLineMgt.ConOrderLineShowWarning(Rec);
        exit("Avail. Warning");
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        Clear(ConversionHeader);
        GetHeader();
        if Type in [Type::Item, Type::Resource] then
            ConversionHeader.TestField(Status, ConversionHeader.Status::Open);
    end;

    procedure GetHeader(): Record "FA Conversion Header"
    var
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeGetHeader(Rec, AssemblyHeader, IsHandled);
        // if IsHandled then
        //     exit;

        if (ConversionHeader."No." <> "Document No.") and ("Document No." <> '') then
            ConversionHeader.Get(Rec."Document No.");

        exit(ConversionHeader)
    end;

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        ConversionLineMgt: Codeunit "Conversion Line Management";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if not UpdateAvailWarning() then
            exit;

        if (CalledByFieldNo = CurrFieldNo) or
       ((CalledByFieldNo = FieldNo("No.")) and (CurrFieldNo <> 0)) or
       ((CalledByFieldNo = FieldNo(Quantity)) and (CurrFieldNo = FieldNo("Quantity per")))
    then
            if ConversionLineMgt.ConversionLineCheck(Rec) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure InitResourceUsageType()
    begin
        case Type of
            Type::" ", Type::Item:
                "Resource Usage Type" := "Resource Usage Type"::" ";
            Type::Resource:
                "Resource Usage Type" := "Resource Usage Type"::Direct;
        end;
    end;

    local procedure CopyFromItem()
    begin
        // OnBeforeCopyFromItem(Rec);

        GetItemResource();
        if IsInventoriableItem() then begin
            "Location Code" := ConversionHeader."Location Code";
            Item.TestField("Inventory Posting Group");
        end;

        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "Inventory Posting Group" := Item."Inventory Posting Group";
        GetDefaultBin();
        Description := Item.Description;
        // "Description 2" := Item."Description 2";
        "Unit Cost" := GetUnitCost();
        Validate("Unit of Measure Code", Item."Base Unit of Measure");
        // CreateDimFromDefaultDim(AssemblyHeader."Dimension Set ID");
        Reserve := Item.Reserve;
        Validate(Quantity);
        Validate("Quantity to Consume",
          MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", ConversionHeader."Quantity to Convert")));

        // OnAfterCopyFromItem(Rec, Item, AssemblyHeader);
    end;

    local procedure CopyFromResource()
    begin
        // OnBeforeCopyFromResource(Rec);

        GetItemResource();
        Resource.TestField("Gen. Prod. Posting Group");
        "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
        "Inventory Posting Group" := '';
        Description := Resource.Name;
        // "Description 2" := Resource."Name 2";
        "Unit Cost" := GetUnitCost();
        Validate("Unit of Measure Code", Resource."Base Unit of Measure");
        // CreateDimFromDefaultDim(AssemblyHeader."Dimension Set ID");
        Validate(Quantity);
        Validate("Quantity to Consume",
          MinValue(MaxQtyToConsume(), CalcQuantity("Quantity per", ConversionHeader."Quantity to Convert")));

        // OnAfterCopyFromResource(Rec, Resource, AssemblyHeader);
    end;

    local procedure GetItemResource()
    begin
        if Type = Type::Item then
            if Item."No." <> "No." then
                Item.Get("No.");
        if Type = Type::Resource then
            if Resource."No." <> "No." then
                Resource.Get("No.");
    end;

    procedure IsInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItemResource();
        exit(Item.IsInventoriableType());
    end;

    local procedure MaxValue(Value: Decimal; Value2: Decimal): Decimal
    begin
        if Value < Value2 then
            exit(Value2);

        exit(Value);
    end;

    local procedure MinValue(Value: Decimal; Value2: Decimal): Decimal
    begin
        if Value < Value2 then
            exit(Value);

        exit(Value2);
    end;

    procedure RoundQty(var Qty: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Qty := UOMMgt.RoundQty(Qty, "Qty. Rounding Precision");
    end;

    procedure MaxQtyToConsume(): Decimal
    begin
        exit("Remaining Quantity");
    end;

    local procedure MaxQtyToConsumeBase(): Decimal
    begin
        exit("Remaining Quantity (Base)");
    end;

    local procedure CalcQuantity(LineQtyPer: Decimal; HeaderQty: Decimal): Decimal
    begin
        exit(CalcBOMQuantity(Type, LineQtyPer, HeaderQty, 1, "Resource Usage Type"));
    end;

    procedure CalcBOMQuantity(LineType: Enum "BOM Component Type"; QtyPer: Decimal; HeaderQty: Decimal; HeaderQtyPerUOM: Decimal; LineResourceUsageType: Option): Decimal
    var
    // IsHandled: Boolean;
    // ReturnBOMQuantity: Decimal;
    begin
        // IsHandled := false;
        // ReturnBOMQuantity := 0;
        // OnBeforeCalcBOMQuantity(Rec, LineType, QtyPer, HeaderQty, HeaderQtyPerUOM, LineResourceUsageType, ReturnBOMQuantity, IsHandled);
        // if IsHandled then
        //     exit(ReturnBOMQuantity);

        if FixedUsage(LineType, LineResourceUsageType) then
            exit(QtyPer);

        if "Qty. Rounding Precision" <> 0 then
            exit(Round(QtyPer * HeaderQty * HeaderQtyPerUOM, "Qty. Rounding Precision"));
        exit(QtyPer * HeaderQty * HeaderQtyPerUOM);
    end;

    procedure FixedUsage(): Boolean
    begin
        exit(FixedUsage(Type, "Resource Usage Type"));
    end;

    local procedure FixedUsage(LineType: Enum "BOM Component Type"; LineResourceUsageType: Option): Boolean
    begin
        if (LineType = Type::Resource) and (LineResourceUsageType = "Resource Usage Type"::Fixed) then
            exit(true);

        exit(false);
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure ReservationStatus(): Integer
    var
        Status: Option " ",Partial,Complete;
    begin
        if (Reserve = Reserve::Never) or ("Remaining Quantity" = 0) then
            exit(Status::" ");

        CalcFields("Reserved Quantity");
        if "Reserved Quantity" = 0 then begin
            if Reserve = Reserve::Always then
                exit(Status::Partial);
            exit(Status::" ");
        end;

        if "Reserved Quantity" < "Remaining Quantity" then
            exit(Status::Partial);

        exit(Status::Complete);
    end;

    procedure AutoReserve()
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeAutoReserve(Rec, IsHandled);
        // if Ishandled then
        //     exit;

        if Type <> Type::Item then
            exit;

        TestField("No.");
        if Reserve <> Reserve::Always then
            exit;

        if "Remaining Quantity (Base)" <> 0 then begin
            TestField("Due Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Due Date", "Remaining Quantity", "Remaining Quantity (Base)");
            Find();
            if not FullAutoReservation and (CurrFieldNo <> 0) then
                if Confirm(Text001, true) then begin
                    Commit();
                    Rec.ShowReservation();
                    Find();
                end;
        end;
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeShowReservation(Rec, IsHandled);
        // if IsHandled then
        //     exit;

        if Type = Type::Item then begin
            TestField("No.");
            TestField(Reserve);
            Clear(Reservation);
            Reservation.SetReservSource(Rec);
            Reservation.RunModal();
        end;
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);

        if not Item2.Get(ItemNo) then
            exit(false);
        exit(true);
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if Type = Type::Item then begin
            TestField("No.");
            ReservEntry.InitSortingAndFilters(true);
            SetReservationFilters(ReservEntry);
            if Modal then
                PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
            else
                PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
        end;
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"FA Conversion Line", //"Document Type".AsInteger(), 
                                    0, "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);
    end;

    procedure IsInbound(): Boolean
    begin
        // if "Document Type" in ["Document Type"::Order, "Document Type"::Quote, "Document Type"::"Blanket Order"] then
        exit("Quantity (Base)" < 0);

        // exit(false);
    end;

    procedure OpenItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        // if IsHandled then
        //     exit;

        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        ConversionLineReserve.CallItemTracking(Rec);
    end;

    procedure GetSourceCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2', "Document No.", "Line No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"FA Conversion Line", //"Document Type".AsInteger(), 
                            0, "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
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

    procedure ShowItemSub()
    begin
        // ItemSubstMgt.ItemAssemblySubstGet(Rec);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(//"Document Type", 
            Type, "No.", "Variant Code", "Location Code", "Due Date");
        // SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Quantity (Base)", '<0')
        else
            SetFilter("Remaining Quantity (Base)", '>0');

        // OnAfterFilterLinesForReservation(Rec, ReservationEntry, DocumentType, AvailabilityFilter, Positive);
    end;

    procedure VerifyReservationQuantity(var NewConLine: Record "FA Conversion Line"; var OldConLine: Record "FA Conversion Line")
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        ConversionLineReserve.VerifyQuantity(NewConLine, OldConLine);
    end;

    procedure VerifyReservationChange(var NewConLine: Record "FA Conversion Line"; var OldConLine: Record "FA Conversion Line")
    begin
        if SkipVerificationsThatChangeDatabase then
            exit;
        ConversionLineReserve.VerifyChange(NewConLine, OldConLine);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ConLine3: Record "FA Conversion Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Open);
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange(Positive, false);
            ItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
        end;
        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            ConLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                ConLine3.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.")
            else
                ConLine3.Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            Rec := ConLine3;
        end;
    end;

    local procedure GetSKU()
    var
        SKU: Record "Stockkeeping Unit";
        Result: Boolean;
    begin
        if Type = Type::Item then
            if (StockkeepingUnit."Location Code" = "Location Code") and
               (StockkeepingUnit."Item No." = "No.") and
               (StockkeepingUnit."Variant Code" = "Variant Code")
            then
                exit;
        GetItemResource();
        StockkeepingUnit := Item.GetSKU("Location Code", "Variant Code");
        Result := SKU.Get("Location Code", "No.", "Variant Code");
        // OnAfterGetSKU(Rec, Result);
    end;

    procedure GetUnitCost(): Decimal
    var
        UnitCost: Decimal;
    begin
        GetItemResource();

        case Type of
            Type::Item:
                begin
                    GetSKU();
                    UnitCost := StockkeepingUnit."Unit Cost" * "Qty. per Unit of Measure";
                end;
            Type::Resource:
                UnitCost := Resource."Unit Cost" * "Qty. per Unit of Measure";
        end;

        // OnAfterGetUnitCost(Rec, UnitCost);

        exit(RoundUnitAmount(UnitCost));
    end;

    procedure CalcCostAmount(Qty: Decimal; UnitCost: Decimal): Decimal
    begin
        exit(Round(Qty * UnitCost));
    end;

    local procedure RoundUnitAmount(UnitAmount: Decimal): Decimal
    begin
        GetGLSetup();

        exit(Round(UnitAmount, GLSetup."Unit-Amount Rounding Precision"));
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true
        end
    end;

    procedure GetDefaultBin()
    begin
        if (Type <> Type::Item) or not IsInventoriableItem() then
            exit;
        if (Quantity * xRec.Quantity > 0) and
           ("No." = xRec."No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code")
        then
            exit;
        Validate("Bin Code", FindBin());
    end;

    procedure FindBin() NewBinCode: Code[20]
    var
        Location: Record Location;
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeFindBin(Rec, NewBinCode, IsHandled);
        // if IsHandled then
        //     exit(NewBinCode);

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation(Location, "Location Code");
            NewBinCode := Location."To-Assembly Bin Code";
            if NewBinCode <> '' then
                exit;

            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", NewBinCode);
        end;

        // OnAfterFindBin(Rec, NewBinCode);
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure CompletelyPicked(): Boolean
    var
        Location: Record Location;
    begin
        TestField(Type, Type::Item);
        GetLocation(Location, "Location Code");
        if Location."Require Shipment" then
            exit("Qty. Picked (Base)" - "Consumed Quantity (Base)" >= "Remaining Quantity (Base)");
        exit("Qty. Picked (Base)" - "Consumed Quantity (Base)" >= "Quantity to Consume (Base)");
    end;
}