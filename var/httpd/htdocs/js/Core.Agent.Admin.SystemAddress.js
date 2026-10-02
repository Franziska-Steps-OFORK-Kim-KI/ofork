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
 * @namespace Core.Agent.Admin.SystemAddress
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special function for AdminSystemAddress module.
 */
 Core.Agent.Admin.SystemAddress = (function (TargetNS) {

    /*
    * @name Init
    * @memberof Core.Agent.Admin.SystemAddress
    * @function
    * @description
    *      This function initializes table filter.
    */
    TargetNS.Init = function () {
        Core.UI.Table.InitTableFilter($('#FilterSystemAddresses'), $('#SystemAddresses'));
        TargetNS.InitOAuth2Check();
    };

    /*
    * @name InitOAuth2Check
    * @memberof Core.Agent.Admin.SystemAddress
    * @function
    * @description
    *      Checks the Exchange Online mailbox of a system address (OAuth2) and shows the result in its row.
    */
    TargetNS.InitOAuth2Check = function () {
        $('#SystemAddresses').on('click', '.OAuth2CheckButton', function (Event) {
            var $Button = $(this),
                $Result = $Button.closest('td').find('.OAuth2CheckResult');

            // the whole row is a link to the edit screen
            Event.stopPropagation();
            Event.preventDefault();

            $Button.prop('disabled', true);
            $Result.text(Core.Language.Translate('Checking...'));

            Core.AJAX.FunctionCall(
                Core.Config.Get('Baselink'),
                {
                    Action: 'AdminSystemAddress',
                    Subaction: 'OAuth2Check',
                    ID: $Button.data('id')
                },
                function (Response) {
                    $Result.empty();
                    $.each((Response && Response.Checks) || [], function (Index, Check) {
                        $('<div/>')
                            .text((Check.Successful ? '✅ ' : '❌ ') + Check.Message)
                            .appendTo($Result);
                    });
                    $Button.prop('disabled', false);
                }
            );
            return false;
        });

        // clicks in the result area must not open the edit screen either
        $('#SystemAddresses').on('click', '.OAuth2Check', function (Event) {
            Event.stopPropagation();
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.SystemAddress || {}));
