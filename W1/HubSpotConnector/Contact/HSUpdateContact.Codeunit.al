namespace TST.Hubspot.Contact;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using TST.Hubspot.Company;
using Microsoft.CRM.BusinessRelation;

codeunit 51320 "Hubspot Update Contact"
{
    trigger OnRun()
    begin

    end;

    var
        Cust: Record Customer;
        HsContactAPI: Codeunit "Hubspot Contact API";
        ContactBusinessRelation: Record "Contact Business Relation";

    internal procedure CreateContactFromContact(var HubspotContact: Record "Hubspot Contact")
    var
        Contact: Record Contact;
    begin
        Contact.Init();
        Contact.Type := Contact.Type::Person;
        Contact."Contact Business Relation" := Contact."Contact Business Relation"::Customer;
        Contact.Validate("First Name", HubspotContact."First Name");
        Contact.Validate("Salutation Code", HubspotContact."Salutation Code");
        Contact.Validate("Job Title", HubspotContact."Job Title");
        Contact.Validate("Middle Name", HubspotContact."Middle Name");
        Contact.Validate(Surname, HubspotContact."Last Name");
        Contact.Validate(Address, HubspotContact.Address);
        Contact.Validate("Address 2", HubspotContact."Address 2");
        Contact.Validate(City, HubspotContact.City);
        Contact.Validate("Country/Region Code", GetCountryCode(HubspotContact."Country/Region Code"));
        Contact.Validate("Post Code", HubspotContact."Post Code");
        if HubspotContact."Phone No." <> '' then
            Contact.Validate("Phone No.", HubspotContact."Phone No.");
        if HubspotContact."Mobile Phone No." <> '' then
            Contact.Validate("Mobile Phone No.", HubspotContact."Mobile Phone No.");
        if (HubspotContact."Company No." <> '') and (Contact."Company No." <> HubspotContact."Company No.") then
            Contact.Validate("Company No.", HubspotContact."Company No.");

        if GetAssociatedCustomer(HubspotContact.Id) then
            if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Cust."No.") then
                Contact.Validate("Company No.", ContactBusinessRelation."Contact No.");

        // Contact."Financial Communication" := HubspotContact."Financial Comm";

        Contact.Insert(true);

        HubspotContact."Contact SystemId" := Contact.SystemId;
        HubspotContact.Modify();
    end;

    internal procedure UpdateContactFromContact(var HubspotContact: Record "Hubspot Contact")
    var
        Contact: Record Contact;
    begin
        if not Contact.GetBySystemId(HubspotContact."Contact SystemId") then
            exit;

        Contact.Type := Contact.Type::Person;
        Contact."Contact Business Relation" := Contact."Contact Business Relation"::Customer;

        Contact.Validate("First Name", HubspotContact."First Name");
        Contact.Validate("Salutation Code", HubspotContact."Salutation Code");
        Contact.Validate("Job Title", HubspotContact."Job Title");
        Contact.Validate("Middle Name", HubspotContact."Middle Name");
        Contact.Validate(Surname, HubspotContact."Last Name");
        Contact.Validate(Address, HubspotContact.Address);
        Contact.Validate("Address 2", HubspotContact."Address 2");
        Contact.Validate(City, HubspotContact.City);
        Contact.Validate("Country/Region Code", GetCountryCode(HubspotContact."Country/Region Code"));
        Contact.Validate("Post Code", HubspotContact."Post Code");
        if HubspotContact."Phone No." <> '' then
            Contact.Validate("Phone No.", HubspotContact."Phone No.");
        if HubspotContact."Mobile Phone No." <> '' then
            Contact.Validate("Mobile Phone No.", HubspotContact."Mobile Phone No.");

        if (HubspotContact."Company No." <> '') and (Contact."Company No." <> HubspotContact."Company No.") then
            Contact.Validate("Company No.", HubspotContact."Company No.");
        if HubspotContact."Company No." = '' then begin
            if GetAssociatedCustomer(HubspotContact.Id) then
                if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Cust."No.") then
                    Contact.Validate("Company No.", ContactBusinessRelation."Contact No.");
        end;
        // Contact."Financial Communication" := HubspotContact."Financial Comm";

        Contact.Modify(true);
    end;

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

    procedure GetAssociatedCustomer(ContactId: BigInteger): Boolean
    var
        CompanyId: BigInteger;
        HubsoptCompany: Record "Hubspot Company";
    begin
        if HsContactAPI.CheckContactAssociationWithCompany(ContactId, CompanyId) then begin
            if HubsoptCompany.Get(CompanyId) then
                if not IsNullGuid(HubsoptCompany."Customer SystemId") then begin
                    Cust.GetBySystemId(HubsoptCompany."Customer SystemId");
                    exit(true);
                end;
        end;
    end;
}