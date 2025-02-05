page 51233 "FA Item Variant Card"
{
    Caption = 'FA Item Variant Card';
    PageType = Card;
    RefreshOnActivate = true;
    UsageCategory = None;
    SourceTable = "FA Item Variant";

    layout
    {
        area(Content)
        {
            group(ItemVariant)
            {
                Caption = 'Item Variant';
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the item card from which you opened the Item Variant Translations window.';
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a code to identify the variant.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the item variant.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item variant in more detail than the Description field.';
                    Visible = false;
                }
                group(BlockedGroup)
                {
                    ShowCaption = false;
                    field(Blocked; Rec.Blocked)
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item variant that is placed in quarantine.';
                    }
                    field("Sales Blocked"; Rec."Sales Blocked")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the item variant cannot be entered on sales documents, except return orders and credit memos, and journals.';
                    }
                    field("Service Blocked"; Rec."Service Blocked")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies that the item variant cannot be entered on service items, service contracts and service documents, except credit memos.';
                    }
                    field("Purchasing Blocked"; Rec."Purchasing Blocked")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the item variant cannot be entered on purchase documents, except return orders and credit memos, and journals.';
                    }
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesPart; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;
}