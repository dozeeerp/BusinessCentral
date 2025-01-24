table 52101 "License Request"
{
    DataClassification = CustomerContent;
    LookupPageId = "License Requests";
    DrillDownPageId = "License Requests";

    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetEmsSetup();
                    NoSeries.TestManual(EmsSetup."License Request Nos.");
                end;
            end;
        }
        field(2; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Customer No.';
            TableRelation = Customer;
            NotBlank = true;

            trigger OnValidate()
            begin
                if "No." = '' then
                    InitRecord();
                TestStatusOpen();
                if ("Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then begin
                    if GetHideValidationDialog() or not GuiAllowed() then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, LICToCustomerTxt);
                    if Confirmed then begin
                        // LicTypeDefFeature.SetRange("License Request No.", "No.");
                        if "Customer No." = '' then begin
                            //     if LicTypeDefFeature.FindFirst then
                            //         Error(
                            //           Text005,
                            //           FieldCaption("Lic-to Customer No."));
                            //     Init();
                            //     //             OnValidateSellToCustomerNoAfterInit(Rec, xRec);
                            //     SalesSetupRec.Get();
                            //     "Req No.Series" := xRec."Req No.Series";
                            //     // InitRecord;
                            //     // InitNoSeries;
                            //     exit;
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;
                GetCust("Customer No.");
                Customer.CheckBlockedCustOnDocs(Customer, "Document Type", false, false);
                Customer.TestField("Organization ID");
                CopyLICToCustomerAddressFieldsFromCustomer(Customer);
                if not SkipLICToContact then
                    UpdateLICToCont("Customer No.");
                CreateDimFromDefaultDim(FieldNo("Customer No."));
            end;
        }
        field(3; "Customer Name"; Text[100])
        {
            DataClassification = CustomerContent;
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
            Caption = 'Customer Name';
            trigger OnLookup()
            var
                CustomerName: Text;
            begin
                CustomerName := "Customer Name";
                LookupCustomerName(CustomerName);
                "Customer Name" := CopyStr(CustomerName, 1, MaxStrLen("Customer Name"));
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
                LookupStateManager: Codeunit "Lookup State Manager";
            begin
                if LookupStateManager.IsRecordSaved() then begin
                    Customer := LookupStateManager.GetSavedRecord();
                    if Customer."No." <> '' then begin
                        LookupStateManager.ClearSavedRecord();
                        Validate("Customer No.", Customer."No.");
                    end;
                end;
                if ShouldSearchForCustomerByName("Customer No.") then Validate("Customer No.", Customer.GetCustNo("Customer Name"));
            end;
        }
        field(4; "Customer Name 2"; Text[50])
        {
            Caption = 'Customer Name 2';
        }
        field(5; "Organization ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Organization ID';
            Editable = false;
        }
        field(6; "Address"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Address';
            Editable = false;
        }
        field(7; "Address 2"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Address 2';
            Editable = false;
        }
        field(8; "City"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'City';
            Editable = false;
        }
        field(9; "Post Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Post Code';
            Editable = false;
        }
        field(10; "Country/Region Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Country Code';
            Editable = false;
        }
        field(11; Contact; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Contact';
            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                Contact.FilterGroup(2);
                LookupContact("Customer No.", "Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                if "Contact" = '' then
                    Validate("Contact No.", '');
            end;
        }
        field(12; "County"; Text[30])
        {
            CaptionClass = '5,2,' + "Country/Region Code";
            Caption = 'County';
        }
        field(13; "Salesperson Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Salesperson Code';
            Editable = false;
        }
        field(14; "Salesperson Name"; Text[50])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Salesperson/Purchaser".Name where(Code = field("Salesperson Code")));
            Caption = 'Salesperson Name';
            Editable = false;
        }
        field(15; "Campaign No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(FieldNo("Campaign No."));
            end;
        }
        field(16; "Campaign Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup(Campaign.Description where("No." = field("Campaign No.")));
            Caption = 'Campaign Name';
            Editable = false;
        }
        field(17; "Request Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Request Date';
        }
        field(18; "Release Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Release Date';
            Editable = false;
        }
        field(19; "Expiry Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Expiry Date';
        }
        field(20; "Activation Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Activation Date';

            trigger OnValidate()
            begin
                //T29353-NS
                IF ("Activation Date" <> 0D) AND ("Activation Date" < Today) THen Rec.FieldError("Activation Date", 'cannot be less than Current Date');
                //T29353-NE
                // If "Activation Date" <> xRec."Activation Date" then CalcualteDates();
            end;
        }
        field(21; "Requested Activation Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Requested Activation Date';

            trigger OnValidate()
            begin
                IF "Requested Activation Date" <> xRec."Requested Activation Date" then begin
                    IF "Document Type" in ["Document Type"::"Add on", "Document Type"::New] then begin
                        IF "Requested Activation Date" <> 0D then Validate("Activation Date", "Requested Activation Date");
                    end;
                end;
            end;
        }
        field(22; "Requested By"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Requester';
            TableRelation = Employee;
        }
        field(23; "Approved BY"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Approver';
        }
        field(24; "Generated By"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Generated By';
            Editable = false;
        }
        field(25; "Activated By"; Option)
        {
            OptionMembers = Dozee,Customer;
            Caption = 'Activated By';
        }
        field(26; "Original Extension Of"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Original Extension Of';
        }
        field(27; "Original Renewal Of"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Original Renewal Of';
        }
        field(28; "Original Add on Of"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Original Add on Of';
        }
        field(29; "Partner ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Partner ID';
        }
        field(30; "Document Type"; Enum "Document Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Document Type';
        }
        field(31; "Device Type"; Enum "Device Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Device Type';
        }
        field(32; "License Type"; Enum "License Type")
        {
            Caption = 'License Type';
        }
        field(33; "License Qty."; Integer)
        {
            Caption = 'Device Covered under license';
        }
        field(34; "Duration"; Code[10])
        {
            Caption = 'Duration';

            trigger OnValidate()
            begin
                // if Duration <> xRec.Duration then CalcualteDates();
            end;
        }
        field(35; "Invoice No"; Code[20])
        {
            Caption = 'Invoice No';
        }
        field(37; "Invoice Amount"; Decimal)
        {
            Caption = 'Invoice Amount';
        }
        field(38; "Invoice Qty"; Decimal)
        {
            Caption = 'Invoice Qty';
        }
        field(39; "Invoice Duration"; Code[10])
        {
            Caption = 'Invoice Duration';
        }
        field(40; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(41; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1), Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(42; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2), Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(43; Terminated; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Terminated';
        }
        field(44; "Terminated Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Terminated Date';
        }
        field(45; "Converted from Notice"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Converted from Notice';
        }
        field(46; Extended; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Extended';
        }
        field(47; "No of extension issued"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("License Request" where("Original Extension Of" = field("License No.")));
            Editable = false;
        }
        field(48; Renewed; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Renewed';
        }
        field(49; "License Code"; Code[20])
        {
            TableRelation = "License Type";

            trigger OnValidate()
            var
                LicType_lRec: Record "License Type";
            begin
                CLEAR(LicType_lRec);
                IF LicType_lRec.Get("License Code") then begin
                    LicType_lRec.TestField("License Type");
                    Validate("License Type", LicType_lRec."License Type");
                    "Pre-paid" := LicType_lRec."Pre-paid";
                end
                Else
                    "Pre-paid" := false;
            end;
        }
        field(50; "No of devices assigned"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Dozee Device" where("License No." = field("License No."), Licensed = const(true), Return = const(false)));
            Editable = false;
        }

        field(60; "Parent Extension Of"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Extension Of';
        }
        field(61; "Parent Renewal Of"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Renewal Of';
        }
        field(62; "Parent Add on Of"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Add on Of';
        }




        field(70; "No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            Caption = 'No. Series';
        }
        field(71; "Active No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Active No. Series';
            TableRelation = "No. Series";
        }
        field(72; "License No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'License No.';
        }
        field(73; "Renewal/Ext Lic No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Renewal/Ext Lic No.';
        }



        field(90; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(91; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';

            trigger OnLookup()
            begin
                LictoContactLookup();
            end;
        }
        field(92; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(93; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "E-Mail" = '' then exit;
                MailManagement.CheckValidEmailAddresses("E-Mail");
            end;
        }
        field(95; "Total Devices"; Integer)
        {
            FieldClass = FlowField;
            Caption = 'Total Devices';
            CalcFormula = count("Dozee Device" where("Customer No." = field("Customer No."), Return = const(false)));
        }
        field(96; "License Value"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(97; "Pre-paid"; Boolean)
        {
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(98; Dunning; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(99; "Dunning Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = " ",Expiry,"Invoice Due Date";
        }
        field(100; Status; enum "EMS Staus")
        {
            DataClassification = CustomerContent;
        }
        field(102; "Duration In Day"; Integer)
        {
            Editable = false;
        }
        field(103; "Old Expiry Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Old Expiry Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "License No.")
        {
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin
        InitInsert();
        if Dunning then begin
            Dunning := false;
            "Dunning Type" := "Dunning Type"::" ";
        end;
        "Renewal/Ext Lic No." := '';
        if "Request Date" = 0D then
            "Request Date" := WorkDate();
        SetView('');
    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    var
        MicApprovalsMgt: Codeunit "Approvals Mgmt.";
        LicReq2: record "License Request";
    begin
        if "Document Type" in ["Document Type"::Renewal, "Document Type"::Extension] then begin
            LicReq2.Reset();
            LicReq2.SetCurrentKey("License No.");
            case "Document Type" of
                "Document Type"::Renewal:
                    begin
                        LicReq2.SetRange("License No.", rec."Parent Renewal Of");
                        if LicReq2.FindFirst() then
                            LicReq2.Renewed := false;
                    end;
                "Document Type"::Extension:
                    begin
                        LicReq2.SetRange("License No.", rec."Parent Extension Of");
                        if LicReq2.FindFirst() then
                            LicReq2.Extended := false;
                    end;
            end;
        end;
        MicApprovalsMgt.OnDeleteRecordInApprovalRequest(rec.RecordId);
    end;

    trigger OnRename()
    begin

    end;

    var
        NoSeries: Codeunit "No. Series";
        Salesperson: Record "Salesperson/Purchaser";
        PostCode: Record "Post Code";
        DimMgt: Codeunit DimensionManagement;
        LicenseRequest: Record "License Request";
        DoYouWantToKeepExistingDimensionsQst: Label 'This will change the dimension specified on the document. Do you want to recalculate/update dimensions?';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        LICToCustomerTxt: Label 'Customer Name';
        ConfirmEmptyEmailQst: Label 'Contact %1 has no email address specified. The value in the Email field on the sales order, %2, will be deleted. Do you want to continue?', Comment = '%1 - Contact No., %2 - Email';
        Text037: Label 'Contact %1 %2 is not related to customer %3.';
        Text053: Label 'You must cancel the approval process if you wish to change the %1.';
        ContactIsNotRelatedToAnyCostomerErr: Label 'Contact %1 %2 is not related to a customer.';
        Confirmed: Boolean;

    protected var
        Customer: Record Customer;
        EmsSetup: Record "EMS Setup";
        StatusCheckSuspended: Boolean;
        HideValidationDialog: Boolean;
        SkipLICToContact: Boolean;

    local procedure InitInsert()
    var
        LicenseRequest2: Record "License Request";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GetEmsSetup();
            "No. Series" := EmsSetup."License Request Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series", WorkDate());
            LicenseRequest2.ReadIsolation(IsolationLevel::ReadUncommitted);
            LicenseRequest2.SetLoadFields("No.");
            while LicenseRequest2.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series", WorkDate());
        end;
    end;

    local procedure InitRecord()
    begin
        GetEmsSetup();
    end;

    procedure AssistEdit(OldLicenseRequest: Record "License Request"): Boolean
    begin
        LicenseRequest.Copy(Rec);
        GetEmsSetup();
        if NoSeries.LookupRelatedNoSeries(EmsSetup."License Request Nos.", OldLicenseRequest."No. Series", LicenseRequest."No. Series") then begin
            LicenseRequest."No." := NoSeries.GetNextNo(LicenseRequest."No. Series");
            Rec := LicenseRequest;
            exit(true);
        end;
    end;

    local procedure GetEmsSetup()
    begin
        EmsSetup.Get();
        EmsSetup.TestField("License Request Nos.");
        EmsSetup.TestField("License Nos.");
    end;

    procedure GetCust(CustNo: Code[20]): Record Customer
    begin
        OnBeforeGetCust(Rec, Customer, CustNo);

        if //not (("Document Type" = "Document Type"::Quote) and 
        not (CustNo = '')//)
         then begin
            if CustNo <> Customer."No." then
                Customer.Get(CustNo);
        end else
            Clear(Customer);

        exit(Customer);
    end;

    internal procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        TestField(Status, Status::Open);
    end;

    local procedure CopyLICToCustomerAddressFieldsFromCustomer(var LICToCustomer: Record Customer)
    begin
        "Customer Name" := Customer.Name;
        "Customer Name 2" := Customer."Name 2";
        "Phone No." := Customer."Phone No.";
        "E-Mail" := Customer."E-Mail";
        "Organization ID" := LICToCustomer."Organization ID";
        "Partner ID" := LICToCustomer."Partner ID";
        if LICToCustomerIsReplaced() or
            ShouldCopyAddressFromCustomer(LICToCustomer) or
            (HasDifferentLICToAddress(LICToCustomer) and LICToCustomer.HasAddress())
        then begin
            "Address" := LICToCustomer.Address;
            "Address 2" := LICToCustomer."Address 2";
            "City" := LICToCustomer.City;
            "Post Code" := LICToCustomer."Post Code";
            "Country/Region Code" := LICToCustomer."Country/Region Code";
            County := LICToCustomer.County;
        end;
        if not SkipLICToContact then
            "Contact" := LICToCustomer.Contact;
        "Salesperson Code" := LICToCustomer."Salesperson Code";
        // Validate("KAM Code", LICToCustomer."KAM Code");
    end;

    local procedure LICToCustomerIsReplaced(): Boolean
    begin
        exit((xRec."Customer No." <> '') and (xRec."Customer No." <> "Customer No."));
    end;

    local procedure ShouldCopyAddressFromCustomer(Customer: Record Customer): Boolean
    begin
        exit((not HasAddress) and Customer.HasAddress);
    end;

    procedure HasDifferentLICToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Address" <> Customer.Address) or
          ("Address 2" <> Customer."Address 2") or
          ("City" <> Customer.City) or
          ("Country/Region Code" <> Customer."Country/Region Code") or
          ("County" <> Customer.County) or
          ("Post Code" <> Customer."Post Code") or
          ("Contact" <> Customer.Contact));
    end;

    procedure HasAddress(): Boolean
    begin
        case true of
            "Address" <> '':
                exit(true);
            "Address 2" <> '':
                exit(true);
            "City" <> '':
                exit(true);
            "Country/Region Code" <> '':
                exit(true);
            "County" <> '':
                exit(true);
            "Post Code" <> '':
                exit(true);
            "Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    procedure ValidateSalesPersonOnLicesneRequest(LicenseRequest2: Record "License Request"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if LicenseRequest2."Salesperson Code" <> '' then
            if Salesperson.Get(LicenseRequest2."Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedTransactionText(Salesperson, IsPostAction, true));
                    if not IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true));
                end;
    end;

    local procedure GetUserSetupSalespersonCode(): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        exit(UserSetup."Salespers./Purch. Code");
    end;

    local procedure UpdateLICToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        OfficeContact: Record Contact;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.GetContact(OfficeContact, CustomerNo) then begin
            HideValidationDialog := true;
            UpdateLICToCust(OfficeContact."No.");
            HideValidationDialog := false;
        end else
            if Cust.Get(CustomerNo) then begin
                if Cust."Primary Contact No." <> '' then
                    "Contact No." := Cust."Primary Contact No."
                else begin
                    ContBusRel.Reset();
                    ContBusRel.SetCurrentKey("Link to Table", "No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("No.", "Customer No.");
                    if ContBusRel.FindFirst then
                        "Contact No." := ContBusRel."Contact No."
                    else
                        "Contact No." := '';
                end;
                "Contact" := Cust.Contact;
            end;
        if "Contact No." <> '' then
            if OfficeContact.Get("Contact No.") then
                OfficeContact.CheckIfPrivacyBlockedGeneric;
    end;

    procedure UpdateLICToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Cont: Record Contact;
        CustomerTempl: Record "Customer Templ.";
        SearchContact: Record Contact;
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        if not Cont.Get(ContactNo) then begin
            "Contact" := '';
            exit;
        end;
        "Contact No." := Cont."No.";

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            ContactBusinessRelationFound :=
                ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;

        if ContactBusinessRelationFound then begin
            if ("Customer No." <> '') and ("Customer No." <> ContBusinessRelation."No.") then
                Error(Text037, Cont."No.", Cont.Name, "Customer No.");

            if "Customer No." = '' then begin
                SkipLICToContact := true;
                Validate("Customer No.", ContBusinessRelation."No.");
                SkipLICToContact := false;
            end;

            if (Cont."E-Mail" = '') and ("E-Mail" <> '') and GuiAllowed then begin
                if Confirm(ConfirmEmptyEmailQst, false, Cont."No.", "E-Mail") then
                    Validate("E-Mail", Cont."E-Mail");
            end else
                Validate("E-Mail", Cont."E-Mail");
            Validate("Phone No.", Cont."Phone No.");
        end else begin
            Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            "Contact" := Cont.Name;
        end;

        UpdateLICToCustContact(Customer, Cont);
    end;

    local procedure UpdateLICToCustContact(Customer: Record Customer; Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin

        if (Cont.Type = Cont.Type::Company) and Customer.Get("Customer No.") then
            "Contact" := Customer.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Contact" := ''
            else
                "Contact" := Cont.Name;
    end;

    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';
    end;

    procedure LookupCustomerName(var CustomerName: Text): Boolean
    var
        Customer: Record Customer;
        LookupStateManager: Codeunit "Lookup State Manager";
        RecVariant: Variant;
        SearchCustomerName: Text;
    begin
        SearchCustomerName := CustomerName;
        Customer.SetFilter("Date Filter", GetFilter("Date Filter"));
        if "Customer No." <> '' then
            Customer.Get("Customer No.");

        if Customer.SelectCustomer(Customer) then begin
            if Rec."Customer Name" = Customer.Name then
                CustomerName := SearchCustomerName
            else
                CustomerName := Customer.Name;
            RecVariant := Customer;
            LookupStateManager.SaveRecord(RecVariant);
            exit(true);
        end;
    end;

    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]) Result: Boolean
    var
        Customer2: Record Customer;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeShouldSearchForCustomerByName(CustomerNo, Result, IsHandled, CurrFieldNo, Rec, xRec);
        // if IsHandled then
        //     exit(Result);

        if CustomerNo = '' then
            exit(true);

        if not Customer2.Get(CustomerNo) then
            exit(true);

        // GetSalesSetup();
        // if SalesSetup."Disable Search by Name" then
        //     exit(false);

        exit(not Customer2."Disable Search by Name");
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        // OnBeforeInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);

        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Customer No.", FieldNo = Rec.FieldNo("Customer No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salesperson Code", FieldNo = Rec.FieldNo("Salesperson Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Campaign, Rec."Campaign No.", FieldNo = Rec.FieldNo("Campaign No."));
        // DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        // DimMgt.AddDimSource(DefaultDimSource, Database::"Customer Templ.", Rec."Bill-to Customer Templ. Code", FieldNo = Rec.FieldNo("Bill-to Customer Templ. Code"));
        // DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        // OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeCreateDim(Rec, IsHandled, DefaultDimSource);
        // if IsHandled then
        //     exit;

        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Sales, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        // OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo, OldDimSetID, DefaultDimSource);

        if (OldDimSetID <> "Dimension Set ID") and (OldDimSetID <> 0) and GuiAllowed and not GetHideValidationDialog() then
            if CouldDimensionsBeKept() then
                if not ConfirmKeepExistingDimensions(OldDimSetID) then begin
                    "Dimension Set ID" := OldDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(Rec."Dimension Set ID", Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
                end;

        // if (OldDimSetID <> "Dimension Set ID") and SalesLinesExist() then begin
        //     OnCreateDimOnBeforeModify(Rec, xRec, CurrFieldNo, OldDimSetID);
        //     Modify();
        //     UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        // end;
    end;

    local procedure ConfirmKeepExistingDimensions(OldDimSetID: Integer) Confirmed: Boolean
    var
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeConfirmKeepExistingDimensions(Rec, xRec, CurrFieldNo, OldDimSetID, Confirmed, IsHandled);
        // if IsHandled then
        //     exit(Confirmed);

        Confirmed := Confirm(DoYouWantToKeepExistingDimensionsQst);
    end;

    local procedure CouldDimensionsBeKept() Result: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCouldDimensionsBeKept(Rec, xRec, Result, IsHandled);
        if not IsHandled then begin
            if (xRec."Customer No." <> '') and (xRec."Customer No." <> Rec."Customer No.") then
                exit(false);
            // if (xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> Rec."Bill-to Customer No.") then
            //     exit(false);

            // if (xRec."Location Code" <> Rec."Location Code") and (xRec."Bill-to Customer No." <> '') then
            //     exit(true);
            if (xRec."Salesperson Code" <> '') and (xRec."Salesperson Code" <> Rec."Salesperson Code") then
                exit(true);
            // if (xRec."Responsibility Center" <> '') and (xRec."Responsibility Center" <> Rec."Responsibility Center") then
            //     exit(true);
        end;
        // OnAfterCouldDimensionsBeKept(Rec, xRec, Result);
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeShowDocDim(Rec, xRec, IsHandled);
        // if IsHandled then
        //     exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        // OnShowDocDimOnBeforeUpdateSalesLines(Rec, xRec);
        if OldDimSetID <> "Dimension Set ID" then begin
            // OnShowDocDimOnBeforeSalesHeaderModify(Rec);
            Modify();
            // if SalesLinesExist() then
            //     UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        // IsHandled := false;
        // OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        // if IsHandled then
        //     exit;

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();

        if OldDimSetID <> "Dimension Set ID" then begin
            // OnValidateShortcutDimCodeOnBeforeUpdateAllLineDim(Rec, xRec);
            if not IsNullGuid(Rec.SystemId) then
                Modify();
            // if SalesLinesExist() then
            //     UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        // OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupContact(CustomerNo: Code[20]; ContactNo: Code[20]; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        FilterByContactCompany: Boolean;
    begin
        if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo) then
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
        // else
        //     if "Document Type" = "Document Type"::Quote then
        //         FilterByContactCompany := true
        else
            Contact.SetRange("Company No.", '');
        if ContactNo <> '' then
            if Contact.Get(ContactNo) then
                // if FilterByContactCompany then
                    Contact.SetRange("Company No.", Contact."Company No.");
    end;

    procedure LICtoContactLookup(): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if "Customer No." <> '' then
            if Contact.Get("Contact No.") then
                Contact.SetRange("Company No.", Contact."Company No.")
            else
                if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, "Customer No.") then
                    Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
                else
                    Contact.SetRange("No.", '');

        if "Contact No." <> '' then
            if Contact.Get("Contact No.") then;
        if Page.RunModal(0, Contact) = Action::LookupOK then begin
            xRec := Rec;
            CurrFieldNo := FieldNo("Contact No.");
            Validate("Contact No.", Contact."No.");
            exit(true);
        end;
        exit(false);
    end;

    procedure MandatoryInvoiceNo()
    var
    begin
        IF Rec."License Type" = Rec."License Type"::Commercial Then begin
            IF "Pre-paid" then begin
                TestField("Invoice No");
                IF Rec."Invoice Qty" <> Rec."License Qty." then Error('Qty. is not matching');
                IF Rec.Duration <> Rec."Invoice Duration" then Error('Duration is not matching');
            end;
        end;
    end;

    internal procedure LicenseLinesExist(): Boolean
    begin
        // LicenseLine.Reset();
        // LicenseLine.SetRange("License Type", "License Type");
        // LicenseLine.SetRange("License Request No.", "No.");
        // exit(not LicenseLine.IsEmpty);
        exit(true);
    end;

    internal procedure CheckMandateFields()
    var
        CLE: Record "Cust. Ledger Entry";
    begin
        TestField("License Code");
        TestField(Duration);
        TestField("License Qty.");
        TestField("E-Mail");
        IF /*"License Type" = LicenseRequest."License Type"::Commercial*/ rec."Pre-paid" then begin
            TestField("Invoice No");
            TestField("Invoice Qty");
            TestField("Invoice Amount");
            IF Rec."Invoice Qty" <> Rec."License Qty." then
                Error('Quantity should be same as invoice quantity');
            IF Rec.Duration <> Rec."Invoice Duration" then
                Error('Duration should be same as invoice duration');
            // IF Rec."Pre-paid" then begin
            CLE.Reset();
            CLE.SetRange("Document No.", Rec."Invoice No");
            CLE.SetRange("Document Type", CLE."Document Type"::Invoice);
            IF CLE.FindFirst() then begin
                CLE.CalcFields("Remaining Amount", "Original Amount");
                IF CLE."Remaining Amount" >= CLE."Original Amount" then
                    Error('No Payment received against Invoice: %1.', Rec."Invoice No");
            end;
        end;
        // end;
        // if "License Type" = LicenseRequest."License Type"::MillionICU then begin
        //     TestField("Doner ID");
        //     TestField("License Value");
        // end;
    end;

    procedure ValidateActivationAndExpiryDate()
    var
        LicReq: Record "License Request";
    begin
        case rec."Document Type" of
            "Document Type"::New:
                begin
                    if rec."Requested Activation Date" <> 0D then begin
                        rec."Activation Date" := rec."Requested Activation Date";
                    end else begin
                        rec."Activation Date" := Today;
                    end;
                    rec."Expiry Date" := CalcDate(rec.Duration, rec."Activation Date");
                    rec."Old Expiry Date" := rec."Expiry Date";
                end;
            "Document Type"::"Add on":
                begin
                    LicReq.Reset();
                    LicReq.SetRange("License No.", rec."Parent Add on Of");
                    if LicReq.FindFirst() then begin
                        if (rec."Requested Activation Date" <> 0D) and
                        (rec."Requested Activation Date" < LicReq."Old Expiry Date") then begin
                            rec."Activation Date" := rec."Requested Activation Date";
                        end else begin
                            rec."Activation Date" := Today;
                        end;
                        rec."Expiry Date" := LicReq."Old Expiry Date";
                        rec."Old Expiry Date" := rec."Expiry Date";
                    end;
                end;
            "Document Type"::Extension:
                begin
                    LicReq.Reset();
                    LicReq.SetRange("License No.", rec."Parent Extension Of");
                    if LicReq.FindFirst() then begin
                        rec."Activation Date" := CalcDate('1D', LicReq."Old Expiry Date");
                        rec."Expiry Date" := CalcDate(rec.Duration, rec."Activation Date");
                        rec."Old Expiry Date" := rec."Expiry Date";
                    end;
                end;
            "Document Type"::Renewal:
                begin
                    LicReq.Reset();
                    LicReq.SetRange("License No.", rec."Parent Renewal Of");
                    if LicReq.FindFirst() then begin
                        rec."Activation Date" := CalcDate('1D', LicReq."Old Expiry Date");
                        rec."Expiry Date" := CalcDate(rec.Duration, rec."Activation Date");
                        rec."Old Expiry Date" := rec."Expiry Date";
                    end;
                end;
        end;
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckLicenseReleaseRestrictions()
    begin
    end;

    procedure CheckLicenseReleaseRestrictions()
    var
        LicApprovalsMgmt: Codeunit "Licesne Approval Mgmt.";
    begin
        OnCheckLicenseReleaseRestrictions;
        LicApprovalsMgmt.PrePostApprovalCheckLicense(Rec);
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckLicenseActivationRestrictions()
    begin
    end;

    procedure CheckLicenseActivationRestrictions()
    begin
        OnCheckLicenseActivationRestrictions();
    end;

    procedure SetStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCust(var LicenseRequest: Record "License Request"; var Customer: Record Customer; CustNo: Code[20])
    begin
    end;
}