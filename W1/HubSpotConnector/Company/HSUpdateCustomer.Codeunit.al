namespace TST.Hubspot.Company;

using TST.Hubspot.Api;
// using Microsoft.Finance.TaxBase;
using Microsoft.Finance.Dimension;
using TSTChanges;
using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using Microsoft.CRM.BusinessRelation;

codeunit 51312 "Hubspot Update Customer"
{
    trigger OnRun()
    begin

    end;

    var
        HSAPIMgmt: Codeunit "Hubspot API Mgmt";
        CustContUpdate: Codeunit "CustCont-Update";

    internal procedure CreateCustomerFromCompany(var HubspotCompany: Record "Hubspot Company")
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer.Validate(Name, HubspotCompany.Name);
        Customer.Validate(Address, HubspotCompany.Address);
        Customer.Validate("Address 2", HubspotCompany."Address 2");
        Customer.Validate("Country/Region Code", GetCountryCode(HubspotCompany."Country/Region"));
        Customer.Validate(City, HubspotCompany.City);
        Customer.Validate("Post Code", HubspotCompany.ZIP);
        // Customer.Validate(County);
        if HubspotCompany.Phone <> '' then
            Customer.Validate("Phone No.", HubspotCompany.Phone);
        if HubspotCompany."Mobile Phone No" <> '' then
            Customer.Validate("Mobile Phone No.", HubspotCompany."Mobile Phone No");
        if HubspotCompany."Currency Code" = 'INR' then
            Customer.Validate("Currency Code", '')
        else
            Customer.Validate("Currency Code", HubspotCompany."Currency Code");
        if HubspotCompany."Customer Type" <> '' then
            UpdatePostingGroupOnCustomer(Customer, HubspotCompany."Customer Type");
        // if HubspotCompany.State > '' then
        //     Customer.Validate("State Code", GetStateCode(HubspotCompany.State));
        if HubspotCompany."Sales Onwer" <> 0 then
            Customer.Validate("Salesperson Code", GetSalesPerson(HubspotCompany."Sales Onwer"));
        // if HubspotCompany."KAM Onwer" <> 0 then
        //     Customer.Validate("KAM Code", GetKam(HubspotCompany."KAM Onwer"));

        // if HubspotCompany."P.A.N. No" <> '' then
        //     Customer.Validate("P.A.N. No.", HubspotCompany."P.A.N. No");
        // if HubspotCompany."GST Registration No" <> '' then begin
        //     if Customer."P.A.N. No." <> CopyStr(HubspotCompany."GST Registration No", 3, 10) then
        //         Customer.Validate("P.A.N. No.", CopyStr(HubspotCompany."GST Registration No", 3, 10));
        //     Customer.Validate("GST Registration No.", HubspotCompany."GST Registration No");
        // end;
        Customer.Insert(true);

        if Customer.Blocked <> Customer.Blocked::" " then begin
            Customer.Blocked := Customer.Blocked::" ";
            Customer.Modify(true);
        end;

        HubspotCompany."Customer SystemId" := Customer.SystemId;
        // HubspotCompany."Customer No." := Customer."No.";
        HubspotCompany.Modify();

        CustContUpdate.OnModify(Customer);

        if HubspotCompany.Zone <> '' then
            UpdateDimensionOnCustomer('REGION', HubspotCompany.Zone, Customer."No.");
    end;

    internal procedure UpdateCustomerFromCompany(var HubspotCompany: Record "Hubspot Company")
    var
        Customer: Record Customer;
    begin
        if not Customer.GetBySystemId(HubspotCompany."Customer SystemId") then
            exit;

        Customer.Validate(Name, HubspotCompany.Name);
        Customer.Validate(Address, HubspotCompany.Address);
        Customer.Validate("Address 2", HubspotCompany."Address 2");
        Customer.Validate("Country/Region Code", GetCountryCode(HubspotCompany."Country/Region"));
        Customer.Validate(City, HubspotCompany.City);
        Customer.Validate("Post Code", HubspotCompany.ZIP);
        // Customer.Validate(County);
        if HubspotCompany.Phone <> '' then
            Customer.Validate("Phone No.", HubspotCompany.Phone);
        if HubspotCompany."Mobile Phone No" <> '' then
            Customer.Validate("Mobile Phone No.", HubspotCompany."Mobile Phone No");
        if HubspotCompany."Currency Code" = 'INR' then
            Customer.Validate("Currency Code", '')
        else
            Customer.Validate("Currency Code", HubspotCompany."Currency Code");
        if HubspotCompany."Customer Type" <> '' then
            UpdatePostingGroupOnCustomer(Customer, HubspotCompany."Customer Type");
        // if (HubspotCompany.State > '') and (Customer."State Code" <> GetStateCode(HubspotCompany.State)) then
        //     Customer.Validate("State Code", GetStateCode(HubspotCompany.State));
        if HubspotCompany."Sales Onwer" <> 0 then
            Customer.Validate("Salesperson Code", GetSalesPerson(HubspotCompany."Sales Onwer"));
        // if HubspotCompany."KAM Onwer" <> 0 then
        //     Customer.Validate("KAM Code", GetKam(HubspotCompany."KAM Onwer"));

        // if (HubspotCompany."P.A.N. No" <> '') and (Customer."P.A.N. No." <> HubspotCompany."P.A.N. No") then
        //     Customer.Validate("P.A.N. No.", HubspotCompany."P.A.N. No");
        // if HubspotCompany."GST Registration No" <> '' then begin
        //     if Customer."P.A.N. No." <> CopyStr(HubspotCompany."GST Registration No", 3, 10) then
        //         Customer.Validate("P.A.N. No.", CopyStr(HubspotCompany."GST Registration No", 3, 10));
        //     Customer.Validate("GST Registration No.", HubspotCompany."GST Registration No");
        // end;

        Customer.Modify();
        // if HubspotCompany."Customer No." <> Customer."No." then begin
        //     HubspotCompany."Customer No." := Customer."No.";
        //     HubspotCompany.Modify();
        // end;
        CustContUpdate.OnModify(Customer);
        if HubspotCompany.Zone <> '' then
            UpdateDimensionOnCustomer('REGION', HubspotCompany.Zone, Customer."No.");
    end;

    local procedure UpdatePostingGroupOnCustomer(var Cust: Record customer; CustGroupValue: Text)
    var
        CustomerType: Text;
    begin
        CustomerType := UpperCase(CustGroupValue);
        Case CustomerType of
            'DOMESTIC':
                begin
                    Cust."Gen. Bus. Posting Group" := CustomerType;
                    Cust."Customer Posting Group" := CustomerType;
                end;
            'FOREIGN':
                begin
                    Cust."Gen. Bus. Posting Group" := CustomerType;
                    Cust."Customer Posting Group" := CustomerType;
                end;
            'B2C':
                begin
                    Cust."Gen. Bus. Posting Group" := 'DOMESTIC';
                    Cust."Customer Posting Group" := CustomerType;
                end;
            'DISTRIBUTOR':
                begin
                    Cust."Gen. Bus. Posting Group" := 'DOMESTIC';
                    Cust."Customer Posting Group" := CustomerType;
                end;
            else
                Error('Customer Type should not be: %1', CustomerType);
        end;
    end;

    // local procedure GetStateCode(StateText: Text): Code[10]
    // var
    //     State: Record State;
    // begin
    //     State.Reset();
    //     if State.Get(CopyStr(StateText, 1, MaxStrLen(State.Code))) then
    //         exit(State.Code);

    //     State.SetFilter(Description, StateText);
    //     if State.FindFirst() then
    //         exit(State.Code);

    //     Error('State not valid %1', StateText);
    // end;

    local procedure GetCountryCode(CountryText: Text): Code[10]
    var
        Country: Record "Country/Region";
    begin
        Country.Reset();
        if Country.Get(CopyStr(CountryText, 1, MaxStrLen(Country.Code))) then
            exit(Country.Code);

        Country.SetFilter(Name, CountryText);
        if Country.FindFirst() then
            exit(Country.Code);

        Error('Country not valid %1', CountryText);
    end;

    local procedure UpdateDimensionOnCustomer(DimCode: Code[20]; DimValue: Code[20]; CustNo: code[20])
    var
        DefDim: Record "Default Dimension";
    begin
        DefDim.Reset();
        if DefDim.Get(Database::Customer, CustNo, DimCode) then begin
            if Defdim."Dimension Value Code" <> DimValue then begin
                DefDim.Validate("Dimension Value Code", DimValue);
                DefDim.Modify(true);
            end;
        end else begin
            DefDim.Init();
            DefDim.Validate("Table ID", Database::Customer);
            DefDim.Validate("No.", CustNo);
            DefDim.Validate("Dimension Code", DimCode);
            DefDim.Validate("Dimension Value Code", DimValue);
            DefDim.Validate("Parent Type", DefDim."Parent Type"::Customer);
            DefDim.Insert(true);
        end;
    end;

    // local procedure GetKam(HSID: BigInteger): Code[20]
    // var
    //     KAM: Record KAM;
    //     KAM2: Record KAM;
    //     Emp: Record Employee;
    //     Email: Text;
    // begin
    //     KAM.Reset();
    //     KAM.SetRange(HS_KAM_ID, HSID);
    //     if KAM.FindFirst() then
    //         exit(KAM.Code);
    //     Email := HSAPIMgmt.GetUserInfoFromHS(Format(HSID));
    //     KAM.Reset();
    //     KAM.SetFilter("E-Mail", '%1', Email);
    //     if KAM.FindFirst() then begin
    //         KAM2.Get(KAM.Code);
    //         KAM2.HS_KAM_ID := HSID;
    //         KAM2.Modify(true);
    //         exit(KAM2.Code);
    //     end;
    //     Emp.Reset();
    //     Emp.SetFilter("E-Mail", '%1', Email);
    //     if Emp.FindFirst() then begin
    //         if not KAM2.Get(Emp."No.") then
    //             CreateKAM(KAM2, Emp, HSID);
    //         exit(KAM2.Code);
    //     end;
    //     Emp.Reset();
    //     Emp.SetFilter("Company E-Mail", '%1', Email);
    //     if Emp.FindFirst() then begin
    //         if not KAM2.Get(Emp."No.") then
    //             CreateKAM(KAM2, Emp, HSID);
    //         exit(KAM2.Code);
    //     end;
    //     if Email <> '' then
    //         Error('Kam not Found, %1', Email)
    //     else
    //         Error('Check Onwer in HS %1', HSID);
    // end;

    // local procedure CreateKAM(var KAM: Record KAM; Emp: Record Employee; HSID: BigInteger)
    // begin
    //     KAM.Init();
    //     KAM.Code := Emp."No.";
    //     KAM.Name := Emp.FullName();
    //     KAM."E-Mail" := Emp."Company E-Mail";
    //     KAM."E-Mail 2" := Emp."E-Mail";
    //     KAM.HS_KAM_ID := HSID;
    //     KAM.Insert(true);
    // end;

    local procedure GetSalesPerson(HSID: BigInteger): Code[20]
    var
        SalesPer: Record "Salesperson/Purchaser";
        SalesPer2: Record "Salesperson/Purchaser";
        Emp: Record Employee;
        Email: Text;
    begin
        SalesPer.Reset();
        SalesPer.SetRange(HS_Sales_ID, HSID);
        if SalesPer.FindFirst() then
            exit(SalesPer.Code);
        Email := HSAPIMgmt.GetUserInfoFromHS(Format(HSID));
        SalesPer.Reset();
        SalesPer.SetFilter("E-Mail", '%1', Email);
        if SalesPer.FindFirst() then begin
            SalesPer2.Get(SalesPer.Code);
            SalesPer2.HS_Sales_ID := HSID;
            SalesPer2.Modify(true);
            exit(SalesPer2.Code);
        end;
        Emp.Reset();
        Emp.SetFilter("E-Mail", '%1', Email);
        if Emp.FindFirst() then begin
            SalesPer2.Init();
            SalesPer2.Code := Emp."No.";
            SalesPer2.Name := Emp.FullName();
            SalesPer2.HS_Sales_ID := HSID;
            SalesPer2.Insert(true);
            exit(SalesPer2.Code);
        end;
        Emp.Reset();
        Emp.SetFilter("Company E-Mail", '%1', Email);
        if Emp.FindFirst() then begin
            SalesPer2.Init();
            SalesPer2.Code := Emp."No.";
            SalesPer2.Name := Emp.FullName();
            SalesPer2.HS_Sales_ID := HSID;
            SalesPer2.Insert(true);
            exit(SalesPer2.Code);
        end;
        if Email <> '' then
            Error('Sales person not Found, %1', Email)
        else
            Error('Check Onwer in HS %1', HSID);
    end;
}