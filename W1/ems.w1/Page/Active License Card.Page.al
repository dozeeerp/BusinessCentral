page 52108 "Active License Card"
{
    PageType = Document;
    Caption = 'Active Licesne';
    InsertAllowed = false;
    PromotedActionCategories = 'New,Process,Report,License,Correct,Print/Send,Navigate';
    RefreshOnActivate = true;
    SourceTable = "License Request";
    Editable = false;
    DataCaptionFields = "License No.";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then;
                        CurrPage.Update;
                    end;
                }
                field("License No."; Rec."License No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License No. field.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then;
                        CurrPage.Update;
                    end;
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
                // field("Ship-to Code"; Rec."Ship-to Code")
                // {
                //     ApplicationArea = All;
                //     ToolTip = 'Specifies the value of the Ship-to Code field.';
                // }
                field("Org ID"; Rec."Organization ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Org ID field.';
                }
                field(Dunning; Rec.Dunning)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dunning field.';
                }
                field("Dunning Type"; Rec."Dunning Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Dunning Type field.';
                }
                field("Delayed Days"; DelayedDays_gInt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Delayed Days field.';
                }
                group("License To")
                {
                    field("Address"; Rec."Address")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Address field.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Address 2 field.';
                    }
                    field("City"; Rec."City")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the City field.';
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Post Code field.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Country Code field.';
                    }
                    field("Contact"; Rec."Contact")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                        ToolTip = 'Specifies the value of the Contact field.';
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                    }
                    field("Contact No."; Rec."Contact No.")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                    }
                    field("Email"; Rec."E-Mail")
                    {
                        ApplicationArea = All;
                        Importance = Additional;
                    }
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Salesperson Code field.';
                }
                field("Salesperson Name"; Rec."Salesperson Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Salesperson Name field.';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Campaign No. field.';
                }
                field("Campaign Name"; Rec."Campaign Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Campaign Name field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
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
                field("Requested Activation Date"; Rec."Requested Activation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Requested Activation Date field.';
                }
                field("Activation Date"; Rec."Activation Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Activation Date field.';
                }
                field("Expiry Date"; Rec."Expiry Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Expiry Date field.';
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
                field("Generated By"; Rec."Generated By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Generated By field.';
                }
                field("Activated By"; Rec."Activated By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Activated By field.';
                }
                field("Partner ID"; Rec."Partner ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Partner ID field.';
                }
                field(Terminated; Rec.Terminated)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Terminated field.';
                }
                field("Terminated Date"; Rec."Terminated Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Terminated Date field.';
                }
                field("Converted from Notice"; Rec."Converted from Notice")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Converted from Notice field.';
                }
                field(Extended; Rec.Extended)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Extended field.';
                }
                field("No of extension issued"; Rec."No of extension issued")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the No of extension issued field.';

                    trigger OnDrillDown()
                    var
                        LicenReq_lRec: Record "License Request";
                        LiceReqAll_lPge: Page "License Request List All";
                    begin
                        LicenReq_lRec.Reset();
                        LicenReq_lRec.SetRange("Original Extension Of", Rec."License No.");
                        LiceReqAll_lPge.SetTableView(LicenReq_lRec);
                        LiceReqAll_lPge.Editable(false);
                        LiceReqAll_lPge.RunModal();
                    end;
                }
                field(Renewed; Rec.Renewed)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Renewed field.';
                }
                field("No of devices assigned"; Rec."No of devices assigned")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the No of devices assigned field.';
                }
                // field("Doner ID"; Rec."Doner ID")
                // {
                //     ApplicationArea = All;
                // }
            }
            group(License)
            {
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
                field("License Code"; Rec."License Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License Code field.';
                }
                field("License Type"; Rec."License Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License Type field.';
                }
                field("License Qty."; Rec."License Qty.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Device Covered under license field.';
                }
                field("Total Devices."; Rec."Total Devices")
                {
                    ApplicationArea = All;
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Duration field.';

                    trigger OnValidate()
                    var
                    //LicenseRequest: Record "License Request";
                    begin
                        // IF Rec."Document Type" = Rec."Document Type"::New Then begin
                        //     IF Rec."Requested Activation Date" <> 0D Then Begin
                        //         Rec."Activation Date" := Rec."Requested Activation Date";
                        //         Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date")
                        //     End else begin
                        //         Rec."Activation Date" := Today;
                        //         Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date");
                        //     end;
                        // end;
                        // IF Rec."Document Type" = Rec."Document Type"::"Add on" Then begin
                        //     IF Rec."Requested Activation Date" <> 0D Then Begin
                        //         Rec."Activation Date" := Rec."Requested Activation Date";
                        //         Clear(LicenseRequest);
                        //         IF LicenseRequest.Get(Rec."Parent Add on Of") then
                        //             Rec."Expiry Date" := LicenseRequest."Expiry Date";
                        //     End else begin
                        //         Rec."Activation Date" := Today;
                        //         Rec."Expiry Date" := CALCDATE(Rec.duration, Rec."Activation Date");
                        //     end;
                        // end;
                    end;
                }
            }
            group(Invoice)
            {
                field("Invoice No"; Rec."Invoice No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Invoice No field.';
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
                field("License Value"; Rec."License Value")
                {
                    ApplicationArea = All;
                }
            }
            // part("Licence TypeDefa Fecture"; "Licence TypeDefa Fecture")
            // {
            //     ApplicationArea = All;
            //     SubPageLink = "License Request No." = field("No."), "License Type" = field("License Type");
            //     Editable = Rec.Status = Rec.Status::Open;
            // }
            group(Others)
            {
                group(Extension)
                {
                    Editable = false;

                    field("Original Extension Of"; Rec."Original Extension Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Original Extension Of field.';
                    }
                    field("Parent Extension Of"; Rec."Parent Extension Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Parent Extension Of field.';
                    }
                }
                group(Renewal)
                {
                    Editable = false;

                    field("Original Renewal Of"; Rec."Original Renewal Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Original Renewal Of field.';
                    }
                    field("Parent Renewal Of"; Rec."Parent Renewal Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Parent Renewal Of field.';
                    }
                }
                group("Add On")
                {
                    Editable = false;

                    field("Original Add on Of"; Rec."Original Add on Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Original Add on Of field.';
                    }
                    field("Parent Add on Of"; Rec."Parent Add on Of")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Parent Add on Of field.';
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Customer)
            {
                ApplicationArea = All;
                ToolTip = 'Executes the Customer action.';

                trigger OnAction()
                var
                    Customer: Record Customer;
                begin
                    Clear(Customer);
                    If Customer.get(Rec."Customer No.") then Page.Run(21, Customer);
                end;
            }
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Enabled = Rec."No." <> '';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    Rec.ShowDocDim;
                    CurrPage.SaveRecord;
                end;
            }
            action(Devices)
            {
                ApplicationArea = All;
                Caption = 'Devices';
                ToolTip = 'Executes the Devices action.';

                trigger OnAction()
                var
                    SinCodeeunit: Codeunit EMS_SinCodeeunit;
                    Devicelinked: Record "Dozee Device";
                begin
                    SinCodeeunit.InsertValue(Rec."No.");
                    Devicelinked.Reset();
                    Devicelinked.SetRange("Customer No.", Rec."Customer No.");
                    IF Devicelinked.FindFirst() Then Page.Run(Page::"Dozee Devices", Devicelinked);
                end;
            }
            action("Issue Extension")
            {
                ApplicationArea = All;
                Image = ExtendedDataEntry;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = EnableAction_l;
                ToolTip = 'Executes the Issue Extension action.';

                trigger OnAction()
                begin
                    // LicenseRequest.Reset();
                    // LicenseRequest.SetRange(Status, LicenseRequest.Status::Open);
                    // LicenseRequest.setfilter("License Type", '%1|%2', LicenseRequest."License Type"::Demo, LicenseRequest."License Type"::Notice);
                    // LicenseList.SetTableView(LicenseRequest);
                    // LicenseList.LookupMode := true;
                    // IF LicenseList.RunModal() = Action::RunObject then
                    //     SinCodeunit.InsertValue(Rec."License No.");
                    rec.Testfield(Extended, false);
                    Clear(ActiveLicMgt_gCdu);
                    ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Extension");
                end;
            }
            action("Issue Renewal")
            {
                ApplicationArea = All;
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = NOT Rec.Renewed;
                ToolTip = 'Executes the Issue Renewal action.';

                trigger OnAction()
                begin
                    // LicenseRequest.Reset();
                    // LicenseRequest.SetRange(Status, LicenseRequest.Status::Open);
                    // LicenseRequest.setfilter("License Type", '%1', LicenseRequest."License Type"::Commercial);
                    // LicenseList.SetTableView(LicenseRequest);
                    // LicenseList.LookupMode := true;
                    // IF LicenseList.RunModal() = Action::LookupOK then
                    //     Rec."Renewal Of" := LicenseList.ReturnSchName();
                    Rec.TestField(Renewed, false);
                    Clear(ActiveLicMgt_gCdu);
                    ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Renewal");
                end;
            }
            action("Issue Add On")
            {
                ApplicationArea = All;
                Image = Add;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Executes the Issue Add On action.';

                trigger OnAction()
                begin
                    // LicenseRequest.Reset();
                    // LicenseRequest.SetRange(Status, LicenseRequest.Status::Open);
                    // LicenseRequest.setfilter("License Type", '%1', LicenseRequest."License Type"::Commercial);
                    // LicenseList.SetTableView(LicenseRequest);
                    // LicenseList.LookupMode := true;
                    // IF LicenseList.RunModal() = Action::LookupOK then
                    //     Rec."Renewal Of" := LicenseList.ReturnSchName();
                    ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Add On");
                end;
            }
            action("Terminate")
            {
                ApplicationArea = All;
                Image = TerminationDescription;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Executes the Terminate action.';

                trigger OnAction()
                begin
                    IF not Confirm('Do you want to terminate Active License: %1?', true, Rec."No.") then exit;
                    Clear(ActiveLicMgt_gCdu);
                    ActiveLicMgt_gCdu.TerminateLicenseRequest(Rec."No.");
                end;
            }
            // action("Convert to Commercial")
            // {
            //     ApplicationArea = All;
            //     Image = Card;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     ToolTip = 'Executes the Convert to Commercial action.';
            //     trigger OnAction()
            //     begin
            //         ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Convert to Commercial");
            //     end;
            // }
            // action("Issue Notice")
            // {
            //     ApplicationArea = All;
            //     Image = Card;
            //     Promoted = true;
            //     PromotedCategory = Process;
            //     PromotedIsBig = true;
            //     ToolTip = 'Executes the Issue Notice action.';
            //     trigger OnAction()
            //     begin
            //         ActiveLicMgt_gCdu.CreateActiveLicenseCard(Rec."No.", Action_gOpt::"Issue Notice");
            //     end;
            // }
        }
    }
    trigger OnOpenPage()
    begin
        EnableAction1;
        DelayedDays_gInt := 0;
    end;

    trigger OnAfterGetRecord()
    begin
        EnableAction1;
        CalcDelayedDays;
    end;

    procedure EnableAction1()
    begin
        IF (Rec."License Type" = Rec."License Type"::Demo) AND (NOT Rec.Extended) Then
            EnableAction_l := true
        else
            EnableAction_l := false;
    end;

    local procedure CalcDelayedDays()
    var
        SalesInvoice_lRec: Record "Sales Invoice Header";
    begin
        DelayedDays_gInt := 0;
        If Rec."Invoice No" <> '' then begin
            SalesInvoice_lRec.get(Rec."Invoice No");
            IF (Today - SalesInvoice_lRec."Due Date") > 0 then DelayedDays_gInt := Today - SalesInvoice_lRec."Due Date";
        end;
    end;

    var
        EnableAction_l: boolean;
        ActiveLicMgt_gCdu: Codeunit "Active License Mgt.";
        Action_gOpt: Option "Issue Extension","Issue Renewal","Issue Add On","Convert to Commercial","Issue Notice";
        DelayedDays_gInt: Integer;
}
