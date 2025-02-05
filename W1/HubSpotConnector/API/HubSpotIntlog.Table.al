namespace TST.Hubspot.Api;
using Microsoft.Utilities;
using System.Reflection;
using Microsoft.Sales.Customer;

table 51301 "HubSpot Int. Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(2; appId; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'App ID';
        }
        field(3; eventId; BigInteger)
        {
            DataClassification = CustomerContent;
            Caption = 'Event ID';
        }
        field(4; subscriptionId; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Subscription Id';
        }
        field(5; portalId; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Portal Id';
        }
        field(6; occurredAt; BigInteger)
        {
            DataClassification = CustomerContent;
            Caption = 'Occurred At';
        }
        field(7; subscriptionType; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Subscription Type';
        }
        field(8; attemptNumber; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Attempt Number';
        }
        field(9; objectId; BigInteger)
        {
            DataClassification = CustomerContent;
            Caption = 'Object Id';
        }
        field(10; changeSource; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Change Source';
        }
        field(11; changeFlag; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Change Flag';
        }
        field(12; sourceId; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(13; Message; Text[1000])
        {
            DataClassification = CustomerContent;
        }
        field(14; propertyName; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(15; propertyValue; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(16; Date; Datetime)
        {
            DataClassification = CustomerContent;
            Caption = 'Date';
        }
        field(17; Status; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = " ",Success,"In Process",Error;
        }
        field(18; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    var
        HSIntLog: Record "HubSpot Int. Log";
        SkipProcess: Boolean;
    begin
        if "Entry No." = 0 then
            "Entry No." := GetLastEntryNo() + 1;

        if occurredAt <> 0 then
            Date := UnixTimestampToDate(occurredAt);

        // if Rec.attemptNumber > 0 then begin
        //     HSIntLog.Reset();
        //     HSIntLog.SetRange(eventId, rec.eventId);
        //     HSIntLog.SetRange(objectId, rec.objectId);
        //     if HSIntLog.FindFirst() then begin
        //         SkipProcess := true;
        //         Status := Status::Success;
        //         Message := StrSubstNo('Alredy processed with entry no %1', HSIntLog."Entry No.")
        //     end;
        // end;
        // if not SkipProcess then
        // GetEventDetailsFromHubSopt(Rec, false);
    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    var
        HSAPIMgmt: Codeunit "Hubspot API Mgmt";
        HSMgmt: Codeunit "Hubspot Mgmt";

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure UnixTimestampToDate(UnixTimeStamp: BigInteger): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        ResultDateTime: DateTime;
        EpochDateTime: DateTime;
        TimezoneOffset: Duration;
        DateInMs: BigInteger;
    begin
        DateInMs := UnixTimeStamp div 1000;
        exit(TypeHelper.EvaluateUnixTimestamp(DateInMs));
    end;

    procedure SetStyle() Style: Text
    var
        IsHandled: Boolean;
    begin
        if Status = Status::Error then begin
            exit('Unfavorable')
        end;
        exit('');
    end;

    procedure GetEventDetailsFromHubSopt(var Rec: Record "HubSpot Int. Log"; Modify: Boolean)
    var
        HSIntLog: Record "HubSpot Int. Log";
        SkipProcess: Boolean;
        Success: Boolean;
    begin
        if Rec.attemptNumber > 0 then begin
            HSIntLog.Reset();
            HSIntLog.SetRange(eventId, Rec.eventId);
            HSIntLog.SetRange(objectId, Rec.objectId);
            if HSIntLog.FindFirst() then
                if Rec."Entry No." <> HSIntLog."Entry No." then begin
                    SkipProcess := true;
                    Success := true;
                    Rec.Status := Status::Success;
                    Rec.Message := StrSubstNo('Already processed with entry no %1', HSIntLog."Entry No.");
                end;
        end;
        if not SkipProcess then begin
            rec.Message := '';
            Success := Codeunit.Run(Codeunit::"Hubspot Mgmt", Rec);
        end;

        if Success then
            Rec.Status := Status::Success
        else
            Rec.Status := Status::Error;

        if Rec.Status = Status::Error then
            Rec.Message := GetLastErrorText();

        if Modify then
            Rec.Modify();
        Commit();
    end;
}