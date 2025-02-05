namespace TSTChanges.FA.Transfer;

using Microsoft.Finance.Dimension;
using TSTChanges.FA.Tracking;
using Microsoft.Inventory.Intrastat;
using Microsoft.Sales.Customer;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
// using Microsoft.Finance.TaxBase;
using Microsoft.Inventory.Comment;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.Navigate;

table 51218 "FA Transfer Receipt Header"
{
    DataClassification = CustomerContent;
    Caption = 'Transfer Receipt Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted FA Transfer Receipts";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
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
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
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
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
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
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
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
        }
        field(20; "Transfer Order Date"; Date)
        {
            Caption = 'Transfer Order Date';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Posted Transfer Receipt"),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "FA Transfer Header";
            ValidateTableRelation = false;
        }
        field(26; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(27; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(28; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';
        }
        field(29; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location.Code where("Use As In-Transit" = const(true));
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(33; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(34; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(35; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
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
        field(49; "Partner VAT ID"; Code[20])
        {
            Caption = 'Partner VAT ID';
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';
        }
        field(80; "Transfer-from Customer"; Code[20])
        {
            Caption = 'Transfer-from Customer';
            TableRelation = Customer;
        }
        field(81; "Transfer-to Customer"; Code[20])
        {
            Caption = 'Transfer-to Customer';
            TableRelation = Customer;
        }
        // field(82; "Transfer-from State Code"; Code[10])
        // {
        //     Caption = 'Transfer-from State Code';
        //     TableRelation = State.Code;
        // }
        // field(83; "Transfer-to State Code"; Code[10])
        // {
        //     Caption = 'Transfer-to State Code';
        //     TableRelation = State.Code;
        // }
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
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Posting Date", "Transfer Order Date")
        {
        }
    }

    trigger OnDelete()
    var
        // InvtCommentLine: Record "Inventory Comment Line";
        TransRcptLine: Record "FA Transfer Receipt Line";
    // MoveEntries: Codeunit "FA MoveEntries";
    begin
        TransRcptLine.SetRange("Document No.", "No.");
        if TransRcptLine.Find('-') then
            repeat
                TransRcptLine.Delete(true);
            until TransRcptLine.Next() = 0;

        // InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Transfer Receipt");
        // InvtCommentLine.SetRange("No.", "No.");
        // InvtCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteItemEntryRelation(
          DATABASE::"FA Transfer Receipt Line", 0, "No.", '', 0, 0, true);

        // MoveEntries.MoveDocRelatedEntries(DATABASE::"FA Transfer Receipt Header", "No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        ItemTrackingMgt: Codeunit "FA Item Tracking Management";

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Report Selections";
        TransRcptHeader: Record "FA Transfer Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, IsHandled);
        if IsHandled then
            exit;

        TransRcptHeader.Copy(Rec);
        ReportSelection.PrintWithDialogForCust(
            ReportSelection.Usage::Inv3, TransRcptHeader, ShowRequestForm, 0);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    procedure CopyFromTransferHeader(FATransHeader: Record "FA Transfer Header")
    begin
        "Transfer-from Code" := FATransHeader."Transfer-from Code";
        "Transfer-from Name" := FATransHeader."Transfer-from Name";
        "Transfer-from Name 2" := FATransHeader."Transfer-from Name 2";
        "Transfer-from Address" := FATransHeader."Transfer-from Address";
        "Transfer-from Address 2" := FATransHeader."Transfer-from Address 2";
        "Transfer-from Post Code" := FATransHeader."Transfer-from Post Code";
        "Transfer-from City" := FATransHeader."Transfer-from City";
        "Transfer-from County" := FATransHeader."Transfer-from County";
        "Trsf.-from Country/Region Code" := FATransHeader."Trsf.-from Country/Region Code";
        "Transfer-from Contact" := FATransHeader."Transfer-from Contact";
        "Transfer-to Code" := FATransHeader."Transfer-to Code";
        "Transfer-to Name" := FATransHeader."Transfer-to Name";
        "Transfer-to Name 2" := FATransHeader."Transfer-to Name 2";
        "Transfer-to Address" := FATransHeader."Transfer-to Address";
        "Transfer-to Address 2" := FATransHeader."Transfer-to Address 2";
        "Transfer-to Post Code" := FATransHeader."Transfer-to Post Code";
        "Transfer-to City" := FATransHeader."Transfer-to City";
        "Transfer-to County" := FATransHeader."Transfer-to County";
        "Trsf.-to Country/Region Code" := FATransHeader."Trsf.-to Country/Region Code";
        "Transfer-to Contact" := FATransHeader."Transfer-to Contact";
        "Transfer Order Date" := FATransHeader."Posting Date";
        "Posting Date" := FATransHeader."Posting Date";
        "Shipment Date" := FATransHeader."Shipment Date";
        "Receipt Date" := FATransHeader."Receipt Date";
        "Shortcut Dimension 1 Code" := FATransHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := FATransHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := FATransHeader."Dimension Set ID";
        "Transfer Order No." := FATransHeader."No.";
        "External Document No." := FATransHeader."External Document No.";
        "In-Transit Code" := FATransHeader."In-Transit Code";
        "Shipping Agent Code" := FATransHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := FATransHeader."Shipping Agent Service Code";
        "Shipment Method Code" := FATransHeader."Shipment Method Code";
        "Transaction Type" := FATransHeader."Transaction Type";
        "Transport Method" := FATransHeader."Transport Method";
        "Partner VAT ID" := FATransHeader."Partner VAT ID";
        "Entry/Exit Point" := FATransHeader."Entry/Exit Point";
        Area := FATransHeader.Area;
        "Transaction Specification" := FATransHeader."Transaction Specification";
        "Direct Transfer" := FATransHeader."Direct Transfer";

        "Transfer-from Customer" := FATransHeader."Transfer-from Customer";
        "Transfer-to Customer" := FATransHeader."Transfer-to Customer";
        // "Transfer-from State Code" := FATransHeader."Transfer-from State Code";
        // "Transfer-to State Code" := FATransHeader."Transfer-to State Code";

        OnAfterCopyFromTransferHeader(Rec, FATransHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTransferHeader(var TransferReceiptHeader: Record "FA Transfer Receipt Header"; TransferHeader: Record "FA Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var TransferReceiptHeader: Record "FA Transfer Receipt Header"; ShowRequestForm: Boolean; var IsHandled: Boolean)
    begin
    end;

}