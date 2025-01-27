pageextension 52113 TST_ServMgrRoleCenter extends "Service Dispatcher Role Center"
{
    layout
    {
        // Add changes to page layout here
        addafter(Control1904652008)
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