page 52105 "Dozee Device"
{
    PageType = Card;
    UsageCategory = None;
    SourceTable = "Dozee Device";
    DataCaptionFields = "Serial No.";
    Caption = 'Dozee Device';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Serial No. field.';
                }
                field("Item No"; Rec."Item No")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the Item no (SKU)';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Item Description field.';
                }
                field(Variant; Rec.Variant)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Variant field.';
                }
            }
            group(GroupName)
            {
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Source Type field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the value of the Source No. field.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Customer Name field.';
                }
                field("Partner No."; Rec."Partner No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Partner No. field.';
                }
                field("Org ID"; Rec."Org ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Caption = 'Organisation ID';
                    ToolTip = 'Specifies the value of the Org ID field.';
                }
                field("Device ID"; Rec."Device ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID used by sanes.';
                    Editable = false;
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Installation Date field.';
                }
                field("Warranty Start Date"; Rec."Warranty Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Warranty Start Date';
                    ToolTip = 'Specifies the device warranty start date.';
                }
                field("Warranty End Date"; Rec."Warranty End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Warranty End Date field.';
                }
                field(Return; Rec.Return)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not rec.Licensed;
                    ToolTip = 'The device is returned to Warehouse.';
                }
            }
            group(License)
            {
                Caption = 'License';
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the License No. field.';
                }
                field("Activation Date"; Rec."Activation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Activation Date field.';
                }
                field("Expiry Date"; Rec."Expiry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Expiry Date field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Change Customer")
            {
                ApplicationArea = All;
                Image = Customer;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not rec.Licensed;
                ToolTip = 'Change the customer of the device from partner to customer';

                trigger OnAction()
                var
                    Customer: Record Customer;
                    PartnerNo: Code[20];
                begin
                    Customer.Reset();
                    if Customer.Get(rec."Customer No.") then
                        if not Customer."Is Partner" then
                            Error('Change of customer is only allowed from partner to customer. "%1" is not a partner.', Customer.Name);
                    PartnerNo := Customer."No.";

                    Clear(Customer);
                    Customer.SetRange("Partner ID", PartnerNo);
                    if Page.RunModal(Page::"Customer List", Customer) = Action::LookupOK then begin
                        rec."Customer No." := Customer."No.";
                        rec."Customer Name" := customer.Name;
                        Rec."Partner No." := PartnerNo;
                        Rec.Modify();
                        Message('Customer is changed for device %1 to %2', Rec."Serial No.", rec."Customer Name");
                    end;
                    CurrPage.Close();
                end;
            }
            action("Return to Partner")
            {
                ApplicationArea = All;
                Image = Customer;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not rec.Licensed;
                ToolTip = 'Change the device from customer to partner.';

                trigger OnAction()
                var
                    Customer: Record Customer;
                begin
                    Customer.Reset();
                    if Customer.Get(rec."Customer No.") then
                        if Customer."Partner ID" = '' then
                            Error('Return to partner is only allowed from customer to partner. "%1" is not managed by partner.', Customer.Name);
                    Clear(Customer);
                    Customer.SetRange("No.", rec."Partner No.");
                    if Page.RunModal(Page::"Customer List", Customer) = Action::LookupOK then begin
                        rec."Customer No." := Customer."No.";
                        rec."Customer Name" := Customer.Name;
                        rec."Partner No." := '';
                        rec.Modify();
                        Message('Customer is changed for device %1 to %2', Rec."Serial No.", rec."Customer Name");
                    end;
                    CurrPage.Close();
                end;
            }
            action("Update Variant")
            {
                Caption = 'Update Variant';
                ToolTip = 'Updates Model SKU tag on platfrom.';
                ApplicationArea = All;
                image = Action;

                trigger OnAction()
                var
                    EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
                begin
                    EMSAPIMgt_lCdu.SendDeviceVariant(Rec);
                end;
            }
            action("Update Device ID")
            {
                Caption = 'Update Device ID';
                ToolTip = 'Updates device id of the selected device.';
                ApplicationArea = All;
                image = Action;

                trigger OnAction()
                var
                    EMSAPIMgt_lCdu: Codeunit "EMS API Mgt";
                begin
                    EMSAPIMgt_lCdu.GetDeviceLicenseId(rec);
                end;
            }
        }
    }
}
