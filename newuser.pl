#!/usr/bin/perl

print "Content-type:text/html\n\n";

use CGI; my $cgi=CGI::new();

require "userinfo.pl";

require "flush.pl";

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

flush(STDOUT);

open(WML, "|./wmlf");
select WML;
print '#include "layout.wml"

{#TITLE#: '.$prefs{'sitename'}.': Create New Account :##}
{#BODY#:
	 
';

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

print '<entry><heading>Create New Account</heading>
<post>
';
if($cgi->param("submit"))
{

    my $errors;
    my $us=$cgi->param("user");

    if($us!~/^[a-zA-Z0-9\-_ ]*$/) { $errors.="<li>User name uses invalid characters\n"; }
    if(($us=~s/.//g) < 3) { $errors.="<li>User name is too short\n"; }

    my $pw=$cgi->param("pass");
    if($pw!~/^[a-zA-Z0-9\-_ ]*$/) { $errors.="<li>Password uses invalid characters\n"; }
    if(($pw=~s/.//g) < 6) { $errors.="<li>Password is too short\n"; }

    if($cgi->param("pass") ne $cgi->param("rpass")) { $errors.="<li>Password and retyped password do not match\n"; }
    
    if($errors) {
	print "The following errors occured while creating your account:\n";
	print "<ul>\n$errors\n</ul>\n";
    } else {
	srand time;
	my $u=$cgi->param("user");
	newuser($u);
	uiset($u, "passhash", crypt($cgi->param("pass"), sprintf("%2X", int(rand()*256) ) ));
	uiset($u, "email", $cgi->param("email"));
	if($prefs{'authnewusers'})
	{
	    print "Your account has been created, and added to the waiting list for authorization.";
	    $prefs{'accountwaitinglist'}.="$u\n";
	    uiset($u, "authority", 5);
	} else {
	    uiset($u, "authority", 3);
	    print "Your account has been created. You may now log in.";
	}
    }
} else {

    if($prefs{'authnewusers'}==1)
    {
	print "Accounts are currently under review. This means that, though you may request a new account, you will not recieve it until the administrator authorizes your account.";
    } else {
	print "Accounts are currently in free mode. This means that you may create an account immediately.";
    }
    
    print "<br><br>\n";
    
    print "<form method=post action=\"newuser.pl\">\n";
    print "Email:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".$cgi->textfield(-name=>"email", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -class=>"thin", -value=>$cgi->param("email"))."<br><br>\n";
    print "Username:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".$cgi->textfield(-name=>"user", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -class=>"thin", -value=>$cgi->param("user"))."<br><br>\n";
    print "Password:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;".$cgi->password_field(-name=>"pass", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -class=>"thin", -value=>$cgi->param("user"))."<br><br>\n";
    print "Retype Password: ".$cgi->password_field(-name=>"rpass", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -class=>"thin", -value=>$cgi->param("user"))."<br><br>\n";
    
    if($prefs{'authnewusers'}==1)
    {
	print $cgi->submit(-name=>"submit", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -label=>"Request Account")."&nbsp"x5;
    } else {
	print $cgi->submit(-name=>"submit", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -label=>"Create Account")."&nbsp"x5;
    }
    print "</form>\n";
}

print '</post>
</entry>
';

print '


:##}

';
close(WML);
wait();
