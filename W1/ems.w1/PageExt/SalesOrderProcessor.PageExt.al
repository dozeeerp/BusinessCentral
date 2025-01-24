pageextension 52114 TST_SalesOrderProcessor extends "Order Processor Role Center"
{
    layout
    {
        // Add changes to page layout here
        addafter(Control1901851508)
        {
            part(LicenseRequesr; LicesneCuePage)
            {
                AccessByPermission = TableData LicenseCueTable = I;
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

}