page 51306 "HubSpot Contacts"
{
    PageType = List;
    ApplicationArea = Basic;
    UsageCategory = Lists;
    SourceTable = "HubSpot Contact";
    CardPageId = "Hubspot Contact";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = Basic, Sutie;
                    ToolTip = 'Specifies the unique identifier for the company in Hubspot.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies the contact number.';

                    trigger OnDrillDown()
                    var
                        Contact: Record Contact;
                        ContactCard: Page "Contact Card";
                    begin
                        if Contact.GetBySystemId(Rec."Contact SystemId") then begin
                            Contact.SetRecFilter();
                            ContactCard.SetTableView(Contact);
                            ContactCard.Run();
                        end;
                    end;
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s name.';
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact''s name.';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(Sync)
            {
                ApplicationArea = All;
                Caption = 'Synchronize Contacts';
                Image = ImportExport;
                ToolTip = 'Synchronize the contacts with Hubspot. The way contacts are synchronized depends on the B2B settings in the Hubspot.';

                trigger OnAction()
                var
                    BackgroundSyncs: Codeunit "Hubspot Background Syncs";
                begin
                    BackgroundSyncs.ContactSync();
                end;
            }
        }
        area(Navigation)
        {
            action(ContactCard)
            {
                ApplicationArea = All;
                Caption = 'Contact Card';
                Image = ContactPerson;
                ToolTip = 'View or edit detailed information about the Contact.';

                trigger OnAction()
                var
                    Contact: Record Contact;
                begin
                    if Contact.GetBySystemId(Rec."Contact SystemId") then begin
                        Contact.SetRecFilter();
                        Page.Run(Page::"Contact Card", Contact);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
                // actionref(AddCompany_Promoted; AddCompany)
                // {
                // }
                actionref(Sunc_Promoted; Sync)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigation';
                actionref(ContactCard_Promoted; ContactCard)
                {
                }
            }
        }
    }
}