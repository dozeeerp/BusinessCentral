page 52114 "Active License - Update"
{
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "License Request";
    SourceTableTemporary = true;
    Caption = 'Active License - Update';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the address.';
                }
            }
            group("&Contact")
            {
                Group("License To")
                {
                    Caption = 'Contact';
                    field("Contact"; Rec."Contact")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Contact No."; Rec."Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Baisc, Suite;
                    Editable = true;
                }
                // field("KAM Code"; Rec."KAM Code")
                // {
                //     ApplicationArea = Basic, Suite;
                // }
            }
        }
    }

    actions
    {
        // area(Processing)
        // {
        //     action(ActionName)
        //     {
        //         ApplicationArea = All;

        //         trigger OnAction()
        //         begin

        //         end;
        //     }
        // }
    }

    trigger OnOpenPage()
    begin
        xLicenseRequest := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Active License - Edit", Rec);
    end;

    var
        xLicenseRequest: Record "License Request";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged := (Rec."Contact" <> xLicenseRequest."Contact") or
        (rec."Contact No." <> xLicenseRequest."Contact No.") or
        (rec."Salesperson Code" <> xLicenseRequest."Salesperson Code") or
        // (rec."KAM Code" <> xLicenseRequest."KAM Code") or
        (rec."E-Mail" <> xLicenseRequest."E-Mail");
    end;

    procedure SetRec(LicReq: Record "License Request")
    begin
        Rec := LicReq;
        Rec.Insert();
    end;
}