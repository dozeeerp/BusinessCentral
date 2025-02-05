namespace TSTChanges.FA.Setup;

using Microsoft.Foundation.AuditCodes;

pageextension 51200 TST_SourceCodeSetup extends "Source Code Setup"
{
    layout
    {
        // Add changes to page layout here
        addlast(Inventory)
        {
            field("FA Conversion"; Rec."FA Conversion")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the code that is linked to entries that are posted with FA conversion orders.';
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