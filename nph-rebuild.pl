#!/usr/bin/perl

use CGI; my $cgi=CGI::new();

require "userinfo.pl";

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

print $cgi->header(-refresh=>"0; URL=http://".$prefs{'domain'}.$prefs{'cgipath'}."/index.pl",
		   -nph=>1
		   );

$ENV{'REGEN'}="yes";
system("./regen.pl");

