page 51303 "Hubspot Activities"
{
    Caption = 'Hubspot Activities';
    PageType = CardPart;
    SourceTable = "Hubspot Cue";
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(HubspotInfo)
            {
                Caption = 'Hubspot info';
                field("Open Quote"; Rec."Open Quote")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Sales Quotes";
                    ToolTip = 'Specifies the number of the Sales Quotes that aren''t processed.';
                }
                field("Released Quote"; Rec."Released Quote")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Sales Quotes";
                    ToolTip = 'Specified the number of the Sales Quotes that are released.';
                }
                field("Unprocessed TR Orders"; Rec."Unprocessed TR Orders")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Transfer Orders";
                    ToolTip = 'Specifies the number of the Transfer Orders that aren''t processed.';
                }
                field("Unprocessed FA TR Orders"; Rec."Unprocessed FA TR Orders")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "FA Transfer Orders";
                    ToolTip = 'Specifies the number of the FA Transfer Orders that aren''t processed.';
                }
                field("Unmapped Companies"; Rec."Unmapped Companies")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "Hubspot Companies";
                    ToolTip = 'Specifies the number of imported companoes that aren''t mapped.';
                }
                field("Synchronization Errors"; Rec."Synchronization Errors")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of synchronization errors.';

                    trigger OnDrillDown()
                    var
                        JobQueueLogEntry: Record "Job Queue Log Entry";
                    begin
                        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::Error);
                        JobQueueLogEntry.SetFilter("Object Type to Run", '%1|%2', JobQueueLogEntry."Object Type to Run"::Report, JobQueueLogEntry."Object Type to Run"::Codeunit);
                        JobQueueLogEntry.SetFilter("Object Id to Run", '%1|%2', Codeunit::"HS Sync Companies",
                                                                Codeunit::"Hubspot Sync Contacts");
                        Page.Run(Page::"Job Queue Log Entries", JobQueueLogEntry);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CuesAndKpis: Codeunit "Cues And KPIs";
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not rec.Get() then
            if Rec.WritePermission then begin
                rec.Init();
                rec.Insert();
                Commit();
            end;
    end;
}