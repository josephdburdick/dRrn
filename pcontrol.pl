#!/usr/bin/perl

use CGI; my $cgi=CGI::new();

require "global.pl"; my %prefs; tie %prefs, BSPrefs;

require "userinfo.pl";

print "Content-type: text/html\n\n";

require "flush.pl"; flush(STDOUT);

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

open(WML, "|./wmlf");
select WML;
print '#include "layout.wml"

<define-tag postselector attributes=verbatim>
 <set-var %attributes>
 <tr>
  <td><input type="checkbox" name="vis_<get-var number>" <if "<get-var visible>" "" "checked">></td> 
  <td><get-var number></td>
  <td><get-var poster></td>
  <td><b><get-var subject></b></td>
  <td><get-var date></td>
  <td><input type="submit" name="ed_<get-var number>" value="Edit Post <get-var number>" class="thin"></td>
 </tr>
 <tr>
  <td></td>
  <td colspan=5><i><get-var body></i></td>
 </tr>
 <tr><td>&nbsp;</td></tr>
</define-tag>

{#TITLE#: '.$prefs{'sitename'}.': post control :##}
{#BODY#:
';

print "<entry><heading>Delete a post</heading>\n";
print "<post>\n";
if(uihash($user)->{'authority'} <= ( $prefs{'staffdelete'} ==1 || $prefs{'staffdeleteown'} ==1 ? 2 : 1) )
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
	       $pu ne $user);
	    next if($pu ne $user && $prefs{'staffdelete'}!=1 && uihash($user)->{'authority'}!=1);
	    next if($pu eq $user && ! $prefs{'staffdeleteown'});
	    print "bam!<br>\n";
	    if((-e "$_.post" ? 1:0) == ($cgi->param($_)?1:0))
	    {
		my @t=("$_.post", "$_.post.del");
		if(-e $t[1])
		{
		    $t[1]=shift @t;
		    print "Restoring post $_<br>\n";
		    uiset($pu, "numposts", uihash($pu)->{'numposts'}+1);
		} else {
		    print "Hiding post $_<br>\n";
		    uiset($pu, "numposts", uihash($pu)->{'numposts'}-1);
		}
		
		system("mv \"$t[0]\" \"$t[1]\"");
	    } else {
#		print "No action on $_<br>\n";
	    }
	}
	print "</blockquote>\nDone.<br>\n";
	print "<br><br>\n<hr>\n<br><br>\n";
	$ENV{'REGEN'}="yes";
	system("./regen.pl");
    }
    print "<form method=post action=\"pcontrol.pl\">\n";
    open(PW, "ls -r archive/*.post.del archive/*.post|");
    print "Number of posts to list: ".$cgi->textfield(-name=>"nump", -value=>$cgi->param("nump")||50, -size=>4, -class=>"thin")."&nbsp;\n";
    print "Start list at post number ".$cgi->textfield(-name=>"numps", -value=>"", -size=>4, -class=>"thin")."&nbsp;\n";
    print $cgi->submit(-name=>"submit", -value=>"Save & Change View", -class=>"thin")."<br><br>\n";
    print "Select or deselect a post to change its visibility. If the post is checked, then it is invisible.<br><br>\n";
    my $nump=$cgi->param("nump");
    print "<table border=0>\n";
    print "<tr><td>Visible<td colspan=5 align=center><i>Post details</i></td></tr>\n";
    foreach(<PW>)
    {
	s/\n//;
	my $pn=$_;
	open(PBODY, $_);
	s/\.post(\.del)?$//;
	open(PD, "$_.data"); my $pu=<PD>; $pu=~s/\n//; close(PD);
	next if(uihash($pu)->{'authority'} <= uihash($user)->{'authority'} &&
	       $pu ne $user);
	next if($pu ne $user && $prefs{'staffdelete'}!=1 && uihash($user)->{'authority'}!=1);
	    next if($pu eq $user && ! $prefs{'staffdeleteown'});
	my $nn=(split /\//)[-1]; $nn=~s/^0+//;
#	next if($cgi->param("numps") && $cgi->param("numps") < $nn);
#	last if(!$nump--);
	open(PDATA, "$_.data");
	my ($subject, $poster, $pdate)=(scr(scalar(<PBODY>)), scr(<PDATA>), timef(<PDATA>));
	my $body=join("",<PBODY>); $body=~s/\<.*?\>//g; substr($body, 100)="..." if(length($body)>100);

	close(PBODY); close(PDATA);
	my $visible;
	$visible="1";
	if($pn=~/\.del$/) 
	{ 
	    $visible="";
#	    print $cgi->checkbox($_, 'checked',1,"");
	} else { 
#	    print $cgi->checkbox($_, undef, 1, "");
	}
#	print "$label<br>\n";
#	print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>$body </i><br>\n";
#	print $cgi->hidden(-name=>"$_.exist", -value=>1)."\n";
#	print "<br>\n";
	foreach ($subject, $body) { s/\n//g; s/\"/&quot;/g; };
	print "<postselector number=\"$nn\" poster=\"$poster\" date=\"$date\" subject=\"$subject\" body=\"$body\" visible=\"$visible\"/>\n";
    }
    print "</table>\n";
    print "<br>\n";
    print $cgi->submit(-name=>"submit", -value=>"save visibility changes")." &nbsp; ";
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
close(WML);
wait();

sub timef
{
    my @t=split(/[\s:]/, localtime(shift));
    return "$t[0], $t[1] $t[2], $t[6] at ".((($t[3]-1) % 12) + 1).":$t[4]".($t[3]>=12?"pm":"am") ;
}

sub scr { $_[0]=~s/\n//; return $_[0]; }
