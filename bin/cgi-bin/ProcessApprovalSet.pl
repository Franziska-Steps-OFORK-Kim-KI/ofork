#!/usr/bin/perl -w
# --
# bin/cgi-bin/ProcessApprovalSet.pl
# Copyright (C) 2010-2018 einraumwerk, http://einraumwerk.de/
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

print "Content-Type: text/html; utf-8\n\n";

my %INPUT;
my ($buffer, $pair, $name, $value);
my @pairs;
if ($ENV{'REQUEST_METHOD'} eq "GET") {
$buffer = $ENV{'QUERY_STRING'};
}elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
}
@pairs = split(/&/, $buffer);
foreach my $pair (@pairs) {
($name, $value) = split(/=/, $pair);
$value =~ s/<!--.*?-->//gs;
$value =~ tr/+/ /;
$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
$name =~ tr/+/ /;
$name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
if (defined $INPUT{$name}) {
$INPUT{$name} = $INPUT{$name}.",".$value;
}else{
$INPUT{$name} = $value;
}
}

# use ../../ as lib location
use FindBin qw($Bin);
use lib "$Bin/../..";
use lib "$Bin/../../Kernel/cpan-lib";
use lib "$Bin/../../Custom";

# 0=off;1=on;
my $Debug = 0;

use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new();

my %CommonObject;
$CommonObject{TicketProcessStepObject} = $Kernel::OM->Get('Kernel::System::TicketProcessStep');

my $ApprovStepCheck = $CommonObject{TicketProcessStepObject}->ApprovStepCheck(
    ProcessID     => $INPUT{ProcessID},
    ProcessStepID => $INPUT{ProcessStepID},
    TicketID      => $INPUT{TicketID},
    Art           => $INPUT{Art},
);

$INPUT{Report} =~ s/[\x0D]/\n<br>/g;

if ( $ApprovStepCheck == 2 ) {
print <<HTML;
<!DOCTYPE html>
<html lang="de-DE">
<head>
<meta charset="utf-8">
</head>
<body>
<div style="color:blue;text-align:center;width:100%;font-size:36px;font-family:Helvetica, Arial, sans-serif;">
<br><br><br>
Der Antrag wurde schon entschieden.<br><br>
Das Fenster kann nun geschlossen werden.<br><br>
</div>
</body>
</html>
HTML
exit 0;
}

$CommonObject{TicketProcessStepObject}->ApprovStep(
    ProcessID     => $INPUT{ProcessID},
    ProcessStepID => $INPUT{ProcessStepID},
    TicketID      => $INPUT{TicketID},
    Report        => $INPUT{Report},
    Art           => $INPUT{Art},
);

if ( $INPUT{Art} eq "genehmigt" ) {
print <<HTML;
<!DOCTYPE html>
<html lang="de-DE">
<head>
<meta charset="utf-8">
</head>
<body>
<div style="color:blue;text-align:center;width:100%;font-size:36px;font-family:Helvetica, Arial, sans-serif;">
<br><br><br>
Der Antrag wurde genehmigt.<br><br>
Das Fenster kann nun geschlossen werden.<br><br>
</div>
</body>
</html>
HTML
}

if ( $INPUT{Art} eq "abgelehnt" ) {
print <<HTML;
<!DOCTYPE html>
<html lang="de-DE">
<head>
<meta charset="utf-8">
</head>
<body>
<div style="color:blue;text-align:center;width:100%;font-size:36px;font-family:Helvetica, Arial, sans-serif;">
<br><br><br>
Der Antrag wurde abgelehnt.<br><br>
Das Fenster kann nun geschlossen werden.<br><br>
</div>
</body>
</html>
HTML
}

exit 0;
