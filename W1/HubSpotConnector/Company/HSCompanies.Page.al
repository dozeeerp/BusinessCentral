namespace TST.Hubspot.Company;

using Microsoft.Sales.Customer;

page 51304 "Hubspot Companies"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Hubspot Company";
    InsertAllowed = false;
    Caption = 'Hubspot Companies';
    Editable = false;
    CardPageId = "HubSpot Company";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = Bsic, Suite;
                    ToolTip = 'Specifies the unique identifier for the company in Hubspot.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies the customer number.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                        CustomerCard: Page "Customer Card";
                    begin
                        if Customer.GetBySystemId(Rec."Customer SystemId") then begin
                            Customer.SetRecFilter();
                            CustomerCard.SetTableView(Customer);
                            CustomerCard.Run();
                        end;
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company''s name.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = all;
                }
                field(State; Rec.State)
                {
                    ApplicationArea = All;
                }
                field("Country/Region"; Rec."Country/Region")
                {
                    ApplicationArea = All;
                }
                field(Zone; Rec.Zone)
                {
                    ApplicationArea = all;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(AddCompany)
            {
                ApplicationArea = All;
                Caption = 'Add Company';
                Image = AddAction;
                ToolTip = 'Select which customers you want to create as companies in Hubspot. Only customers with an e-mail address will be created.';

                trigger OnAction()
                var
                    AddCompanyToHubspot: Report "HS Add Company to Hubspot";
                begin
                    AddCompanyToHubspot.Run();
                end;
            }
            action(Sync)
            {
                ApplicationArea = All;
                Caption = 'Synchronize Companies';
                Image = ImportExport;
                ToolTip = 'Synchronize the companies with Hubspot. The way companies are synchronized depends on the B2B settings in the Hubspot.';

                trigger OnAction()
                var
                    BackgroundSyncs: Codeunit "Hubspot Background Syncs";
                begin
                    BackgroundSyncs.CompanySync();
                end;
                // trigger OnAction()
                // var
                //     CompanySync: Codeunit "HS Sync Companies";
                // begin
                //     CompanySync.Run()
                // end;
            }
        }
        area(Navigation)
        {
            action(CustomerCard)
            {
                ApplicationArea = All;
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
                actionref(AddCompany_Promoted; AddCompany)
                {
                }
                actionref(Sunc_Promoted; Sync)
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
}