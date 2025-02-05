namespace TSTChanges.FA.FAItem;

using Microsoft.FixedAssets.Setup;
// using Microsoft.Finance.GST.Base;
using Microsoft.FixedAssets.FixedAsset;
using TSTChanges.FA.Tracking;
using TSTChanges.FA.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Setup;
// using Microsoft.FixedAssets.FADepreciation;
using Microsoft.Utilities;
using TSTChanges.FA.Transfer;
using System.Automation;
using Microsoft.Finance.Dimension;
using TSTChanges.Automation;
using TSTChanges.FA.Conversion;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Ledger;
using TSTChanges.FA.Journal;
using Microsoft.Inventory.Planning;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Ledger;

table 51200 "FA Item"
{
    Caption = 'FA Item';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "FA Item List";
    LookupPageId = "FA Item List";
    // LookupPageID = "Item Lookup";
    Permissions = //TableData "Service Item" = rm,
    //               TableData "Service Item Component" = rm,
                  TableData "Bin Content" = d,
                  TableData "Planning Assignment" = d;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Inventory; Decimal)
        {
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("FA Item ledger Entry".Quantity where("FA Item No." = field("No."),
                                                                    "Location Code" = field("Location Filter"),
                                                                    "Variant Code" = field("Variant Filter"),
                                                                    "Unit of Measure Code" = field("Unit of Measure Filter")));
        }
        field(4; "Inventory Demo"; Decimal)
        {
            Caption = 'Inventory Demo';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("FA Item ledger Entry".Quantity where("FA Item No." = field("No."),
                                                                    "Location Code" = const('DEMO LOC'),
                                                                    "Variant Code" = field("Variant Filter"),
                                                                    "Unit of Measure Code" = field("Unit of Measure Filter")));
        }
        field(5; "Inventory Rental"; Decimal)
        {
            Caption = 'Inventory Rental';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("FA Item ledger Entry".Quantity where("FA Item No." = field("No."),
                                                                    "Location Code" = const('Rental'),
                                                                    "Variant Code" = field("Variant Filter"),
                                                                    "Unit of Measure Code" = field("Unit of Measure Filter")));
        }
        field(6; "Inventory Warehosue"; Decimal)
        {
            Caption = 'Inventory Warehouse';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("FA Item ledger Entry".Quantity where("FA Item No." = field("No."),
                                                                    "Customer No." = const(''),
                                                                    "Location Code" = filter(<> 'IN TRANSIT'),
                                                                    "Variant Code" = field("Variant Filter"),
                                                                    "Unit of Measure Code" = field("Unit of Measure Filter")));
        }
        field(7; Picture; MediaSet)
        {
            DataClassification = CustomerContent;
        }
        field(8; "FA Class Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'FA Class Code';
            TableRelation = "FA Class";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
            begin
                if "FA Subclass Code" = '' then
                    exit;

                FASubclass.Get("FA Subclass Code");
                if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                    "FA Subclass Code" := '';
            end;
        }
        field(9; "FA Subclass Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
            begin
                if "FA Subclass Code" = '' then begin
                    Validate("FA Posting Group", '');
                    exit;
                end;

                FASubclass.Get("FA Subclass Code");
                if "FA Class Code" <> '' then begin
                    if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                        Error(UnexpctedSubclassErr);
                end else
                    Validate("FA Class Code", FASubclass."FA Class Code");

                if "FA Posting Group" = '' then
                    Validate("FA Posting Group", FASubclass."Default FA Posting Group");
            end;
        }
        field(10; "FA Posting Group"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";
        }
        field(11; Device; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Device';
        }
        field(12; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        // field(15; "FA Block Code"; Code[10])
        // {
        //     DataClassification = CustomerContent;
        //     Caption = 'FA Block Code';
        //     TableRelation = "Fixed Asset Block".Code where("FA Class Code" = field("FA Class Code"));
        // }
        field(16; "No. of Depreciation Years"; Decimal)
        {
            DataClassification = CustomerContent;
            BlankZero = true;
            Caption = 'No. of Depreciation Years';
            DecimalPlaces = 2 : 8;
            MinValue = 0;
        }
        field(20; "Qty. on Conversion Order"; Decimal)
        {
            CalcFormula = sum("FA Conversion Header"."Remaining Quantity (Base)" where(//"Document Type" = const(Order),
                                                                                   "FA Item No." = field("No."),
                                                                                    //"Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                    //"Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                    "Location Code" = field("Location Filter"),
                                                                                    "Variant Code" = field("Variant Filter"),
                                                                                    "Due Date" = field("Date Filter"),
                                                                                    "Unit of Measure Code" = field("Unit of Measure Filter")));
            Caption = 'Qty. on Conversion Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempItem: Record "FA Item" temporary;
                UnitOfMeasure: Record "Unit of Measure";
                ValidateBaseUnitOfMeasure: Boolean;
            begin
                if CurrentClientType() in [ClientType::ODataV4, ClientType::API] then
                    if not TempItem.Get(Rec."No.") and IsNullGuid(Rec.SystemId) then
                        Rec.Insert(true);

                UpdateUnitOfMeasureId();

                if not ValidateBaseUnitOfMeasure then
                    ValidateBaseUnitOfMeasure := "Base Unit of Measure" <> xRec."Base Unit of Measure";

                if ValidateBaseUnitOfMeasure then begin
                    TestNoOpenEntriesExist(FieldCaption("Base Unit of Measure"));
                    if "Base Unit of Measure" <> '' then begin
                        // If we can't find a Unit of Measure with a GET,
                        // then try with International Standard Code, as some times it's used as Code
                        if not UnitOfMeasure.Get("Base Unit of Measure") then begin
                            UnitOfMeasure.SetRange("International Standard Code", "Base Unit of Measure");
                            if not UnitOfMeasure.FindFirst() then
                                Error(UnitOfMeasureNotExistErr, "Base Unit of Measure");
                            "Base Unit of Measure" := UnitOfMeasure.Code;
                        end;

                        if not ItemUnitOfMeasure.Get("No.", "Base Unit of Measure") then
                            CreateItemUnitOfMeasure()
                        else
                            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 1 then
                                Error(BaseUnitOfMeasureQtyMustBeOneErr, "Base Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
                        UpdateQtyRoundingPrecisionForBaseUoM();
                    end;
                    // "Sales Unit of Measure" := "Base Unit of Measure";
                    // "Purch. Unit of Measure" := "Base Unit of Measure";
                end;
            end;
        }
        field(22; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
            Editable = false;
        }
        field(23; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(24; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
            Editable = false;
        }
        field(25; "Item Tracking Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Item Tracking Code';
            TableRelation = "Item Tracking Code";

            trigger OnValidate()
            begin
                if "Item Tracking Code" = xRec."Item Tracking Code" then
                    exit;

                if not ItemTrackingCode.Get("Item Tracking Code") then
                    Clear(ItemTrackingCode);

                if not ItemTrackingCode2.Get(xRec."Item Tracking Code") then
                    Clear(ItemTrackingCode2);
            end;
        }
        field(26; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked then
                    "Block Reason" := '';
            end;
        }
        field(27; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';

            trigger OnValidate()
            begin
                if ("Block Reason" <> '') and ("Block Reason" <> xRec."Block Reason") then
                    TestField(Blocked, true);
            end;
        }
        field(28; "Lot Nos."; Code[20])
        {
            Caption = 'Lot Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Lot Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(29; "Serial Nos."; Code[20])
        {
            Caption = 'Serial Nos.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Serial Nos." <> '' then
                    TestField("Item Tracking Code");
            end;
        }
        field(30; "Order Tracking Policy"; Enum "Order Tracking Policy")
        {
            Caption = 'Order Tracking Policy';
        }
        field(31; "Application Wksh. User ID"; Code[128])
        {
            Caption = 'Application Wksh. User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(32; "Rounding Precision"; Decimal)
        {
            // AccessByPermission = TableData "Production Order" = R;
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                if "Rounding Precision" <= 0 then
                    FieldError("Rounding Precision", Text027);
            end;
        }
        field(33; Type; Enum "Item Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                // OnValidateTypeOnBeforeCheckExistsItemLedgerEntry(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    if ExistsItemLedgerEntry() then
                        Error(CannotChangeFieldErr, FieldCaption(Type), TableCaption(), "No.", ItemLedgEntryTableCaptionTxt);
                TestNoWhseEntriesExist(FieldCaption(Type));
                CheckJournalsAndWorksheets(FieldNo(Type));
                CheckDocuments(FieldNo(Type));
                // if IsNonInventoriableType() then
                //     CheckUpdateFieldsForNonInventoriableItem();
            end;
        }
        field(34; "Reserved Qty. on Inventory"; Decimal)
        {
            // AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("FA Reservation Entry"."Quantity (Base)" where("Item No." = field("No."),
                                                                           "Source Type" = const(51201),
                                                                           "Source Subtype" = const("0"),
                                                                           "Reservation Status" = const(Reservation),
                                                                           "Serial No." = field("Serial No. Filter"),
                                                                           "Lot No." = field("Lot No. Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                           "Package No." = field("Package No. Filter")));
            Caption = 'Reserved Qty. on Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(36; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(37; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(38; "Package No. Filter"; Code[50])
        {
            Caption = 'Package No. Filter';
            CaptionClass = '6,3';
            FieldClass = FlowFilter;
        }
        field(39; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(40; "Unit of Measure Id"; Guid)
        {
            Caption = 'Unit of Measure Id';
            TableRelation = "Unit of Measure".SystemId;

            trigger OnValidate()
            begin
                UpdateUnitOfMeasureCode();
            end;
        }
        field(41; MRP; Decimal)
        {
            Caption = 'MRP';
            DataClassification = CustomerContent;
        }
        // field(42; "GST Group Code"; code[20])
        // {
        //     Caption = 'GST Group Code';
        //     DataClassification = CustomerContent;
        //     TableRelation = "GST Group";
        // }
        // field(43; "HSN/SAC Code"; code[10])
        // {
        //     Caption = 'HSN/SAC Code';
        //     DataClassification = CustomerContent;
        //     TableRelation = "HSN/SAC".Code where("GST Group Code" = field("GST Group Code"));
        // }
        field(44; "Variant Mandatory if Exists"; Option)
        {
            Caption = 'Variant Mandatory if Exists';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(45; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "FA Item Variant".Code where("Item No." = field("No."));
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
        fieldgroup(DropDown; "No.", Description, "Base Unit of Measure")
        {
        }
        fieldgroup(Brick; "No.", Description, Inventory, "Base Unit of Measure", Picture)
        {
        }
    }

    trigger OnInsert()
    begin
        DimMgt.UpdateDefaultDim(DATABASE::"FA Item", "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
        UpdateReferencedIds();
        SetLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        UpdateReferencedIds();
        SetLastDateTimeModified();
    end;

    trigger OnDelete()
    begin
        TSTApprovalsMgmt.OnCancelFAItemApprovalRequest(Rec);
        CheckJournalsAndWorksheets(0);
        CheckDocuments(0);

        // MoveEntries.MoveItemEntries(Rec);

        DeleteRelatedData;
    end;

    trigger OnRename()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        DimMgt.RenameDefaultDim(DATABASE::"FA Item", xRec."No.", "No.");
        ApprovalsMgmt.OnRenameRecordInApprovalRequest(xRec.RecordId, RecordId);
        SetLastDateTimeModified();
    end;

    var
        FAItemJnlLine: Record "FA Item Journal Line";
        ItemUnitOfMeasure: Record "FA Item Unit of Measure";
        ItemLedgEntryTableCaptionTxt: Label 'FA Item Ledger Entry';
        UnexpctedSubclassErr: Label 'This fixed asset subclass belongs to a different fixed asset class.';
        CannotChangeFieldErr: Label 'You cannot change the %1 field on %2 %3 because at least one %4 exists for this item.', Comment = '%1 = Field Caption, %2 = Item Table Name, %3 = Item No., %4 = Table Name';
        WhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for this item.', Comment = '%1: Changed field name';
        UnitOfMeasureNotExistErr: Label 'The Unit of Measure with Code %1 does not exist.', Comment = '%1 = Code of Unit of measure';
        BaseUnitOfMeasureQtyMustBeOneErr: Label 'The quantity per base unit of measure must be 1. %1 is set up with %2 per unit of measure.\\You can change this setup in the Item Units of Measure window.', Comment = '%1 Name of Unit of measure (e.g. BOX, PCS, KG...), %2 Qty. of %1 per base unit of measure ';
        Text016: Label 'You cannot delete %1 %2 because there are one or more outstanding transfer orders that include this item.';
        Text019: Label 'You cannot change %1 because there are one or more open ledger entries for this item.';
        Text023: Label 'You cannot delete %1 %2 because there is at least one %3 that includes this item.';
        Text027: Label 'must be greater than 0.', Comment = 'starts with "Rounding Precision"';
        Text028: Label 'You cannot perform this action because entries for item %1 are unapplied in %2 by user %3.';
        SelectItemErr: Label 'You must select an existing item.';
        CreateNewItemTxt: Label 'Create a new item card for %1.', Comment = '%1 is the name to be used to create the customer. ';
        ItemNotRegisteredTxt: Label 'This item is not registered. To continue, choose one of the following options:';
        SelectItemTxt: Label 'Select an existing item.';
        FAItem: Record "FA Item";
        TSTApprovalsMgmt: Codeunit "TST Approvals Mgmt";
        DimMgt: Codeunit DimensionManagement;
        TransLine: Record "FA Transfer Line";

    protected var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";

    local procedure DeleteRelatedData()
    var
        BinContent: Record "Bin Content";
        // MyItem: Record "My Item";
        // ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        FAItemVariant: Record "FA Item Variant";
    // EntityText: Record "Entity Text";
    begin
        // ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name", "Item No.");
        // ItemBudgetEntry.SetRange("Item No.", "No.");
        // ItemBudgetEntry.DeleteAll(true);

        // ItemSub.Reset();
        // ItemSub.SetRange(Type, ItemSub.Type::Item);
        // ItemSub.SetRange("No.", "No.");
        // ItemSub.DeleteAll();

        // ItemSub.Reset();
        // ItemSub.SetRange("Substitute Type", ItemSub."Substitute Type"::Item);
        // ItemSub.SetRange("Substitute No.", "No.");
        // ItemSub.DeleteAll();

        // StockkeepingUnit.Reset();
        // StockkeepingUnit.SetCurrentKey("Item No.");
        // StockkeepingUnit.SetRange("Item No.", "No.");
        // StockkeepingUnit.DeleteAll();

        // CatalogItemMgt.NonstockItemDel(Rec);
        // CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        // CommentLine.SetRange("No.", "No.");
        // CommentLine.DeleteAll();

        // ItemVendor.SetCurrentKey("Item No.");
        // ItemVendor.SetRange("Item No.", "No.");
        // ItemVendor.DeleteAll();

        // ItemReference.SetRange("Item No.", "No.");
        // ItemReference.DeleteAll();

        // SalesPrepmtPct.SetRange("Item No.", "No.");
        // SalesPrepmtPct.DeleteAll();

        // PurchPrepmtPct.SetRange("Item No.", "No.");
        // PurchPrepmtPct.DeleteAll();

        // ItemTranslation.SetRange("Item No.", "No.");
        // ItemTranslation.DeleteAll();

        ItemUnitOfMeasure.SetRange("Item No.", "No.");
        ItemUnitOfMeasure.DeleteAll();

        FAItemVariant.SetRange("Item No.", "No.");
        FAItemVariant.DeleteAll();

        // ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
        // ExtTextHeader.SetRange("No.", "No.");
        // ExtTextHeader.DeleteAll(true);

        // ItemAnalysisViewEntry.SetRange("Item No.", "No.");
        // ItemAnalysisViewEntry.DeleteAll();

        // ItemAnalysisBudgViewEntry.SetRange("Item No.", "No.");
        // ItemAnalysisBudgViewEntry.DeleteAll();

        // PlanningAssignment.SetRange("Item No.", "No.");
        // PlanningAssignment.DeleteAll();

        // BOMComp.Reset();
        // BOMComp.SetRange("Parent Item No.", "No.");
        // BOMComp.DeleteAll();

        // TroubleshSetup.Reset();
        // TroubleshSetup.SetRange(Type, TroubleshSetup.Type::Item);
        // TroubleshSetup.SetRange("No.", "No.");
        // TroubleshSetup.DeleteAll();

        // ResSkillMgt.DeleteItemResSkills("No.");
        // DimMgt.DeleteDefaultDim(DATABASE::Item, "No.");

        // ItemIdent.Reset();
        // ItemIdent.SetCurrentKey("Item No.");
        // ItemIdent.SetRange("Item No.", "No.");
        // ItemIdent.DeleteAll();

        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "No.");
        BinContent.DeleteAll();

        // MyItem.SetRange("Item No.", "No.");
        // MyItem.DeleteAll();

        // ItemAttributeValueMapping.Reset();
        // ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"FA Item");
        // ItemAttributeValueMapping.SetRange("No.", "No.");
        // ItemAttributeValueMapping.DeleteAll();

        // EntityText.SetRange(Company, CompanyName());
        // EntityText.SetRange("Source Table Id", Database::Item);
        // EntityText.SetRange("Source System Id", Rec.SystemId);
        // EntityText.DeleteAll();

        // OnAfterDeleteRelatedData(Rec);
    end;

    procedure UpdateReferencedIds();
    begin
        UpdateUnitOfMeasureId();
    end;

    procedure SetLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime;
        "Last Date Modified" := DT2Date("Last DateTime Modified");
        "Last Time Modified" := DT2Time("Last DateTime Modified");
    end;

    procedure ExistsItemLedgerEntry(): Boolean
    var
        ItemLedgEntry: Record "FA Item Ledger Entry";
    begin
        if "No." = '' then
            exit;

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetLoadFields("FA Item No.");
        ItemLedgEntry.SetCurrentKey("FA Item No.");
        ItemLedgEntry.SetRange("FA Item No.", "No.");
        exit(not ItemLedgEntry.IsEmpty);
    end;

    local procedure TestNoWhseEntriesExist(CurrentFieldName: Text)
    var
        WarehouseEntry: Record "Warehouse Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeTestNoWhseEntriesExist(Rec, CurrentFieldName, IsHandled);
        if IsHandled then
            exit;

        WarehouseEntry.SetRange("Item No.", "No.");
        if not WarehouseEntry.IsEmpty() then
            Error(WhseEntriesExistErr, CurrentFieldName);
    end;

    procedure TestNoOpenEntriesExist(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "FA Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeTestNoOpenEntriesExist(Rec, ItemLedgEntry, CurrentFieldName, IsHandled);
        if IsHandled then
            exit;

        ItemLedgEntry.SetCurrentKey("FA Item No.", Open);
        ItemLedgEntry.SetRange("FA Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text019,
              CurrentFieldName);
    end;


    procedure TestFixedAssetFields()
    begin
        TestField("FA Class Code");
        TestField("FA Posting Group");
        TestField("FA Subclass Code");
        // TestField("FA Block Code");
        TestField("No. of Depreciation Years");
    end;

    procedure CheckBlockedByApplWorksheet()
    var
        ApplicationWorksheet: Page "Application Worksheet";
    begin
        if "Application Wksh. User ID" <> '' then
            Error(Text028, "No.", ApplicationWorksheet.Caption, "Application Wksh. User ID");
    end;

    procedure CheckJournalsAndWorksheets(CurrFieldNo: Integer)
    begin
        CheckItemJnlLine(CurrFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckStdCostWksh(CurrFieldNo);
        // CheckReqLine(CurrFieldNo, FieldNo(Type), FieldCaption(Type));
    end;

    local procedure CheckItemJnlLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        if "No." = '' then
            exit;

        // IsHandled := false;
        // OnBeforeCheckItemJnlLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        // if IsHandled then
        //     exit;

        FAItemJnlLine.SetRange("FA Item No.", "No.");
        if not FAItemJnlLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", FAItemJnlLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", FAItemJnlLine.TableCaption());
        end;
    end;

    procedure CheckDocuments(CurrentFieldNo: Integer)
    begin
        if "No." = '' then
            exit;

        // CheckBOM(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckPurchLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckSalesLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckProdOrderLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckProdOrderCompLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckPlanningCompLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckTransLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckServLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckProdBOMLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckServContractLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckAsmHeader(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckAsmLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        // CheckJobPlanningLine(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));
        CheckConHeader(CurrentFieldNo, FieldNo(Type), FieldCaption(Type));

        // OnAfterCheckDocuments(Rec, xRec, CurrentFieldNo);
    end;

    procedure CheckConHeader(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ConversionHeader: Record "FA Conversion Header";
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckAsmHeader(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        // if IsHandled then
        //     exit;

        // ConversionHeader.SetCurrentKey("Document Type", "FA Item No.");
        ConversionHeader.SetRange("FA Item No.", "No.");
        if not ConversionHeader.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text023, TableCaption(), "No.", ConversionHeader.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", ConversionHeader.TableCaption());
        end;
    end;

    procedure CheckTransLine(CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
    // IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCheckTransLine(Rec, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
        // if IsHandled then
        //     exit;

        TransLine.SetCurrentKey("FA Item No.");
        TransLine.SetRange("FA Item No.", "No.");
        if not TransLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(Text016, TableCaption(), "No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(CannotChangeFieldErr, CheckFieldCaption, TableCaption(), "No.", TransLine.TableCaption());
        end;
    end;

    local procedure CreateItemUnitOfMeasure()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCreateItemUnitOfMeasure(Rec, ItemUnitOfMeasure, IsHandled);
        if IsHandled then
            exit;

        ItemUnitOfMeasure.Init();
        if IsTemporary then
            ItemUnitOfMeasure."Item No." := "No."
        else
            ItemUnitOfMeasure.Validate("Item No.", "No.");
        ItemUnitOfMeasure.Validate(Code, "Base Unit of Measure");
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ItemUnitOfMeasure.Insert();
    end;

    procedure UpdateUnitOfMeasureId()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if "Base Unit of Measure" = '' then begin
            Clear("Unit of Measure Id");
            exit;
        end;

        if not UnitOfMeasure.Get("Base Unit of Measure") then
            exit;

        "Unit of Measure Id" := UnitOfMeasure.SystemId;
    end;

    local procedure UpdateQtyRoundingPrecisionForBaseUoM()
    var
        BaseItemUnitOfMeasure: Record "FA Item Unit of Measure";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeUpdateQtyRoundingPrecisionForBaseUoM(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        // Reset Rounding Percision in old Base UOM
        if BaseItemUnitOfMeasure.Get("No.", xRec."Base Unit of Measure") then begin
            BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 0);
            BaseItemUnitOfMeasure.Modify(true);
        end;
    end;

    local procedure UpdateUnitOfMeasureCode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not IsNullGuid("Unit of Measure Id") then
            UnitOfMeasure.GetBySystemId("Unit of Measure Id");

        "Base Unit of Measure" := UnitOfMeasure.Code;
    end;

    procedure TryGetItemNo(var ReturnValue: Text[50]; ItemText: Text; DefaultCreate: Boolean): Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        exit(TryGetItemNoOpenCard(ReturnValue, ItemText, DefaultCreate, true, not InventorySetup."Skip Prompt to Create Item"));
    end;

    procedure TryGetItemNoOpenCard(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean): Boolean
    var
        ItemView: Record Item;
    begin
        ItemView.SetRange(Blocked, false);
        exit(TryGetItemNoOpenCardWithView(ReturnValue, ItemText, DefaultCreate, ShowItemCard, ShowCreateItemOption, ItemView.GetView()));
    end;

    internal procedure TryGetItemNoOpenCardWithView(var ReturnValue: Text; ItemText: Text; DefaultCreate: Boolean; ShowItemCard: Boolean; ShowCreateItemOption: Boolean; View: Text): Boolean
    var
        FAItem: Record "FA Item";
        // SalesLine: Record "Sales Line";
        FindRecordMgt: Codeunit "Find Record Management";
        ItemNo: Code[20];
        ItemWithoutQuote: Text;
        ItemFilterContains: Text;
        FoundRecordCount: Integer;
    begin
        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if ItemText = '' then
            exit(DefaultCreate);

        FoundRecordCount :=
            // FindRecordMgt.
            FindRecordByDescriptionAndView(ReturnValue, 2, ItemText, View);

        if FoundRecordCount = 1 then
            exit(true);

        ReturnValue := CopyStr(ItemText, 1, MaxStrLen(ReturnValue));
        if FoundRecordCount = 0 then begin
            if not DefaultCreate then
                exit(false);

            if not GuiAllowed then
                Error(SelectItemErr);

            // OnTryGetItemNoOpenCardWithViewOnBeforeShowCreateItemOption(Rec);
            if FAItem.WritePermission then
                if ShowCreateItemOption then
                    case StrMenu(
                           StrSubstNo('%1,%2', StrSubstNo(CreateNewItemTxt, ConvertStr(ItemText, ',', '.')), SelectItemTxt), 1, ItemNotRegisteredTxt)
                    of
                        0:
                            Error('');
                        1:
                            begin
                                ReturnValue := CreateNewItem(CopyStr(ItemText, 1, MaxStrLen(FAItem.Description)), ShowItemCard);
                                exit(true);
                            end;
                    end
                else
                    exit(false);
        end;

        if not GuiAllowed then
            Error(SelectItemErr);

        if FoundRecordCount > 0 then begin
            ItemWithoutQuote := ConvertStr(ItemText, '''', '?');
            ItemFilterContains := '''@*' + ItemWithoutQuote + '*''';
            FAItem.FilterGroup(-1);
            FAItem.SetFilter("No.", ItemFilterContains);
            FAItem.SetFilter(Description, ItemFilterContains);
            FAItem.SetFilter("Base Unit of Measure", ItemFilterContains);
            // OnTryGetItemNoOpenCardOnAfterSetItemFilters(Item, ItemFilterContains);
        end;

        if ShowItemCard then
            ItemNo := PickItem(FAItem)
        else begin
            ReturnValue := '';
            exit(true);
        end;

        if ItemNo <> '' then begin
            ReturnValue := ItemNo;
            exit(true);
        end;

        if not DefaultCreate then
            exit(false);
        Error('');
    end;

    local procedure CreateNewItem(ItemName: Text[100]; ShowItemCard: Boolean): Code[20]
    var
        FAItem: Record "FA Item";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        FAItemCard: Page "FA Item Card";
    begin
        // OnBeforeCreateNewItem(Item, ItemName);
        // if not ItemTemplMgt.InsertItemFromTemplate(FAItem) then
        //     Error(SelectItemErr);

        // FAItem.Description := ItemName;
        // FAItem.Modify(true);
        // Commit();
        // if not ShowItemCard then
        //     exit(FAItem."No.");
        // FAItem.SetRange("No.", FAItem."No.");
        // FAItemCard.SetTableView(FAItem);
        // if not (FAItemCard.RunModal() = ACTION::OK) then
        //     Error(SelectItemErr);

        // exit(FAItem."No.");
    end;

    procedure PickItem(var FAItem: Record "FA Item"): Code[20]
    var
        ItemList: Page "FA Item List";
    begin
        if FAItem.FilterGroup = -1 then
            ItemList.SetTempFilteredItemRec(FAItem);

        if FAItem.FindFirst() then;
        ItemList.SetTableView(FAItem);
        ItemList.SetRecord(FAItem);
        ItemList.LookupMode := true;
        if ItemList.RunModal() = ACTION::LookupOK then
            ItemList.GetRecord(FAItem)
        else
            Clear(FAItem);

        exit(FAItem."No.");
    end;

    procedure FindRecordByDescriptionAndView(var Result: Text; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; SearchText: Text; RecordView: Text): Integer
    var
        RecRef: RecordRef;
        SearchFieldRef: array[4] of FieldRef;
        SearchFieldNo: array[4] of Integer;
        KeyNoMaxStrLen: Integer;
        RecWithoutQuote: Text;
        RecFilterFromStart: Text;
        RecFilterContains: Text;
        MatchCount: Integer;
        IsHandled: Boolean;
        FindRecordMgt: Codeunit "Find Record Management";
    begin
        // Try to find a record by SearchText looking into "No." OR "Description" fields
        // SearchFieldNo[1] - "No."
        // SearchFieldNo[2] - "Description"/"Name"
        // SearchFieldNo[3] - "Base Unit of Measure" (used for items)
        Result := '';
        if SearchText = '' then
            exit(0);

        if not (Type in [Type::" " .. Type::"Charge (Item)"]) then
            exit(0);

        GetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
        RecRef.SetView(RecordView);

        SearchFieldRef[1] := RecRef.Field(SearchFieldNo[1]);
        SearchFieldRef[2] := RecRef.Field(SearchFieldNo[2]);
        if SearchFieldNo[3] <> 0 then
            SearchFieldRef[3] := RecRef.Field(SearchFieldNo[3]);

        IsHandled := false;
        MatchCount := 0;
        // OnBeforeFindRecordByDescriptionAndView(Result, Type, RecRef, SearchFieldRef, SearchText, RecordView, MatchCount, IsHandled);
        if IsHandled then
            exit(MatchCount);

        // Try GET(SearchText)
        KeyNoMaxStrLen := SearchFieldRef[1].Length;
        if StrLen(SearchText) <= KeyNoMaxStrLen then begin
            SearchFieldRef[1].SetRange(CopyStr(SearchText, 1, KeyNoMaxStrLen));
            RecRef.SetLoadFields(SearchFieldRef[1].Number);
            if RecRef.FindFirst() then begin
                Result := SearchFieldRef[1].Value;
                exit(1);
            end;
        end;
        SearchFieldRef[1].SetRange();
        ClearLastError();

        RecWithoutQuote := ConvertStr(SearchText, '''()&|', '?????');

        // Try FINDFIRST "No." by mask "Search string *"
        if TrySetFilterOnFieldRef(SearchFieldRef[1], RecWithoutQuote + '*') then begin
            RecRef.SetLoadFields(SearchFieldRef[1].Number);
            if RecRef.FindFirst() then begin
                Result := SearchFieldRef[1].Value;
                exit(1);
            end;
        end;
        SearchFieldRef[1].SetRange();
        ClearLastError();

        // Two items with descrptions = "aaa" and "AAA";
        // Try FINDFIRST by exact "Description" = "AAA"
        SearchFieldRef[2].SetRange(CopyStr(SearchText, 1, SearchFieldRef[2].Length));
        RecRef.SetLoadFields(SearchFieldRef[1].Number);
        if RecRef.FindFirst() then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;
        SearchFieldRef[2].SetRange();

        // Example of SearchText = "Search string ''";
        // Try FINDFIRST "Description" by mask "@Search string ?"
        SearchFieldRef[2].SetFilter('''@' + RecWithoutQuote + '''');
        RecRef.SetLoadFields(SearchFieldRef[1].Number);
        if RecRef.FindFirst() then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;
        SearchFieldRef[2].SetRange();

        // Try FINDFIRST "No." OR "Description" by mask "@Search string ?*"
        RecRef.FilterGroup := -1;
        RecFilterFromStart := '''@' + RecWithoutQuote + '*''';
        SearchFieldRef[1].SetFilter(RecFilterFromStart);
        SearchFieldRef[2].SetFilter(RecFilterFromStart);
        // OnBeforeFindRecordStartingWithSearchString(Type, RecRef, RecFilterFromStart);
        RecRef.SetLoadFields(SearchFieldRef[1].Number);
        if RecRef.FindFirst() then begin
            Result := SearchFieldRef[1].Value;
            exit(1);
        end;

        // Try FINDFIRST "No." OR "Description" OR additional field by mask "@*Search string ?*"
        RecFilterContains := '''@*' + RecWithoutQuote + '*''';
        SearchFieldRef[1].SetFilter(RecFilterContains);
        SearchFieldRef[2].SetFilter(RecFilterContains);
        if SearchFieldNo[3] <> 0 then
            SearchFieldRef[3].SetFilter(RecFilterContains);
        // OnBeforeFindRecordContainingSearchString(Type, RecRef, RecFilterContains);
        RecRef.SetLoadFields(SearchFieldRef[1].Number);
        if RecRef.FindFirst() then begin
            Result := SearchFieldRef[1].Value;
            exit(RecRef.Count);
        end;

        // Try FINDLAST record with similar "Description"
        IsHandled := false;
        // OnFindRecordByDescriptionAndViewOnBeforeFindRecordWithSimilarName(RecRef, SearchText, SearchFieldNo, IsHandled);
        if not IsHandled then begin
            RecRef.SetLoadFields(SearchFieldRef[1].Number);
            if FindRecordMgt.FindRecordWithSimilarName(RecRef, SearchText, SearchFieldNo[2]) then begin
                Result := SearchFieldRef[1].Value;
                exit(1);
            end;
        end;

        // Try find for extension
        MatchCount := 0;
        // OnAfterFindRecordByDescriptionAndView(Result, Type, RecRef, SearchFieldRef, SearchFieldNo, SearchText, MatchCount);
        if MatchCount <> 0 then
            exit(MatchCount);

        // Not found
        exit(0);
    end;

    local procedure GetRecRefAndFieldsNoByType(RecRef: RecordRef; Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"; var SearchFieldNo: array[4] of Integer)
    var
        //     GLAccount: Record "G/L Account";
        Item: Record "FA Item";
        FixedAsset: Record "Fixed Asset";
        // Resource: Record Resource;
        ItemCharge: Record "Item Charge";
        StandardText: Record "Standard Text";
    begin
        // OnBeforeGetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
        case Type of
            // Type::"G/L Account":
            //     begin
            //         RecRef.Open(DATABASE::"G/L Account");
            //         SearchFieldNo[1] := GLAccount.FieldNo("No.");
            //         SearchFieldNo[2] := GLAccount.FieldNo(Name);
            //         SearchFieldNo[3] := 0;
            //     end;
            Type::Item:
                begin
                    RecRef.Open(DATABASE::"FA Item");
                    SearchFieldNo[1] := Item.FieldNo("No.");
                    SearchFieldNo[2] := Item.FieldNo(Description);
                    SearchFieldNo[3] := Item.FieldNo("Base Unit of Measure");
                end;
            Type::Resource:
                begin
                    // RecRef.Open(DATABASE::Resource);
                    // SearchFieldNo[1] := Resource.FieldNo("No.");
                    // SearchFieldNo[2] := Resource.FieldNo(Name);
                    // SearchFieldNo[3] := 0;
                end;
            Type::"Fixed Asset":
                begin
                    RecRef.Open(DATABASE::"Fixed Asset");
                    SearchFieldNo[1] := FixedAsset.FieldNo("No.");
                    SearchFieldNo[2] := FixedAsset.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::"Charge (Item)":
                begin
                    RecRef.Open(DATABASE::"Item Charge");
                    SearchFieldNo[1] := ItemCharge.FieldNo("No.");
                    SearchFieldNo[2] := ItemCharge.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
            Type::" ":
                begin
                    RecRef.Open(DATABASE::"Standard Text");
                    SearchFieldNo[1] := StandardText.FieldNo(Code);
                    SearchFieldNo[2] := StandardText.FieldNo(Description);
                    SearchFieldNo[3] := 0;
                end;
        end;
        // OnAfterGetRecRefAndFieldsNoByType(RecRef, Type, SearchFieldNo);
    end;

    [TryFunction]
    local procedure TrySetFilterOnFieldRef(var FieldRef: FieldRef; "Filter": Text)
    begin
        FieldRef.SetFilter(Filter);
    end;

    procedure IsNonInventoriableType(): Boolean
    begin
        exit(Type in [Type::"Non-Inventory", Type::Service]);
    end;

    procedure IsInventoriableType(): Boolean
    begin
        exit(not IsNonInventoriableType());
    end;

    procedure IsDozeeDevice(ItemNo: Code[20]): Boolean
    begin
        if FAItem.Get(ItemNo) then
            exit(FAItem.device);
        exit(false);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        // OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"FA Item", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        // OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure IsVariantMandatory(IsTypeItem: Boolean; ItemNo: Code[20]): Boolean
    begin
        if IsTypeItem and (ItemNo <> '') then
            exit(IsVariantMandatory(ItemNo));
        exit(false)
    end;

    procedure IsVariantMandatory(): Boolean
    begin
        exit(IsVariantMandatory(Rec."No."));
    end;

    local procedure IsVariantMandatory(ItemNo: Code[20]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeIsVariantMandatory(ItemNo, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ItemNo <> Rec."No." then begin
            Rec.SetLoadFields("No.", "Variant Mandatory if Exists");
            if Rec.Get(ItemNo) then;
            Rec.SetLoadFields();
        end;
        if ItemNo <> Rec."No." then
            exit(false);
        if VariantMandatoryIfAvailable(false, false) then
            exit(VariantsAvailable(ItemNo))
        else
            exit(false);
    end;

    internal procedure IsVariantMandatory(InvtSetupDefaultSetting: boolean): Boolean
    begin
        if VariantMandatoryIfAvailable(true, InvtSetupDefaultSetting) then
            exit(VariantsAvailable())
        else
            exit(false);
    end;

    local procedure VariantMandatoryIfAvailable(InvtSetupDefaultIsKnown: boolean; InvtSetupDefaultSetting: boolean): Boolean
    begin
        case "Variant Mandatory if Exists" of
            "Variant Mandatory if Exists"::Default:
                begin
                    if InvtSetupDefaultIsKnown then
                        exit(InvtSetupDefaultSetting);
                    // GetInvtSetup();
                    // exit(InventorySetup."Variant Mandatory if Exists");
                end;
            "Variant Mandatory if Exists"::No:
                exit(false);
            "Variant Mandatory if Exists"::Yes:
                exit(true);
        end;
    end;

    local procedure VariantsAvailable(): Boolean
    begin
        exit(VariantsAvailable(Rec."No."));
    end;

    local procedure VariantsAvailable(ItemNo: Code[20]): Boolean
    var
        ItemVariant: Record "FA Item Variant";
    begin
        ItemVariant.SetLoadFields("Item No.");
        ItemVariant.SetRange("Item No.", ItemNo);
        exit(not ItemVariant.IsEmpty());
    end;
}