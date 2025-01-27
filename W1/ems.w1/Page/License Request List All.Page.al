page 52109 "License Request List All"
{
    PageType = List;
    Caption = 'License Request List';
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "License Request";
    Editable = false;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Customer No. field.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Customer Name field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Request Date"; Rec."Request Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Request Date field.';
                }
                field("Release Date"; Rec."Release Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Release Date field.';
                }
                field("Requested By"; Rec."Requested By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requester field.';
                }
                field("Approved BY"; Rec."Approved BY")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Approver field.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.';
                }
                field("Device Type"; Rec."Device Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Device Type field.';
                }
                field("License Type"; Rec."License Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License Type field.';
                }
                field("Invoice Amount"; Rec."Invoice Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice Amount field.';
                }
                field("Invoice Qty"; Rec."Invoice Qty")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice Qty field.';
                }
                field("Invoice Duration"; Rec."Invoice Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice Duration field.';
                }
            }
        }
    }
    actions
    {
        area(navigation)
        {
            Group(License)
            {
                action("View Card")
                {
                    ApplicationArea = All;
                    Image = Card;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Executes the View Card action.';

                    trigger OnAction()
                    var
                        OpenLicensRequest_lPge: Page "License Request";
                        LicenseRequest_lRec: Record "License Request";
                    begin
                        LicenseRequest_lRec.Reset();
                        LicenseRequest_lRec.SetRange("No.", Rec."No.");
                        IF LicenseRequest_lRec.FindFirst() then begin
                            OpenLicensRequest_lPge.SetTableView(LicenseRequest_lRec);
                            IF LicenseRequest_lRec.Status = LicenseRequest_lRec.Status::Active then OpenLicensRequest_lPge.Editable(false);
                            OpenLicensRequest_lPge.RunModal();
                        end;
                    end;
                }
            }
        }
    }
    procedure ReturnSchName(): Code[20]
    begin
        exit(SaveSch);
    end;

    trigger OnClosePage()
    begin
        SaveSch := rec."License No.";
    end;

    var
        SaveSch: Code[20];
}
