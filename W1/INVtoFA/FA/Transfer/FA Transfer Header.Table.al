namespace TSTChanges.FA.Transfer;

using Microsoft.Foundation.NoSeries;
using TSTChanges.FA.Setup;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Request;
using TSTChanges.FA.Tracking;
using TSTChanges.Automation;
using System.Utilities;
using Microsoft.Finance.TaxBase;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Shipping;
using TSTChanges.FA.Conversion;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.Dimension;
using System.Automation;
using System.Security.User;
using Microsoft.Foundation.Address;

table 51214 "FA Transfer Header"
{
    DataClassification = CustomerContent;
    Caption = 'FA Transfer Header';
    DataCaptionFields = "No.";
    LookupPageID = "FA Transfer Orders";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetFAConversionSetup();
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                Location: Record Location;
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidateTransferFromCode(Rec, xRec, IsHandled, HideValidationDialog);
                if IsHandled then
                    exit;

                if "Transfer-from Code" <> '' then
                    CheckTransferFromAndToCodesNotTheSame();

                if "Direct Transfer" then
                    VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");

                if xRec."Transfer-from Code" <> "Transfer-from Code" then begin
                    if HideValidationDialog or
                       (xRec."Transfer-from Code" = '')
                    then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-from Code"));
                    if Confirmed then begin
                        if Location.Get("Transfer-from Code") then begin
                            InitFromTransferFromLocation(Location);
                            if not "Direct Transfer" then begin
                                "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                                TransferRoute.GetTransferRoute(
                                  "Transfer-from Code", "Transfer-to Code", "In-Transit Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code");
                                // OnAfterGetTransferRoute(Rec, TransferRoute);
                                TransferRoute.GetShippingTime(
                                  "Transfer-from Code", "Transfer-to Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code",
                                  "Shipping Time");
                                CalcReceiptDate();
                            end;
                            FATransLine.LockTable();
                            FATransLine.SetRange("Document No.", "No.");
                        end;
                        // OnValidateTransferFromCodeOnBeforeUpdateTransLines(Rec);
                        UpdateTransLines(Rec, FieldNo("Transfer-from Code"));
                    end else
                        "Transfer-from Code" := xRec."Transfer-from Code";
                end;

                CreateDimFromDefaultDim(FieldNo("Transfer-from Code"));
            end;
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = if ("Trsf.-from Country/Region Code" = const('')) "Post Code"
            else
            if ("Trsf.-from Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Trsf.-from Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                // IsHandled := false;
                // OnBeforeValidateTransferFromPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                // if not IsHandled then
                PostCode.ValidatePostCode(
                    "Transfer-from City", "Transfer-from Post Code",
                    "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            TableRelation = if ("Trsf.-from Country/Region Code" = const('')) "Post Code".City
            else
            if ("Trsf.-from Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Trsf.-from Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                // IsHandled := false;
                // OnBeforeValidateTransferFromCity(Rec, PostCode, CurrFieldNo, IsHandled);
                // if not IsHandled then
                PostCode.ValidateCity(
                    "Transfer-from City", "Transfer-from Post Code",
                    "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            CaptionClass = '5,7,' + "Trsf.-from Country/Region Code";
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County",
                  "Trsf.-from Country/Region Code", xRec."Trsf.-from Country/Region Code");
            end;
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                Location: Record Location;
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                // IsHandled := false;
                // OnBeforeValidateTransferToCode(Rec, xRec, IsHandled, HideValidationDialog);
                // if IsHandled then
                //     exit;

                if "Transfer-to Code" <> '' then
                    CheckTransferFromAndToCodesNotTheSame();

                if "Direct Transfer" then
                    VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");

                if xRec."Transfer-to Code" <> "Transfer-to Code" then begin
                    if HideValidationDialog or (xRec."Transfer-to Code" = '') then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-to Code"));
                    if Confirmed then begin
                        if Location.Get("Transfer-to Code") then begin
                            InitFromTransferToLocation(Location);
                            if not "Direct Transfer" then begin
                                "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";
                                TransferRoute.GetTransferRoute(
                                  "Transfer-from Code", "Transfer-to Code", "In-Transit Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code");
                                // OnAfterGetTransferRoute(Rec, TransferRoute);
                                TransferRoute.GetShippingTime(
                                  "Transfer-from Code", "Transfer-to Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code",
                                  "Shipping Time");
                                CalcReceiptDate();
                            end;
                            FATransLine.LockTable();
                            FATransLine.SetRange("Document No.", "No.");
                        end;
                        UpdateTransLines(Rec, FieldNo("Transfer-to Code"));
                    end else
                        "Transfer-to Code" := xRec."Transfer-to Code";
                end;

                CreateDimFromDefaultDim(FieldNo("Transfer-to Code"));
            end;
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferToPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                        "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            TableRelation = if ("Trsf.-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Trsf.-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Trsf.-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                // OnBeforeValidateTransferToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                        "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            CaptionClass = '5,8,' + "Trsf.-to Country/Region Code";
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", xRec."Trsf.-to Country/Region Code");
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                // OnValidateShipmentDateOnBeforeCalcReceiptDate(IsHandled, Rec);
                if not IsHandled then
                    CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Shipment Date"));
            end;
        }
        field(22; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                // OnValidateReceiptDateOnBeforeCalcShipmentDate(IsHandled, Rec);
                if not IsHandled then
                    CalcShipmentDate();

                UpdateTransLines(Rec, FieldNo("Receipt Date"));
            end;
        }
        field(23; Status; Enum "Conversion Document Status")
        {
            Caption = 'Status';
            Editable = false;
            trigger OnValidate()
            begin
                UpdateTransLines(Rec, FieldNo(Status));
            end;
        }
        field(24; Comment; Boolean)
        {
            // CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Transfer Order"),
            //                                                     "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            // FieldClass = FlowField;
        }
        field(25; "Shortcut Dimension 1 Code"; Code[20])
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
        field(26; "Shortcut Dimension 2 Code"; Code[20])
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
        field(27; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location where("Use As In-Transit" = const(true));

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateTransLines(Rec, FieldNo("In-Transit Code"));
            end;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(29; "Last Shipment No."; Code[20])
        {
            Caption = 'Last Shipment No.';
            Editable = false;
            TableRelation = "FA Transfer Shipment Header";
        }
        field(30; "Last Receipt No."; Code[20])
        {
            Caption = 'Last Receipt No.';
            Editable = false;
            TableRelation = "FA Transfer Receipt Header";
        }
        field(31; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(32; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(33; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            var
            // WhseTransferRelease: Codeunit "Whse.-Transfer Release";
            begin
                // if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) then
                //     WhseTransferRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(34; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                // OnBeforeValidateShippingAgentCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
                UpdateTransLines(Rec, FieldNo("Shipping Agent Code"));
            end;
        }
        field(35; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            begin
                TestStatusOpen();
                TransferRoute.GetShippingTime(
                  "Transfer-from Code", "Transfer-to Code",
                  "Shipping Agent Code", "Shipping Agent Service Code",
                  "Shipping Time");
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Shipping Agent Service Code"));
            end;
        }
        field(36; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Shipping Time"));
            end;
        }
        field(37; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(38; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(39; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(40; "Partner VAT ID"; Code[20])
        {
            Caption = 'Partner VAT ID';
        }
        field(41; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(42; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = "Area";
        }
        field(43; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(44; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Direct Transfer" then begin
                    VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
                    VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
                    // OnValidateDirectTransferOnBeforeValidateInTransitCode(Rec, IsHandled);
                    if not IsHandled then
                        Validate("In-Transit Code", '');
                end;

                Modify(true);
                UpdateTransLines(Rec, FieldNo("Direct Transfer"));
            end;
        }
        field(50; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';

            trigger OnValidate()
            // var
            //     TransferWarehouseMgt: Codeunit "Transfer Warehouse Mgt.";
            begin
                if "Shipping Advice" <> xRec."Shipping Advice" then begin
                    TestStatusOpen();
                    //         TransferWarehouseMgt.TransHeaderVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(51; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        field(52; "Completely Shipped"; Boolean)
        {
            CalcFormula = min("FA Transfer Line"."Completely Shipped" where("Document No." = field("No."),
                                                                          "Shipment Date" = field("Date Filter"),
                                                                          "Transfer-from Code" = field("Location Filter"),
                                                                          "Derived From Line No." = const(0)));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Completely Received"; Boolean)
        {
            CalcFormula = min("FA Transfer Line"."Completely Received" where("Document No." = field("No."),
                                                                           "Receipt Date" = field("Date Filter"),
                                                                           "Transfer-to Code" = field("Location Filter"),
                                                                           "Derived From Line No." = const(0)));
            Caption = 'Completely Received';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(55; "Outbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Outbound Whse. Handling Time"));
            end;
        }
        field(56; "Inbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Inbound Whse. Handling Time"));
            end;
        }
        field(57; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(60; "Has Shipped Lines"; Boolean)
        {
            CalcFormula = exist("FA Transfer Line" where("Document No." = field("No."),
                                                       "Quantity Shipped" = filter(> 0)));
            Caption = 'Has Shipped Lines';
            FieldClass = FlowField;
        }
        field(70; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(80; "Transfer-from Customer"; Code[20])
        {
            Caption = 'Transfer-from Customer';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
                Confirmed: Boolean;
            begin
                TestStatusOpen();

                if "Transfer-from Customer" <> '' then
                    CheckTransferFromAndToCustomerNotTheSame();

                if xRec."Transfer-from Customer" <> "Transfer-from Customer" then begin
                    if HideValidationDialog or
                       (xRec."Transfer-from Customer" = '')
                    then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-from Customer"));
                    if Confirmed then begin
                        if Customer.Get("Transfer-from Customer") then begin
                            InitFromTransferFromCustomerLocation(Customer);
                            if not "Direct Transfer" then begin

                            end;
                            FATransLine.LockTable();
                            FATransLine.SetRange("Document No.", "No.");
                        end;
                        UpdateTransLines(Rec, FieldNo("Transfer-from Customer"));
                    end else
                        "Transfer-from Customer" := xRec."Transfer-from Customer";
                end;
                CreateDimFromDefaultDim(FieldNo("Transfer-from Customer"));
            end;
        }
        field(81; "Transfer-to Customer"; Code[20])
        {
            Caption = 'Transfer-to Customer';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
                Confirmed: Boolean;
            begin
                TestStatusOpen();

                if "Transfer-to Customer" <> '' then
                    CheckTransferFromAndToCustomerNotTheSame();

                if xRec."Transfer-to Customer" <> "Transfer-to Customer" then begin
                    if HideValidationDialog or
                       (xRec."Transfer-to Customer" = '')
                    then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-to Customer"));
                    if Confirmed then begin
                        if Customer.Get("Transfer-to Customer") then begin
                            InitFromTransferToCustomer(Customer);
                            if not "Direct Transfer" then begin

                            end;
                            FATransLine.LockTable();
                            FATransLine.SetRange("Document No.", "No.");
                        end;
                        UpdateTransLines(Rec, FieldNo("Transfer-to Customer"));
                    end else
                        "Transfer-to Customer" := xRec."Transfer-to Customer";
                end;
                CreateDimFromDefaultDim(FieldNo("Transfer-to Customer"));
            end;
        }
        field(82; "Transfer-from State Code"; Code[10])
        {
            Caption = 'Transfer-from State Code';
            TableRelation = State.Code;
        }
        field(83; "Transfer-to State Code"; Code[10])
        {
            Caption = 'Transfer-to State Code';
            TableRelation = State.Code;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
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
    }

    trigger OnInsert()
    begin
        GetFAConversionSetup();
        InitInsert();
        Validate("Shipment Date", WorkDate());
    end;

    //     trigger OnModify()
    //     begin

    //     end;

    trigger OnDelete()
    var
        ReservMgt: Codeunit "FA Reservation Management";
    begin
        TestField(Status, Status::Open);

        WhseRequest.SetRange("Source Type", DATABASE::"FA Transfer Line");
        WhseRequest.SetRange("Source No.", "No.");
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);

        ReservMgt.DeleteDocumentReservation(DATABASE::"FA Transfer Line", 0, "No.", HideValidationDialog);

        DeleteTransferLines();

        // InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Transfer Order");
        // InvtCommentLine.SetRange("No.", "No.");
        // InvtCommentLine.DeleteAll();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        TransferRoute: Record "Transfer Route";
        FATransHeader: Record "FA Transfer Header";
        FATransLine: Record "FA Transfer Line";
        PostCode: Record "Post Code";
        // NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        FASetup: Record "FA Conversion Setup";
        InvtSetup: Record "Inventory Setup";
        DimMgt: Codeunit DimensionManagement;
        WhseRequest: Record "Warehouse Request";
        HasFAConversionSetup: Boolean;
        HasInventorySetup: Boolean;
        CalledFromWhse: Boolean;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";

        Text000: Label 'You cannot rename a %1.';
        Text001: Label '%1 and %2 cannot be the same in %3 %4.';
        Text002: Label 'Do you want to change %1?';
        SameLocationErr: Label 'Transfer order %1 cannot be posted because %2 and %3 are the same.', Comment = '%1 - order number, %2 - location from, %3 - location to';
        TransferOrderPostedMsg1: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = transfer order number e.g. Transfer order 1003 was successfully posted and is now deleted ';
        Text007: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        CheckTransferLineMsg: Label 'Check transfer document line.';

    protected var
        HideValidationDialog: Boolean;

    procedure InitRecord()
    begin
        if "Posting Date" = 0D then
            Validate("Posting Date", WorkDate());

        // OnAfterInitRecord(Rec);
    end;

    local procedure InitFromTransferToLocation(Location: Record Location)
    begin
        "Transfer-to Name" := Location.Name;
        "Transfer-to Name 2" := Location."Name 2";
        "Transfer-to Address" := Location.Address;
        "Transfer-to Address 2" := Location."Address 2";
        "Transfer-to Post Code" := Location."Post Code";
        "Transfer-to City" := Location.City;
        "Transfer-to County" := Location.County;
        "Trsf.-to Country/Region Code" := Location."Country/Region Code";
        "Transfer-to Contact" := Location.Contact;
        "Transfer-to State Code" := Location."State Code";

        if not Location."Demo Location" then
            "Transfer-to Customer" := '';


        // OnAfterInitFromTransferToLocation(Rec, Location);
    end;

    local procedure InitFromTransferToCustomer(Customer: Record Customer)
    begin
        "Transfer-to Name" := Customer.Name;
        "Transfer-to Name 2" := Customer."Name 2";
        "Transfer-to Address" := Customer.Address;
        "Transfer-to Address 2" := Customer."Address 2";
        "Transfer-to Post Code" := Customer."Post Code";
        "Transfer-to City" := Customer.City;
        "Transfer-to County" := Customer.County;
        "Trsf.-to Country/Region Code" := Customer."Country/Region Code";
        "Transfer-to Contact" := Customer.Contact;
        "Transfer-to State Code" := Customer."State Code";

        // OnAfterInitFromTransferToLocation(Rec, Location);
    end;

    local procedure InitFromTransferFromLocation(Location: Record Location)
    begin
        "Transfer-from Name" := Location.Name;
        "Transfer-from Name 2" := Location."Name 2";
        "Transfer-from Address" := Location.Address;
        "Transfer-from Address 2" := Location."Address 2";
        "Transfer-from Post Code" := Location."Post Code";
        "Transfer-from City" := Location.City;
        "Transfer-from County" := Location.County;
        "Trsf.-from Country/Region Code" := Location."Country/Region Code";
        "Transfer-from Contact" := Location.Contact;
        "Transfer-from State Code" := Location."State Code";

        if not Location."Demo Location" then
            "Transfer-from Customer" := '';

        // OnAfterInitFromTransferFromLocation(Rec, Location);
    end;

    local procedure InitFromTransferFromCustomerLocation(Customer: Record Customer)
    begin
        "Transfer-from Name" := Customer.Name;
        "Transfer-from Name 2" := Customer."Name 2";
        "Transfer-from Address" := Customer.Address;
        "Transfer-from Address 2" := Customer."Address 2";
        "Transfer-from Post Code" := Customer."Post Code";
        "Transfer-from City" := Customer.City;
        "Transfer-from County" := Customer.County;
        "Trsf.-from Country/Region Code" := Customer."Country/Region Code";
        "Transfer-from Contact" := Customer.Contact;
        "Transfer-from State Code" := Customer."State Code";
    end;

    procedure AssistEdit(OldFATransHeader: Record "FA Transfer Header"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        FATransHeader := Rec;
        GetFAConversionSetup();
        TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldFATransHeader."No. Series", FATransHeader."No. Series") then begin
            FATransHeader."No." := NoSeries.GetNextNo(FATransHeader."No. Series");
            Rec := FATransHeader;
            exit(true);
        end;
    end;

    local procedure CalcReceiptDate()
    begin
        TransferRoute.CalcReceiptDate(
            "Shipment Date",
            "Receipt Date",
            "Shipping Time",
            "Outbound Whse. Handling Time",
            "Inbound Whse. Handling Time",
            "Transfer-from Code",
            "Transfer-to Code",
            "Shipping Agent Code",
            "Shipping Agent Service Code");
    end;

    local procedure CalcShipmentDate()
    begin
        TransferRoute.CalcShipmentDate(
            "Shipment Date",
            "Receipt Date",
            "Shipping Time",
            "Outbound Whse. Handling Time",
            "Inbound Whse. Handling Time",
            "Transfer-from Code",
            "Transfer-to Code",
            "Shipping Agent Code",
            "Shipping Agent Service Code");
    end;

    local procedure DeleteTransferLines()
    var
        FATransLine: Record "FA Transfer Line";
    //     IsHandled: Boolean;
    begin
        //     OnBeforeDeleteTransferLines(IsHandled, Rec);
        //     if IsHandled then
        //         exit;

        FATransLine.SetRange("Document No.", "No.");
        FATransLine.DeleteAll(true);
    end;

    local procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GetFAConversionSetup();
        IsHandled := false;
        // OnBeforeTestNoSeries(Rec, InvtSetup, IsHandled);
        if IsHandled then
            exit;

        FASetup.TestField("FA Transfer Order Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GetFAConversionSetup();
        IsHandled := false;
        // OnBeforeGetNoSeriesCode(Rec, InvtSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        NoSeriesCode := FASetup."FA Transfer Order Nos.";
        // OnAfterGetNoSeriesCode(Rec, NoSeriesCode);
        exit(NoSeriesCode);
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        // OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if TransferLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        // OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure GetFAConversionSetup()
    begin
        if not HasFAConversionSetup then begin
            FASetup.Get();
            HasFAConversionSetup := true;
        end;
    end;

    local procedure GetInventorySetup()
    begin
        if not HasInventorySetup then begin
            InvtSetup.Get();
            HasInventorySetup := true;
        end;
    end;

    procedure UpdateTransLines(FATransferHeader: Record "FA Transfer Header"; FieldID: Integer)
    var
        FATransferLine: Record "FA Transfer Line";
        TempFATransferLine: Record "FA Transfer Line" temporary;
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeUpdateTransLines(TransferHeader, FieldID, IsHandled);
        //     if IsHandled then
        //         exit;

        FATransferLine.SetRange("Document No.", "No.");
        FATransferLine.SetFilter("FA Item No.", '<>%1', '');
        if FATransferLine.FindSet() then begin
            FATransferLine.LockTable();
            repeat
                case FieldID of
                    FieldNo("In-Transit Code"):
                        FATransferLine.Validate("In-Transit Code", FATransferHeader."In-Transit Code");
                    FieldNo("Transfer-from Code"):
                        begin
                            FATransferLine.Validate("Transfer-from Code", FATransferHeader."Transfer-from Code");
                            FATransferLine.Validate("Shipping Agent Code", FATransferHeader."Shipping Agent Code");
                            FATransferLine.Validate("Shipping Agent Service Code", FATransferHeader."Shipping Agent Service Code");
                            FATransferLine.Validate("Shipment Date", FATransferHeader."Shipment Date");
                            FATransferLine.Validate("Receipt Date", FATransferHeader."Receipt Date");
                            FATransferLine.Validate("Shipping Time", FATransferHeader."Shipping Time");
                        end;
                    FieldNo("Transfer-from Customer"):
                        begin

                        end;
                    FieldNo("Transfer-to Code"):
                        begin
                            FATransferLine.Validate("Transfer-to Code", FATransferHeader."Transfer-to Code");
                            FATransferLine.Validate("Shipping Agent Code", FATransferHeader."Shipping Agent Code");
                            FATransferLine.Validate("Shipping Agent Service Code", FATransferHeader."Shipping Agent Service Code");
                            FATransferLine.Validate("Shipment Date", FATransferHeader."Shipment Date");
                            FATransferLine.Validate("Receipt Date", FATransferHeader."Receipt Date");
                            FATransferLine.Validate("Shipping Time", FATransferHeader."Shipping Time");
                        end;
                    FieldNo("Transfer-to Customer"):
                        begin

                        end;
                    FieldNo("Shipping Agent Code"):
                        begin
                            FATransferLine.Validate("Shipping Agent Code", FATransferHeader."Shipping Agent Code");
                            FATransferLine.BlockDynamicTracking(true);
                            FATransferLine.Validate("Shipping Agent Service Code", FATransferHeader."Shipping Agent Service Code");
                            FATransferLine.Validate("Shipment Date", FATransferHeader."Shipment Date");
                            FATransferLine.Validate("Receipt Date", FATransferHeader."Receipt Date");
                            FATransferLine.Validate("Shipping Time", FATransferHeader."Shipping Time");
                            // OnUpdateTransLinesOnShippingAgentCodeOnBeforeBlockDynamicTracking(TransferLine, TransferHeader);
                            FATransferLine.BlockDynamicTracking(false);
                            FATransferLine.DateConflictCheck();
                        end;
                    FieldNo("Shipping Agent Service Code"):
                        begin
                            FATransferLine.BlockDynamicTracking(true);
                            FATransferLine.Validate("Shipping Agent Service Code", FATransferHeader."Shipping Agent Service Code");
                            FATransferLine.Validate("Shipment Date", FATransferHeader."Shipment Date");
                            FATransferLine.Validate("Receipt Date", FATransferHeader."Receipt Date");
                            FATransferLine.Validate("Shipping Time", FATransferHeader."Shipping Time");
                            FATransferLine.BlockDynamicTracking(false);
                            FATransferLine.DateConflictCheck();
                        end;
                    FieldNo("Shipment Date"):
                        begin
                            FATransferLine.BlockDynamicTracking(true);
                            FATransferLine.Validate("Shipment Date", FATransferHeader."Shipment Date");
                            FATransferLine.Validate("Receipt Date", FATransferHeader."Receipt Date");
                            FATransferLine.Validate("Shipping Time", FATransferHeader."Shipping Time");
                            FATransferLine.BlockDynamicTracking(false);
                            FATransferLine.DateConflictCheck();
                        end;
                    FieldNo("Receipt Date"), FieldNo("Shipping Time"):
                        begin
                            FATransferLine.BlockDynamicTracking(true);
                            FATransferLine.Validate("Shipping Time", FATransferHeader."Shipping Time");
                            FATransferLine.Validate("Receipt Date", FATransferHeader."Receipt Date");
                            FATransferLine.BlockDynamicTracking(false);
                            FATransferLine.DateConflictCheck();
                        end;
                    FieldNo("Outbound Whse. Handling Time"):
                        FATransferLine.Validate("Outbound Whse. Handling Time", FATransferHeader."Outbound Whse. Handling Time");
                    FieldNo("Inbound Whse. Handling Time"):
                        FATransferLine.Validate("Inbound Whse. Handling Time", FATransferHeader."Inbound Whse. Handling Time");
                    FieldNo(Status):
                        FATransferLine.Validate(Status, FATransferHeader.Status);
                    FieldNo("Direct Transfer"):
                        begin
                            FATransferLine.Validate("In-Transit Code", FATransferHeader."In-Transit Code");
                            TempFATransferLine := FATransferLine;
                            FATransferLine.Validate("FA Item No.", TempFATransferLine."FA Item No.");
                            FATransferLine.Validate("Variant Code", TempFATransferLine."Variant Code");
                            FATransferLine.Validate("Dimension Set ID", TempFATransferLine."Dimension Set ID");
                        end;
                // else
                // OnUpdateTransLines(TransferLine, TransferHeader, FieldID);
                end;
                // OnUpdateTransLinesOnBeforeModifyTransferLine(TransferHeader, TransferLine);
                FATransferLine.Modify(true);
            // OnUpdateTransLinesOnAfterModifyTransferLine(TransferHeader, TransferLine);
            until FATransferLine.Next() = 0;
        end;
    end;

    procedure ShouldDeleteOneTransferOrder(var FATransLine2: Record "FA Transfer Line"): Boolean
    var
    //     IsHandled: Boolean;
    //     ShouldDelete: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeShouldDeleteOneTransferOrder(TransLine2, ShouldDelete, IsHandled);
        //     if IsHandled then
        //         exit(ShouldDelete);

        if FATransLine2.Find('-') then
            repeat
                if (FATransLine2.Quantity <> FATransLine2."Quantity Shipped") or
                   (FATransLine2.Quantity <> FATransLine2."Quantity Received") or
                   (FATransLine2."Quantity (Base)" <> FATransLine2."Qty. Shipped (Base)") or
                   (FATransLine2."Quantity (Base)" <> FATransLine2."Qty. Received (Base)") or
                   (FATransLine2."Quantity Shipped" <> FATransLine2."Quantity Received") or
                   (FATransLine2."Qty. Shipped (Base)" <> FATransLine2."Qty. Received (Base)")
                then
                    exit(false);
            until FATransLine2.Next() = 0;

        exit(true);
    end;

    procedure DeleteOneTransferOrder(var FATransHeader2: Record "FA Transfer Header"; var FATransLine2: Record "FA Transfer Line")
    var
        //     ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        WhseRequest: Record "Warehouse Request";
        //     InvtCommentLine: Record "Inventory Comment Line";
        No: Code[20];
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeDeleteOneTransferOrder(TransHeader2, TransLine2, IsHandled);
        //     if IsHandled then
        //         exit;

        No := FATransHeader2."No.";

        WhseRequest.SetRange("Source Type", DATABASE::"FA Transfer Line");
        WhseRequest.SetRange("Source No.", No);
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);

        //     InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Transfer Order");
        //     InvtCommentLine.SetRange("No.", No);
        //     InvtCommentLine.DeleteAll();

        //     ItemChargeAssgntPurch.SetCurrentKey(
        //       "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        //     ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");
        //     ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", TransLine2."Document No.");
        //     ItemChargeAssgntPurch.DeleteAll();

        //     OnBeforeTransLineDeleteAll(TransHeader2, TransLine2);

        if FATransLine2.Find('-') then
            FATransLine2.DeleteAll();

        //     OnDeleteOneTransferOrderOnBeforeTransHeaderDelete(TransHeader2, HideValidationDialog);
        ApprovalsMgmt.OnDeleteRecordInApprovalRequest(FATransHeader2.RecordId);
        FATransHeader2.Delete();
        if not HideValidationDialog then
            Message(TransferOrderPostedMsg1, No);
    end;

    procedure TestStatusOpen()
    begin
        if not CalledFromWhse then
            TestField(Status, Status::Open);
    end;

    internal procedure PerformManualRelease()
    var
        ReleaseFATransferDocuemnt: Codeunit "Release FA Transfer Document";
    begin
        if Rec.Status <> Rec.Status::Released then begin
            ReleaseFATransferDocuemnt.PerformManualCheckAndRelease(Rec);
            Commit();
        end;
    end;

    procedure CalledFromWarehouse(CalledFromWhse2: Boolean)
    begin
        CalledFromWhse := CalledFromWhse2;
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetFilter(
          "Source Document", '%1|%2',
          WhseRequest."Source Document"::"Inbound Transfer",
          WhseRequest."Source Document"::"Outbound Transfer");
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnCreateDimFromDefaultDimOnBeforeCreateDim(Rec, FieldNo, IsHandled);
        //     if IsHandled then
        //         exit;

        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Transfer-from Code", FieldNo = Rec.FieldNo("Transfer-from Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Transfer-to Code", FieldNo = Rec.FieldNo("Transfer-to Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Transfer-from customer", FieldNo = Rec.FieldNo("Transfer-from Customer"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Transfer-to Customer", FieldNo = Rec.FieldNo("Transfer-to Customer"));

        // OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Transfer, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and (OldDimSetID <> 0) then
            DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if (OldDimSetID <> "Dimension Set ID") and TransferLinesExist() then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        // OnShowDocDimOnAfterAssignDimensionSetID(Rec);

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if TransferLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure TransferLinesExist(): Boolean
    begin
        FATransLine.Reset();
        FATransLine.SetRange("Document No.", "No.");
        exit(FATransLine.FindFirst());
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
        ShippedLineDimChangeConfirmed: Boolean;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;

        if not HideValidationDialog and GuiAllowed then
            if not ConfirmManagement.GetResponseOrDefault(Text007, true) then
                exit;

        FATransLine.Reset();
        FATransLine.SetRange("Document No.", "No.");
        FATransLine.LockTable();
        if FATransLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(FATransLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if FATransLine."Dimension Set ID" <> NewDimSetID then begin
                    FATransLine."Dimension Set ID" := NewDimSetID;

                    VerifyShippedLineDimChange(ShippedLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      FATransLine."Dimension Set ID", FATransLine."Shortcut Dimension 1 Code", FATransLine."Shortcut Dimension 2 Code");
                    // OnUpdateAllLineDimOnBeforeTransLineModify(TransLine);
                    FATransLine.Modify();
                end;
            until FATransLine.Next() = 0;
    end;

    local procedure VerifyShippedLineDimChange(var ShippedLineDimChangeConfirmed: Boolean)
    begin
        if FATransLine.IsShippedDimChanged() then
            if not ShippedLineDimChangeConfirmed then
                ShippedLineDimChangeConfirmed := FATransLine.ConfirmShippedDimChange();
    end;

    procedure CheckBeforePost()
    begin
        TestField("Transfer-from Code");
        TestField("Transfer-to Code");
        CheckTransferFromAndToCodesNotTheSame();

        if not "Direct Transfer" then
            TestField("In-Transit Code")
        else begin
            VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
            VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
        end;
        TestField(Status, Status::Released);
        TestField("Posting Date");

        // OnAfterCheckBeforePost(Rec);
    end;

    // procedure CheckBeforeTransferPost()
    // var
    //     IsHandled: Boolean;
    // begin
    //     IsHandled := false;
    //     OnBeforeCheckBeforeTransferPost(Rec, IsHandled);
    //     if IsHandled then
    //         exit;

    //     TestField("Transfer-from Code");
    //     TestField("Transfer-to Code");
    //     TestField("Direct Transfer");
    //     if ("Transfer-from Code" <> '') and
    //        ("Transfer-from Code" = "Transfer-to Code")
    //     then
    //         Error(
    //           SameLocationErr,
    //           "No.", FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"));
    //     TestField("In-Transit Code", '');
    //     TestField(Status, Status::Released);
    //     TestField("Posting Date");

    //     OnAfterCheckBeforeTransferPost(Rec);
    // end;

    local procedure CheckTransferFromAndToCodesNotTheSame()
    // var
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeCheckTransferFromAndToCodesNotTheSame(Rec, IsHandled);
        //     if IsHandled then
        //         exit;

        if "Transfer-from Code" = "Transfer-to Code" then
            Error(
              Text001,
              FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"),
              TableCaption, "No.");
    end;

    local procedure CheckTransferFromAndToCustomerNotTheSame()
    begin
        if "Transfer-from Customer" = "Transfer-to Customer" then
            Error(
                  Text001,
                  FieldCaption("Transfer-from Customer"), FieldCaption("Transfer-to Customer"),
                  TableCaption, "No.");
    end;

    // procedure CheckInvtPostingSetup()
    // var
    //     InventoryPostingSetup: Record "Inventory Posting Setup";
    //     IsHandled: Boolean;
    // begin
    //     IsHandled := false;
    //     OnBeforeCheckInvtPostingSetup(Rec, IsHandled);
    //     if IsHandled then
    //         exit;

    //     InventoryPostingSetup.SetRange("Location Code", "Transfer-from Code");
    //     InventoryPostingSetup.FindFirst();
    //     InventoryPostingSetup.SetRange("Location Code", "Transfer-to Code");
    //     InventoryPostingSetup.FindFirst();
    // end;

    // procedure HasShippedItems(): Boolean
    // var
    //     TransferLine: Record "FA Transfer Line";
    // begin
    //     TransferLine.SetRange("Document No.", "No.");
    //     TransferLine.SetFilter("Item No.", '<>%1', '');
    //     TransferLine.SetFilter("Quantity Shipped", '>%1', 0);
    //     exit(not TransferLine.IsEmpty);
    // end;

    // procedure HasTransferLines(): Boolean
    // var
    //     TransferLine: Record "FA Transfer Line";
    // begin
    //     TransferLine.SetRange("Document No.", "No.");
    //     TransferLine.SetFilter("Item No.", '<>%1', '');
    //     exit(not TransferLine.IsEmpty);
    // end;

    // procedure GetReceiptLines()
    // var
    //     PurchRcptHeader: Record "Purch. Rcpt. Header";
    //     TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary;
    //     PostedPurchaseReceipts: Page "Posted Purchase Receipts";
    // begin
    //     PurchRcptHeader.SetRange("Location Code", "Transfer-from Code");
    //     PostedPurchaseReceipts.SetTableView(PurchRcptHeader);
    //     PostedPurchaseReceipts.LookupMode := true;
    //     if PostedPurchaseReceipts.RunModal() = ACTION::LookupOK then begin
    //         PostedPurchaseReceipts.GetSelectedRecords(TempPurchRcptHeader);
    //         CreateTransferLinesFromSelectedPurchReceipts(TempPurchRcptHeader);
    //     end;
    // end;

    // local procedure CreateTransferLinesFromSelectedPurchReceipts(var TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary)
    // var
    //     PurchRcptLine: Record "Purch. Rcpt. Line";
    //     TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
    //     SelectionFilterManagement: Codeunit SelectionFilterManagement;
    //     PostedPurchaseReceiptLines: Page "Posted Purchase Receipt Lines";
    //     RecRef: RecordRef;
    // begin
    //     RecRef.GetTable(TempPurchRcptHeader);
    //     PurchRcptLine.SetFilter(
    //       "Document No.",
    //       SelectionFilterManagement.GetSelectionFilter(RecRef, TempPurchRcptHeader.FieldNo("No.")));
    //     PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
    //     PurchRcptLine.SetRange("Location Code", "Transfer-from Code");
    //     PostedPurchaseReceiptLines.SetTableView(PurchRcptLine);
    //     PostedPurchaseReceiptLines.LookupMode := true;
    //     if PostedPurchaseReceiptLines.RunModal() = ACTION::LookupOK then begin
    //         PostedPurchaseReceiptLines.GetSelectedRecords(TempPurchRcptLine);
    //         CreateTransferLinesFromSelectedReceiptLines(TempPurchRcptLine);
    //     end;
    // end;

    // local procedure CreateTransferLinesFromSelectedReceiptLines(var PurchRcptLine: Record "Purch. Rcpt. Line")
    // var
    //     TransferLine: Record "FA Transfer Line";
    //     LineNo: Integer;
    // begin
    //     TransferLine.SetRange("Document No.", "No.");
    //     if TransferLine.FindLast() then;
    //     LineNo := TransferLine."Line No.";

    //     if PurchRcptLine.FindSet() then
    //         repeat
    //             LineNo := LineNo + 10000;
    //             AddTransferLineFromReceiptLine(PurchRcptLine, LineNo);
    //         until PurchRcptLine.Next() = 0;
    // end;

    // local procedure AddTransferLineFromReceiptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; LineNo: Integer)
    // var
    //     TransferLine: Record "FA Transfer Line";
    //     ItemLedgerEntry: Record "Item Ledger Entry";
    //     TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    //     ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    //     ItemTrackingMgt: Codeunit "Item Tracking Management";
    // begin
    //     TransferLine."Document No." := "No.";
    //     TransferLine."Line No." := LineNo;
    //     TransferLine.Validate("Item No.", PurchRcptLine."No.");
    //     TransferLine.Validate("Variant Code", PurchRcptLine."Variant Code");
    //     TransferLine.Validate(Quantity, PurchRcptLine.Quantity);
    //     TransferLine.Validate("Unit of Measure Code", PurchRcptLine."Unit of Measure Code");
    //     TransferLine."Shortcut Dimension 1 Code" := PurchRcptLine."Shortcut Dimension 1 Code";
    //     TransferLine."Shortcut Dimension 2 Code" := PurchRcptLine."Shortcut Dimension 2 Code";
    //     TransferLine."Dimension Set ID" := PurchRcptLine."Dimension Set ID";
    //     OnAddTransferLineFromReceiptLineOnBeforeTransferLineInsert(TransferLine, PurchRcptLine, Rec);
    //     TransferLine.Insert(true);

    //     PurchRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgerEntry);
    //     ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempItemLedgerEntry, ItemLedgerEntry);
    //     ItemTrackingMgt.CopyItemLedgEntryTrkgToTransferLine(TempItemLedgerEntry, TransferLine);

    //     OnAfterAddTransferLineFromReceiptLine(TransferLine, PurchRcptLine, TempItemLedgerEntry, Rec);
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnUpdateTransLines(var TransferLine: Record "FA Transfer Line"; TransferHeader: Record "FA Transfer Header"; FieldID: Integer)
    // begin
    // end;

    procedure VerifyNoOutboundWhseHandlingOnLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    //     IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeVerifyNoOutboundWhseHandlingOnLocation(LocationCode, IsHandled);
        //     if IsHandled then
        //         exit;

        if not Location.Get(LocationCode) then
            exit;

        GetInventorySetup();
        if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer" then
            exit;

        Location.TestField("Require Pick", false);
        Location.TestField("Require Shipment", false);
    end;

    procedure VerifyNoInboundWhseHandlingOnLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    // IsHandled: Boolean;
    begin
        //     IsHandled := false;
        //     OnBeforeVerifyNoInboundWhseHandlingOnLocation(LocationCode, IsHandled);
        //     if IsHandled then
        //         exit;

        if not Location.Get(LocationCode) then
            exit;

        Location.TestField("Directed Put-away and Pick", false);

        GetInventorySetup();
        if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer" then
            exit;

        Location.TestField("Require Put-away", false);
        Location.TestField("Require Receive", false);
    end;

    local procedure InitInsert()
    var
        FATransferHeader: Record "FA Transfer Header";
        IsHandled: Boolean;
        NoSeries: Codeunit "No. Series";
    begin
        IsHandled := false;
        OnInitInsertOnBeforeInitSeries(xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                // NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Posting Date", "No.", "No. Series");
                if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := GetNoSeriesCode();
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
                FATransferHeader.ReadIsolation(IsolationLevel::ReadUncommitted);
                FATransferHeader.SetLoadFields("No.");
                while FATransferHeader.Get("No.") do
                    "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
            end;

        OnInitInsertOnBeforeInitRecord(xRec);
        InitRecord();
    end;

    procedure TransferLinesEditable() IsEditable: Boolean;
    begin
        if not "Direct Transfer" then
            IsEditable := ("Transfer-from Code" <> '') and ("Transfer-to Code" <> '') and ("In-Transit Code" <> '')
        else
            IsEditable := ("Transfer-from Code" <> '') and ("Transfer-to Code" <> '');

        // OnAfterTransferLinesEditable(Rec, IsEditable);
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckFATransferReleaseRestrictions()
    begin
    end;

    procedure CheckFATransferReleaseRestrictions()
    var
        TSTApprovalsMgmt: Codeunit "TST Approvals Mgmt";
    begin
        OnCheckFATransferReleaseRestrictions;
        TSTApprovalsMgmt.PrePostApprovalCheckFATransfer(Rec);
    end;

    [IntegrationEvent(true, false)]
    procedure OnCheckFATransferPostRestrictions()
    begin
    end;

    procedure CheckFATransferPostRestrictions()
    begin
        OnCheckFATransferPostRestrictions();
    end;

    procedure CheckTransferLines(Ship: Boolean)
    var
        FATransferLine: Record "FA Transfer Line";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        FATransferLine.SetRange("Document No.", Rec."No.");
        FATransferLine.SetRange("Derived From Line No.", 0);
        if FATransferLine.FindSet() then
            repeat
                ErrorMessageMgt.PushContext(ErrorContextElement, FATransferLine.RecordId(), 0, CheckTransferLineMsg);
                TestTransferLine(FATransferLine, Ship);
            until FATransferLine.Next() = 0;
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    procedure TestTransferLine(FATransferLine: Record "FA Transfer Line"; Ship: Boolean)
    var
        DummyTrackingSpecification: Record "FA Tracking Specification";
    begin
        if Ship then
            DummyTrackingSpecification.CheckItemTrackingQuantity(Database::"FA Transfer Line", 0, "No.", FATransferLine."Line No.",
                FATransferLine."Qty. to Ship (Base)", FATransferLine."Qty. to Ship (Base)", true, false)
        else
            DummyTrackingSpecification.CheckItemTrackingQuantity(Database::"FA Transfer Line", 1, "No.", GetSourceRefNo(FATransferLine),
                FATransferLine."Qty. to Receive (Base)", FATransferLine."Qty. to Receive (Base)", true, false);
    end;

    local procedure GetSourceRefNo(FATransferLine: Record "FA Transfer Line"): Integer
    var
        ReservationEntry: Record "FA Reservation Entry";
    begin
        ReservationEntry.SetLoadFields("Source Ref. No.");
        ReservationEntry.SetSourceFilter(Database::"FA Transfer Line", 1, FATransferLine."Document No.", 0, true);
        ReservationEntry.SetRange("Item No.", FATransferLine."FA Item No.");
        ReservationEntry.SetRange("Source Prod. Order Line", FATransferLine."Line No.");
        if ReservationEntry.FindFirst() then
            exit(ReservationEntry."Source Ref. No.");
    end;

    // internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    // var
    //     TransferLineLocal: Record "FA Transfer Line";
    //     TransferLineReserve: Codeunit "Transfer Line-Reserve";
    //     QtyReservedFromStock: Decimal;
    // begin
    //     QtyReservedFromStock := TransferLineReserve.GetReservedQtyFromInventory(Rec);

    //     TransferLineLocal.SetRange("Document No.", Rec."No.");
    //     TransferLineLocal.CalcSums("Outstanding Qty. (Base)");

    //     case QtyReservedFromStock of
    //         0:
    //             exit(Result::None);
    //         TransferLineLocal."Outstanding Qty. (Base)":
    //             exit(Result::Full);
    //         else
    //             exit(Result::Partial);
    //     end;
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAddTransferLineFromReceiptLineOnBeforeTransferLineInsert(var TransferLine: Record "FA Transfer Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterAddTransferLineFromReceiptLine(var TransferLine: Record "FA Transfer Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgerEntry: Record "Item Ledger Entry"; var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterCheckBeforePost(var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterCheckBeforeTransferPost(var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterGetNoSeriesCode(var TransferHeader: Record "FA Transfer Header"; var NoSeriesCode: Code[20])
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterGetTransferRoute(var TransferHeader: Record "FA Transfer Header"; TransferRoute: Record "Transfer Route");
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterInitRecord(var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterInitFromTransferToLocation(var TransferHeader: Record "FA Transfer Header"; Location: Record Location)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterInitFromTransferFromLocation(var TransferHeader: Record "FA Transfer Header"; Location: Record Location)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterTransferLinesEditable(TransferHeader: Record "FA Transfer Header"; var IsEditable: Boolean);
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterValidateShortcutDimCode(var TransferHeader: Record "FA Transfer Header"; var xTransferHeader: Record "FA Transfer Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeCheckInvtPostingSetup(TransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeCheckTransferFromAndToCodesNotTheSame(TransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(true, false)]
    // local procedure OnBeforeDeleteTransferLines(var IsHandled: Boolean; var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeGetNoSeriesCode(var TransferHeader: Record "FA Transfer Header"; InventorySetup: Record "Inventory Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeShouldDeleteOneTransferOrder(var TransferLine: record "FA Transfer Line"; var ShouldDelete: Boolean; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeTestNoSeries(TransferHeader: Record "FA Transfer Header"; InvtSetup: Record "Inventory Setup"; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeTransLineDeleteAll(TransferHeader: Record "FA Transfer Header"; var TransferLine: Record "FA Transfer Line")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeUpdateTransLines(TransferHeader: Record "FA Transfer Header"; FieldID: Integer; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeValidateShortcutDimCode(var TransferHeader: Record "FA Transfer Header"; var xTransferHeader: Record "FA Transfer Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferFromCode(var FATransferHeader: Record "FA Transfer Header"; var xFATransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean; var HideValidationDialog: Boolean)
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeValidateTransferToCode(var TransferHeader: Record "FA Transfer Header"; var xTransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean; var HideValidationDialog: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeVerifyNoOutboundWhseHandlingOnLocation(LocationCode: Code[10]; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnDeleteOneTransferOrderOnBeforeTransHeaderDelete(var TransferHeader: Record "FA Transfer Header"; var HideValidationDialog: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnShowDocDimOnAfterAssignDimensionSetID(var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnUpdateAllLineDimOnBeforeTransLineModify(var TransLine: Record "FA Transfer Line")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnValidateReceiptDateOnBeforeCalcShipmentDate(var IsHandled: Boolean; var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnValidateShipmentDateOnBeforeCalcReceiptDate(var IsHandled: Boolean; var TransferHeader: Record "FA Transfer Header")
    // begin
    // end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitSeries(var xTransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var xTransferHeader: Record "FA Transfer Header")
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeDeleteOneTransferOrder(var TransHeader2: Record "FA Transfer Header"; var TransLine2: Record "FA Transfer Line"; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnUpdateTransLinesOnShippingAgentCodeOnBeforeBlockDynamicTracking(var TransferLine: record "FA Transfer Line"; var TransferHeader: record "FA Transfer Header")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnUpdateTransLinesOnBeforeModifyTransferLine(TransferHeader: Record "FA Transfer Header"; var TransferLine: record "FA Transfer Line")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnUpdateTransLinesOnAfterModifyTransferLine(TransferHeader: Record "FA Transfer Header"; var TransferLine: record "FA Transfer Line")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnValidateDirectTransferOnBeforeValidateInTransitCode(var TransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeValidateTransferFromCity(var TransferHeader: Record "FA Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeValidateTransferFromPostCode(var TransferHeader: Record "FA Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeValidateTransferToCity(var TransferHeader: Record "FA Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferToPostCode(var FATransferHeader: Record "FA Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTransferFromCodeOnBeforeUpdateTransLines(var FATransferHeader: Record "FA Transfer Header")
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnCreateDimFromDefaultDimOnBeforeCreateDim(var TransferHeader: Record "FA Transfer Header"; FieldNo: Integer; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnAfterInitDefaultDimensionSources(var TransferHeader: Record "FA Transfer Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeCheckBeforeTransferPost(TransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeVerifyNoInboundWhseHandlingOnLocation(LocationCode: Code[10]; var IsHandled: Boolean)
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeValidateShippingAgentCode(var TransferHeader: Record "FA Transfer Header"; var IsHandled: Boolean)
    // begin
    // end;
}