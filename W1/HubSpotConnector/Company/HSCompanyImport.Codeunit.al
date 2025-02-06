namespace TST.Hubspot.Company;

using TST.Hubspot.Setup;

codeunit 51310 "Hubspot Company import"
{
    Access = Internal;
    TableNo = "Hubspot Company";

    trigger OnRun()
    begin
        HSSetup.Get();
        if Rec.Id = 0 then
            exit;
        SetCompany(rec.Id);

        if not CompanyAPI.RetrieveHubspotCompany(HubspotCompany) then begin
            HubspotCompany.Delete();
            exit;
        end;

        Commit();
        if CompanyMapping.FindMapping(HubspotCompany) then begin
            UpdateCustomer.UpdateCustomerFromCompany(HubspotCompany);
        end else
            if HSSetup."Create Cutomer" = HSSetup."Create Cutomer"::AllCompanies then
                UpdateCustomer.CreateCustomerFromCompany(HubspotCompany);
    end;

    var
        HubspotCompany: Record "Hubspot Company";
        CompanyAPI: Codeunit "Hubspot Company API";
        CompanyMapping: Codeunit "Hubspot Company Mapping";
        UpdateCustomer: Codeunit "Hubspot Update Customer";
        HSSetup: Record "Hubspot Setup";

    local procedure SetCompany(Id: BigInteger)
    begin
        if Id <> 0 then begin
            Clear(HubspotCompany);
            HubspotCompany.SetRange(Id, Id);
            if not HubspotCompany.FindFirst() then begin
                HubspotCompany.Id := Id;
                HubspotCompany.Insert(false);
            end;
        end;
    end;
}