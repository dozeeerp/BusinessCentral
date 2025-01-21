namespace Ems;

permissionset 52100 "EMS Edit"
{
    Assignable = true;
    Permissions = tabledata "EMS Setup" = RIMD,
        tabledata "License Request" = RIMD,
        table "EMS Setup" = X,
        table "License Request" = X,
        page "Ems Setup" = X,
        codeunit "Document Attachment" = X,
        codeunit "EMS Record Restriction mgt" = X,
        codeunit "EMS Workflow Events" = X,
        codeunit "EMS Workflow Resposnses" = X,
        codeunit "Licesne Approval Mgmt." = X,
        codeunit "Release License Document" = X,
        page "License Requests" = X;
}