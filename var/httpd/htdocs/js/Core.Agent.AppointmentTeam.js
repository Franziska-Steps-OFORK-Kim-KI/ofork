// --
// Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace
 * @exports TargetNS as Core.Agent.AppointmentTeam
 * @description
 *      This namespace contains the special module functions for Appointment modules.
 */
Core.Agent.AppointmentTeam = (function (TargetNS) {

    /**
     * @name Init
     * @function
     * @description
     *       Initialize module functionalities.
     */
    TargetNS.Init = function () {
        var Action = Core.Config.Get('Action'),
            DataType = Core.Config.Get('CheckboxDataType');

        // Initialize table filter for AppointmentTeam module.
        if (Action === 'AgentAppointmentTeam') {
            Core.UI.Table.InitTableFilter($('#FilterTeams'), $('#AppointmentTeams'));
        }

        if (Action === 'AgentAppointmentTeamUser') {

            // Initialize table filter for AppointmentTeamUser module.
            Core.UI.Table.InitTableFilter($('#Filter'), $('#UserTeams'));
            Core.UI.Table.InitTableFilter($('#FilterAgents'), $('#Users'));
            Core.UI.Table.InitTableFilter($('#FilterTeams'), $('#Teams'));

            // Create events for check-box all selection.
            Core.Form.InitSelectAllCheckboxes($('table td input:checkbox[name=' + DataType + ']'), $('#SelectAll' + DataType));
            $('input:checkbox[name=' + DataType + ']').bind('click', function () {
                Core.Form.SelectAllCheckboxes($(this), $('#SelectAll' + DataType));
            });
        }
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.AppointmentTeam || {}));
