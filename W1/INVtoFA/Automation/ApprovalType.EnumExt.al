namespace TSTChanges.Automation;

using System.Automation;

enumextension 51204 TST_ApprovalDocType extends "Approval Document Type"
{
    value(51200; "Transfer Order")
    {
        Caption = 'Transfer Order';
    }
    value(51201; "FA Conversion Order")
    {
        Caption = 'FA Conversion Order';
    }
    value(51202; "FA Transfer Order")
    {
        Caption = 'FA Transfer Order';
    }
}