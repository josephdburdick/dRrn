#!/usr/bin/perl

use CGI; $cgi=CGI::new();

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

require "userinfo.pl";

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

require "flush.pl";
flush(STDOUT);
if($user eq "") { exit; }
if(${uihash($user)}{'authority'} <= 1 + $prefs{'staffdelete'} || $ENV{'REGEN'})
{
    #ignore regen from unauthorized users
    $ENV{'REGEN'}="yes";
    system("./index.pl >/".$prefs{'docroot'}."/".$prefs{'docpath'}."/".$prefs{'docindex'}) if($prefs{'docindex'});
}
