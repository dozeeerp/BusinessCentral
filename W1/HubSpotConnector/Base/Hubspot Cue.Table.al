table 51304 "Hubspot Cue"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Open Quote"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const("Sales Document Type"::Quote),
                                                    Status = const("Sales Document Status"::Open),
                                                    HS_ID = filter(<> 0)));
            FieldClass = FlowField;
        }
        field(3; "Released Quote"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const("Sales Document Type"::Quote),
                                                    Status = const("Sales Document Status"::Released),
                                                    HS_ID = filter(<> 0)));
            FieldClass = FlowField;
        }
        field(4; "Unprocessed TR Orders"; Integer)
        {
            CalcFormula = count("Transfer Header" where(HS_ID = filter(<> 0)));
            FieldClass = FlowField;
        }
        field(5; "Unprocessed FA TR Orders"; Integer)
        {
            CalcFormula = count("FA Transfer Header" where(HS_ID = filter(<> 0)));
            FieldClass = FlowField;
        }
        field(6; "Unmapped Companies"; Integer)
        {
            CalcFormula = count("Hubspot Company" where("Customer No." = const('')));
            FieldClass = FlowField;
        }
        field(7; "Synchronization Errors"; Integer)
        {
            CalcFormula = count("Job Queue Log Entry" where(Status = const(Error),
                                                            "Object Type to Run" = filter('Report | Codeunit'),
                                                            "Object ID to Run" = filter(
                                                                // Report::"Shpfy Sync Orders from Shopify"|
                                                                // Report::"Shpfy Sync Shipm. to Shopify" |
                                                                // Report::"Shpfy Sync Products" |
                                                                // Report::"Shpfy Sync Stock to Shopify" |
                                                                // Report::"Shpfy Sync Images" |
                                                                // Report::"Shpfy Sync Payments" |
                                                                // Report::"Shpfy Sync Companies" |
                                                                // Report::"Shpfy Sync Catalogs" |
                                                                // Report::"Shpfy Sync Catalog Prices"
                                                                Codeunit::"HS Sync Companies" |
                                                                Codeunit::"Hubspot Sync Contacts"
                                                                )));
            Caption = 'Synchronization Errors';
            FieldClass = FlowField;
        }

    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }
    var
        a: Enum "Sales Document Type";
}