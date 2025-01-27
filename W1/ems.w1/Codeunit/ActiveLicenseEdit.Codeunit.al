codeunit 52112 "Active License - Edit"
{
    Permissions = tabledata "License Request" = rm;
    TableNo = "License Request";

    trigger OnRun()
    var
        LicenseReq: Record "License Request";
    begin
        LicenseReq := Rec;
        LicenseReq.LockTable();
        LicenseReq."Contact" := rec."Contact";
        LicenseReq."Contact No." := rec."Contact No.";
        LicenseReq."E-Mail" := rec."E-Mail";
        LicenseReq."Salesperson Code" := rec."Salesperson Code";
        LicenseReq."Salesperson Name" := rec."Salesperson Name";
        // LicenseReq."KAM Code" := rec."KAM Code";
        // LicenseReq."KAM Name" := rec."KAM Name";

        LicenseReq.TestField("No.", rec."No.");
        LicenseReq.TestField("License No.", Rec."License No.");
        LicenseReq.Modify();
        Rec := LicenseReq;
    end;

    var
        myInt: Integer;
}