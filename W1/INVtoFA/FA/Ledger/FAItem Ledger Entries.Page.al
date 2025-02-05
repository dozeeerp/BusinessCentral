namespace TSTChanges.FA.Ledger;

using TSTChanges.FA.FAItem;
using System.Globalization;
using Microsoft.Foundation.Navigate;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Tracking;
using TSTChanges.FA.Tracking;
using Microsoft.Finance.Dimension;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;

page 51203 "FA Item Ledger Entries"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    Caption = 'FA Item Ledger Entries';
    DataCaptionExpression = GetCaption();
    DataCaptionFields = "FA Item No.";
    Editable = false;
    SourceTableView = sorting("Entry No.")
                      order(descending);
    UsageCategory = History;
    SourceTable = "FA Item ledger Entry";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what type of document was posted to create the item ledger entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the entry. The document is the voucher that the entry was based on, for example, a receipt.';
                }
                field("FA Item No."; Rec."FA Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the FA item in the entry.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Fixed Asset in the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a serial number if the posted item carries such a number.';

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "FA Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."FA Item No.", Rec."Variant Code", Enum::"Item Tracking Type"::"Serial No.", Rec."Serial No.");
                    end;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a lot number if the posted item carries such a number.';

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."FA Item No.", Rec."Variant Code", "Item Tracking Type"::"Lot No.", Rec."Lot No.");
                    end;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a package number if the posted item carries such a number.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        ItemTrackingManagement: Codeunit "Item Tracking Management";
                    begin
                        ItemTrackingManagement.LookupTrackingNoInfo(
                            Rec."FA Item No.", Rec."Variant Code", "Item Tracking Type"::"Package No.", Rec."Package No.");
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of units of the item in the item entry.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                    Visible = true;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Book Value(Company)"; Rec."Book Value(Company)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specified the book value of the FA linked with this entry.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cusotmer no. this FA Item tagged with.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer name that this FA item tagged with.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee this FA Item tagged with.';
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim8Visible;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                    end;
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Show Applied FA Entries", Rec);
                    end;
                }
                action("Reservation Entries")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                // action("Application Worksheet")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Application Worksheet';
                //     Image = ApplicationWorksheet;
                //     ToolTip = 'View item applications that are automatically created between item ledger entries during item transactions.';

                //     trigger OnAction()
                //     var
                //         ApplicationWorksheet: Page "Application Worksheet";
                //     begin
                //         Clear(ApplicationWorksheet);
                //         ApplicationWorksheet.SetRecordToShow(Rec);
                //         ApplicationWorksheet.Run();
                //     end;
                // }
            }
        }
        area(Processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
                group(Category_Category4)
                {
                    Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                    {
                    }
                    actionref("Reservation Entries_Promoted"; "Reservation Entries")
                    {
                    }
                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref(SetDimensionFilter_Promoted; SetDimensionFilter)
                    {
                    }
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        // OnBeforeOpenPage();

        if (Rec.GetFilters() <> '') and not Rec.Find() then
            if Rec.FindFirst() then;

        SetDimVisibility();
    end;

    var
        Navigate: Page Navigate;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        PackageTrackingVisible: Boolean;

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;


    local procedure GetCaption() Result: Text
    var
        GLSetup: Record "General Ledger Setup";
        ObjTransl: Record "Object Translation";
        Item: Record "FA Item";
        // ProdOrder: Record "Production Order";
        Cust: Record Customer;
        Vend: Record Vendor;
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        SourceTableName: Text;
        SourceFilter: Text;
        Description: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeGetCaption(Rec, Result, IsHandled);
        if IsHandled then
            exit;

        Description := '';

        case true of
            Rec.GetFilter("FA Item No.") <> '':
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 51200);
                    SourceFilter := Rec.GetFilter("FA Item No.");
                    if MaxStrLen(Item."No.") >= StrLen(SourceFilter) then
                        if Item.Get(SourceFilter) then
                            Description := Item.Description;
                end;
            // (Rec.GetFilter("Order No.") <> '') and (Rec."Order Type" = Rec."Order Type"::Production):
            //     begin
            //         SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5405);
            //         SourceFilter := Rec.GetFilter("Order No.");
            //         if MaxStrLen(ProdOrder."No.") >= StrLen(SourceFilter) then
            //             if ProdOrder.Get(ProdOrder.Status::Released, SourceFilter) or
            //                ProdOrder.Get(ProdOrder.Status::Finished, SourceFilter)
            //             then begin
            //                 SourceTableName := StrSubstNo('%1 %2', ProdOrder.Status, SourceTableName);
            //                 Description := ProdOrder.Description;
            //             end;
            //     end;
            Rec.GetFilter("Source No.") <> '':
                case Rec."Source Type" of
                    Rec."Source Type"::Customer:
                        begin
                            SourceTableName :=
                              ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 18);
                            SourceFilter := Rec.GetFilter("Source No.");
                            if MaxStrLen(Cust."No.") >= StrLen(SourceFilter) then
                                if Cust.Get(SourceFilter) then
                                    Description := Cust.Name;
                        end;
                    Rec."Source Type"::Vendor:
                        begin
                            SourceTableName :=
                              ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 23);
                            SourceFilter := Rec.GetFilter("Source No.");
                            if MaxStrLen(Vend."No.") >= StrLen(SourceFilter) then
                                if Vend.Get(SourceFilter) then
                                    Description := Vend.Name;
                        end;
                end;
            Rec.GetFilter("Global Dimension 1 Code") <> '':
                begin
                    GLSetup.Get();
                    Dimension.Code := GLSetup."Global Dimension 1 Code";
                    SourceFilter := Rec.GetFilter("Global Dimension 1 Code");
                    SourceTableName := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(GLSetup."Global Dimension 1 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
            Rec.GetFilter("Global Dimension 2 Code") <> '':
                begin
                    GLSetup.Get();
                    Dimension.Code := GLSetup."Global Dimension 2 Code";
                    SourceFilter := Rec.GetFilter("Global Dimension 2 Code");
                    SourceTableName := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(GLSetup."Global Dimension 2 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
            Rec.GetFilter("Document Type") <> '':
                begin
                    SourceTableName := Rec.GetFilter("Document Type");
                    SourceFilter := Rec.GetFilter("Document No.");
                    Description := Rec.GetFilter("Document Line No.");
                end;
        end;
        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, Description));
    end;
}