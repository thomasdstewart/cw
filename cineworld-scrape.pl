#!/usr/bin/perl -w
###############################################################################
#cineworld-scrape gets cinema listings and converts them from html to xml
#
#Copyright (C) 2006 Thomas Stewart <thomas@stewarts.org.uk
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
###############################################################################

use strict;
use Data::Dumper;
use LWP::Simple; 
use Switch;
use Time::Local;
use XML::DOM;

# defaults to stevenage;
my $abv_name;
if(defined($ARGV[0])) {
        $abv_name = $ARGV[0];
} else {
        $abv_name = "soi"; 
}

#This seems to be hardcoded, ie from main cineworld page you select 
#"Ashton Under Lyne" from a combo, which uses "ashton" goto to:
#http://www.cineworld.co.uk/cinemas/ashton.phtml which has a printer friendly
#link http://www.cineworld.co.uk/listings/printable.php?wantedSite=adi
#where adi seems to be static. So the xml file produced has a good name, just
#hard code a conversion here.
my $name;
switch ($abv_name) {
        case "aai"      { $name="Ashford";                      }
        case "adi"      { $name="Ashton Under Lyne"             }
        case "bfi"      { $name="Bexleyheath";                  }
        case "1bi"      { $name="Bishop's Stortford";           }
        case "7bi"      { $name="Bradford";                     }
        case "8bi"      { $name="Braintree";                    }
        case "bmi"      { $name="Bristol";                      }
        case "b3i"      { $name="Burton on Trent";              }
        case "xyi"      { $name="Bury St. Edmunds";             }
        case "xii"      { $name="Cambridge";                    }
        case "c7i"      { $name="Castleford";                   }
        case "x2i"      { $name="Cheltenham";                   }
        case "cai"      { $name="Chesterfield";                 }
        case "1ci"      { $name="Chichester";                   }
        case "fhi"      { $name="Falkirk";                      }
        case "fai"      { $name="Feltham";                      }
        case "hli"      { $name="Huntingdon";                   }
        case "idi"      { $name="Ilford";                       }
        case "nii"      { $name="Isle of Wight";                }
        case "jdi"      { $name="Jersey";                       }
        case "lhi"      { $name="Llandudno Junction";           }
        case "lji"      { $name="Luton";                        }
        case "mdi"      { $name="Milton Keynes";                }
        case "nii"      { $name="Newport - Isle of Wight";      }
        case "rhi"      { $name="Rugby";                        }
        case "rgi"      { $name="Runcorn";                      }       
        case "sai"      { $name="Shrewsbury";                   }
        case "szi"      { $name="Solihull";                     }
        case "syi"      { $name="St. Helens";                   }
        case "s8i"      { $name="Sunderland";                   }
        case "jdi"      { $name="St. Helier";                   }
        case "soi"      { $name="Stevenage";                    }
        case "sbi"      { $name="Swindon";                      }
        case "wli"      { $name="Wakefield";                    }
        case "wxi"      { $name="Wandsworth";                   }
        case "wmi"      { $name="Weymouth";                     }
        case "wbi"      { $name="Wolverhampton";                }
        case "wti"      { $name="Wood Green";                   }
        case "yci"      { $name="Yeovil";                       }
}

#form printer friendly url and get the html from the intraweb
my $url="http://www.cineworld.co.uk/listings/" .
                "printable.php?wantedSite=" . $abv_name;
my $data=get($url);

#split the text over newline marks and test to see if a line has a <hr> in, if
#it does put it in a new element of the films array. ie split the text over 
#<hr>'s, filling the text into an array
my @films;
my $i=0;
foreach(split ('\r\n', $data)) {
        chomp;
        if(/<hr/) { $i++; }
        if(!defined($films[$i])) { $films[$i]="";}
        $films[$i] = $films[$i] . $_;
}

#print Dumper(@films);

#create a new xml document and add some general info elements
my $xml = XML::DOM::Document->new;
my $xml_pi = $xml->createXMLDecl ('1.0');
my $cinemalistings = $xml->createElement('cinemalistings');
$cinemalistings->setAttribute('chain', 'cineworld');
$cinemalistings->setAttribute('name', $name);
$cinemalistings->setAttribute('abvname', $abv_name);
$cinemalistings->setAttribute('originalurl', $url);

my $starttime; my $endtime;
my $type="normal";
foreach(@films) {
        if(/Films from \w+ (\d+)<sup>\w+<\/sup> (\w+) for (\d+) days/) {
                #"Films from Friday 31<sup>st</sup> March for 7 days"
                #$1=31
                #$2=March
                #$3=7

                #print $1 . "," . "$2" . "," . "$3\n"; 

                my $month=0;
                switch ($2) {
                        case "January"          { $month = 0;  }
                        case "February"         { $month = 1;  }
                        case "March"            { $month = 2;  }
                        case "April"            { $month = 3;  }
                        case "May"              { $month = 4;  }
                        case "June"             { $month = 5;  }
                        case "July"             { $month = 6;  }
                        case "August"           { $month = 7;  }
                        case "September"        { $month = 8;  }
                        case "October"          { $month = 9;  }
                        case "November"         { $month = 10; }
                        case "December"         { $month = 11; }
                }             

                my $year = `date +%Y`;

                $starttime = timelocal(0, 0, 4, $1, $month, $year);
                $endtime = $starttime + timelocal(0, 0, 0, $3 + 2, 0, 0);

                #print scalar localtime $starttime;              print "\n";
                #print scalar localtime $endtime   . "\n";       print "\n";
        }

        if(/<br><br><b><big>/) {
                if(/advance showings/) {
                        $type = "advance";
                } elsif(/bollywood/) {
                        $type = "bollywood";
                } elsif(/movies for juniors/) {
                        $type = "juniors";
                } elsif(/monday classic/) {
                        $type = "classic";
                } else {
                        $type = "normal";
                }
        }

        if(/<hr.+<b><big>(.+)<\/big><small>\((.+)\)\((.+)\)<\/small><\/b><br>(.+)$/) {
                my $title = $1;
                my $cert = $2;
                my $length = $3;
                my $times = $4;

                #Make title title case
                $title =~ s/(\w)(\w+)/\U$1\L$2/g;
                $title =~ s/'(\w)/'\L$1/g;

                $title =~ s/\x92/'/g;
                $title =~ s/\x96/-/g;

                #if($title ne "Hostel") { next; }
                
                #drop the min, and sometimes there are 2 times, frop that too
                $length =~ s/mins//;
                $length =~ s/\d+ (\d+)/$1/;
                $length =~ s/ //g;

                #Clean up the times a bit
                $times =~ s/<small>[\(\),a-zA-Z ]+<\/small>//i;
                $times =~ s/(<p><small><b>\[<\/b> Listings powered by.+)//i;
                $times =~ s/OSCAR WINNER//i;
                $times =~ s/<br>//ig;

                $times =~ s/\s*[-=\/]*\s*Audio Description\s*//ig;
                $times =~ s/\s*[-=\/]*\s*Subtitled\s*//ig;
                $times =~ s/AD\/S/ADS/ig;

                $times =~ s/a\.m/am/ig;
                $times =~ s/p\.m/pm/ig;
                $times =~ s/ & /, /g;
                $times =~ s/except/not/ig;

                $times =~ s/^\s*//;
                $times =~ s/\s*$//;
                $times =~ s/\s\)/\)/g;

                $times =~ s/monday/mon/ig;
                $times =~ s/tuesday/tue/ig;
                $times =~ s/wednesday/wed/ig;
                $times =~ s/thursday/thu/ig;
                $times =~ s/friday/fri/ig;
                $times =~ s/saturday/sat/ig;
                $times =~ s/sunday/sun/ig;
                $times =~ s/mon/mon/ig;
                $times =~ s/tue/tue/ig;
                $times =~ s/wed/wed/ig;
                $times =~ s/thu/thu/ig;
                $times =~ s/fri/fri/ig;
                $times =~ s/sat/sat/ig;
                $times =~ s/sun/sun/ig;

                if($type eq "classic") {
                        $times = "mon " . $times;
                }

                my @splittimes = split (',', $times);
                foreach(@splittimes) {
                        s/\(//g;
                        s/\)//g;
                        s/ //g;
                        s/only//g;
                        s/not//g;

                        s/ADS//g;
                        s/AD//g;

                        s/(mon)|(tue)|(wed)|(thu)|(fri)|(sat)|(sun)//g;
                }

                @splittimes = grep /\S/, @splittimes;

                #print "*" . $times . "\n";
                #foreach (@splittimes) { print "-" ; print; print "-\t"; }
                #print "\n";

                $splittimes[0] =~ /(\d{1,2})\.(\d{2})/;
                my $hour = $1; my $min = $2;
                my $firsttimecode = ($hour * 60) + $min;
                my $prevtimecode = $firsttimecode;
                
                my $am_or_pm = "am";
                if($splittimes[0] =~/([apm]{2})/) {
                        $am_or_pm = $1;
                }

                foreach my $splittime (@splittimes) {
                        $splittime =~ /(\d{1,2})\.(\d{2})/;
                        my $hour = $1; my $min = $2;
                        my $timecode = ($hour * 60) + $min;
                        #print $hour . "." . $min . "." . $am_or_pm . "-";
                        #print $timecode . "\n";

                        if($timecode < $prevtimecode) {
                                $am_or_pm = "pm";
                        }

                        if(($hour < 9) && ($am_or_pm eq "am")) {
                                $am_or_pm = "pm";
                        }

                        $splittime = $hour . "." . $min . $am_or_pm;
                }

                #print "*" . $times . "\n";
                #foreach (@splittimes) { print; print "\t"; } print "\n";

                foreach my $time (@splittimes) {
                        #print Dumper $time;
                        $time =~ /^(\d{1,2})\.(\d{2})([apm]{2})$/;
                        my $hour = $1; my $min = $2; my $am_or_pm = $3;
                        my $adj_hour = $hour;

                        if(($am_or_pm eq "pm") && ($hour != 12)) {
                                $adj_hour += 12;
                        }
                        #print $hour . "." . $min . $am_or_pm;
                        #print "(" . $adj_hour . ")\n";

                        $times =~ s/$hour\.${min}am/$adj_hour\.$min/;
                        $times =~ s/\($hour\.${min}am/\($adj_hour\.$min/;

                        $times =~ s/$hour\.${min}pm/$adj_hour\.$min/;
                        $times =~ s/\($hour\.${min}pm/\($adj_hour\.$min/;

                        $times =~ s/ $hour\.$min,/ $adj_hour\.$min,/;
                        $times =~ s/\($hour\.$min,/\($adj_hour\.$min,/;
                        $times =~ s/$hour\.$min /$adj_hour\.$min /;
                        $times =~ s/$hour\.$min$/$adj_hour\.$min/;
                        $times =~ s/^$hour\.$min,/$adj_hour\.$min,/;
                        $times =~ s/$hour\.${min}ADS/$adj_hour\.${min}ADS/;
                        $times =~ s/$hour\.${min}AD/$adj_hour\.${min}AD/;
                        #print $times . "\n";
                }

                #printf ("%-48s %s\n", $title, $times); next;
                $times =~ s/,/ /g;
                $times =~ s/\(/\( /g;
                $times =~ s/\)/ \)/g;
                $times =~ s/  / /g;
                #print $times . "\n";

                @splittimes = split(' ', $times);
                #foreach my $time (@splittimes) { print "*" . $time . "\n"; }

                my $mode="none";
                my @daylist=();
                my @timelist=();
                $times ="";
                
                # $time+
                # $day+ $time+
                # $time+ ( $time $day+ only ) $time+ ( $time+ not $day )
        
                for my $i (0..$#splittimes) {
                        my $time = $splittimes[$i];

                        if($time =~ /only/) { $mode = "only";   }
                        if($time =~ /not/)  { $mode = "not";    }

                        if($time =~ /^((mon)|(tue)|(wed)|(thu)|(fri)|(sat)|(sun))$/) {
                                push(@daylist, $1);
                        }

                        if($time =~ /^(\d{1,2}\.\d{2})/) {
                                push(@timelist,$1);
                        }

                        if(($time =~ /^\($/) || ($time =~ /^\)$/) || 
                                        ($i == $#splittimes)) {

                                if($mode eq "none") {
                                        if($#daylist == -1) {
                                                @daylist = qw/ mon tue wed thu fri sat sun /;
                                        }
                                } elsif($mode eq "only") {

                                } elsif($mode eq "not") {
                                        my $days = "mon,tue,wed,thu,fri,sat,sun";
                                        foreach my $day (@daylist) {
                                                $days =~ s/$day,//;        
                                        }
                                        @daylist = split(',', $days);
                                        #print "N" . join('-', @daylist) . "\n";
                                }

                                @daylist = sort @daylist;
                                foreach my $day (@daylist) {
                                        foreach my $time (@timelist) {
                                                $times = $times . 
                                                        $time . $day . ";";
                                        }
                                }

                                #print "##" . join('-', @daylist) . " " .
                                #       join('-', @timelist) . "\n";

                                $mode = "none";
                                @daylist=();
                                @timelist=();
                        }

                }

                @splittimes = split(';', $times);
                $times="";
                foreach my $time (@splittimes) {
                        $time =~ /^(\d{1,2})\.(\d{2})(\w{3})$/;
                        my $hour = $1; my $min = $2; my $day_of_week = $3;

                        my $offset;
                        if(      $day_of_week eq "fri") { $offset=0;
                        } elsif ($day_of_week eq "sat") { $offset=1;
                        } elsif ($day_of_week eq "sun") { $offset=2;
                        } elsif ($day_of_week eq "mon") { $offset=3;
                        } elsif ($day_of_week eq "tue") { $offset=4;
                        } elsif ($day_of_week eq "wed") { $offset=5;
                        } elsif ($day_of_week eq "thu") { $offset=6;
                        }


                        (my $day, my $month, my $year) =
                                (localtime($starttime))[3,4,5]; 

                        $time = timelocal(0, 0, $hour, $day + $offset,
                                        $month, $year);
                        $times = $times . $time . ';';
                }
                

                #print $times . "\n\n";

                #Handel ADS on monday
                
                #printf ("%-9s %-48s %4s %4s %s\n",
                #       $type, $title, $cert, $length, $times);

                my $film = $xml->createElement('film');
                $film->setAttribute('title', $title);
                $film->setAttribute('cert', $cert);
                $film->setAttribute('type', $type);
                $film->setAttribute('length', $length);

                my $times_node = $xml->createElement('times');
                foreach my $time (split(';', $times)) {
                        my $time_node = $xml->createElement('time');
                        my $text = $xml->createTextNode($time);
                        $time_node->appendChild($text);
                        $times_node->appendChild($time_node);
                }

                $film->appendChild($times_node);
                $cinemalistings->appendChild($film);

        }
}

print $xml_pi->toString;
print $cinemalistings->toString;


