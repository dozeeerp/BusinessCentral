report 52100 "Enter Termination Date"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field("Termination Date"; TerminationDate)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the TerminationDate field.';
                    }
                }
            }
        }
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            IF CloseAction IN [ACTION::Cancel, ACTION::LookupCancel] THEN TerminationDate := 0D;
        end;
    }
    var
        TerminationDate: Date;

    procedure GetTerminationDate(var TerminationDate_vDte: Date)
    begin
        TerminationDate_vDte := TerminationDate;
    end;
}
