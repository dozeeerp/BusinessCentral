namespace TST.Hubspot.Api;

page 51302 "HubSpot Int Logs"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    Caption = 'HubSpot Int Logs';
    AdditionalSearchTerms = 'HS Int Logs';
    SourceTable = "HubSpot Int. Log";
    SourceTableView = sorting("Entry No.")
                      order(descending);

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = ' Entry No.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                }
                field(occurredAt; Rec.occurredAt)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(subscriptionType; Rec.subscriptionType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription Type';
                }
                field(objectId; Rec.objectId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Id';
                }
                field(propertyName; Rec.propertyName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Property Name';
                }
                field(propertyValue; Rec.propertyValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Property Value';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    StyleExpr = StyleTxt;
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(changeSource; Rec.changeSource)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Source';
                }
                field(changeFlag; Rec.changeFlag)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Flag';
                }
                field(attemptNumber; Rec.attemptNumber)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(appId; Rec.appId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'App Id';
                }
                field(eventId; Rec.eventId)
                {
                    Caption = 'Event Id';
                    ApplicationArea = Basic, Suite;
                }
                field(subscriptionId; Rec.subscriptionId)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subscription Id';
                }
                field(portalId; Rec.portalId)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(GetInfoFromHS)
            {
                Caption = 'Get Info From HS';
                ApplicationArea = Basic, Suite;
                Image = GetSourceDoc;

                trigger OnAction()
                var
                    HsIntLog: Record "HubSpot Int. Log";
                begin
                    CurrPage.SetSelectionFilter(HsIntLog);
                    if HsIntLog.FindSet() then
                        repeat
                            rec.GetEventDetailsFromHubSopt(HsIntLog, true);
                        until HsIntLog.Next() = 0;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.SetStyle();
    end;

    var
        StyleTxt: Text;
}