#!/usr/bin/perl

print "Content-type:text/html\n\n";

use CGI; my $cgi=CGI::new();

require "userinfo.pl";

require "flush.pl";

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

flush(STDOUT);

open(WML, "|./wmlf");
select WML;
print '#include "layout.wml"

{#TITLE#: '.$prefs{'sitename'}.': Manage Accounts :##}
{#BODY#:
<entry>
<heading>Manage User Accounts</heading>
<post>
';

if(uihash($user)->{'authority'} != 1)
{
    print "you do not have authorization to manage accounts.";
} else {
    print "<form method=post action=\"accountmanager.pl\">\n";

    print "God mode.<br><br>\n<hr>\n";

    if($cgi->param("manage")) {
	print "account manager: ".$cgi->param("manage")."<br><br>";

	print $cgi->hidden(-name=>"_m_user", -value=>$cgi->param("manage"))."\n";

	$cgi->param("_m_user",$cgi->param("manage")); 

	print optionhtml();

	print "\n<hr>\n";
    }

    if($cgi->param("global")) {

	my $u;
	if($u=$cgi->param("_m_user")) {
	    foreach(options()) {
		uiset($u, $_->[0], $cgi->param("_m_".$_->[0]));
	    }
    	}

	print "Change Log:<br>
<i>( Select an item to verify the change )</i><br>
";

	foreach($cgi->param())
	{
	    if(!/^_c_ac_/) { next; }
	    s/^_c_ac_//;
	    my ($u, $type)=split(/_(?=[^_]+(?=_data)?\Z)/x,$_,2);
#	    print "UT: $u <> $t<br>\n";
	    if($type eq "pass") {
		my ($pass, $rpass)=$cgi->param("_c_ac_".$u."_pass_data");
		if($pass ne $rpass)
		{
		    print "password change on $u failed: new and retyped passwords not identical<br>\n";
		    next;
		}
		uiset($u, "passhash", crypt($pass, sprintf("%2X", int(rand()*256))));
		$cgi->delete("_c_ac_".$u."_pass");
		$cgi->delete("_c_ac_".$u."_pass_data");
		$cgi->delete("ac_".$u."_pass");
		$cgi->delete("ac_".$u."_rpass");
		$cgi->delete("ac_".$u."_pass_data");
		
	    } elsif($type eq "authority" && $cgi->param("_c_ac_".$u."_authority_data") < 6) {
		print "authority change on $u<br>\n";
		uiset($u, "authority", $cgi->param("_c_ac_".$u."_authority_data"));
		$cgi->delete("_c_ac_".$u."_authority");
		$cgi->delete("_c_ac_".$u."_authority_data");
		$cgi->delete("ac_".$u."_authority");
		$cgi->delete("ac_".$u."_authority_data");
	    } elsif($type eq "authority" && $cgi->param("_c_ac_".$u."_authority_data") == 6) {
		print "deleted user $u<br>\n";
		removeuser(0, $u);
		$cgi->delete("_c_ac_".$u."_authority");
		$cgi->delete("_c_ac_".$u."_authority_data");
		$cgi->delete("ac_".$u."_authority");
		$cgi->delete("ac_".$u."_authority_data");
	    }
	     
	}

	print "<ul>\n";
	
	foreach(getusers())
	{
	    print "<li>".$cgi->checkbox(-name=>"_c_ac_".$_."_pass", -label=>"$_ : change password\n").$cgi->hidden(-name=>"_c_ac_".$_."_pass_data", -value=>[$cgi->param("ac_".$_."_pass"), $cgi->param("ac_".$_."_rpass")])."\n"
		if($cgi->param("ac_".$_."_pass"));
	    print "<li>".$cgi->checkbox(-name=>"_c_ac_".$_."_authority", -label=>"$_ : change authority\n").$cgi->hidden(-name=>"_c_ac_".$_."_authority_data", -value=>$cgi->param("ac_".$_."_authority"))."\n"
		if($cgi->param("ac_".$_."_authority") && $cgi->param("ac_".$_."_authority") ne uihash($_)->{'authority'} && $cgi->param("ac_".$_."_authority") < 6);
	    print "<li>".$cgi->checkbox(-name=>"_c_ac_".$_."_authority", -label=>"$_ : delete user\n").$cgi->hidden(-name=>"_c_ac_".$_."_authority_data", -value=>$cgi->param("ac_".$_."_authority"))."\n"
		if($cgi->param("ac_".$_."_authority") == 6);
	    
	}
	print "</ul>\n";
	print "<hr>\n";
	if($ENV{'REGEN'}) {
	    system("./regen.pl");
	} else {
	    $ENV{'REGEN'}="yes";
	    system("./regen.pl");
	    delete $ENV{'REGEN'};
	}
	
    }

    print join("\n<hr>\n", map {
	"$_ ( ".uihash($_)->{'email'}." )<br><br>
<table border=0>
<tr><td align=left>".$cgi->password_field(-name=>"ac_".$_."_pass")." &nbsp; new password</td><td align=right>
detailed Management for &nbsp; " .$cgi->submit(-name=>"manage", -value=>$_)."</td></tr>
<tr><td align=left>
".$cgi->password_field(-name=>"ac_".$_."_rpass")." &nbsp; retype password</td>
<td align=right>
user authority: &nbsp;".$cgi->popup_menu("ac_".$_."_authority",
					 [ '1', '2', '3', '4', '5', '6' ],
					 ('1', '2', '3', '4', '5')[uihash($_)->{'authority'}-1],
					 { '1'=>'owner',
					   '2' => 'staff',
					   '3' => 'user',
					   '4' => 'restricted',
					   '5' => 'waiting in limbo',
					   '6' => 'delete user'
					   }
					 )."</td></tr>
</table>
"
    
} getusers());

print "<hr>\n";
    print $cgi->submit(-name=>"global", -value=>"Enact changes")." &nbsp; ";
    print $cgi->reset('Reset changes')."<br><br>\n";
    
    print "</form>\n";
}


print '
</post>
</entry>
:##}

';
close(WML);
wait();


sub optionhtml
{
    my $ot;

    my @options=@_;
    if(!@options) { @options=options(); }
    my $ou=$cgi->param("_m_user");
    foreach(@options)
    {
	my $oname=shift(@$_);
	my $otype=shift(@$_);
	my @oargs=();
	@oargs=@$_ if(scalar @$_);

	if($otype eq "cb")
	{
	    $ot.=cb($oname, $oargs[0]);
	} elsif($otype eq "text") {
	    $ot.="<input type=\"text\" name=\"_m_$oname\" value=\"".uihash($ou)->{$oname}."\" size=\"$oargs[0]\">&nbsp;".$oargs[1];
	} elsif($otype eq "pass") {
	    $ot.=$cgi->password_field("_m_".$oname, undef, $oargs[0])."&nbsp;".$oargs[1];
	} elsif($otype eq "cat") {
	    $ot.="<font style=\"font-size:1.333em;\">$oname</font>";
	}
	$ot.="<br><br>\n";
    }

    $ot.="\n<br><br>\n";
    return $ot;
}

sub cb
{
    my ($name, $label)=@_;

    my $t;

    if(uihash($cgi->param("_m_user"))->{$name} == 1)
    {
	$t.=$cgi->checkbox(-name=>"_m_".$name, -class=>"thin", -checked=>'yes', label=>$label);
    } else {
	$t.=$cgi->checkbox(-name=>"_m_".$name, -class=>"thin", label=>$label);
    }
    
    return $t;
}

sub options
{
    return (
	    ["email", "text", "30", "email address"],
	    ["skipanonymous", "cb", "ignore posts by anonymous or restricted users (eg contributor)"],
	    ["weblogsize", "text", 4, "number of posts to display on main weblog"],
	    ["link", "text", "30", "username link on weblog"]
	    );
}
