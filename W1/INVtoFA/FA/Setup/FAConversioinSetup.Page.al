namespace TSTChanges.FA.Setup;

page 51207 "FA Conversion Setup"
{
    Caption = 'FA Conversion Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "FA Conversion Setup";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Default Location for Orders"; Rec."Default Location for Orders")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies at which location FA conversion orders are created by default.';
                }
                field("Use Diffrent No Series for FA"; Rec."Use Diffrent No Series for FA")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specified if diffrent no series to be used for Fixed Asset.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Inventory Adjmt. Account"; Rec."Inventory Adjmt. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post inventory adjustments.';// with this particular combination of business posting group and product posting group.';
                }
                field("Inventory Capitalize Account"; Rec."Inventory Capitalize Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post inventory capitalisation.';
                }
            }
            group(Numbering)
            {
                field("FA Nos."; Rec."FA Nos.")
                {
                    ApplicationArea = All;
                    Editable = rec."Use Diffrent No Series for FA";
                    ToolTip = 'Specifies the number series code used to assign numbers to Fixed Assets when they are created.';
                }
                field("FA Item Nos."; Rec."FA Item Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series code used to assign numbers to FA Item when they are created.';
                }
                field("Conversion Order No."; Rec."Conversion Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series code used to assign numbers to FA conversion orders when they are created.';
                }
                field("Posted Conversion Order No."; Rec."Posted Conversion Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series code used to assign numbers to FA Conversion orders when they are posted.';
                }
                field("FA Transfer Order Nos."; Rec."FA Transfer Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series code used to assign numbers to FA transfer orders.';
                }
                field("Posted Transfer Shpt. Nos."; Rec."Posted Transfer Shpt. Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series code used to assign numbers to FA Posted transfer shipments.';
                }
                field("Posted Transfer Rcpt. Nos."; Rec."Posted Transfer Rcpt. Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series code used to assign numbers to FA Posted transfer receipts.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}