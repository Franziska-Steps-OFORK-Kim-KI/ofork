// --
// Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
// Copyright (C) 2010-2025 OFORK, https://o-fork.de
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.RoomIcon
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module function for RoomIcon module.
 */
 Core.Agent.Admin.RoomIcon = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Admin.RoomIcon
     * @function
     * @description
     *      This function initializes the table filter.
     */
    TargetNS.Init = function () {
        Core.UI.Table.InitTableFilter($("#FilterAttachments"), $("#Attachments"));

        // delete attachment
        TargetNS.InitAttachmentDelete();
    };

    /**
     * @name AttachmentDelete
     * @memberof Core.Agent.Admin.RoomIcon
     * @function
     * @description
     *      This function deletes icon on button click.
     */
    TargetNS.InitAttachmentDelete = function () {
        $('.AttachmentDelete').on('click', function () {
            var $AttachmentDeleteElement = $(this);

            Core.UI.Dialog.ShowContentDialog(
                $('#DeleteAttachmentDialogContainer'),
                Core.Language.Translate('Delete this icon'),
                '240px',
                'Center',
                true,
                [
                    {
                        Class: 'Primary',
                        Label: Core.Language.Translate("Confirm"),
                        Function: function() {
                            $('.Dialog .InnerContent .Center').text(Core.Language.Translate("Deleting icon..."));
                            $('.Dialog .Content .ContentFooter').remove();

                            Core.AJAX.FunctionCall(
                                Core.Config.Get('Baselink') + 'Action=AdminRequestRoomIcon;Subaction=Delete',
                                { ID: $AttachmentDeleteElement.data('id') },
                                function(Reponse) {
                                    var DialogText = Core.Language.Translate("There was an error deleting the icon. Please check the logs for more information.");
                                    if (parseInt(Reponse, 10) > 0) {
                                        $('#AttachmentID_' + parseInt(Reponse, 10)).fadeOut(function() {
                                            $(this).remove();
                                        });
                                        DialogText = Core.Language.Translate("Icon was deleted successfully.");
                                    }
                                    $('.Dialog .InnerContent .Center').text(DialogText);
                                    window.setTimeout(function() {
                                        Core.UI.Dialog.CloseDialog($('.Dialog:visible'));
                                    }, 1000);
                                }
                            );
                        }
                    },
                    {
                        Label: Core.Language.Translate("Cancel"),
                        Function: function () {
                            Core.UI.Dialog.CloseDialog($('#DeleteAttachmentDialog'));
                        }
                    }
                ]
            );
            return false;
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
 }(Core.Agent.Admin.Attachment || {}));
