namespace Ems;

permissionset 52100 "EMS Edit"
{
    Assignable = true;
    Permissions =
        tabledata "EMS Setup" = RIMD,
        tabledata "License Request" = RIMD,
        table "EMS Setup" = X,
        table "License Request" = X,
        page "Ems Setup" = X;
}