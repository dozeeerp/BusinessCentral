pageextension 51306 "HS Order Processor" extends "Order Processor Role Center"
{
    layout
    {
        // Add changes to page layout here
        addafter(Control1901851508)
        {
            part(HubSpotActivities; "Hubspot Activities")
            {
                ApplicationArea = ALL;
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