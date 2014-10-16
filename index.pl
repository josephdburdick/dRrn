#!/usr/bin/perl


use CGI; my $cgi=new CGI(STDIN);

require "global.pl";
my %prefs; tie %prefs, BSPrefs;

require "userinfo.pl";

my $user=checkuserpasscookie($cgi->cookie("user"), $cgi->cookie("pass"));
$user=undef if($ENV{'REGEN'});

if($user."" eq "" && !$ENV{'REGEN'}) {
    print $cgi->redirect("http://".ue($prefs{'domain'}."/".$prefs{'docpath'}."/".$prefs{'docindex'})) if($prefs{'docindex'}); 
    exit(0);
}
if(!$ENV{'REGEN'})
{
    print "Content-type:text/html\n\n";
}
require "flush.pl";

flush(STDOUT);

open(MOTD, "/".$prefs{'docroot'}."/".$prefs{'docpath'}."/MOTD");
my $subj=<MOTD>;
my $body=join("<br>",<MOTD>);
close(MOTD);
$body=~s/(\<br\>\s*)*\Z//gs;
open(WML, "|./wmlf");
select WML;
print '#include "index.wml"

{#TITLE#: '.$prefs{'sitename'}.': post list :##}

{#BODY#:
<img src="/m/0_drrnewsfront.jpg" width="245" height="40"><br>
      <span align="right"><img src="/m/0_staticetc.jpg"></span><br>
      <table width="98%" border="0" cellpadding="3" align="center">
        <tr> 
          <td class="text" height="100%" valign="top" background="/m/1_staticnews.jpg"> 
            <span class="head"> '.$subj.' </span><br>
	    '.$body.'
	  </td>
        </tr>
      </table>
      <span align="right"><img src="/m/0_dailylog.jpg"></span><br>
';

my @PL=reverse glob("archive/*.post");

my %mo=(1, "Jan",
	2, "Feb",
	3, "Mar",
	4, "Apr",
	5, "May",
	6, "Jun",
	7, "Jul",
	8, "Aug",
	9, "Sep",
	10, "Oct",
	11, "Nov",
	12, "Dec");

my $a=0;

while( ($a++) < (uihash($user)->{'weblogsize'} || $prefs{'frontentries'}) )
{ 
    flush(STDOUT);
    $file=shift @PL; $file=~s/\n//;


    if($file eq "") { last; }
    
    my $num=(split(/\./,$file))[0];
    open(POSTINFO, $file);
    open(POSTDATA, $num.".data");
    my $subject=scr(scalar(<POSTINFO>));
    my $post=join("",<POSTINFO>);
    my $poster=scr(scalar(<POSTDATA>));
    
#    print $post." <br>\n";;
    
    if(uihash($user)->{'skipanonymous'} == 1 && uihash($poster)->{'authority'} > 3)
    {
	$a--;
	print "Skipping $file <br>\n";
	next;
    }
    
    $poster="<a href=\"".uihash($poster)->{'link'}."\">$poster</a>"
	if(uihash($poster)->{'link'}."" ne "" and $prefs{'userlinks'});
    
    my $date=scr(scalar(<POSTDATA>));
    my $pn=sprintf("%7u",(split(/\//,$num))[-1]);
    $pn=~tr/ /0/;
    close(POSTINFO); close(POSTDATA);
    
    print("
<entry>
<date number=\"$pn\" date=\"", datef($date),"\">
<heading>
\[$poster\] $subject
</heading>
<post>");
    
    print $post;
    print "\n</post>\n<time>\n<b>posted by $poster</a> at ";
    flush(STDOUT);
    print timef($date);
    print "</b></time>\n";


    if(-e "$num.post.note")
    {
	open(NOTE, "$num.post.note");
	print "<post>
<ul>
<entry>
<heading>post notes</heading>
<post>
<ol type=\"i\">\n";
	print <NOTE>;
	print "
</ol>
</post>
</entry>
</ol>
</post>
";
	close(NOTE);
    }

print "</entry>\n";
};

close(PL);

sub scr { $_=$_[0]; s/\n//g; return $_; }

print '

:##}

';
close(WML);
wait();

sub timef
{
    my @t=split(/[\s:]+/, localtime(shift));
    return ((($t[3]-1) % 12) + 1).":$t[4]".($t[3]>=12?"pm":"am") ;
}

sub datef
{
    my @t=localtime(shift);
    my $a=sprintf("%4u%2u%2u",$t[5]+1900,$t[4]+1,$t[3]);
    $a=~tr/ /0/;
    return $a;
}
