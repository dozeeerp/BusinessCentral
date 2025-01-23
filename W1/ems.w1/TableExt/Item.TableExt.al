tableextension 52101 ExtItem extends Item
{
    fields
    {
        // Add changes to table fields here
        field(50000; "Devices Item"; Boolean)
        {
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                ItemTracking_LRec: Record "Item Tracking Code";
            begin
                IF "Devices Item" then begin
                    TestField("Item Tracking Code");
                    ItemTracking_LRec.Get("Item Tracking Code");
                    ItemTracking_LRec.TestField("SN Specific Tracking", true);
                end;
            end;
        }
        field(50001; "Item Flag"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
}
