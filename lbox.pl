#!/usr/bin/perl

use CGI; my $cgi=CGI::new();

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

require "userinfo.pl";

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));


if($user && !$ENV{'REGEN'})
{
    print "
<menusection>
<img src=\"http://www.e3-r.com/e3r/img/mnu_userinterface.jpg\" width=\"245\" height=\"15\"><br>
<menuheading> Welcome, $user </menuheading>
<menubody>
<ol>
<li><a href=\"index.pl\">post list</a><br>
<li><a href=\"post.pl\">new post</a><br>
".( ( ${uihash($user)}{'authority'} <= 3 ) ? "
<li><a href=\"prefs.pl\">preferences</a><br>
" : "" )."
".( ( ${uihash($user)}{'authority'} ==1 ) ? "
<li><a href=\"siteprefs.pl\">global settings</a><br>
" : "" )."
". ( ( ${uihash($user)}{'authority'} <= ( ($prefs{'staffdelete'} ==1 || $prefs{'staffdeleteown'} ==1) ? 2 : 1) ) ? "
<li><a href=\"delete.pl\">delete(d) posts</a><br>
" : "" )."
".( ( ${uihash($user)}{'authority'} ==1 ) ? "
<li><a href=\"accountmanager.pl\">account manager</a><br>
<li><a href=\"authnewusers.pl\">activate new users</a><br>
" : "" )."
".( ( ${uihash($user)}{'authority'} <= ( ($prefs{'staffregenerate'} ==1) ? 2 : 1) ) && $prefs{'docindex'} ? "
<li><a href=\"nph-rebuild.pl\">rebuild weblog</a><br>
" : "" )."
".( ( ${uihash($user)}{'authority'} <= ( ($prefs{'staffedit'} ==1 || $prefs{'staffeditown'} ==1) ? 2 : 1) ) ? "
<li><a href=\"edit.pl\">edit posts</a><br>
" : "" )."
<li><a href=\"login.pl?user=&pass=\">logout</a><br>
</ol>
</menubody>
</menusection>
";    
} else {
    print "<menusection>\n";

    if(($cgi->cookie("user") ne "") && !$ENV{'REGEN'})
    {
	print "<menuheading> Invalid Login </menuheading>\n";
	print "<menubody>\n";    
    }  else {
	print "<menuheading>".$prefs{'sitename'}."</menuheading>\n";
	print "<menubody><font size=-1 style=\"font-size: .8em;\">To post, please login.</font><br><br>\n";
    }

print "
<form method=post action=\"".ue("/".$prefs{'cgipath'}."/login.pl\"").">
Login: ".$cgi->textfield(-name=>"user", -size=>"12", -align=>"right", -value=>"contributor", -class=>"thin", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;")."<br>
Pass:&nbsp;&nbsp;" .$cgi->password_field(-name=>"pass", -size=>"12", -align=>"right", -value=>"contributor", -class=>"thin", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;")."<br><br>
".$cgi->submit(-value=>"Login", -align=>right, -class=>"thin", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;")."&nbsp;&nbsp;<a href=\"".ue("/".$prefs{'cgipath'}."/newuser.pl\"").">New User?</a>
</form>
</menubody>
</menusection>";
    
}


#flush(STDOUT);
#close(WML);
#wait();


1;






