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
###############################################################################

use strict;
use Data::Dumper;
use LWP::Simple; 
use Time::Local;
use HTML::TreeBuilder;
use XML::DOM;
use XML::XPath;

my $site_id = "1";

#download raw html data
my $url="http://www.cineworld.co.uk/jahia/Jahia/cache/bypass/pid/21?" .
        "siteId=" .  $site_id ; #. "&otherDays=2006-10-13";
#$url="http://d8s7c1j/~thomas/cw.html";
my $data=get($url);
$data =~ s/\n//g;
$data =~ s/\r//g;

#create new xml doc
my $xml = XML::DOM::Document->new;
my $xml_pi = $xml->createXMLDecl ('1.0');
my $xml_dt = $xml->createDocumentType('cinemalistings', 'cw.dtd');
my $cinemalistings = $xml->createElement('cinemalistings');
$cinemalistings->setAttribute('chain', 'cineworld');
$cinemalistings->setAttribute('name', 'Stevenage');
$cinemalistings->setAttribute('siteid', $site_id);
$cinemalistings->setAttribute('originalurl', $url);

#parse shit html into a tree and convert to xml
my $tree = HTML::TreeBuilder->new;
$tree->parse($data);
$tree->eof();
$data=$tree->as_XML;
$tree->delete;

#search the xml, get a bunch for films
my $xpath = XML::XPath->new(xml => $data);
my $filmset = $xpath->find('//div[@class="contentFullContainer"]');

foreach my $film ($filmset->get_nodelist) {
        $xpath = XML::XPath->new(
                        xml => XML::XPath::XMLParser::as_string($film));
        
        my $film = $xml->createElement('film');

        my $title = $xpath->find('//tr[1]/td/strong/a[1]/text()');
        $title = XML::XPath::XMLParser::as_string($title->get_node(0));
        $title =~ s/&amp;/&/;
        $film->setAttribute('title', $title);

        my $cert = $xpath->find('//tr[1]/td/strong/a[2]/text()');
        $cert = XML::XPath::XMLParser::as_string($cert->get_node(0));
        $cert =~ s/\(//;
        $cert =~ s/\)//;
        $film->setAttribute('cert', $cert);
        
        my $guidance = $xpath->find('//tr[1]/td/div/text()');
        if($guidance->size() == 1) {
                $guidance = XML::XPath::XMLParser::as_string(
                                $guidance->get_node(0));
                $film->setAttribute('guidance', $guidance);
        }

        my $showings_node = $xml->createElement('showings');
        my $timesblob = $xpath->find('//tr[2]//tr//td');
        foreach my $timeblob ($timesblob->get_nodelist) {
                my $timesblobxpath = XML::XPath->new(
                        xml => XML::XPath::XMLParser::as_string($timeblob));
                my $times = $timesblobxpath->find('/td/text()');
                foreach my $time ($times->get_nodelist) {
                        my $showing_node = $xml->createElement('showing');

                        $time = XML::XPath::XMLParser::as_string($time);
                        $time =~ s/ //g;

                        $showing_node->setAttribute('time', $time);

                        $showing_node->setAttribute('audiodescribed', "false");
                        $showing_node->setAttribute('subtitled', "false");

                        my $infos = $timesblobxpath->find('/td/span/text()');
                        foreach my $info ($infos->get_nodelist) {
                                if (XML::XPath::XMLParser::as_string($info) eq "(AD)") {
                                        $showing_node->setAttribute('audiodescribed', "true");
                                }

                                if (XML::XPath::XMLParser::as_string($info) eq "(S)") {
                                        $showing_node->setAttribute('subtitled', "true");
                                }
                        }

                        $showings_node->appendChild($showing_node);
                }
        }
        $film->appendChild($showings_node);

        $cinemalistings->appendChild($film);
}

print $xml_pi->toString. $xml_dt->toString . $cinemalistings->toString . "\n";
