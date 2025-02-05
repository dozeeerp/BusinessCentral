namespace TSTChanges.FA.Setup;

using Microsoft.Foundation.AuditCodes;

tableextension 51200 TST_SourceCodeSetup extends "Source Code Setup"
{
    fields
    {
        // Add changes to table fields here
        field(51200; "FA Conversion"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'FA Conversion';
            TableRelation = "Source Code";
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}