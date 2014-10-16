#!/usr/bin/perl

require "userinfo.pl";

use CGI;
my $cgi=CGI::new();

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

print "Content-type: text/html\n";
print "Refresh: 0; URL=".ue("/".$prefs{'cgipath'}."/index.pl")."\n";


#attempting to log in
my $user=$cgi->param("user");
my $pass=$cgi->param("pass");
if( checkuserpass($user,$pass) && uihash($user)->{'authority'} < 5)
{
    print "Set-Cookie: user=$user
Set-Cookie: pass=".crypt(${uihash($user)}{'passhash'}, $user)."

";
    "Login successfull.<br><br>\n";
}
else
{
    print "Set-Cookie: user=".($cgi->param("user")?"invalid":"")."
Set-Cookie: pass=login

";
    
}

my $j;


