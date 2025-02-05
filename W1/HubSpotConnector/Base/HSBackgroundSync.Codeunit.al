codeunit 51314 "Hubspot Background Syncs"
{
    Access = Internal;
    trigger OnRun()
    begin

    end;

    var
        JobQueueCategoryLbl: Label 'HUBSPOT', Locked = true;

    internal procedure CompanySync()
    var
        Parameters: Text;
        SyncTypeLbl: Label 'Companies';

    begin
        EnqueueJobEntry(Codeunit::"HS Sync Companies", StrSubstNo(SyncTypeLbl, SyncTypeLbl), true, true);
    end;

    internal procedure ContactSync()
    var
        Parameters: Text;
        SyncTypeLbl: Label 'Contacts';

    begin
        EnqueueJobEntry(Codeunit::"Hubspot Sync Contacts", StrSubstNo(SyncTypeLbl, SyncTypeLbl), true, true);
    end;

    local procedure EnqueueJobEntry(ObjectId: Integer; SyncDescription: Text; AllowBackgroundSync: Boolean; ShowNotification: Boolean): Guid
    var
        CanCreateTask: Boolean;
        MyNotifications: Record "My Notifications";
        Notify: Notification;
        JobQueueEntry: Record "Job Queue Entry";
        NotificationNameTok: Label 'Hubspot Background Sync Notification';
        DescriptionTok: Label 'Show notification when user starts synchronization jobs in background';
        SyncStartMsg: Label 'Job Queue started for: %1', Comment = '%1 = Synchronization Description';
        ShowLogMsg: Label 'Show log info';
        DontShowAgainTok: Label 'Don''t show again';
    begin
        CanCreateTask := TaskScheduler.CanCreateTask();
        if CanCreateTask and AllowBackgroundSync then begin
            Clear(JobQueueEntry.ID);
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := ObjectId;
            // JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
            JobQueueEntry."Notify On Success" := GuiAllowed();
            JobQueueEntry.Description := CopyStr(SyncDescription, 1, MaxStrLen(JobQueueEntry.Description));
            JobQueueEntry."No. of Attempts to Run" := 5;
            JobQueueEntry."Job Queue Category Code" := JobQueueCategoryLbl;
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
            // JobQueueEntry.SetXmlContent();
            if GuiAllowed and ShowNotification then begin
                MyNotifications.InsertDefault(HubspotNotificationID(), NotificationNameTok, DescriptionTok, true);
                if MyNotifications.IsEnabled(HubspotNotificationID()) then begin
                    Notify.Id := HubspotNotificationID();
                    Notify.SetData('JobQueueEntry.Id', Format(JobQueueEntry.ID));
                    Notify.Message(StrSubstNo(SyncStartMsg, SyncDescription));
                    Notify.AddAction(ShowLogMsg, Codeunit::"Hubspot Background Syncs", 'ShowLog');
                    Notify.AddAction(DontShowAgainTok, Codeunit::"Hubspot Background Syncs", 'DisableNotifications');
                    Notify.Send();
                end;
            end;
        end else
            Codeunit.Run(ObjectId);
        exit(JobQueueEntry.ID);
    end;

    internal procedure ShowLog(Notify: Notification)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        Id: Guid;
    begin
        Evaluate(Id, Notify.GetData('JobQueueEntry.Id'));
        JobQueueLogEntry.SetRange(ID, Id);
        if JobQueueLogEntry.FindSet(false) then
            Page.Run(Page::"Job Queue Log Entries", JobQueueLogEntry);
    end;

    internal procedure DisableNotifications(Notify: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(Notify.Id);
    end;

    local procedure HubspotNotificationID(): Guid
    begin
        exit('00000000-0000-0000-0000-000000000001')
    end;
}