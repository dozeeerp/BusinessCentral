namespace TST.Hubspot.Company;

using Microsoft.Sales.Customer;
using Microsoft.CRM.Team;
// using Microsoft.Finance.TaxBase;
using TSTChanges;
using Microsoft.Foundation.Address;

codeunit 51313 "Hubspot Company Export"
{
    Access = Internal;
    TableNo = Customer;
    trigger OnRun()
    var
        Customer: Record Customer;
        HubspotCompany: Record "Hubspot Company";
    begin
        Customer.CopyFilters(Rec);
        if Customer.FindSet(false) then
            repeat
                HubspotCompany.SetRange("Customer SystemId", Customer.SystemId);
                if not HubspotCompany.FindFirst() then begin
                    if CreateCustomers then
                        CreateHubspotCompany(Customer)
                end else
                    if not CreateCustomers then
                        UpdateHubspotCompany(Customer, HubspotCompany.Id);
                Commit();
            until Customer.Next() = 0;
    end;

    var
        CompanyAPI: Codeunit "Hubspot Company API";
        CreateCustomers: Boolean;

    local procedure CreateHubspotCompany(Customer: Record Customer)
    var
        HubspotCompany: Record "Hubspot Company";
    begin
        // if Customer."E-Mail" = '' then
        //     exit;
        if FillInHubspotCompany(Customer, HubspotCompany) then begin
            if CompanyAPI.CreateCompany(HubspotCompany) then begin
                HubspotCompany."Customer SystemId" := Customer.SystemId;
                // HubspotCompany."Customer No." := Customer."No.";
                HubspotCompany."Last Updated by BC" := CurrentDateTime();
                HubspotCompany.Insert();
            end;

        end;

    end;

    internal procedure FillInHubspotCompany(Customer: Record Customer; var HubspotCompany: Record "Hubspot Company"): Boolean
    var
        TempHubspotCompany: Record "Hubspot Company" temporary;
        // KAM: Record KAM;
        SalesPerson: Record "Salesperson/Purchaser";
        Country: Record "Country/Region";
    // State: Record State;
    begin
        TempHubspotCompany := HubspotCompany;
        HubspotCompany.Name := Customer.Name;
        HubspotCompany.Address := Customer.Address;
        HubspotCompany."Address 2" := Customer."Address 2";
        HubspotCompany.City := Customer.City;
        HubspotCompany.Phone := Customer."Phone No.";
        HubspotCompany."Mobile Phone No" := Customer."Mobile Phone No.";
        if Country.Get(Customer."Country/Region Code") then
            HubspotCompany."Country/Region" := Country.Name;
        // if State.Get(Customer."State Code") then
        //     HubspotCompany.State := State.Description;
        HubspotCompany.ZIP := Customer."Post Code";
        HubspotCompany."Currency Code" := Customer."Currency Code";
        if Customer."Customer Posting Group" <> '' then begin
            case Customer."Customer Posting Group" of
                'DOMESTIC':
                    HubspotCompany."Customer Type" := 'Domestic';
                'FOREIGN':
                    HubspotCompany."Customer Type" := 'Foreign';
                'B2C':
                    HubspotCompany."Customer Type" := Customer."Customer Posting Group";
            end;
        end;
        // HubspotCompany."GST Registration No" := Customer."GST Registration No.";
        // HubspotCompany."P.A.N. No" := Customer."P.A.N. No.";
        // if KAM.Get(Customer."KAM Code") then
        //     HubspotCompany."KAM Onwer" := kam.HS_KAM_ID;
        if SalesPerson.Get(Customer."Salesperson Code") then
            HubspotCompany."Sales Onwer" := SalesPerson.HS_Sales_ID;

        if HasDiff(HubspotCompany, TempHubspotCompany) then begin
            HubspotCompany."Last Updated by BC" := CurrentDateTime;
            exit(true);
        end;
    end;

    local procedure HasDiff(RecAsVariant: Variant; xRecAsVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
        xRecordRef: RecordRef;
        Index: Integer;
    begin
        RecordRef.GetTable(RecAsVariant);
        xRecordRef.GetTable(xRecAsVariant);
        if RecordRef.Number = xRecordRef.Number then
            for Index := 1 to RecordRef.FieldCount do
                if RecordRef.FieldIndex(Index).Value <> xRecordRef.FieldIndex(Index).Value then
                    exit(true);
    end;

    local procedure UpdateHubspotCompany(Customer: Record Customer; CompanyId: BigInteger)
    var
        HubspotCompany: Record "Hubspot Company";
    begin
        HubspotCompany.Get(CompanyId);
        if HubspotCompany."Customer SystemId" <> Customer.SystemId then
            exit;

        if FillInHubspotCompany(Customer, HubspotCompany) then begin
            CompanyAPI.UpdateCompany(HubspotCompany);
            HubspotCompany.Modify();
        end;
    end;

    internal procedure SetCreateCompanies(NewCustomers: Boolean)
    begin
        CreateCustomers := NewCustomers;
    end;
}