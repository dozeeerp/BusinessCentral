namespace TSTChanges.FA.Journal;

using TSTChanges.FA.FAItem;
using TSTChanges.Warehouse;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Structure;
using TSTChanges.FA.Conversion;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.AuditCodes;
using TSTChanges.FA.Ledger;
using TSTChanges.FA.Tracking;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;

table 51209 "FA Item Journal Line"
{
    DataClassification = CustomerContent;
    Caption = 'FA Item Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Item Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; "FA Item No."; Code[20])
        {
            Caption = 'FA Item No.';
            TableRelation = "FA Item";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Entry Type"; Enum "FA Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) "FA Item";
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                CallWhseCheck: Boolean;
            begin
                if ("Entry Type".AsInteger() <= "Entry Type"::Transfer.AsInteger()) and (Quantity <> 0) then
                    TestField("FA Item No.");

                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                // CallWhseCheck :=
                //   ("Entry Type" = "Entry Type"::"Assembly Consumption") or
                //   ("Entry Type" = "Entry Type"::Consumption) or
                //   ("Entry Type" = "Entry Type"::Output) and
                //   LastOutputOperation(Rec);

                // if CallWhseCheck then begin
                //     GetItem();
                //     if Item.IsInventoriableType() then
                //         WhseValidateSourceLine.ItemLineVerifyChange(Rec, xRec);
                // end;

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if FAItem.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption(Quantity));
                end;

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                // // if ("Entry Type" = "Entry Type"::Output) and
                // //    ("Value Entry Type" <> "Value Entry Type"::Revaluation)
                // // then
                // //     "Invoiced Quantity" := 0
                // // else
                "Invoiced Quantity" := Quantity;
                "Invoiced Qty. (Base)" := CalcBaseQty("Invoiced Quantity", FieldCaption("Invoiced Quantity"), FieldCaption("Invoiced Qty. (Base)"));

                CheckSerialNoQty();

                // OnValidateQuantityOnBeforeGetUnitAmount(Rec, xRec, CurrFieldNo);

                // GetUnitAmount(FieldNo(Quantity));
                // UpdateAmount();

                CheckItemAvailable(FieldNo(Quantity));

                if "Entry Type" = "Entry Type"::Transfer then begin
                    "Qty. (Calculated)" := 0;
                    "Qty. (Phys. Inventory)" := 0;
                    "Last Item Ledger Entry No." := 0;
                end;

                CheckReservedQtyBase();

                if FAItem."Item Tracking Code" <> '' then
                    ItemJnlLineReserve.VerifyQuantity(Rec, xRec);
            end;
        }
        field(11; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(12; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(13; "Applies-to Entry"; Integer)
        {
            Caption = 'Applies-to Entry';
        }
        field(14; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
            Editable = false;
        }
        field(15; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(16; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(17; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Location Code" <> xRec."New Location Code" then begin
                    "New Bin Code" := '';
                    if ("New Location Code" <> '') and ("FA Item No." <> '') then begin
                        GetLocation("New Location Code");
                        GetItem();
                        if IsDefaultBin() and FAItem.IsInventoriableType() then
                            WMSManagement.GetDefaultBin("FA Item No.", "Variant Code", "New Location Code", "New Bin Code")
                    end;
                end;

                CreateNewDimFromDefaultDim(Rec.FieldNo("New Location Code"));

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(18; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(19; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(20; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(21; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            // TableRelation = if ("Order Type" = const(Production)) "Production Order"."No." where(Status = const(Released));

            trigger OnValidate()
            var
                ConversionHeader: Record "FA Conversion Header";
            // ProdOrder: Record "Production Order";
            // ProdOrderLine: Record "Prod. Order Line";
            begin
                case "Order Type" of
                    //     "Order Type"::Production,
                    //     "Order Type"::Assembly:
                    //         begin
                    //             if "Order No." = '' then begin
                    //                 case "Order Type" of
                    //                     "Order Type"::Production:
                    //                         CreateProdDim();
                    //                     "Order Type"::Assembly:
                    //                         CreateAssemblyDim();
                    //                 end;
                    //                 exit;
                    //             end;

                    //             case "Order Type" of
                    //                 "Order Type"::Production:
                    //                     begin
                    //                         GetMfgSetup();
                    //                         if MfgSetup."Doc. No. Is Prod. Order No." then
                    //                             "Document No." := "Order No.";
                    //                         ProdOrder.Get(ProdOrder.Status::Released, "Order No.");
                    //                         ProdOrder.TestField(Blocked, false);
                    //                         Description := ProdOrder.Description;
                    //                         OnValidateOrderNoOrderTypeProduction(Rec, ProdOrder);
                    //                     end;
                    //                 "Order Type"::Assembly:
                    //                     begin
                    //                         AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Order No.");
                    //                         Description := AssemblyHeader.Description;
                    //                         OnValidateOrderNoOnAfterProcessOrderTypeAssembly(Rec, ProdOrder, AssemblyHeader);
                    //                     end;
                    //             end;

                    //             "Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
                    //             case true of
                    //                 "Entry Type" = "Entry Type"::Output:
                    //                     begin
                    //                         "Inventory Posting Group" := ProdOrder."Inventory Posting Group";
                    //                         "Gen. Prod. Posting Group" := ProdOrder."Gen. Prod. Posting Group";
                    //                     end;
                    //                 "Entry Type" = "Entry Type"::"Assembly Output":
                    //                     begin
                    //                         "Inventory Posting Group" := AssemblyHeader."Inventory Posting Group";
                    //                         "Gen. Prod. Posting Group" := AssemblyHeader."Gen. Prod. Posting Group";
                    //                     end;
                    //                 "Entry Type" = "Entry Type"::Consumption:
                    //                     begin
                    //                         ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                    //                         if ProdOrderLine.Count = 1 then begin
                    //                             ProdOrderLine.FindFirst();
                    //                             Validate("Order Line No.", ProdOrderLine."Line No.");
                    //                         end;
                    //                     end;
                    //             end;

                    //             if ("Order No." <> xRec."Order No.") or ("Order Type" <> xRec."Order Type") then
                    //                 case "Order Type" of
                    //                     "Order Type"::Production:
                    //                         CreateProdDim();
                    //                     "Order Type"::Assembly:
                    //                         CreateAssemblyDim();
                    //                 end;
                    //         end;
                    "Order Type"::Transfer://, "Order Type"::Service, "Order Type"::" ":
                        Error(Text002, FieldCaption("Order No."), FieldCaption("Order Type"), "Order Type");
                //     else
                //         OnValidateOrderNoOnCaseOrderTypeElse(Rec);
                end;
            end;
        }
        field(22; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("FA Item No."));
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Entry Type" = filter("Negative Adjmt." | Transfer),
                                Quantity = filter(> 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                        "Item No." = field("FA Item No."))
            else
            if ("Entry Type" = filter("Negative Adjmt." | Transfer),
                Quantity = filter(<= 0)) Bin.Code where("Location Code" = field("Location Code"),
                                                        "Item Filter" = field("FA Item No."));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
                IsHandled: Boolean;
            begin
                if "Bin Code" <> xRec."Bin Code" then begin
                    TestField("Location Code");
                    if "Bin Code" <> '' then begin
                        GetItem();
                        FAItem.TestField(Type, FAItem.Type::Inventory);
                        GetBin("Location Code", "Bin Code");
                        GetLocation("Location Code");
                        //         IsHandled := false;
                        //         OnBinCodeOnBeforeTestBinMandatory(Rec, IsHandled);
                        //         if not IsHandled then
                        Location.TestField("Bin Mandatory");
                        if CurrFieldNo <> 0 then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Bin Code"));
                        TestField("Location Code", Bin."Location Code");
                        //         WhseIntegrationMgt.CheckBinTypeCode(
                        //             Database::"Item Journal Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", "Entry Type".AsInteger());
                    end;
                    //     SetNewBinCodeForSameLocationTransfer();

                    //     IsHandled := false;
                    //     OnBinCodeOnCheckProdOrderCompBinCodeCheckNeeded(Rec, IsHandled);
                    //     if not IsHandled then
                    //         if ("Entry Type" = "Entry Type"::Consumption) and
                    //         ("Bin Code" <> '') and ("Prod. Order Comp. Line No." <> 0)
                    //         then begin
                    //             TestField("Order Type", "Order Type"::Production);
                    //             TestField("Order No.");
                    //             CheckProdOrderCompBinCode();
                    //         end;
                end;

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(24; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(25; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
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
        field(28; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(29; "Invoiced Qty. (Base)"; Decimal)
        {
            Caption = 'Invoiced Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(30; "Reserved Qty. (Base)"; Decimal)
        {
            // AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("FA Reservation Entry"."Quantity (Base)" where("Source ID" = field("Journal Template Name"),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(50209),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field("Entry Type"),
#pragma warning restore
                                                                           "Source Batch Name" = field("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-from Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "FA Item ledger Entry";
                ItemTrackingLines: Page "Item Tracking Lines";
                IsHandled: Boolean;
            begin
                if "Applies-from Entry" <> 0 then begin
                    TestField(Quantity);
                    if Signed(Quantity) < 0 then begin
                        if Quantity > 0 then
                            FieldError(Quantity, Text030);
                        if Quantity < 0 then
                            FieldError(Quantity, Text029);
                    end;
                    ItemLedgEntry.Get("Applies-from Entry");
                    ItemLedgEntry.TestField(Positive, false);

                    // OnValidateAppliesfromEntryOnBeforeCheckTrackingExistsError(Rec, ItemLedgEntry, IsHandled);
                    if not IsHandled then
                        if ItemLedgEntry.TrackingExists() then
                            Error(Text033, FieldCaption("Applies-from Entry"), ItemTrackingLines.Caption);
                    // "Unit Cost" := CalcUnitCost(ItemLedgEntry);
                end;
            end;
        }
        field(32; Correction; Boolean)
        {
            Caption = 'Correction';
        }

        field(33; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Serial No."));
            end;
        }
        field(34; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Lot No."));
            end;
        }
        field(35; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            Editable = false;
        }
        field(36; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            Editable = false;
        }
        field(37; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            Editable = false;

            trigger OnValidate()
            begin
                if "Order Type" = xRec."Order Type" then
                    exit;
                Validate("Order No.", '');
                "Order Line No." := 0;
            end;
        }
        field(38; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(39; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(40; "New Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1,' + Text007;
            Caption = 'New Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
            end;
        }
        field(41; "New Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2,' + Text007;
            Caption = 'New Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");
            end;
        }
        field(42; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(43; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Qty. (Phys. Inventory)");
            end;
        }
        field(44; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Phys. Inventory", true);

                if CurrFieldNo <> 0 then begin
                    GetItem();
                    if FAItem.IsInventoriableType() then
                        WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("Qty. (Phys. Inventory)"));
                end;

                "Qty. (Phys. Inventory)" := UOMMgt.RoundAndValidateQty("Qty. (Phys. Inventory)", "Qty. Rounding Precision (Base)", FieldCaption("Qty. (Phys. Inventory)"));

                PhysInvtEntered := true;
                Quantity := 0;
                if "Qty. (Phys. Inventory)" >= "Qty. (Calculated)" then begin
                    Validate("Entry Type", "Entry Type"::"Positive Adjmt.");
                    Validate(Quantity, "Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                end else begin
                    Validate("Entry Type", "Entry Type"::"Negative Adjmt.");
                    Validate(Quantity, "Qty. (Calculated)" - "Qty. (Phys. Inventory)");
                end;
                PhysInvtEntered := false;
            end;
        }
        field(45; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(46; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            Editable = false;
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(50; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(62; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = "Area";
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(79; "Document Type"; Enum "Item Ledger Document Type")
        {
            Caption = 'Document Type';
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            // TableRelation = if ("Order Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = const(Released),
            //  "Prod. Order No." = field("Order No."));

            trigger OnValidate()
            var
            // ProdOrderLine: Record "Prod. Order Line";
            begin
                TestField("Order No.");
                case "Order Type" of
                    "Order Type"::Production,
                    "Order Type"::Assembly:
                        begin
                            // if "Order Type" = "Order Type"::Production then begin
                            //     ProdOrderLine.SetFilterByReleasedOrderNo("Order No.");
                            //     ProdOrderLine.SetRange("Line No.", "Order Line No.");
                            //     OnValidateOrderLineNoOnAfterProdOrderLineSetFilters(Rec, ProdOrderLine);
                            //     if ProdOrderLine.FindFirst() then begin
                            //         "Source Type" := "Source Type"::Item;
                            //         "Source No." := ProdOrderLine."Item No.";
                            //         "Order Line No." := ProdOrderLine."Line No.";
                            //         "Routing No." := ProdOrderLine."Routing No.";
                            //         "Routing Reference No." := ProdOrderLine."Routing Reference No.";
                            //         if "Entry Type" = "Entry Type"::Output then begin
                            //             "Location Code" := ProdOrderLine."Location Code";
                            //             "Bin Code" := ProdOrderLine."Bin Code";
                            //         end;
                            //         OnOrderLineNoOnValidateOnAfterAssignProdOrderLineValues(Rec, ProdOrderLine);
                            //     end;
                            // end;

                            // if "Order Line No." <> xRec."Order Line No." then
                            //     case "Order Type" of
                            //         "Order Type"::Production:
                            //             CreateProdDim();
                            //         "Order Type"::Assembly:
                            //             CreateAssemblyDim();
                            //     end;
                        end;
                    else
                // OnValidateOrderLineNoOnCaseOrderTypeElse(Rec);
                end;
            end;
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(481; "New Dimension Set ID"; Integer)
        {
            Caption = 'New Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(5406; "New Bin Code"; Code[20])
        {
            Caption = 'New Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("New Location Code"),
                                            "Item Filter" = field("FA Item No."),
                                            "Variant Filter" = field("Variant Code"));

            trigger OnValidate()
            var
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestField("Entry Type", "Entry Type"::Transfer);
                if "New Bin Code" <> xRec."New Bin Code" then begin
                    TestField("New Location Code");
                    if "New Bin Code" <> '' then begin
                        GetItem();
                        FAItem.TestField(Type, FAItem.Type::Inventory);
                        GetBin("New Location Code", "New Bin Code");
                        GetLocation("New Location Code");
                        Location.TestField("Bin Mandatory");
                        if CurrFieldNo <> 0 then
                            WMSManagement.CheckItemJnlLineFieldChange(Rec, xRec, FieldCaption("New Bin Code"));
                        TestField("New Location Code", Bin."Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"FA Item Journal Line", FieldCaption("New Bin Code"), "New Location Code", "New Bin Code", "Entry Type".AsInteger());
                    end;
                end;

                ItemJnlLineReserve.VerifyChange(Rec, xRec);
            end;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnValidate()
            begin
                CheckItemTracking(FieldNo("Package No."));
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,1';
            Editable = false;
        }
        field(7316; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
            DataClassification = SystemMetadata;
        }
        field(8000; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin
        LockTable();
        ItemJnlTemplate.Get("Journal Template Name");
        ItemJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
        ValidateNewShortcutDimCode(1, "New Shortcut Dimension 1 Code");
        ValidateNewShortcutDimCode(2, "New Shortcut Dimension 2 Code");

        // CheckPlanningAssignment();
    end;

    trigger OnModify()
    begin
        // OnBeforeVerifyReservedQty(Rec, xRec, 0);
        ItemJnlLineReserve.VerifyChange(Rec, xRec);
        // CheckPlanningAssignment();
    end;

    trigger OnDelete()
    begin
        ItemJnlLineReserve.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnRename()
    begin
        ItemJnlLineReserve.RenameLine(Rec, xRec);
    end;

    var
        ItemJnlLineReserve: Codeunit "FA Item Jnl. Line-Reserve";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        FAItem: Record "FA Item";
        Location: Record Location;
        Bin: Record Bin;
        WMSManagement: Codeunit "TST WMS Management";
        ItemTrackingExistsErr: Label 'You cannot change %1 because item tracking already exists for this journal line.', Comment = '%1 - Serial or Lot No.';
        Text001: Label '%1 must be reduced.';
        Text002: Label 'You cannot change %1 when %2 is %3.';
        Text007: Label 'New ';
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
        Text031: Label 'You can not insert item number %1 because it is not produced on released production order %2.';
        Text032: Label 'When posting, the entry %1 will be opened first.';
        Text033: Label 'If the item carries serial or lot numbers, then you must use the %1 field in the %2 window.';
        IncorrectQtyForSNErr: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        BlockedErr: Label 'You cannot choose %2 %1 because the %3 check box is selected on its %2 card.', Comment = '%1 - Item No., %2 - Table Caption (item/variant), %3 - Field Caption';

    protected var
        FAItemJnlLine: Record "FA Item Journal Line";
        PhysInvtEntered: Boolean;

    procedure EmptyLine(): Boolean
    begin
        exit(
          (Quantity = 0) and
          //((TimeIsEmpty() and
          ("FA Item No." = '')) //or
                                //"Value Entry Type" = "Value Entry Type"::Revaluation));
    end;

    // procedure TimeIsEmpty(): Boolean
    // begin
    //     exit(("Setup Time" = 0) and ("Run Time" = 0) and ("Stop Time" = 0));
    // end;

    procedure ItemPosting(): Boolean
    var
    // ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    // NextOperationNoIsEmpty: Boolean;
    // IsHandled: Boolean;
    begin
        // if ("Entry Type" = "Entry Type"::Output) and ("Output Quantity" <> 0) and ("Operation No." <> '') then begin
        //     // GetProdOrderRoutingLine(ProdOrderRoutingLine);
        //     IsHandled := false;
        //     OnAfterItemPosting(ProdOrderRoutingLine, NextOperationNoIsEmpty, IsHandled);
        //     if IsHandled then
        //         exit(NextOperationNoIsEmpty);
        //     exit(ProdOrderRoutingLine."Next Operation No." = '');
        // end;

        exit(true);
    end;

    procedure Signed(Value: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeSigned(Rec, Value, Result, IsHandled);
        // if IsHandled then
        //     exit(Result);

        case "Entry Type" of
            "Entry Type"::"Positive Adjmt.",
            "Entry Type"::"Conversion Output":
                Result := Value;
            "Entry Type"::"Negative Adjmt.",
            "Entry Type"::Transfer:
                Result := -Value;
        end;

        // case "Entry Type" of
        //     //     "Entry Type"::Purchase,
        //     "Entry Type"::"Positive Adjmt.",
        //     //   "Entry Type"::Output,
        //     "Entry Type"::"Conversion Output":
        //         Result := Value;
        //     //     "Entry Type"::Sale,
        //     "Entry Type"::"Negative Adjmt.",
        //         //   "Entry Type"::Consumption,
        //         "Entry Type"::Transfer://,
        //                                //   "Entry Type"::"Assembly Consumption":
        //         Result := -Value;
        // end;
        // OnAfterSigned(Rec, Value, Result);
    end;

    procedure IsInbound(): Boolean
    begin
        exit((Signed(Quantity) > 0) or (Signed("Invoiced Quantity") > 0));
    end;

    local procedure IsItemTrackingEnabledInBatch(): Boolean
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        if ItemJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
            exit(ItemJournalBatch."Item Tracking on Lines");

        exit(false);
    end;

    local procedure CheckItemTracking(CalledByFieldNo: Integer)
    var
        FieldCap: Text;
        IsHandled: Boolean;
    begin
        // OnBeforeCheckItemTracking(Rec, IsHandled);
        // if IsHandled then
        //     exit;

        if not IsItemTrackingEnabledInBatch() then begin
            ClearTracking();
            ClearDates();
            exit;
        end;

        case CalledByFieldNo of
            FieldNo("Serial No."):
                begin
                    CheckSerialNoQty();
                    if "Serial No." <> '' then
                        if HasItemTracking() then
                            FieldCap := FieldCaption("Serial No.");
                end;
            FieldNo("Lot No."):
                if "Lot No." <> '' then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Lot No.");
            FieldNo("Package No."):
                if "Package No." <> '' then
                    if HasItemTracking() then
                        FieldCap := FieldCaption("Package No.");
        // FieldNo("Warranty Date"):
        //     if "Warranty Date" <> 0D then
        //         if HasItemTracking() then
        //             FieldCap := FieldCaption("Warranty Date");
        // FieldNo("Expiration Date"):
        //     if "Expiration Date" <> 0D then
        //         if HasItemTracking() then
        //             FieldCap := FieldCaption("Expiration Date");
        end;

        if FieldCap <> '' then
            Error(ItemTrackingExistsErr, FieldCap);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        // OnAfterClearTracking(Rec);
    end;

    procedure ClearDates()
    begin
        // "Expiration Date" := 0D;
        // "Warranty Date" := 0D;
    end;

    local procedure CheckSerialNoQty()
    begin
        if ("Serial No." = '') and ("New Serial No." = '') then
            exit;
        if not ("Quantity (Base)" in [-1, 0, 1]) then
            Error(IncorrectQtyForSNErr);
    end;

    local procedure HasItemTracking(): Boolean
    var
        ReservationEntry: Record "FA Reservation Entry";
    begin
        SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        exit(not ReservationEntry.IsEmpty());
    end;

    procedure SetReservationFilters(var ReservEntry: Record "FA Reservation Entry")
    begin
        SetReservEntrySourceFilters(ReservEntry, false);
        ReservEntry.SetTrackingFilterFromItemJnlLine(Rec);

        // OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    internal procedure SetReservEntrySourceFilters(var ReservEntry: Record "FA Reservation Entry"; SourceKey: Boolean)
    begin
        // if IsSourceSales() then
        //     ReservEntry.SetSourceFilter(Database::"FA Item Journal Line", "Entry Type".AsInteger(), "Document No.", "Document Line No.", SourceKey)
        // else
        ReservEntry.SetSourceFilter(Database::"FA Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", SourceKey);
        ReservEntry.SetSourceFilter("Journal Batch Name", 0);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeTestItemFields(Rec, ItemNo, VariantCode, LocationCode, IsHandled);
        if IsHandled then
            exit;

        TestField("FA Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure CheckTrackingIsEmpty()
    begin
        TestField("Serial No.", '');
        TestField("Lot No.", '');

        // OnAfterCheckTrackingisEmpty(Rec);
    end;

    procedure CheckNewTrackingIsEmpty()
    begin
        TestField("New Serial No.", '');
        TestField("New Lot No.", '');

        // OnAfterCheckNewTrackingisEmpty(Rec);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "FA Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        // OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyNewTrackingFromNewSpec(TrackingSpecification: Record "FA Tracking Specification")
    begin
        "New Serial No." := TrackingSpecification."New Serial No.";
        "New Lot No." := TrackingSpecification."New Lot No.";

        // OnAfterCopyNewTrackingFromNewSpec(Rec, TrackingSpecification);
    end;

    procedure HasSameNewTracking() IsSameTracking: Boolean
    begin
        IsSameTracking := ("Serial No." = "New Serial No.") and ("Lot No." = "New Lot No.");

        // OnAfterHasSameNewTracking(Rec, IsSameTracking);
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '');

        // OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure CheckTrackingEqualTrackingSpecification(TrackingSpecification: Record "FA Tracking Specification")
    begin
        TestField("Lot No.", TrackingSpecification."Lot No.");
        TestField("Serial No.", TrackingSpecification."Serial No.");

        // OnAfterCheckTrackingEqualTrackingSpecification(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "FA Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        // OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "FA Item No."));
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "FA Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        ReservEntry.ClearTrackingFilter();
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "FA Item Ledger Entry";
        ItemJnlLine2: Record "FA Item Journal Line";
        PositiveFilterValue: Boolean;
    begin
        // OnBeforeSelectItemEntry(Rec, xRec, CurrentFieldNo);

        // if ("Entry Type" = "Entry Type"::Output) and
        //    ("Value Entry Type" <> "Value Entry Type"::Revaluation) and
        //    (CurrentFieldNo = FieldNo("Applies-to Entry"))
        // then begin
        //     ItemLedgEntry.SetCurrentKey(
        //       "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        //     ItemLedgEntry.SetRange("Order Type", "Order Type"::Production);
        //     ItemLedgEntry.SetRange("Order No.", "Order No.");
        //     ItemLedgEntry.SetRange("Order Line No.", "Order Line No.");
        //     ItemLedgEntry.SetRange("Entry Type", "Entry Type");
        //     ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", 0);
        // end else begin
        ItemLedgEntry.SetCurrentKey("FA Item No.", Positive);
        ItemLedgEntry.SetRange("FA Item No.", "FA Item No.");
        // end;

        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");

        if CurrentFieldNo = FieldNo("Applies-to Entry") then begin
            if Quantity <> 0 then begin
                PositiveFilterValue := (Signed(Quantity) < 0);//or ("Value Entry Type" = "Value Entry Type"::Revaluation);
                ItemLedgEntry.SetRange(Positive, PositiveFilterValue);
            end;

            // if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
            //     ItemLedgEntry.SetCurrentKey("Item No.", Open);
            //     ItemLedgEntry.SetRange(Open, true);
            // end;
        end else
            ItemLedgEntry.SetRange(Positive, false);

        // OnSelectItemEntryOnBeforeOpenPage(ItemLedgEntry, Rec, CurrentFieldNo);

        if PAGE.RunModal(PAGE::"FA Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            ItemJnlLine2 := Rec;
            if CurrentFieldNo = FieldNo("Applies-to Entry") then
                ItemJnlLine2.Validate("Applies-to Entry", ItemLedgEntry."Entry No.")
            else
                ItemJnlLine2.Validate("Applies-from Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := ItemJnlLine2;
        end;

        // OnAfterSelectItemEntry(Rec);
    end;

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        if (CurrFieldNo = 0) or (CurrFieldNo <> CalledByFieldNo) then // Prevent two checks on quantity
            exit;

        IsHandled := false;
        // OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        // if (CurrFieldNo <> 0) and ("FA Item No." <> '') and (Quantity <> 0) and
        //    ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and ("Item Charge No." = '')
        // then
        //     if ItemCheckAvail.ItemJnlCheckLine(Rec) then
        //         ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    procedure SetReservationEntry(var ReservEntry: Record "FA Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"FA Item Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", "Journal Batch Name", 0);
        ReservEntry.SetItemData("FA Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Posting Date";
        ReservEntry."Shipment Date" := "Posting Date";

        // OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    internal procedure CalcReservedQuantity()
    var
        ReservationEntry: Record "FA Reservation Entry";
    begin
        // if IsSourceSales() then begin
        //     SetReservEntrySourceFilters(ReservationEntry, false);
        //     ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        //     ReservationEntry.CalcSums("Quantity (Base)");
        //     "Reserved Qty. (Base)" := ReservationEntry."Quantity (Base)"
        // end else
        CalcFields("Reserved Qty. (Base)");
    end;

    // procedure IsConversionResourceConsumpLine(): Boolean
    // begin
    //     exit(("Entry Type" = "Entry Type"::"Conversion Output") and (Type = Type::Resource));
    // end;

    Procedure IsConversionOutputLine(): Boolean
    begin
        exit(("Entry Type" = "Entry Type"::"Conversion Output")); //and (Type = Type::" "));
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    begin
        Result := UOMMgt.CalcBaseQty("FA Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName);
        // OnAfterCalcBaseQty(Rec, xRec, FromFieldName, Result);
    end;

    procedure IsNotInternalWhseMovement(): Boolean
    begin
        exit(
          not (("Entry Type" = "Entry Type"::Transfer) and
               ("Location Code" = "New Location Code") and
                ("Dimension Set ID" = "New Dimension Set ID")
                //    and
                //    ("Value Entry Type" = "Value Entry Type"::"Direct Cost") and
                //    not Adjustment
                ));
    end;

    procedure DisplayErrorIfItemIsBlocked(FAItem: Record "FA Item")
    begin
        if FAItem.Blocked then
            Error(BlockedErr, FAItem."No.", FAItem.TableCaption(), FAItem.FieldCaption(Blocked));
    end;

    procedure CopyDocumentFields(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20];
                                              ExtDocNo: Text[35];
                                              SourceCode: Code[10];
                                              NoSeriesCode: Code[20])
    begin
        "Document Type" := DocType;
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        // OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        // OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        // OnAfterShowDimensions(Rec);
    end;

    procedure ValidateNewShortcutDimCode(FieldNumber: Integer; var NewShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, NewShortcutDimCode, "New Dimension Set ID");
    end;

    local procedure CheckReservedQtyBase()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCheckReservedQtyBase(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Qty. (Base)");
        if Abs("Quantity (Base)") < Abs("Reserved Qty. (Base)") then
            Error(Text001, FieldCaption("Reserved Qty. (Base)"));
    end;

    local procedure GetItem()
    begin
        if FAItem."No." <> "FA Item No." then
            FAItem.Get("FA Item No.");

        // OnAfterGetItemChange(Item, Rec);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);

        // OnAfterGetLocation(Location, LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if BinCode = '' then
            Clear(Bin)
        else
            if (Bin.Code <> BinCode) or (Bin."Location Code" <> LocationCode) then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure CreateNewDimFromDefaultDim(FieldNo: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        SourceCode: Code[10];
    begin
        if not DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);

        SourceCode := "Source Code";
        if SourceCode = '' then
            if ItemJournalTemplate.Get("Journal Template Name") then
                SourceCode := ItemJournalTemplate."Source Code";

        "New Shortcut Dimension 1 Code" := '';
        "New Shortcut Dimension 2 Code" := '';
        "New Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCode,
            "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code", 0, 0);
        DimMgt.UpdateGlobalDimFromDimSetID("New Dimension Set ID", "New Shortcut Dimension 1 Code", "New Shortcut Dimension 2 Code");
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    begin
        case true of
            FieldNo = Rec.FieldNo("FA Item No."):
                TableValuePair.Add(Database::"FA Item", Rec."FA Item No.");
            // FieldNo = Rec.FieldNo("Salespers./Purch. Code"):
            // TableValuePair.Add(Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code");
            // FieldNo = Rec.FieldNo("Work Center No."):
            // TableValuePair.Add(Database::"Work Center", Rec."Work Center No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
            FieldNo = Rec.FieldNo("New Location Code"):
                TableValuePair.Add(Database::Location, Rec."New Location Code");
        end;

        // OnAfterInitTableValuePair(Rec, TableValuePair, FieldNo);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"FA Item", Rec."FA Item No.", FieldNo = Rec.FieldNo("FA Item No."));
        // DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salespers./Purch. Code", FieldNo = Rec.FieldNo("Salespers./Purch. Code"));
        // DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", Rec."Work Center No.", FieldNo = Rec.FieldNo("Work Center No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."New Location Code", FieldNo = Rec.FieldNo("New Location Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Customer No.", FieldNo = Rec.FieldNo("Customer No."));

        // OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    local procedure IsDefaultBin() Result: Boolean
    begin
        Result := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";

        // OnAfterIsDefaultBin(Location, Result);
    end;

    procedure CheckNewTrackingIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No. Required" then
            TestField("New Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            TestField("New Lot No.");

        // OnAfterCheckNewTrackingIfRequired(Rec, ItemTrackingSetup);
    end;

    procedure CheckItemJournalLineRestriction()
    begin
        OnCheckItemJournalLinePostRestrictions();
    end;

    procedure CopyNewTrackingFromOldItemLedgerEntry(FAItemLedgEntry: Record "FA Item Ledger Entry")
    begin
        "New Serial No." := FAItemLedgEntry."Serial No.";
        "New Lot No." := FAItemLedgEntry."Lot No.";

        // OnAfterCopyNewTrackingFromOldItemLedgerEntry(Rec, ItemLedgEntry);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCheckItemJournalLinePostRestrictions()
    begin
    end;
}