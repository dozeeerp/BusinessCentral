namespace TST.Hubspot.Company;

using Microsoft.Sales.Customer;

codeunit 51311 "Hubspot Company Mapping"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    internal procedure DoMapping()
    begin

    end;

    internal procedure FindMapping(var HubspotCompany: Record "Hubspot Company"): Boolean
    var
        Customer: Record Customer;
    begin
        if not IsNullGuid(HubspotCompany."Customer SystemId") then
            if Customer.GetBySystemId(HubspotCompany."Customer SystemId") then
                exit(true)
            else begin
                Clear(HubspotCompany."Customer SystemId");
                HubspotCompany.Modify();
            end;

        // if IsNullGuid(HubspotCompany."Customer SystemId") then begin
        //     if HubspotCompany."Customer No." <> '' then
        //         if Customer.Get(HubspotCompany."Customer No.") then begin
        //             HubspotCompany."Customer SystemId" := Customer.SystemId;
        //             HubspotCompany.Modify();
        //             exit(true);
        //         end;
        // end;
    end;
}