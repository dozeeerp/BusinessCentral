namespace TSTChanges.FA.FAItem.Picture;

using TSTChanges.FA.FAItem;
using System.Device;
using Microsoft.Integration.Entity;
using System.IO;
using System.Text;

page 51202 "FA Item Picture"
{
    Caption = 'FA Item Picture';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = "FA Item";

    layout
    {
        area(Content)
        {
            field(Picture; Rec.Picture)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ShowCaption = false;
                ToolTip = 'Specifies the picture that has been inserted for the item.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakePicture)
            {
                ApplicationArea = All;
                Caption = 'Take';
                Image = Camera;
                // Promoted = true;
                // PromotedCategory = Process;
                // PromotedIsBig = true;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable AND (HideActions = FALSE);

                trigger OnAction()
                begin
                    TakeNewPicture();
                end;
            }
            action(ImportPicture)
            {
                ApplicationArea = All;
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture file.';
                Visible = HideActions = FALSE;

                trigger OnAction()
                begin
                    ImportFromDevice();
                end;
            }
            action(ExportFile)
            {
                ApplicationArea = All;
                Caption = 'Export';
                Enabled = DeleteExportEnabled;
                Image = Export;
                ToolTip = 'Export the picture to a file.';
                Visible = HideActions = FALSE;

                trigger OnAction()
                var
                    DummyPictureEntity: Record "Picture Entity";
                    FileManagement: Codeunit "File Management";
                    StringConversionManager: Codeunit StringConversionManagement;
                    ToFile: Text;
                    ConvertedCodeType: Text;
                    ExportPath: Text;
                begin
                    Rec.TestField("No.");
                    Rec.TestField(Description);
                    ConvertedCodeType := Format(Rec."No.");
                    ToFile := DummyPictureEntity.GetDefaultMediaDescription(Rec);
                    ConvertedCodeType := StringConversionManager.RemoveNonAlphaNumericCharacters(ConvertedCodeType);
                    // ExportPath := TemporaryPath + ConvertedCodeType + Format(Rec.Picture.MediaId);
                    // Rec.Picture.ExportFile(ExportPath + '.' + DummyPictureEntity.GetDefaultExtension());

                    // FileManagement.ExportImage(ExportPath, ToFile);
                end;
            }
            action(DeletePicture)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Enabled = DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';
                Visible = HideActions = FALSE;

                trigger OnAction()
                begin
                    DeleteItemPicture();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetEditableOnPictureActions();
    end;

    trigger OnOpenPage()
    begin
        CameraAvailable := Camera.IsAvailable();
    end;


    var
        Camera: Codeunit Camera;
        CameraAvailable: Boolean;
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        SelectPictureTxt: Label 'Select a picture to upload';
        DeleteExportEnabled: Boolean;
        HideActions: Boolean;
        MustSpecifyDescriptionErr: Label 'You must add a description to the item before you can import a picture.';
        MimeTypeTok: Label 'image/jpeg', Locked = true;

    procedure TakeNewPicture()
    begin
        Rec.Find();
        Rec.TestField("No.");
        Rec.TestField(Description);

        OnAfterTakeNewPicture(Rec, DoTakeNewPicture());
    end;

    // [Scope('OnPrem')]
    procedure ImportFromDevice()
    var
        FileManagement: Codeunit "File Management";
    // FileName: Text;
    // ClientFileName: Text;
    begin
        Rec.Find();
        Rec.TestField("No.");
        if Rec.Description = '' then
            Error(MustSpecifyDescriptionErr);

        if Rec.Picture.Count > 0 then
            if not Confirm(OverrideImageQst) then
                Error('');

        // ClientFileName := '';
        // FileName := FileManagement.UploadFile(SelectPictureTxt, ClientFileName);
        //     if FileName = '' then
        //         Error('');

        //     Clear(Rec.Picture);
        //     Rec.Picture.ImportFile(FileName, ClientFileName);
        //     Rec.Modify(true);
        //     OnImportFromDeviceOnAfterModify(Rec);

        //     if FileManagement.DeleteServerFile(FileName) then;
    end;

    local procedure DoTakeNewPicture(): Boolean
    var
        PictureInstream: InStream;
        PictureDescription: Text;
    begin
        if Rec.Picture.Count() > 0 then
            if not Confirm(OverrideImageQst) then
                exit(false);

        if Camera.GetPicture(PictureInstream, PictureDescription) then begin
            Clear(Rec.Picture);
            Rec.Picture.ImportStream(PictureInstream, PictureDescription, MimeTypeTok);
            Rec.Modify(true);
            exit(true);
        end;

        exit(false);
    end;

    local procedure SetEditableOnPictureActions()
    begin
        DeleteExportEnabled := Rec.Picture.Count <> 0;
    end;

    procedure DeleteItemPicture()
    begin
        Rec.TestField("No.");

        if not Confirm(DeleteImageQst) then
            exit;

        Clear(Rec.Picture);
        Rec.Modify(true);

        OnAfterDeleteItemPicture(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteItemPicture(var Item: Record "FA Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTakeNewPicture(var Item: Record "FA Item"; IsPictureAdded: Boolean)
    begin
    end;
}