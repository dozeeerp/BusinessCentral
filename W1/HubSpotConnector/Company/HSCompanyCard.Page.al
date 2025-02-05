namespace TST.Hubspot.Company;

using Microsoft.Sales.Customer;

page 51305 "HubSpot Company"
{
    PageType = Card;
    UsageCategory = None;
    SourceTable = "Hubspot Company";
    InsertAllowed = false;
    Caption = 'Hubspot Company';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = false;
                field(Id; Rec.Id)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique idenifier for the company in hubspot.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s anme.';
                }
            }
            group(Mapping)
            {
                Caption = 'Mapping';
                Editable = false;
                field(CustomerNo; CustomerNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    TableRelation = Customer;
                    ToolTip = 'Specifies the unique identifier for the customer in D365BC.';

                    trigger OnValidate()
                    begin
                        if CustomerNo <> '' then begin
                            Customer.Get(CustomerNo);
                            Rec."Customer SystemId" := Customer.SystemId;
                            GetMappedCustomer();
                        end;
                    end;

                    trigger OnAssistEdit()
                    var
                        CustomerList: page "Customer List";
                    begin
                        CustomerList.LookupMode := true;
                        CustomerList.SetRecord(Customer);
                        if CustomerList.RunModal() = Action::LookupOK then begin
                            CustomerList.GetRecord(Customer);
                            Rec."Customer SystemId" := Customer.SystemId;
                            CustomerNo := Customer."No.";
                            Rec.Modify();
                        end;
                    end;
                }
                field(CustomerName; Customer."Name")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the customer''s name.';
                }
                field(Address; Customer.Address)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Address';
                    ToolTip = 'Specifies the customer''s address.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(CustomerCard)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Card';
                Image = Customer;
                ToolTip = 'View or edit detailed information about the customer.';

                trigger OnAction()
                var
                    Customer: Record Customer;
                begin
                    if Customer.GetBySystemId(Rec."Customer SystemId") then begin
                        Customer.SetRecFilter();
                        Page.Run(Page::"Customer Card", Customer);
                    end;
                end;
            }
        }
        area(Processing)
        {
            action(CreateCustomer)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Customer';
                Image = NewCustomer;
                ToolTip = 'Create customer from hubspot company';

                trigger OnAction()
                var
                    UpdateCustomer: Codeunit "Hubspot Update Customer";
                begin
                    if not IsNullGuid(Rec."Customer SystemId") then
                        Error('Customer mapping exist with %1', CustomerNo);

                    UpdateCustomer.CreateCustomerFromCompany(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(CreateCustomer_Promoted; CreateCustomer)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigation';
                actionref(CustomerCard_Promoted; CustomerCard)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetMappedCustomer();
    end;

    var
        Customer: Record Customer;
        CustomerNo: Code[20];

    local procedure GetMappedCustomer()
    begin
        if IsNullGuid(Rec."Customer SystemId") then begin
            Clear(Customer);
            Clear(CustomerNo);
        end else
            if Customer.GetBySystemId(Rec."Customer SystemId") then
                CustomerNo := Customer."No."
            else begin
                Clear(Customer);
                Clear(CustomerNo);
            end;
    end;

}