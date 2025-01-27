pageextension 52112 TST_BusManRoleCenter extends "Business Manager Role Center"
{
    layout
    {
        // Add changes to page layout here
        addafter(Control16)
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