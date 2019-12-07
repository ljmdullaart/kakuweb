#!/usr/bin/perl 
#REMOTE@ chi /var/www/cgi-bin/home.pl
use strict;
use CGI;
use POSIX qw(strftime);

my $datafile='/var/www/data/kaku/data';
my $codefile='/var/www/data/kaku/codes';

my %crons;
my $display='switch';

if (open (my $DATA, "<", $datafile)){
	while (<$DATA>){
		chomp;
		(my $key,my $value)=split ',';
		$crons{$key}=$value;
	}
	close $DATA;
}
my $query = CGI->new();
print $query->header( "text/html" );
print $query->start_html(
	-title   => "Home", 
	-style   => "http://chi.home/kaku.css",
	-meta    => {
		viewport => 'width=device-width,initial-scale=1,user-scalable=yes'
	}
);

my $debugout;

my $action='none';
my @lines ;

my %codes;
my %codelist;
if (open (my $CODES, "<", $codefile)){
	while (<$CODES>){
		chomp;
		s/#.*//;
		my @a=/;/g;
		if ( scalar @a == 2){

			(my $key,my $name,my $list)=split ';';
			$codes{$key}=$name;
			$codelist{$key}=$list;
		}

	}
	close $CODES;
}
else {
	print "<p>No code file</p>";
}
#$codes{7500}="lampen TVkast L-J";
#$codes{7501}="vitrine fototoestellen";
#$codes{7502}="vitrine souvenirs";
#$codes{7503}="bar meubel";
#$codes{7504}="printer";
#$codes{7505}="meterkast";
#$codes{7506}="lamp boven cavias";
#$codes{7507}="lamp bibliotheek";
#$codes{7508}="open haard";
#$codes{7510}="fontein";
#$codes{7600}="kerst ramen voor";
#$codes{7601}="kerst klokjes achter";
#$codes{7602}="kerstboom";
#$codes{'woonkamer'}="Woonkamer L-J";
##

# read form data

my %params=$query->Vars;

if ($params{"display"} ne ''){
		$display=$params{"display"};
}
if ($params{"clock"} ne ''){
		$display='clock';
}
if ($params{"switch"} ne ''){
		$display='switch';
}

for my $k (keys %codes){
	if ($params{"aan$k"} ne ''){
			$action="aan$k";
			$display='switch';
	}
	if ($params{"uit$k"} ne ''){
			$action="uit$k";
			$display='switch';
	}
	for (my $i=0; $i<24; $i++){
		if ($params{"c$i$k"} ne ''){
			$action="c$i$k";
			$display='clock';
		}
	}
}
#
if ($action =~ /aan(..*)/) {
	my $key=$1;
	my @list=split(',',$codelist{$key});
	for (@list){
		system ("logger KAKU  $_ 1 on");
		system ("newkaku $_ 1 on | logger 2>&1");
	}
}
elsif ($action =~ /uit(..*)/) {
	my $key=$1;
	my @list=split(',',$codelist{$key});
	for (@list){
		system ("logger KAKU  $_ 1 off");
		system ("newkaku $_ 1 off | logger 2>&1");
	}
}
elsif ($action =~/^c/){
	for my $k (sort (keys %codes)){
		my $hr;
		if (exists ($crons{$k})){
			if ($action =~ /c([0-9]*)$k/){
				$hr=$1;
				if ($crons{$k}=~/on$hr;/){
					$crons{$k}=~s/on$hr;/off$hr;/;
				}
				elsif ($crons{$k}=~/off$hr;/){
					$crons{$k}=~s/off$hr;//;
				}
				else {
					$crons{$k}="$crons{$k}on$hr;";
				}
			}
		}
	}
}


if (open (my $DATA, ">", $datafile)){
	for my $k (sort (keys %codes)){
		print $DATA "$k,$crons{$k}\n";
	}
	close $DATA;
}

#
# provide the output
#
#
#
#
print $query->h1( "Klik Aan, Klik Uit" );
print "\n";
print $query->hr;
print $query->start_form;
print $query->submit(
	-name    => "switch",
	-value   => 'switch',
	-class   => 'tab',
);
print $query->submit(
	-name    => "clock",
	-value   => 'clock',
	-class   => 'tab',
);
print $query->hidden(
	-name    => 'display',
	-value   => $display,
);
if ($display eq 'switch'){
	print "<table class='switchtable'>";
	print "\n";
	for my $k (sort (keys %codes)){
		print "    <tr>\n        <td class='swname'>$codes{$k}</td>\n        <td class='swon'>";
		print $query->submit(
			-name    => "aan$k",
			-value   => 'aan',
			-class   => 'onoff',
		);
		print "</td>\n        <td class='swoff'>";
		print $query->submit(
			-name    => "uit$k",
			-value   => 'uit',
			-class   => 'onoff',
		);
		print "</td>\n    </tr>\n";
	}
	print "</table>";
	#
}
elsif ($display eq 'clock'){
	print "<table>";
	print "\n";
	for my $k (sort (keys %codes)){
		print "    <tr>\n        <td>$codes{$k}</td>\n        <td>";
		for (my $i=0; $i<24;$i++){
			print "</td>\n        <td>";
			my $style;
			$style='cron';
			if ($crons{$k}=~/on$i;/){
				$style='cronon';
			}
			if ($crons{$k}=~/off$i;/){
				$style='cronoff';
			}
			print $query->submit(
				-name    => "c$i$k",
				-value   => "$i",
				-class   => $style,
			);
		}
		print "</td>\n    </tr>\n";
	}
	print "</table>";
	#
	
	
}
print $debugout;
print $query->end_html;
