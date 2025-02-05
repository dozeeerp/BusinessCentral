page 51307 "Hubspot Contact"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    UsageCategory = None;
    SourceTable = "HubSpot Contact";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Editable = false;
                field(Id; Rec.Id)
                {
                    ApplicationArea = Bsic, Suite;
                    ToolTip = 'Specifies the unique identifier for the company in Hubspot.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                group(Communication)
                {
                    field("Financial Comm"; Rec."Financial Comm")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
            }
            group(Mapping)
            {
                Caption = 'Mapping';
                Editable = false;
                field(ContactNo; ContactNo)
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnValidate()
                    begin
                        if ContactNo <> '' then begin
                            Contact.Get(ContactNo);
                            Rec."Contact SystemId" := Contact.SystemId;
                            GetMappedContact();
                        end;
                    end;

                    trigger OnAssistEdit()
                    var
                        ContactList: page "Contact List";
                    begin
                        ContactList.LookupMode := true;
                        ContactList.SetRecord(Contact);
                        if ContactList.RunModal() = Action::LookupOK then begin
                            ContactList.GetRecord(Contact);
                            Rec."Contact SystemId" := Contact.SystemId;
                            ContactNo := Contact."No.";
                            Rec.Modify();
                        end;
                    end;
                }

                field(Name; Contact.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ContactCard)
            {
                ApplicationArea = Basic, Suite;
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
        area(Processing)
        {
            action(CreateContact)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Contact';
                Image = AddContacts;
                ToolTip = 'Create Contact from hubspot company';

                trigger OnAction()
                var
                    UpdateContact: Codeunit "Hubspot Update Contact";
                begin
                    if not IsNullGuid(Rec."Contact SystemId") then
                        Error('Contact mapping exist with %1', ContactNo);

                    UpdateContact.CreateContactFromContact(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetMappedContact();
    end;

    var
        Contact: Record Contact;
        ContactNo: Code[20];

    local procedure GetMappedContact()
    begin
        if IsNullGuid(Rec."Contact SystemId") then begin
            Clear(Contact);
            Clear(ContactNo);
        end else
            if Contact.GetBySystemId(Rec."Contact SystemId") then
                ContactNo := Contact."No."
            else begin
                Clear(Contact);
                Clear(ContactNo);
            end;
    end;

}