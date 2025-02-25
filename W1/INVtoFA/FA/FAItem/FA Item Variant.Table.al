namespace TSTChanges.FA.FAItem;

using TSTChanges.FA.Ledger;
using TSTChanges.FA.Conversion;
using TSTChanges.FA.Transfer;
using TSTChanges.FA.Journal;

table 51221 "FA Item Variant"
{
    Caption = 'FA Item Variant';
    DataCaptionFields = "Item No.", "Code", Description;
    LookupPageID = "FA Item Variants";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = "FA Item";

            trigger OnValidate()
            var
                FAItem: Record "FA Item";
            begin
                if "Item No." = '' then
                    Clear("Item Id")
                else
                    if FAItem.Get("Item No.") then
                        "Item Id" := FAItem.SystemId;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Item Id"; Guid)
        {
            Caption = 'Item Id';
            TableRelation = "FA Item".SystemId;

            trigger OnValidate()
            var
                FAItem: Record "FA Item";
            begin
                if IsNullGuid("Item Id") then
                    "Item No." := ''
                else
                    if FAItem.GetBySystemId("Item Id") then
                        "Item No." := FAItem."No.";
            end;
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';
            DataClassification = CustomerContent;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';
            DataClassification = CustomerContent;
        }
        field(8010; "Service Blocked"; Boolean)
        {
            Caption = 'Service Blocked';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Code")
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; "Item Id", "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Code", Description)
        {
        }
    }

    trigger OnRename()
    var
    // SalesLine: Record "Sales Line";
    // PurchaseLine: Record "Purchase Line";
    begin
        // if xRec."Item No." <> "Item No." then begin
        //     SalesLine.SetRange(Type, SalesLine.Type::Item);
        //     SalesLine.SetRange("No.", xRec."Item No.");
        //     SalesLine.SetRange("Variant Code", xRec.Code);
        //     if not SalesLine.IsEmpty() then
        //         Error(CannotRenameItemUsedInSalesLinesErr, FieldCaption("Item No."), TableCaption());

        //     PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        //     PurchaseLine.SetRange("No.", xRec."Item No.");
        //     PurchaseLine.SetRange("Variant Code", xRec.Code);
        //     if not PurchaseLine.IsEmpty() then
        //         Error(CannotRenameItemUsedInPurchaseLinesErr, FieldCaption("Item No."), TableCaption());
        // end;

        // if (xRec."Item No." = "Item No.") and (xRec.Code <> Code) then begin
        //     SalesLine.SetRange(Type, SalesLine.Type::Item);
        //     SalesLine.SetRange("No.", "Item No.");
        //     SalesLine.SetRange("Variant Code", xRec.Code);
        //     if not SalesLine.IsEmpty() then
        //         SalesLine.ModifyAll("Variant Code", Code, true);

        //     PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        //     PurchaseLine.SetRange("No.", "Item No.");
        //     PurchaseLine.SetRange("Variant Code", xRec.Code);
        //     if not PurchaseLine.IsEmpty() then
        //         PurchaseLine.ModifyAll("Variant Code", Code, true);
        // end;
    end;

    trigger OnDelete()
    var
        // ItemTranslation: Record "Item Translation";
        // StockkeepingUnit: Record "Stockkeeping Unit";
        // ItemIdentifier: Record "Item Identifier";
        // ItemReference: Record "Item Reference";
        // BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "FA Item Journal Line";
        // RequisitionLine: Record "Requisition Line";
        // PurchaseLine: Record "Purchase Line";
        // SalesLine: Record "Sales Line";
        // ProdOrderComponent: Record "Prod. Order Component";
        TransferLine: Record "FA Transfer Line";
        // ServiceLine: Record "Service Line";
        // ProductionBOMLine: Record "Production BOM Line";
        // ServiceContractLine: Record "Service Contract Line";
        // ServiceItem: Record "Service Item";
        ConversionHeader: Record "FA Conversion Header";
        // ItemSubstitution: Record "Item Substitution";
        // ItemVendor: Record "Item Vendor";
        // PlanningAssignment: Record "Planning Assignment";
        // ServiceItemComponent: Record "Service Item Component";
        // BinContent: Record "Bin Content";
        ItemLedgerEntry: Record "FA Item ledger Entry";
    // ValueEntry: Record "Value Entry";
    // ConversionLine: Record "FA Conversion Line";
    begin
        // BOMComponent.SetCurrentKey(Type, "No.");
        // BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        // BOMComponent.SetRange("No.", "Item No.");
        // BOMComponent.SetRange("Variant Code", Code);
        // if not BOMComponent.IsEmpty() then
        //     Error(Text001, Code, BOMComponent.TableCaption());

        // ProductionBOMLine.SetCurrentKey(Type, "No.");
        // ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        // ProductionBOMLine.SetRange("No.", "Item No.");
        // ProductionBOMLine.SetRange("Variant Code", Code);
        // if not ProductionBOMLine.IsEmpty() then
        //     Error(Text001, Code, ProductionBOMLine.TableCaption());

        // ProdOrderComponent.SetCurrentKey(Status, "Item No.");
        // ProdOrderComponent.SetRange("Item No.", "Item No.");
        // ProdOrderComponent.SetRange("Variant Code", Code);
        // if not ProdOrderComponent.IsEmpty() then
        //     Error(Text001, Code, ProdOrderComponent.TableCaption());

        // if ProdOrderExist() then
        //     Error(Text002, "Item No.");

        // ConversionHeader.SetCurrentKey("Document Type", "Item No.");
        ConversionHeader.SetRange("FA Item No.", "Item No.");
        ConversionHeader.SetRange("Variant Code", Code);
        if not ConversionHeader.IsEmpty() then
            Error(Text001, Code, ConversionHeader.TableCaption());

        // ConversionLine.SetCurrentKey("Document Type", Type, "No.");
        // AssemblyLine.SetRange("No.", "Item No.");
        // AssemblyLine.SetRange("Variant Code", Code);
        // if not AssemblyLine.IsEmpty() then
        //     Error(Text001, Code, AssemblyLine.TableCaption());

        // BinContent.SetCurrentKey("Item No.");
        // BinContent.SetRange("Item No.", "Item No.");
        // BinContent.SetRange("Variant Code", Code);
        // if not BinContent.IsEmpty() then
        //     Error(Text001, Code, BinContent.TableCaption());

        TransferLine.SetCurrentKey("FA Item No.");
        TransferLine.SetRange("FA Item No.", "Item No.");
        TransferLine.SetRange("Variant Code", Code);
        if not TransferLine.IsEmpty() then
            Error(Text001, Code, TransferLine.TableCaption());

        // RequisitionLine.SetCurrentKey(Type, "No.");
        // RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        // RequisitionLine.SetRange("No.", "Item No.");
        // RequisitionLine.SetRange("Variant Code", Code);
        // if not RequisitionLine.IsEmpty() then
        //     Error(Text001, Code, RequisitionLine.TableCaption());

        // PurchaseLine.SetCurrentKey(Type, "No.");
        // PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        // PurchaseLine.SetRange("No.", "Item No.");
        // PurchaseLine.SetRange("Variant Code", Code);
        // if not PurchaseLine.IsEmpty() then
        //     Error(Text001, Code, PurchaseLine.TableCaption());

        // SalesLine.SetCurrentKey(Type, "No.");
        // SalesLine.SetRange(Type, SalesLine.Type::Item);
        // SalesLine.SetRange("No.", "Item No.");
        // SalesLine.SetRange("Variant Code", Code);
        // if not SalesLine.IsEmpty() then
        //     Error(Text001, Code, SalesLine.TableCaption());

        // ServiceItem.SetCurrentKey("Item No.", "Serial No.");
        // ServiceItem.SetRange("Item No.", "Item No.");
        // ServiceItem.SetRange("Variant Code", Code);
        // if not ServiceItem.IsEmpty() then
        //     Error(Text001, Code, ServiceItem.TableCaption());

        // ServiceLine.SetCurrentKey(Type, "No.");
        // ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        // ServiceLine.SetRange("No.", "Item No.");
        // ServiceLine.SetRange("Variant Code", Code);
        // if not ServiceLine.IsEmpty() then
        //     Error(Text001, Code, ServiceLine.TableCaption());

        // ServiceContractLine.SetRange("Item No.", "Item No.");
        // ServiceContractLine.SetRange("Variant Code", Code);
        // if not ServiceContractLine.IsEmpty() then
        //     Error(Text001, Code, ServiceContractLine.TableCaption());

        // ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        // ServiceItemComponent.SetRange("No.", "Item No.");
        // ServiceItemComponent.SetRange("Variant Code", Code);
        // ServiceItemComponent.ModifyAll("Variant Code", '');

        ItemJournalLine.SetCurrentKey("FA Item No.");
        ItemJournalLine.SetRange("FA Item No.", "Item No.");
        ItemJournalLine.SetRange("Variant Code", Code);
        if not ItemJournalLine.IsEmpty() then
            Error(Text001, Code, ItemJournalLine.TableCaption());

        ItemLedgerEntry.SetCurrentKey("FA Item No.");
        ItemLedgerEntry.SetRange("FA Item No.", "Item No.");
        ItemLedgerEntry.SetRange("Variant Code", Code);
        if not ItemLedgerEntry.IsEmpty() then
            Error(Text001, Code, ItemLedgerEntry.TableCaption());

        // ValueEntry.SetCurrentKey("Item No.");
        // ValueEntry.SetRange("Item No.", "Item No.");
        // ValueEntry.SetRange("Variant Code", Code);
        // if not ValueEntry.IsEmpty() then
        //     Error(Text001, Code, ValueEntry.TableCaption());

        // ItemTranslation.SetRange("Item No.", "Item No.");
        // ItemTranslation.SetRange("Variant Code", Code);
        // ItemTranslation.DeleteAll();

        // ItemIdentifier.SetCurrentKey("Item No.");
        // ItemIdentifier.SetRange("Item No.", "Item No.");
        // ItemIdentifier.SetRange("Variant Code", Code);
        // ItemIdentifier.DeleteAll();

        // ItemReference.SetRange("Item No.", "Item No.");
        // ItemReference.SetRange("Variant Code", Code);
        // ItemReference.DeleteAll();

        // ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        // ItemSubstitution.SetRange("No.", "Item No.");
        // ItemSubstitution.SetRange("Substitute Type", ItemSubstitution."Substitute Type"::Item);
        // ItemSubstitution.SetRange("Variant Code", Code);
        // ItemSubstitution.DeleteAll();

        // ItemVendor.SetCurrentKey("Item No.");
        // ItemVendor.SetRange("Item No.", "Item No.");
        // ItemVendor.SetRange("Variant Code", Code);
        // ItemVendor.DeleteAll();

        // StockkeepingUnit.SetRange("Item No.", "Item No.");
        // StockkeepingUnit.SetRange("Variant Code", Code);
        // StockkeepingUnit.DeleteAll(true);

        // PlanningAssignment.SetRange("Item No.", "Item No.");
        // PlanningAssignment.SetRange("Variant Code", Code);
        // PlanningAssignment.DeleteAll();
    end;

    var
        Text001: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.';
        Text002: Label 'You cannot delete item variant %1 because there are one or more outstanding production orders that include this item.';
        CannotRenameItemUsedInSalesLinesErr: Label 'You cannot rename %1 in a %2, because it is used in sales document lines.', Comment = '%1 = Item No. caption, %2 = Table caption.';
        CannotRenameItemUsedInPurchaseLinesErr: Label 'You cannot rename %1 in a %2, because it is used in purchase document lines.', Comment = '%1 = Item No. caption, %2 = Table caption.';

    // local procedure ProdOrderExist(): Boolean
    // var
    //     ProdOrderLine: Record "Prod. Order Line";
    // begin
    //     ProdOrderLine.SetCurrentKey(Status, "Item No.");
    //     ProdOrderLine.SetRange("Item No.", "Item No.");
    //     ProdOrderLine.SetRange("Variant Code", Code);
    //     if not ProdOrderLine.IsEmpty() then
    //         exit(true);

    //     exit(false);
    // end;

    // procedure UpdateReferencedIds()
    // var
    //     Item: Record Item;
    // begin
    //     if "Item No." = '' then begin
    //         Clear("Item Id");
    //         exit;
    //     end;

    //     if not Item.Get("Item No.") then
    //         exit;

    //     "Item Id" := Item.SystemId;
    // end;
}