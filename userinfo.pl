#!/usr/bin/perl

my @fields=(
	    "username", 
	    "passhash", 
	    "authority", 
	    "link", 
	    "email", 
	    "skipanonymous", 
	    "weblogsize", 
	    "numposts"
	    );

sub getuserinfo
{
    my $matchfield=shift;
    my $matchvalue=shift;
    open(PW, "priv/.htpasswd");
    my @pwl=<PW>;
    close(PW);

    my @matches=();

    foreach(@pwl)
    {
	s/\n//;
	my @uinfo=split(/::/, $_);
	
	if($uinfo[$matchfield] eq $matchvalue)
	{
	    push(@matches, \@uinfo);
	}
    }

    return @matches;
}

sub getusers
{
    open(PW, "priv/.htpasswd");
    my @pwl=<PW>;
    close(PW);

    my @users=();

    foreach(@pwl)
    {
	s/\n//;
	my @uinfo=split(/::/, $_);
	push(@users, $uinfo[0]) if($uinfo[0]."" ne "");
    }

    return @users;
    
}

sub removeuser
{
    my $matchfield=shift;
    my $matchvalue=shift;
    open(PW, "priv/.htpasswd");
    my @pwl=<PW>;
    close(PW);

    my @matches=();
    my @nonmatch=();

    foreach(@pwl)
    {
	s/\n//;
	my @uinfo=split(/::/, $_);
	
	if($uinfo[$matchfield] eq $matchvalue)
	{
	    push(@matches, \@uinfo);
	} else {
	    push(@nonmatch, \@uinfo);
	}
    }

    open(PW, ">priv/.htpasswd");
    foreach(@nonmatch)
    {
	print PW join("::", @{$_})."\n";
    }
    close(PW);
    return @matches;
}

sub setuserinfo
{
    my $matchfield=shift;
    my @uinfo=@_;
    open(PW, "priv/.htpasswd");
    my @pwl=<PW>;
    close(PW);

    foreach(@uinfo) { s/(::)|(\n)//g }

    my @infofile;
    my $updated=0;

    open(PW, ">priv/.htpasswd");
    foreach(@pwl)
    {
	s/\n//;
	my @infoline=split(/::/, $_);
	if($infoline[$matchfield] eq $uinfo[$matchfield])
	{
	    $updated++;
	    @infoline=@uinfo;
	}
	print PW join("::",@infoline);
	print PW "\n";
    }
    close(PW);
    return $updated;
    
}

sub newuser
{
    my $user=shift;
    open(PW, ">>priv/.htpasswd");
    print PW "$user\n";
    close(PW);
}

sub checkuserpass
{
    my $user=shift;
    my $pass=shift;
    my %uinfo=%{uihash($user)};

    if(! $uinfo{'passhash'}) { return; }

    return if(uihash($user)->{'authority'} >= 5);

    return $user if(crypt($pass, $uinfo{'passhash'}) eq $uinfo{'passhash'});

    return;
}

sub checkuserpasscookie
{
    my $user=shift;
    my $pass=shift;
    my %uinfo=%{uihash($user)};

    if(! $uinfo{'passhash'}) { return; }

    return if(uihash($user)->{'authority'} >= 5);

    return $user if(crypt($uinfo{'passhash'}, $user) eq $pass);

    return;
}

    
sub uihash
{
    my $user=shift;

    my %fields=();
    
    my @tf=@fields;

    my @uinfo=@{(getuserinfo(0, $user))[0]};

    $fields{shift @tf}=shift @uinfo while(@tf);

    return \%fields;
}

sub uiset
{
    my $user=shift;
    my $field=shift;
    my $value=shift;

    my @tf=@fields;
    
    shift @tf while($tf[0] ne $field && @tf);

    return if(!@tf);

    my @uinfo=@{(getuserinfo(0, $user))[0]};
    $uinfo[@fields-@tf]=$value;
    setuserinfo(0, @uinfo);
}

1;
