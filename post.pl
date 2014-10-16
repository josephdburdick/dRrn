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

{#TITLE#: '.$prefs{'sitename'}.': Add a new post :##}
{#BODY#:

';

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));

if(!$user)
{
    print "<entry>
<heading> Error: Please Log In </heading>
<post> You must log in before you can post.<br><br>

If you want an account, just click on the \"New User\" link, next to the Login button. Or, if you're lazy and don't want to bother, just click Login to post as a contributor.
</post>
</entry>
";


} elsif(!$cgi->param("submit")) {
    print "<entry>
<heading> Add a new post as $user </heading>
<post>

<form method=post action=\"post.pl\">
Post subject: ".$cgi->textfield(-name=>"subject", -size=>"65", -value=>$cgi->param("subject"))."<br><br>
Post:<br>\n
<nostrip>
".$cgi->textarea("body", $cgi->param("body")||"", 15, 65)
    ."
</nostrip>
<br><br>\n";

    if($cgi->param("nlex")) {
	print $cgi->checkbox(-name=>"nlex", -checked=>$cgi->param("nlex"), -label=>"Skip expansion of newlines to <BR>");
    } else {
	print $cgi->checkbox(-name=>"nlex", -label=>"Skip expansion of newlines to <BR>");
    }
    print "<br><br>\n".$cgi->submit(-name=>"preview", -value=>"Preview");

    if($cgi->param("preview"))
    {
	#force preview
	print $cgi->submit(-name=>"submit", -value=>"Post");
    } else {
	print " [The <b>Post</b> button will activate once you Preview your post]\n";
    }

    print $cgi->hidden(-name=>"postid", -value=>($cgi->param("postid")?$cgi->param("postid"):rand()));

    print "\n<br><br> Acceptable HTML: ".ok_html()."<br>\n";

    print "</form>
</post>
</entry>
";

    if($cgi->param("preview"))
	#post preview
    {
	my $s=$cgi->param("subject"); $s=~s/\</&lt;/gs; $cgi->param("subject", $s); #strip HTML from subject

	my $subject=$cgi->param("subject");
	my $body=add_br($cgi->param("body"));
	print "
<entry>
<heading> $subject </heading>
<post> $body </post>
</entry>
";
    }
} else {
    #submit post

    my $subject=$cgi->param("subject");
    my $body=add_br($cgi->param("body"));

    if(! -e "postid/".$cgi->param("postid"))
	#catch accidental reposts
    {
	print "
<entry>
<heading> $subject </heading>
<post> $body </post>
</entry>

<entry>
<heading> Your post has been added </heading>
<post> Don't like it? Found a typo?<br>Only STAFF level accounts can edit posts. </post>
</entry>
";
	
	open(PN, "archive/.maxpost"); $pn=<PN>; $pn+=1; close(PN);
	open(PN, ">archive/.maxpost"); print PN $pn; close(PN);

	open(POST, ">archive/".nf($pn).".post");
	print POST "$subject\n";
	print POST "$body";
	close(POST);

	open(POSTDATA, ">archive/".nf($pn).".data");
	print POSTDATA $cgi->cookie("user")."\n"; #user
	print POSTDATA time()."\n"; #date/time
	close(POSTDATA);       
	
	open(POSTID, ">postid/".$cgi->param("postid"));
	print POSTID scalar time();
	close(POSTID);

	uiset($user, 'numposts', uihash($user)->{'numposts'}+1);

	$ENV{'REGEN'}="yes";
	system("./regen.pl");
	
	system("chmod 666 archive/".nf($pn).".post archive/".nf($pn).".data postid/".$cgi->param("postid"));

    } else {
	#repost
	print "
<entry>
<heading> You big pooferadooferus... </heading>
<post> That post has already been added! </post>
</entry>
";
	
    }
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
    $_[0]=html_check($_[0]);
    return $_[0] if($cgi->param("nlex"));
    my @text=split(/\<\/?pre(\s+[^\>]*)?\>/si, $_[0]);
    my $text;
    for(my $a=0; $a <= @text; $a+=4)
    {
	$text[$a]=~s/\n/\<br\>\n/g;
	$text.=$text[$a];
	$text.="<pre>".$text[$a+2]."</pre>\n" if($text[$a+2]);
    }
    return $text;
}
    
sub scr { $_=$_[0]; s/\n//g; return $_; }

sub html_check
{
    #sometimes people are stupid; this fixes that problem (somewhat).
    if(!$prefs{'okhtml'}=~/\S/s) 
	#No HTML allowed (!)
    {
	$_[0]=~s/\</&lt;/gxs;
	return $_[0];
    }

    my $ok_html=join("|", map { "($_\\b)|(\\/$_\\b)" } split(/\s+/s, $prefs{'okhtml'}));
    $_[0]=~s/\<(?!$ok_html)/&lt;/igxs; #strip bad tags

    #okay, time to get bloody. Strip bad elements of good tags
    $_[0]=~s/<[^<>]*(?=<)/" [\<b>runaway tag detected:<\/b> ".s_lt("$&")."] "/gsxe;
    $_[0]=~s/\<[^\>]*\>/&h_arg($&)/gxes;
    return $_[0];
}

sub s_lt { $_[0]=~s/</&lt;/gs; return $_[0]; }

sub h_arg
{

    
    my @args=map { $_ if($_=~/\S/) } split( /\s+(?!([^\"]*\"[^\"]*\")*[^\"]*\"[^\"]*\Z)/xs,
				      $_[0]
				      );
    my $os=shift(@args);
    $os=~s/^\<//;
    if($os=~/(?<!\A)\W(?!\Z)|\A[^\w\/]/ or !$os or $_[0]=~/(?<!\A)\</) 
    { 
	my ($dummy, $t, $f)=split(/([\<\>])/, $os, 2);
	$os=~s/\</&lt;/g;
	return " [\<b>invalid tag detected:</b> $os] ".($t eq "<"?"<":"");
    }
    my $ok_args=join("|", split(/\s+/s, $prefs{'okhtml_'.lc($os)}));
    
    $os="<$os";
#    return $os;
    foreach(@args)
    {
	next if(!/\S/);
	if((split(/=(?!([^\"]*\"[^\"]*\")*\Z)/,$_,2))[0]=~/\A\s*$ok_args\s*\Z/i) 
	{
	    $os.=" $_";
	} else {

	    my $o=(split(/=(?!([^\"]*\"[^\"]*\")*\Z)/,$_,2))[0];

	    if((split(/=(?!([^\"]*\"[^\"]*\")*[^\"]*\"[^\"]*\Z)/,$_,2))[0]=~/[\>\<]/)
	    {
		#runaway argument, it seems
		my ($dummy, $t, $f)=split(/([\<\>])/, $os, 2);
		return " [\<b>runaway tag detected:<\/b> ".s_lt($os)."] ".($t eq "<"?"<":"");;
	    }
	    
	    
#	    $os.=" --".(split(/=(?!([^\"]*\"[^\"]*\")*[^\"]*\"[^\"]*\Z)/,$_,2))[0]."-- ";
	}
    }
    $os.=">" if($os!~/>\s*\Z/);
    return $os;
}

sub ok_html
{
    if(!$prefs{'okhtml'}=~/\S/s) 
	#No HTML allowed (!)
    {
	return "[ <b>NONE</b> ]";
    }
    return join(" ", 
		map { 
		    "<b>$_</b>".($prefs{"okhtml_$_"}?"[".join(" ", map { s/\s//g; $_ if(/\S/) } split(/\s+/s, $prefs{'okhtml_'.$_}))."]":"") if(/\S/) 
		    } 
		split( /\s+/s, $prefs{'okhtml'} )
		);
}
