namespace TSTChanges.FA.Setup;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Setup;
using System.Reflection;

page 51230 "Report Selection - FA Item"
{
    PageType = Worksheet;
    Caption = 'Report Selection - FA Item';
    ApplicationArea = Basic, Suite;
    UsageCategory = Tasks;
    SaveValues = true;
    SourceTable = "Report Selections";

    layout
    {
        area(Content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Inventory";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Inventory"::"Transfer Order":
                Rec.SetRange(Usage, Rec.Usage::"FA T.Ord");
            "Report Selection Usage Inventory"::"Transfer Shipment":
                Rec.SetRange(Usage, Rec.Usage::"FA T.Ship");
            "Report Selection Usage Inventory"::"Transfer Receipt":
                Rec.SetRange(Usage, Rec.Usage::"FA T.Rcpt");
        end;
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        NewReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(NewReportUsage, Rec.GetFilter(Usage)) then
                case NewReportUsage of
                    NewReportUsage::"FA T.Ord":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Transfer Order";
                    NewReportUsage::"FA T.Ship":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Transfer Shipment";
                    NewReportUsage::"FA T.Rcpt":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Transfer Receipt";
                end;
            Rec.SetRange(Usage);
        end;
    end;
}