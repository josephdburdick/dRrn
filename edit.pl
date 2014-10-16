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

{#TITLE#: '.$prefs{'sitename'}.': Edit a post :##}
{#BODY#:
';

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

if(!$user || !(uihash($user)->{'authority'} <= ( $prefs{'staffedit'} ==1 || $prefs{'staffeditown'} ==1 ? 2 : 1) ))
{

    print "<entry><post>You do not have authorization to edit a post.</post></entry>\n";

} elsif(!$cgi->param("pn")) {

    print "<entry>
<heading> Select a post to edit </heading>
<post>
";

    print "<form method=post action=\"edit.pl\">\n";
    open(PW, "ls -r archive/*.post.del archive/*.post|");
    print "Select a post to edit.<br><br>\n";
    foreach(<PW>)
    {
	s/\n//;
	my $pn=$_;
	open(PBODY, $_);
	s/\.post(\.del)?$//;
	open(PD, "$_.data"); my $pu=<PD>; $pu=~s/\n//; close(PD);
	next if(uihash($pu)->{'authority'} <= uihash($user)->{'authority'} &&
	       $pu ne $user);
	next if($pu ne $user && $prefs{'staffedit'}!=1 && uihash($user)->{'authority'}!=1);
	    next if($pu eq $user && ! $prefs{'staffeditown'});
	open(PDATA, "$_.data");
	my $nn=(split /\//)[-1];
	my $fnn=$nn; $nn=~s/^0+//;
	my $label="<b>".scr(scalar(<PBODY>))."</b> by ".scr(<PDATA>)." on ".timef(<PDATA>)." [ $nn ]";
	my $body=join("",<PBODY>); $body=~s/\<.*?\>//g; substr($body, 100)="" if(length($body)>100);
	close(PBODY); close(PDATA);

	$label="[DELETED] $label" if($pn=~/\.del$/);

	print "<input type=\"radio\" name=\"pn\" value=\"$fnn\">\n";
	print "<input type=\"hidden\" name=\"pf-$fnn\" value=\"$pn\">\n";

	print "$label<br>\n";
	print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>$body </i><br>\n";
	print $cgi->hidden(-name=>"$_.exist", -value=>1)."\n";
	print "<br>\n";
    }
    print "<br><br>\n";
    print $cgi->submit(-style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px;color:FFFFFF;", -name=>"submit", -value=>"Edit Post");
    print "</form>\n";
    close(PW);
    

    print "
</post>
</entry>
";
} elsif($cgi->param("submit") eq "Edit Post") {

    my $pn=$cgi->param("pn");
    
    open(PDATA, glob("archive/$pn.post*"));
    my ($subject, $body)=(scr(scalar(<PDATA>)), join("",<PDATA>));
    close(PDATA);
    
    print "<entry>
<heading> Edit post: $subject </heading>
<post>

<form method=post action=\"edit.pl\">
<span class=\"Ltext\">Post subject:</span> ".$cgi->textfield(-name=>"subject", -style=>"width:500px", -size=>"80", -value=>"$subject")."<br><br>
Post:<br>\n<nostrip>
<textarea name=\"body\" rows=30 columns=400 style=\"width:500px\">
$body
</textarea>
</nostrip>
<br><br>\n";

    print $cgi->checkbox(-name=>"nlex", -checked=>"yes", -label=>"Skip expansion of newlines to <BR>");

    print "<br><br>\n".$cgi->submit(-name=>"preview", -value=>"Preview");

    print " [The <b>Save</b> button will activate once you Preview your edit]\n";

    print $cgi->hidden(-name=>"pn", -value=>$cgi->param("pn"));
    print $cgi->hidden(-name=>"pf-".$cgi->param("pn"), -value=>$cgi->param("pf-".$cgi->param("pn")));
    
    print "</form>
</post>
</entry>
";
} elsif($cgi->param("preview")) {
    print "<entry>
<heading> Edit post: ".$cgi->param("subject")." </heading>
<post>

<form method=post action=\"edit.pl\">
<font class=\"Ltext\">Post subject:</font> ".$cgi->textfield(-name=>"subject", -size=>"80", -value=>$cgi->param("subject"))."<br><br>
Post:<br>\n<nostrip>
<textarea name=\"body\" rows=15 columns=400 style=\"width:500px\">
".$cgi->param("body")."
</textarea>
</nostrip>
<br><br>\n";

    if($cgi->param("nlex")) {
	print $cgi->checkbox(-name=>"nlex", -checked=>"yes", -label=>"Skip expansion of newlines to <BR>");
    } else {
	print $cgi->checkbox(-name=>"nlex", -label=>"Skip expansion of newlines to <BR>");
    }
    print "<br><br>\n".$cgi->submit(-name=>"preview", -value=>"Preview", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana;font-size:10px;color:FFFFFF;")."&nbsp;";

    print $cgi->submit(-name=>"submit", -value=>"Save", -style=>"border:1px solid #990000;background:FF0000;font-family:verdana; font-size:10px;color:FFFFFF;");

    print $cgi->hidden(-name=>"pn", -value=>$cgi->param("pn"));
    print $cgi->hidden(-name=>"pf-".$cgi->param("pn"), -value=>$cgi->param("pf-".$cgi->param("pn")));

    print "\n";
    print "</form>
</post>
</entry>

<entry>
<heading> ".$cgi->param("subject")." </heading>
<post> ".add_br($cgi->param("body"))." </post>
</entry>
";
} elsif($cgi->param("submit") eq "Save") {
    #submit post

    my $subject=$cgi->param("subject");
    my $body=add_br($cgi->param("body"));

	print "
<entry>
<heading> $subject </heading>
<post> $body </post>
</entry>

<entry>
<heading> Post changed </heading>
<post> The post has been edited sucessfully. </post>
</entry>
";
	
    my $pn=$cgi->param("pn");

    open(POST, ">".$cgi->param("pf-$pn"));
    print POST "$subject\n";
    print POST "$body";
    close(POST);
    
    $ENV{'REGEN'}="yes";
    system("./regen.pl");
	
    system("chmod 666 archive/".nf($pn).".post*");
    

}

print '

:##}

';
close(WML);
wait();

sub nf
{
    #turn a number into one with 8 digits, ie 123 -> 00000123
    $_=sprintf("%8u",@_);
    s/ /0/g;
    return $_;
}

sub add_br
{
    return $_[0] if($cgi->param("nlex"));
    my @text=split(/\<\/?pre(\s+[^\>]*)?\>/si, $_[0]);
    my $text;
    for(my $a=0; $a <= @text; $a+=4)
    {
	$text[$a]=~s/\n/\<br\>\n/g;
	$text.=$text[$a]."<pre>".$text[$a+2]."</pre>\n";
    }
    $text=~s/<pre><\/pre>$//;
    return $text;
}
    
sub scr { $_=$_[0]; s/\n//g; return $_; }

sub timef
{
    my @t=split(/[\s:]/, localtime(shift));
    return "$t[0], $t[1] $t[2], $t[6] at ".((($t[3]-1) % 12) + 1).":$t[4]".($t[3]>=12?"pm":"am") ;
}

