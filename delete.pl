#!/usr/bin/perl

use CGI; my $cgi=CGI::new();

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

require "userinfo.pl";

print "Content-type: text/html\n\n";

require "flush.pl"; flush(STDOUT);

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

open(WML, "|./wmlf");
select WML;
print '#include "layout.wml"

{#TITLE#: '.$prefs{'sitename'}.': delete posts :##}
{#BODY#:
';

print "<entry><heading>Delete a post</heading>\n";
print "<post>\n";
if((uihash($user)->{'authority'} <= ( $prefs{'staffdelete'} ==1 || $prefs{'staffdeleteown'} ==1 ? 2 : 1) ) && $user)
{
    if($cgi->param("submit"))
    {
	print "Post changes...<br>\n<blockquote>\n";
	open(PW, "ls -r archive/*.post.del archive/*.post|");
	foreach(<PW>)
	{
	    s/\.post(\.del)?\n$//;
	    next if(!$cgi->param("$_.exist"));
	    open(PD, "$_.data"); my $pu=<PD>; $pu=~s/\n//; close(PD);
	    next if(uihash($pu)->{'authority'} <= uihash($user)->{'authority'} &&
	       $pu ne $user && uihash($user)->{'authority'}!=1);
	    next if($pu ne $user && $prefs{'staffdelete'}!=1 && uihash($user)->{'authority'}!=1);
	    next if($pu eq $user && ! $prefs{'staffdeleteown'});
	    if((-e "$_.post" ? 1:0) == ($cgi->param($_)?1:0))
	    {
		my @t=("$_.post", "$_.post.del");
		if(-e $t[1])
		{
		    $t[1]=shift @t;
		    print "Restoring post $_<br>\n";
		    uiset($pu, "numposts", uihash($pu)->{'numposts'}+1);
		} else {
		    print "Deleting post $_<br>\n";
		    uiset($pu, "numposts", uihash($pu)->{'numposts'}-1);
		}
		
		system("mv \"$t[0]\" \"$t[1]\"");
	    } else {
#		print "No action on $_<br>\n";
	    }
	}
	print "</blockquote>\nDone.<br>\n";
	print "<br><br>\n<hr color=#FFFFFF>\n<br><br>\n";
	$ENV{'REGEN'}="yes";
	system("./regen.pl");
    }
    print "<form method=post action=\"delete.pl\">\n";
    open(PW, "ls -r archive/*.post.del archive/*.post|");
    print "<font class=\"Ltext\">Number of posts to list:&nbsp;&nbsp;&nbsp;&nbsp;".$cgi->textfield(-style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -name=>"nump", -value=>$cgi->param("nump")||50, -size=>4, -class=>"thin")."&nbsp;<br>\n";
    print "Start list at post number: ".$cgi->textfield(-style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -name=>"numps", -value=>"", -size=>4, -class=>"thin")."&nbsp;<br>\n";
    print $cgi->submit(-style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;", -name=>"submit", -value=>"Save & Change View", -class=>"thin")."<br><br></font>\n";
    print "Select or deselect a post to change its visibility. If the post is checked, then it is invisible.<br><br>\n";
    my $nump=$cgi->param("nump") || 50;
    foreach(<PW>)
    {
	s/\n//;
	my $pn=$_;
	open(PBODY, $_);
	s/\.post(\.del)?$//;
	open(PD, "$_.data"); my $pu=<PD>; $pu=~s/\n//; close(PD);
	next if(uihash($pu)->{'authority'} <= uihash($user)->{'authority'} &&
	       $pu ne $user && uihash($user)->{'authority'}!=1);
	next if($pu ne $user && $prefs{'staffdelete'}!=1 && uihash($user)->{'authority'}!=1);
	    next if($pu eq $user && ! $prefs{'staffdeleteown'});
	my $nn=(split /\//)[-1]; $nn=~s/^0+//;
	next if($cgi->param("numps") && $cgi->param("numps") < $nn);
	last if(!$nump--);
	open(PDATA, "$_.data");
	my $label="<b>".scr(scalar(<PBODY>))."</b> by ".scr(<PDATA>)." on ".timef(<PDATA>)." [ $nn ]";
	my $body=join("",<PBODY>); $body=~s/\<.*?\>//gs; if(length($body)>100) {substr($body, 100)=""; };
	close(PBODY); close(PDATA);
	if($pn=~/\.del$/) 
	{ 
	    print $cgi->checkbox($_, 'checked',1,"");
	} else { 
	    print $cgi->checkbox($_, undef, 1, "");
	}
	print "$label<br>\n";
	print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i> ";
	print $body;
	print "</i><br>\n";
	print $cgi->hidden("$_.exist", 1)."\n";
	print "<br>\n";
    }
    print "<br><br>\n";
    print $cgi->submit(-name=>"submit", -value=>"save visibility changes", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px; color:FFFFFF;")." &nbsp; ";
    print $cgi->reset("reset visibility changes")."<br>\n";
    print "</form>\n";
    close(PW);
} else {
    print "You do not have authorization to delete posts\n";
}

print '
</post>
</entry>

:##}

';
flush(WML);
close(WML);
wait();

sub timef
{
    my @t=split(/[\s:]/, localtime(shift));
    return "$t[0], $t[1] $t[2], $t[6] at ".((($t[3]-1) % 12) + 1).":$t[4]".($t[3]>=12?"pm":"am") ;
}

sub scr { $_[0]=~s/\n//; return $_[0]; }
