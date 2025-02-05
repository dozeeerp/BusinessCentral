tableextension 51205 TST_TransferHeader extends "Transfer Header"
{
    fields
    {
        // Add changes to table fields here
        modify(Status)
        {
            trigger OnAfterValidate()
            begin
                if Status = Status::Released then
                    Status1 := Status1::Released;
                if Status = Status::Open then
                    Status1 := Status1::Open;
            end;
        }
        modify("Customer No.")
        {
            trigger OnAfterValidate()
            var
                Customer: Record Customer;
            begin
                if Customer.Get(rec."Customer No.") then begin
                    if Customer."Privacy Blocked" then
                        Customer.CustPrivacyBlockedErrorMessage(Customer, false);
                    if (Customer.Blocked = Customer.Blocked::All) or (Customer.Blocked = Customer.Blocked::Ship) then
                        Customer.CustBlockedErrorMessage(Customer, false);
                end;
            end;
        }
        field(51000; Status1; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval';
            OptionMembers = Open,Released,"Pending Approval";

            trigger OnValidate()
            begin
                if Status1 = Status1::Open then
                    Status := Status::Open;
            end;
        }
    }

    trigger OnDelete()
    begin
        ApprovalsMgmt.OnDeleteRecordInApprovalRequest(rec.RecordId);
    end;

    var
        TransferPrePostCheckErr: Label 'Transfer Order %1 must be approved and released before you can perform this action', Comment = '%1=Transfer Order No.';
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";

    procedure CheckBeforeTransferApprove()
    var
        Location: Record Location;
        FromIsDemo: Boolean;
        ToIsDemo: Boolean;
    begin
        TestField("Transfer-from Code");
        TestField("Transfer-to Code");

        if not "Direct Transfer" then
            TestField("In-Transit Code");

        TestField(Status, Status::Open);
        TestField(Status1, Status1::Open);
        TestField("Posting Date");

        if Location.Get(rec."Transfer-from Code") then
            FromIsDemo := Location."Demo Location";
        if Location.Get(Rec."Transfer-to Code") then
            ToIsDemo := Location."Demo Location";
        if FromIsDemo and ToIsDemo then
            Error('Devices can not be moved between customers please get them back to warehouse first before sending it to another customer.');
    end;

    procedure PerformManualRelease()
    var
        ApprovalsMgmt: Codeunit "TST Approvals Mgmt";
        TransferRelease: Codeunit "Release Transfer Document";
    begin
        if ApprovalsMgmt.IsTransferOrderPendingApproval(Rec) then
            Error(TransferPrePostCheckErr, rec."No.");

        TransferRelease.Run(Rec);
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckTransferReleaseRestrictions()
    begin
    end;

    procedure CheckTransferReleaseRestrictions()
    var
        TSTApprovalsMgmt: Codeunit "TST Approvals Mgmt";
    begin
        OnCheckTransferReleaseRestrictions;
        // TSTApprovalsMgmt.PrePostApprovalCheckLicense(Rec);
    end;

    [IntegrationEvent(true, false)]
    procedure OnCheckTransferPostRestrictions()
    begin
    end;

    procedure CheckTransferPostRestrictions()
    begin
        OnCheckTransferPostRestrictions();
    end;
}