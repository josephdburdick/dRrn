#!/usr/bin/perl

print "Content-type:text/html\n\n";

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

use CGI; my $cgi=CGI::new();

require "userinfo.pl";

require "flush.pl";

flush(STDOUT);

open(WML, "|./wmlf");
select WML;
print '#include "layout.wml"

{#TITLE#: '.$prefs{'sitename'}.': User Preferences :##}
{#BODY#:

';

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

if(!$user or ${uihash($user)}{'authority'} > 3)
{
    print "<entry>
<heading> Error: Please Log In </heading>
<post>
".($user ? "
The account <b>$user</b> does not have permission to set preferences.
": "You must log in before you can set preferences.
")."<br><br>

</post>
</entry>
";
} else {
    # no issues with pref setting
    print "<entry><heading>Preferences for $user</heading>\n";
    print "<post>";

    if($cgi->param("submit"))
    {
	if($cgi->param("pass")) {
	    my $errors;
	    my $pw=$cgi->param("pass");
	    if($pw!~/^[a-zA-Z0-9\-_ ]*$/) { $errors.="<li>Password uses invalid characters\n"; }
	    if(($pw=~s/.//g) < 6) { $errors.="<li>Password is too short\n"; }

	    if($cgi->param("pass") ne $cgi->param("rpass")) { $errors.="<li>Password and retyped password do not match\n"; }

	    if($errors) {
		print "Failed to change password:<ul>\n";
		print $errors;
		print "</ul>\n\n";
	    } else {
		uiset($user, "passhash", crypt($cgi->param("pass"), sprintf("%2X", int(rand()*256) ) ));
		print "Password changed\n";
	    }
	    
	}
	$cgi->delete("pass");
	$cgi->delete("rpass");
	foreach(options())
	{
	    my $oname=shift(@$_);
	    my $otype=shift(@$_);
	    my @oargs=@$_;
	    
	    if($otype eq "cb") {
		uiset($user, $oname, ($cgi->param($oname))?1:0);
	    } elsif($otype eq "text") {
		uiset($user, $oname, $cgi->param($oname));
	    } elsif($otype eq "pass") {
		uiset($user, $oname, $cgi->param($oname));
	    }
	    
	}
    }

    print optionhtml();

    print "</post></entry>\n";
}

print '


:##}

';
close(WML);
wait();

sub optionhtml
{

    my $ot;

    my @options=@_;
    if(!@options) { @options=options(); }

    $ot.="<form method=post action=\"prefs.pl\">\n";

    foreach(@options)
    {
	my $oname=shift(@$_);
	my $otype=shift(@$_);
	my @oargs=@$_;

	if($otype eq "cb")
	{
	    $ot.=cb($oname, $oargs[0]);
	} elsif($otype eq "text") {
	    $ot.=$cgi->textfield(-name=>$oname, -class=>"thin", -size=>$oargs[0], -value=>uihash($user)->{$oname})."&nbsp;".$oargs[1];
	} elsif($otype eq "pass") {
	    $ot.=$cgi->password_field(-name=>$oname, -class=>"thin", -size=>$oargs[0])."&nbsp;".$oargs[1];
	} elsif($otype eq "cat") {
	    $ot.="<font style=\"font-size:1.333em;\">$oname</font>";
	}
	$ot.="<br><br>\n";
    }

    $ot.="\n<br><br>\n";
    $ot.=$cgi->submit(-name=>"submit", -label=>"Save Settings")."&nbsp"x5;
    $ot.=$cgi->reset(-label=>"Reset Changes");
    $ot.="\n<br><br>\n";

    $ot.="</form>";

    return $ot;
}

sub cb
{
    my ($name, $label)=@_;

    my $t;

    if(uihash($user)->{$name} == 1)
    {
	$t.=$cgi->checkbox(-name=>$name, -class=>"thin", -checked=>'yes', label=>$label);
    } else {
	$t.=$cgi->checkbox(-name=>$name, -class=>"thin", label=>$label);
    }
    
    return $t;
}

sub options
{
    return (
	    ["$user\'s account type: ".("Owner", "Staff", "Normal", "Restricted", "Disabled")[ uihash($user)->{'authority'}-1], "cat"],
	    ["General Options", "cat"],
	    ["pass", "pass", "10", "new password"],
	    ["rpass", "pass", "10", "retype new password"],
	    ["email", "text", "30", "email address"],
	    
	    ["Weblog Options", "cat"],
	    ["skipanonymous", "cb", "ignore posts by anonymous or restricted users (eg contributor)"],
	    ["weblogsize", "text", 4, "number of posts to display on main weblog"],
	    ["link", "text", "30", "username link on weblog"]
	    );
}
