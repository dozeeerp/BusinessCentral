namespace TST.Hubspot.Api;

page 51301 "HubSpot Int API"
{
    PageType = API;
    Caption = 'HubSpot Int Log';
    APIPublisher = 'TST';
    APIGroup = 'hubspot';
    APIVersion = 'v1.0';
    EntityName = 'hslog';
    EntitySetName = 'hslog';
    SourceTable = "HubSpot Int. Log";
    DelayedInsert = true;

    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'System ID';
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(appId; Rec.appId)
                {
                    Caption = 'App Id';
                }
                field(eventId; Rec.eventId)
                {
                    Caption = 'Event Id';
                }
                field(subscriptionId; Rec.subscriptionId)
                { }
                field(portalId; Rec.portalId)
                { }
                field(occurredAt; Rec.occurredAt)
                { }
                field(subscriptionType; Rec.subscriptionType)
                { }
                field(attemptNumber; Rec.attemptNumber)
                { }
                field(objectId; Rec.objectId)
                { }
                field(changeSource; Rec.changeSource)
                { }
                field(changeFlag; Rec.changeFlag)
                { }
                field(sourceId; Rec.sourceId)
                { }
                field(propertyName; Rec.propertyName)
                { }
                field(propertyValue; Rec.propertyValue)
                { }
            }
        }
    }

    [ServiceEnabled]
    procedure runhsint(var ActionContext: WebServiceActionContext)
    var
        HSintLog: Record "HubSpot Int. Log";
    begin
        GetHSIntLog(HSintLog);
        HSintLog.GetEventDetailsFromHubSopt(HSintLog, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"HubSpot Int API");
        ActionContext.AddEntityKey(rec.FieldNo(SystemId), Rec.SystemId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    local procedure GetHSIntLog(var HSIntLog: Record "HubSpot Int. Log")
    begin
        if not HSIntLog.GetBySystemId(rec.SystemId) then
            Error('Cannot find HS int log');
    end;
}