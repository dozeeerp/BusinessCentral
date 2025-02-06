namespace TST.Hubspot.Company;

using Microsoft.Sales.Customer;

report 51300 "HS Add Company to Hubspot"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Add Company to Hubspot';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
            trigger OnAfterGetRecord()
            begin
                if GuiAllowed then begin
                    CurrCustomerNo := Customer."No.";
                    ProcessDialog.Update();
                end;

                CompanyExport.Run(Customer);
            end;

            trigger OnPreDataItem()
            begin
                Clear(CompanyExport);
                CompanyExport.SetCreateCompanies(true);

                if GuiAllowed then begin
                    CurrCustomerNo := Customer."No.";
                    ProcessDialog.Open(ProcessMsg, CurrCustomerNo);
                    ProcessDialog.Update();
                end;
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then
                    ProcessDialog.Close();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
        }

        actions
        {
        }
    }

    // rendering
    // {
    //     layout(LayoutName)
    //     {
    //         Type = Excel;
    //         LayoutFile = 'mySpreadsheet.xlsx';
    //     }
    // }

    var
        CompanyExport: Codeunit "Hubspot Company Export";
        CurrCustomerNo: Code[20];
        ProcessMsg: Label 'Adding customer #1####################', Comment = '#1 = Customer no.';
        ProcessDialog: Dialog;

}