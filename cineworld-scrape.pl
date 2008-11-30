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

#download raw html data
my $region = "3";
my $cinema = "1";
my $date   = "20070928";

#http://jonas.liljegren.org/perl/libxml/XML/DOM.html

my $url="http://www.cineworld.co.uk/reservation/ChoixResa.jgi?REGION=$region&CINEMA=$cinema&formulaireDate=$date";
#$url="http://jade/cw.html";
my $data=get($url);
$data =~ s/\n//g;
$data =~ s/\r//g;

#create new xml doc
my $xml = XML::DOM::Document->new;
my $xml_d = $xml->createXMLDecl ('1.0');
my $xml_t = $xml->createDocumentType('cinemalistings', 'cw.dtd');
my $xml_i = $xml->createProcessingInstruction("xml-stylesheet", "type=\"text/xsl\" href=\"cw.xsl\"");
my $cinemalistings = $xml->createElement('cinemalistings');
$cinemalistings->setAttribute('chain', 'cineworld');
$cinemalistings->setAttribute('name', 'Stevenage');
$cinemalistings->setAttribute('originalurl', $url);

#parse shit html into a tree and convert to xml
my $tree = HTML::TreeBuilder->new;
$tree->parse($data);
$tree->eof();
$data=$tree->as_XML;
$tree->delete;
#print $data; exit;

#get the main table of data
my $xpath = XML::XPath->new(xml => $data);
my $filmset = $xpath->find('//table[4]//table//table//table//table');

#split this table into its rows, the first table in the main payload
$xpath = XML::XPath->new( xml => 
        XML::XPath::XMLParser::as_string($filmset->shift()) );
my $trs = $xpath->find('table/tr');

#loop over each row
my $title = "";
for(my $tr=0; $tr < $trs->size; $tr++) {
        #the film titles are all in bold tags
        $xpath = XML::XPath->new( xml => 
                XML::XPath::XMLParser::as_string( $trs->get_node($tr) ) );
        my $name = $xpath->find('//b');
        if($name->size eq 1) {
                $title = XML::XPath::XMLParser::as_string($name->shift());
                $title =~ s/<b>(.+)<\/b>/$1/;
                $title =~ s/&amp;/&/;
                $title =~ s/(\w+)/\u\L$1/g;
        }

        #see if this row conains times
        $xpath = XML::XPath->new( xml => 
                XML::XPath::XMLParser::as_string( $trs->get_node($tr) ) );
        my $times = $xpath->find('//a[@class="basenoirsoul"]/text()');
        if($times->size < 1) { next };

        #make a new film node and attach the title to it
        my $film = $xml->createElement('film');
        $film->setAttribute('title', $title);

        #loop over each time
        my $showings = $xml->createElement('showings');
        foreach my $time ($times->get_nodelist) {
                my $time = XML::XPath::XMLParser::as_string($time);
                $time =~ s/ //g;

                my $showing = $xml->createElement('showing');
                $showing->setAttribute('time', $time);
                $showings->appendChild($showing);
        }
        $film->appendChild($showings);
        $cinemalistings->appendChild($film);

        $title="";
}
print $xml_d->toString . $xml_t->toString . $xml_i->toString . $cinemalistings->toString . "\n";

