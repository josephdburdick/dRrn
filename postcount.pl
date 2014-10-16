#!/usr/bin/perl

use CGI; my $cgi=CGI::new();

require "userinfo.pl";
require "flush.pl";

print '
<menusection>
<menuheading>User/DLS Accounts</menuheading>
<menubody>
<table width="100%" cellspacing="0" cellpadding="0">
';

print map { fm($_) } &getusers();


print '</table>
</menubody>
</menusection>
';


sub fm
{
    my $name=shift;
    my $num=uihash($name)->{'numposts'} or return;
    my $email=uihash($name)->{'email'};
    my $link=uihash($name)->{'link'};
    my $auth=("master", "staff", "user", "restricted", "purgatory")[uihash($name)->{'authority'}-1];
    my $st="";
    $st.=$link?"<tr><td align=\"left\" class=\"Ltext\"><a href=\"$link\">$name</a></td>":"<tr><td align=\"left\" class=\"Ltext\">$name</td>";
    $st.=$email?"<td align=\"right\" class=\"Ltext\">e[<a href=\"mailto:$email\">@</a>]&nbsp;&nbsp;":"<td align=\"right\" class=\"Ltext\">";
    $st.="n[<b>$num</b>]&nbsp;&nbsp;<b>!</b>[$auth]</td></tr>\n";
    return $st;
}


1;
