tableextension 52103 ExtSaleLine extends "Sales Line"
{
    fields
    {
        // Add changes to table fields here
        field(50000; Duration; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Duration';

            trigger OnValidate()
            var
                ItemCategory_lRec: Record "Item Category";
            begin
                IF (Duration <> '') AND (Rec.Duration <> xRec.Duration) then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                    ItemCategory_lRec.Get(Rec."Item Category Code");
                    ItemCategory_lRec.TestField("Used for License", true);
                end;
            end;
        }
    }
}
