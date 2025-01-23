pageextension 52106 ItemLedgerEntries extends "Item Ledger Entries"
{
    layout
    {
        // Add changes to page layout here
        addafter("Item No.")
        {
            field("Customer No."; Rec."Customer No.")
            {
                ApplicationArea = All;
                Editable = False;
                ToolTip = 'Specifies the value of the Customer No. field.';
            }
            field("Customer Name"; Rec."Customer Name")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the name of the customer.';
            }
            field("Demo Location"; rec."Demo Location")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Demo Location field.';
            }
        }
    }
    actions
    {
        addlast(processing)
        {
            // action("Export ILE")
            // {
            //     ApplicationArea = All;
            //     Image = ImportExport;
            //     Caption = 'Export ILE';
            //     Description = 'T37794';
            //     PromotedCategory = Category4;
            //     Promoted = true;

            //     trigger OnAction()
            //     var
            //         ExportILE_lXpt: XmlPort "Export ILE";
            //     begin
            //         Clear(ExportILE_lXpt);
            //         ExportILE_lXpt.Run();
            //     end;
            // }
        }
    }
}
