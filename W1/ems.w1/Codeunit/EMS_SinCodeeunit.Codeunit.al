codeunit 52107 EMS_SinCodeeunit
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    procedure InsertValue(SCHName: Code[20])
    begin
        Clear(SaveSch);
        SaveSch := SCHName;
    end;

    procedure ReturnSchName(): Code[20]
    begin
        exit(SaveSch);
    end;

    procedure InsertValue11(SCHName1: Code[20])
    begin
        Clear(SaveSch1);
        SaveSch1 := SCHName1;
    end;

    procedure ReturnSchName1(): Code[20]
    begin
        exit(SaveSch1);
    end;

    procedure ClearSchName()
    begin
        SaveSch := '';
    end;

    var
        SaveSch: Code[20];
        SaveSch1: Code[20];
}
