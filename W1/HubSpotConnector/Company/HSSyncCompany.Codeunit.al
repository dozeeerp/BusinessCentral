namespace TST.Hubspot.Company;

using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using TSTChanges;
using TST.Hubspot.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.CRM.Team;

codeunit 51307 "HS Sync Companies"
{
    Access = Internal;
    Permissions =
        tabledata "Country/Region" = r,
        tabledata Customer = rim,
        tabledata "Dimensions Template" = r,
        // tabledata KAM = rim,
        tabledata "Salesperson/Purchaser" = rim,
        tabledata Employee = r;

    trigger OnRun()
    var
        SyncStartTime: DateTime;
        HSSetup: Record "Hubspot Setup";
    begin
        HSSetup.Get();
        SyncStartTime := CurrentDateTime;
        if HSSetup."Company Import From Hubspot" = HSSetup."Company Import From Hubspot"::AllCompanies then
            ImportCompaniesFromHubspot();
        if HSSetup."Can Update Hubspot Companies" then
            ExportCompaniesToHubSpot();

        HSSetup.SetLastSyncTime(SyncStartTime);
        HSSetup.Modify()
    end;

    var
        CompanyAPI: Codeunit "Hubspot Company API";
        CompanyExport: Codeunit "Hubspot Company Export";
        CompanyImport: Codeunit "Hubspot Company Import";

    local procedure ImportCompaniesFromHubspot()
    var
        Company: Record "Hubspot Company";
        TempCompany: Record "Hubspot Company" temporary;
        ID: BigInteger;
        UpdatedAt: DateTime;
        CompanyIds: Dictionary of [BigInteger, DateTime];
    begin
        CompanyAPI.RetrieveHubspotCompanyIds(CompanyIds);
        foreach ID in CompanyIds.Keys do begin
            Company.SetRange(Id, ID);
            if Company.FindFirst() then begin
                CompanyIds.Get(ID, UpdatedAt);
                if ((Company."Updated At" = 0DT) or (Company."Updated At" < UpdatedAt)) and (Company."Last Updated by BC" < UpdatedAt) then begin
                    TempCompany := Company;
                    TempCompany.Insert(false);
                end;
            end else begin
                Clear(TempCompany);
                TempCompany.Id := ID;
                TempCompany.Insert(false);
            end;
        end;
        Clear(TempCompany);
        if TempCompany.FindSet(false) then
            repeat
                CompanyImport.Run(TempCompany);
            until TempCompany.Next() = 0;
    end;

    local procedure ExportCompaniesToHubSpot()
    var
        Customer: Record Customer;
    begin
        CompanyExport.SetCreateCompanies(false);
        CompanyExport.Run(Customer);
    end;
}