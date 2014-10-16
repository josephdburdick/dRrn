#!/usr/bin/perl

sub BSPrefs::TIEHASH
{
    my $class=shift;
    my $self={};
    return bless $self, $class;
}

sub BSPrefs::DESTROY
{
    my $self=shift;
}

sub BSPrefs::FETCH
{
    my ($self, $key)=@_;
    $key=~s/:/::/g;
    $key=~s/\//:f/g;
    open(KEY, "prefs/$key") or return;
    my $value=join("",<KEY>);
    close KEY;
    return $value;
}

sub BSPrefs::STORE
{
    my ($self, $key, $value)=@_;
    $key=~s/:/::/g;
    $key=~s/\//:f/g;
    open(KEY, ">prefs/$key") or return;
    print KEY $value;
    close(KEY);
    system("chmod 777 \"prefs/$key\"");
    return $value;
}

sub BSPrefs::DELETE
{
    my ($self, $key)=@_;
    $key=~s/:/::/g;
    $key=~s/\//:f/g;
    unlink;
}

sub BSPrefs::EXISTS
{
    my ($self, $key)=@_;
    $key=~s/:/::/g;
    $key=~s/\//:f/g;
    return -e "prefs/$key";
}

sub BSPrefs::FIRSTKEY
{
    my ($self)=@_;
    open(DLIST, "ls prefs|");
    @{$self{dlist}}=<DLIST>;
    close(DLIST);
    return shift(@{$self{dlist}});
}

sub BSPrefs::NEXTKEY
{
    my ($self, $lastkey)=@_;
    return shift(@{$self{dlist}});
}

sub ue
{
   @_ = map { s/\/+/\//sg; $_ } @_;
   return @_ if(@_>1);
   return $_[0];
};

1;

