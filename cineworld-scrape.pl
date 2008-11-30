#!/usr/bin/perl -w
###############################################################################
#cineworld-scrape gets cinema listings and converts them from html to xml
#
#Copyright (C) 2007 Thomas Stewart <thomas@stewarts.org.uk
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
###############################################################################

use strict;
use Data::Dumper;
use LWP::Simple; 
use Time::Local;
use HTML::TreeBuilder;
use XML::DOM;
use XML::XPath;
use XML::XSLT;

#download raw html data
my $region = "3";
my $cinema = "1";
my $date   = `date +%Y%m%d`;

#http://jonas.liljegren.org/perl/libxml/XML/DOM.html

#http://www.cineworld.co.uk/reservation/ChoixResa.jgi?REGION=3&CINEMA=1&formulaireDate=20070929
my $url="http://www.cineworld.co.uk/reservation/ChoixResa.jgi?REGION=$region&CINEMA=$cinema&formulaireDate=$date";
#$url="http://jade/cw.html";
my $data=get($url);
$data =~ s/\n//g;
$data =~ s/\r//g;
$data =~ s/&nbsp;//g;

#parse shit html into a tree and convert to xml
my $tree = HTML::TreeBuilder->new;
$tree->parse($data);
$tree->eof();
$data=$tree->as_XML;
$tree->delete;
#print $data; exit;

#create new xml doc
my $xml = XML::DOM::Document->new;
my $xml_d = $xml->createXMLDecl ('1.0');
my $xml_t = $xml->createDocumentType('cinemalistings', 'cw.dtd');
my $xml_i = $xml->createProcessingInstruction("xml-stylesheet",
        'type="text/xsl" href="cw.xsl"');
my $cinemalistings = $xml->createElement('cinemalistings');
$cinemalistings->setAttribute('chain', 'cineworld');
$cinemalistings->setAttribute('name', 'Stevenage');
$cinemalistings->setAttribute('originalurl', $url);

#get the main table of data
my $xpath = XML::XPath->new(xml => $data);
my $films = $xpath->find('/html/body/table[3]/tr/td/table/tr/td/table/tr[2]/td[2]/table/tr/td[2]/table/tr');
print STDERR $films->size . "\n"; for(my $t=0; $t < $films->size; $t++) { print XML::XPath::XMLParser::as_string($films->get_node($t)); } exit;
#print XML::XPath::XMLParser::as_string($films->get_node(0)); exit;

#loop over each row
foreach my $film ($films->get_nodelist) {
        $xpath = XML::XPath->new( xml => 
                XML::XPath::XMLParser::as_string($film) );

        my $img = $xpath->find('//img/@src');
        if($img->size() eq 1) {
                $img = XML::XPath::XMLParser::as_string($img->get_node(0));
                $img =~ s/^ src="//;
                $img =~ s/"$//;
        } else {
                $img = "";
        }

        my $url = $xpath->find('//a[@class="a3SousTitre color03Txt"]/@href');
        if($url->size() eq 1) {
                $url = XML::XPath::XMLParser::as_string($url->get_node(0));
                $url =~ s/^ href="//;
                $url =~ s/"$//;
                $url =~ s/&amp;/&/g;
                $url = "http://www.cineworld.co.uk/reservation/" . $url;
        } else {
                $url = "";
        }

        my $title = $xpath->find('//a[@class="a3SousTitre color03Txt"]/text()');
        if($title->size() eq 1) {
                $title = XML::XPath::XMLParser::as_string($title->get_node(0));
                $title =~ s/<b>(.+)<\/b>/$1/;
                $title =~ s/&amp;/&/g;
                $title =~ s/(\w+)/\u\L$1/g;
        } else {
                $title = "";
        }

        my $cert = $xpath->find('//span[@class="Nb_Film color03Txt"]/text()');
        if($cert->size() eq 1) {
                $cert = XML::XPath::XMLParser::as_string($cert->get_node(0));
                $cert =~ s/ //g;
        } else {
                $cert = "";
        }

        my $dir = $xpath->find('//span[3]/text()');
        if($dir->size() eq 1) {
                $dir = XML::XPath::XMLParser::as_string($dir->get_node(0));
        } else {
                $dir = "";
        }

        my $staring = $xpath->find('//span[6]/text()');
        if($staring->size() eq 1) {
                $staring = XML::XPath::XMLParser::as_string(
                                $staring->get_node(0));
        } else {
                $staring = "";
        }

        my $showings = $xml->createElement('showings');
        my $times = $xpath->find('//a[@class="basenoirsoul"]');
        foreach my $time ($times->get_nodelist) {
                $xpath = XML::XPath->new( xml => 
                        XML::XPath::XMLParser::as_string($time) );
        
                my $time = $xpath->find('//a/text()');
                $time = XML::XPath::XMLParser::as_string($time->get_node(0));
                $time =~ s/ //g;

                my $url = $xpath->find('//a/@href');
                $url = XML::XPath::XMLParser::as_string($url->get_node(0));
                $url =~ s/^ href="//;
                $url =~ s/"$//;
                $url =~ s/&amp;/&/g;

                my $showing = $xml->createElement('showing');
                $showing->setAttribute('time', $time);
                $showing->setAttribute('url', $url);

                $showings->appendChild($showing);
        }

        #print Dumper $img; print Dumper $url; print Dumper $title; print Dumper $cert; print Dumper $dir; print Dumper $staring;

        my $film = $xml->createElement('film');
        $film->setAttribute('img', $img);
        $film->setAttribute('url', $url);
        $film->setAttribute('title', $title);
        $film->setAttribute('cert', $cert);
        $film->setAttribute('dir', $dir);
        $film->setAttribute('staring', $staring);
        $film->appendChild($showings);

        $cinemalistings->appendChild($film);

}
print $xml_d->toString . $xml_t->toString;
#print $xml_i->toString;
print $cinemalistings->toString . "\n";
