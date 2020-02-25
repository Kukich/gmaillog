#!/usr/bin/perl
use DBI;
use strict;
use lib './';
use Utils qw/LoadYamlFile/;
use Data::Dumper;


my $conf = LoadYamlFile('gconf.yaml');

my $dbh = DBI->connect(
        'dbi:mysql:dbname='
          . $conf->{db}
          . ( $conf->{host} ? ';host=' . $conf->{host} : '' )
          . ( $conf->{port} ? ';port=' . $conf->{port} : '' ),
        $conf->{user} ? $conf->{user} : '',
        $conf->{passwd} ? $conf->{passwd} : '',
        $conf->{attrs}) or die $DBI::errstr;

open STDIN,"<out" or die "cant open file because $!";
my $j=0;

my $v = 0;

my $hash = {};
while (<STDIN>){
	$j++;
	chomp;
	my $str = $_;
	if($str =~ /^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (.+?)\s?([<=>\-*]{2})? (.+)$/){
		my ($created,$int_id,$status,$other) = ($1,$2,$3,$4);
		$str =~ s/${created} //;
		if($status eq '<='){
			my $id = "";
			if($other =~ /id=(.+)\s?/){
				$id = $1;
				my $sql = qq~insert into message values(?,?,?,?,?)~;
				$dbh->do($sql,undef,$created,$id,$int_id,$str,0);
				$hash->{$int_id}=1;
			}else{
				print STDERR "cant insert str to message with int_id = $int_id because no id\n";
				$v++;
			}
		}else{
			my $address = "";
			if($other =~ /([a-z0-9\-\_.]+\@[a-z0-9\-_.]+\.[a-z0-9\-_.]+)/i){
				$address = $1;
			}
			my $sql = qq~insert into log values(?,?,?,?)~;
			$dbh->do($sql,undef,$created,$int_id,$str,$address);
			if($status eq '=>' ){
				if(exists $hash->{$int_id}){
					my $sql = qq~update message set status =1 where int_id =?~;
					$dbh->do($sql,undef,$int_id);
					delete $hash->{$int_id};
				}
			}
		}
	}

	
#	last if $j>=150;
}
print "didnt insert $v lines\n";
my $inserted = $j-$v;
print "insert $inserted lines\n";
close STDIN;
$dbh->disconnect;
   
