namespace TST.Hubspot.Setup;

using Microsoft.Inventory.Location;
using TST.Hubspot.Company;

page 51300 "Hubspot Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Hubspot Setup";

    layout
    {
        area(Content)
        {
            group(general)
            {
                Caption = 'General';
                field("Base Url"; Rec."Base Url")
                {
                    ApplicationArea = All;
                }
                field("Access Token"; Rec."Access Token")
                {
                    ApplicationArea = All;
                }
                field("Business Unit"; Rec."Business Unit")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Business Unit';
                    ToolTip = 'Specifies the business unit from HubSpot, the data to be syncronized for, (leave blank for sync all records.)';
                }
            }
            group(location)
            {
                Caption = 'Location';
                field("Default Warehouse"; Rec."Default Warehouse")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Warehouse';
                    TableRelation = Location;
                    ToolTip = 'Specifies the default warehouse from which the items will be shipped or get back to.';
                }
                field("Demo Location"; Rec."Demo Location")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Demo Location';
                    TableRelation = Location;
                    ToolTip = 'Specifies the location of the items when they are sent for demo via transfer order.';
                }
                field("Rental Location"; Rec."Rental Location")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rental Location';
                    TableRelation = Location;
                    ToolTip = 'Specifies the locaiton of the items when they are sent for reantal via transfer order.';
                }
                field("Employee Location"; Rec."Employee Location")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Location';
                    TableRelation = Location;
                    ToolTip = 'Specifies the locaiton of the items when they are sent to employee via transfer order.';
                }
            }
            group(Association)
            {
                field("AssociationID Ticket to Device"; Rec."AssociationID Ticket to Device")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'AssociatioinID Ticket to Device';
                    ToolTip = 'Specifies the Associatioin ID from Tcket to Device.';
                }
            }
            group(Sync)
            {
                field("Last Sync Time"; Rec."Last Sync Time")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Company Import From Hubspot"; Rec."Company Import From Hubspot")
                {
                    ApplicationArea = All;
                }
                field("Create Cutomer"; Rec."Create Cutomer")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if how the custmomer should be created from hubspot companies.';
                }
                field("Can Update Hubspot Companies"; Rec."Can Update Hubspot Companies")
                {
                    ApplicationArea = All;
                }
                field("Hubspot Can Update Companies"; Rec."Hubspot Can Update Companies")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Companies)
            {
                ApplicationArea = All;
                Caption = 'Companies';
                Image = Company;
                RunObject = Page "Hubspot Companies";
                ToolTip = 'Add, view or edit detailed information for the companies.';
            }
        }
        area(Processing)
        {
            group("$Sync")
            {
                Caption = 'Sync';
                action(SyncCompanies)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Companies';
                    Image = ImportExport;
                    ToolTip = 'Synchronize the companies with HubSpot. The way companies are synchronized depends on the settings in the Hubspot Card.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Hubspot Background Syncs";
                    begin
                        BackgroundSyncs.CompanySync();
                    end;
                }
                action(SyncAll)
                {
                    ApplicationArea = All;
                    Caption = 'Sync All';
                    Image = ImportExport;
                    ToolTip = 'Execute all synchronizations (Products, Product images, Inventory, Customers and payouts) in batch.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Hubspot Background Syncs";
                    begin
                        // BackgroundSyncs.CustomerSync(Rec);
                        // BackgroundSyncs.ProductsSync(Rec);
                        // BackgroundSyncs.InventorySync(Rec);
                        // BackgroundSyncs.ProductImagesSync(Rec, '');
                        // BackgroundSyncs.ProductPricesSync(Rec);
                        // if Rec."B2B Enabled" then begin
                        BackgroundSyncs.CompanySync();
                        //     BackgroundSyncs.CatalogPricesSync(Rec, '');
                        // end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Companies_Promoted; Companies)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Syncronization';
                actionref(SuncCompanies_Promoted; SyncCompanies)
                {
                }
                actionref(SyncAll_Promoted; SyncAll)
                {
                }
            }
        }
    }

    var
        myInt: Integer;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}