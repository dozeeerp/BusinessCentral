Table 52106 "Email Template"
{
    // --------------------------------------------------------------------------------------------------
    // Intech Systems Pvt. Ltd.
    // --------------------------------------------------------------------------------------------------
    // No.                    Date        Author
    // --------------------------------------------------------------------------------------------------
    // I-A004_I-403002-01     23/01/15    Nilesh Gajjar
    //                                    Email Template Functionality
    //                                    New Table Desgin
    // --------------------------------------------------------------------------------------------------
    Caption = 'Email Template';
    DrillDownPageID = "Email Templates";
    LookupPageID = "Email Templates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(21; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(22; "Email To"; Text[250])
        {
            Caption = 'Email To';
            ExtendedDatatype = EMail;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Email To" <> '' then SMTPMail_gCdu.ValidateEmailAddresses("Email To");
            end;
        }
        field(23; "Email CC"; Text[250])
        {
            Caption = 'Email CC';
            ExtendedDatatype = EMail;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Email CC" <> '' then SMTPMail_gCdu.ValidateEmailAddresses("Email CC");
            end;
        }
        field(24; "Email BCC"; Text[250])
        {
            Caption = 'Email BCC';
            ExtendedDatatype = EMail;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Email BCC" <> '' then SMTPMail_gCdu.ValidateEmailAddresses("Email BCC");
            end;
        }
        field(31; Subject; Text[100])
        {
            Caption = 'Subject';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
            end;
        }
        field(32; "Body 1"; Text[250])
        {
            Caption = 'Body 1';
            DataClassification = CustomerContent;
        }
        field(33; "Body 2"; Text[250])
        {
            Caption = 'Body 2';
            DataClassification = CustomerContent;
        }
        field(34; "Body 3"; Text[250])
        {
            Caption = 'Body 3';
            DataClassification = CustomerContent;
        }
        field(35; "Body 4"; Text[250])
        {
            Caption = 'Body 4';
            DataClassification = CustomerContent;
        }
        field(36; "Body 5"; Text[250])
        {
            Caption = 'Body 5';
            DataClassification = CustomerContent;
        }
        field(37; "Body 6"; Text[250])
        {
            Caption = 'Body 6';
            DataClassification = CustomerContent;
        }
        field(38; "Body 7"; Text[250])
        {
            Caption = 'Body 7';
            DataClassification = CustomerContent;
        }
        field(39; "Body 8"; Text[250])
        {
            Caption = 'Body 8';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
            end;
        }
        field(90010; "Email Body Report ID"; Integer)
        {
            Caption = 'Email Body Report ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));

            trigger OnValidate()
            begin
                CalcFields("Email Body Report Caption");
            end;
        }
        field(90020; "Email Body Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report), "Object ID" = field("Email Body Report ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(90030; "Email Body Layout Code"; Code[20])
        {
            Caption = 'Email Body Layout Code';
            DataClassification = CustomerContent;
            TableRelation = if ("Email Body Layout Type" = const("Custom Report Layout")) "Custom Report Layout".Code where(Code = field("Email Body Layout Code"), "Report ID" = field("Email Body Report ID"))
            else if ("Email Body Layout Type" = const("HTML Layout")) "O365 HTML Template".Code;

            trigger OnValidate()
            begin
                CalcFields("Email Body Layout Descr");
            end;
        }
        field(90040; "Email Body Layout Descr"; Text[250])
        {
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Email Body Layout Code")));
            Caption = 'Email Body Layout Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(90050; "Email Body Layout Type"; Option)
        {
            Caption = 'Email Body Layout Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Custom Report Layout,HTML Layout';
            OptionMembers = "Custom Report Layout","HTML Layout";
        }
    }
    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
    }
    var
        SMTPMail_gCdu: Codeunit "Email Account";
}
