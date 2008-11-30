#!/usr/bin/env python

#Copyright (C) 2008 Thomas Stewart <thomas@stewarts.org.uk>
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

from time import strftime
import urllib
import tidy
import xml.dom.ext.reader.Sax2
import xml.xpath
import xml.dom.ext
import xml.dom.minidom
import sys
import libxml2
import libxslt

class CineworldScrape:
        def __init__ (self, region = 3, cinema = 1, \
                        date = strftime ("%Y%m%d")): 
                self.region = region
                self.cinema = cinema
                self.date = date

        def listingsurl (self):
                return "http://www.cineworld.co.uk/reservation/ChoixResa.jgi?" \
                        + "&REGION=" + str(self.region) \
                        + "&CINEMA=" + str(self.cinema) \
                        + "&formulaireDate=" + self.date

        def download (self, url):
                raw = urllib.urlopen(url)
                html = raw.read ()
                raw.close ()
                return str(html)

        def tidy (self, html):
                options = dict (
                        add_xml_decl=1,
                        output_xhtml=1,
                        show_warnings=0,
                        indent=0,
                        bare=1,
                        force_output=1
                        )
                return str(tidy.parseString(html, **options))

        def parse (self, html):
                reader = xml.dom.ext.reader.Sax2.Reader()
                return reader.fromString (html)

        def downloadtidyparse (self, url):
                html = self.download (url)
                html = self.tidy (html)
                return self.parse (html)

        def rawlistings (self):
                url = self.listingsurl()
                html = self.download (url)
                print self.tidy (html)

        def rawfilm (self, url):
                html = self.download (url)
                print self.tidy (html)

        def filmurls (self, doc):
                urls = xml.xpath.Evaluate('//a[@class="a3SousTitre"]/@href',
                        doc)
                base = "http://www.cineworld.co.uk/reservation/"
                urls = [ base + url.nodeValue for url in urls ] 
                return urls

        def xpath (self, xp, doc):
                result = xml.xpath.Evaluate(xp, doc)
                #print 'hits: %s' % (len (result))
                #for r in result:
                #        print 'hit: %s' % (r.nodeValue)
                if len (result) == 1:
                        result = result[0].nodeValue.replace("\n", " ").strip()
                        result = result.encode('ascii', 'replace')
                        return result
                elif len (result) > 1:
                        return "ERROR (more than one result)"
                else:
                        return ""

        def scrapefilm (self, doc):
                film = xml.dom.minidom.Document().createElement("film")

                title = self.xpath ('//a[@class="rbaseNew2"]/b/text()', doc)
                title = title.title()
                film.setAttribute ("title", title)

                showings = xml.dom.minidom.Document().createElement("showings")
                film.appendChild(showings)
                xp = '//a[@class="basenoirsoul"]'
                sts = xml.xpath.Evaluate(xp, doc)
                for st in sts:
                        showing = xml.dom.minidom.Document(). \
                                createElement("showing")

                        time = self.xpath ('text()', st)
                        showing.setAttribute ("time", time)

                        url = self.xpath ('@href', st)
                        showing.setAttribute ("url", url)

                        showings.appendChild(showing)

                img = self.xpath ('//img[@height="130"]/@src', doc)
                if img[0] == '/':
                        img = "http://www.cineworld.co.uk" + img
                film.setAttribute ("img", img)

                cert = self.xpath ('//a[@target="bbfc"]/img/@alt', doc)
                film.setAttribute ("cert", cert)

                certimg = self.xpath ('//a[@target="bbfc"]/img/@src', doc)
                certimg = "http://www.cineworld.co.uk" + certimg
                film.setAttribute ("certimg", certimg)
                
                warning = self.xpath( \
                        '//span[@class="basenoir"]/strong/text()', doc)
                film.setAttribute ("warning", warning)
                
                synopsis = self.xpath('//span[@class="rbaseNew4"]/text()', doc)
                film.setAttribute ("synopsis", synopsis)

                director = self.xpath( \
                        '//td[2]/span[@class="rbaseNew2"][2]/b/text()', doc)
                film.setAttribute ("director", director)

                xp = '//td[4]/span[@class="rbaseNew2"]/b/text()'
                staring = xml.xpath.Evaluate (xp, doc)
                staring = [ s.nodeValue.replace("\n", " ") for s in staring ] 
                staring = [ s + ", " for s in staring ]
                staring = "".join (staring)
                staring = staring[0:-2]
                film.setAttribute ("staring", staring)

                runtime = self.xpath ( \
                        '//td[6]/span[@class="rbaseNew2"][1]/b/text()', doc)
                film.setAttribute ("runtime", runtime)

                showingfrom = self.xpath( \
                        '//td[6]/span[@class="rbaseNew2"][2]/b/text()', doc)
                film.setAttribute ("showingfrom", showingfrom)

                return film
               
        def scrape (self):
                url = self.listingsurl()
                doc = self.downloadtidyparse (url)
                urls = self.filmurls (doc)

                doc = xml.dom.minidom.Document()
                #my $xml_t = $xml->createDocumentType('cinemalistings', 'cw.dtd');
                #my $xml_i = $xml->createProcessingInstruction("xml-stylesheet", 'type="text/xsl" href="cw.xsl"');

                cinemalistings = doc.createElement("cinemalistings")
                cinemalistings.setAttribute ("chain", "Cineworld")
                cinemalistings.setAttribute ("location", "Stevenage")
                cinemalistings.setAttribute ("url", url)
                doc.appendChild(cinemalistings)

                for url in urls:
                        filmdoc = self.downloadtidyparse(url)
                        film = self.scrapefilm(filmdoc)
                        film.setAttribute ("url", url)
                        cinemalistings.appendChild(film)
                
                return doc

if __name__ == "__main__":
        c=CineworldScrape()
        #url="http://www.cineworld.co.uk/reservation/ChoixResa.jgi?CINEMA=1&FILM=25811&VERSION="

        #url = c.listingsurl()
        #doc = c.downloadtidyparse (url)
        
        #c.rawfilm(url)

        #doc = xml.dom.minidom.Document()
        #cinemalistings = doc.createElement("cinemalistings")
        #doc.appendChild(cinemalistings)

        #filmdoc = c.downloadtidyparse(url)
        #film = c.scrapefilm(filmdoc)
        #cinemalistings.appendChild(film)
        #print doc.toprettyxml(indent="  ")

        #print c.scrape().toprettyxml(indent="  ")

        doc = c.scrape()
        xml.dom.ext.PrettyPrint(doc, open("/home/thomas/www/cw/cw.xml", "w"))

        styledoc = libxml2.parseFile("/home/thomas/www/cw/cw.xsl")
        style = libxslt.parseStylesheetDoc(styledoc)
        doc = libxml2.parseFile("/home/thomas/www/cw/cw.xml")
        result = style.applyStylesheet(doc, None)
        style.saveResultToFilename("/home/thomas/www/cw/cw.html", result, 0)

        styledoc = libxml2.parseFile("/home/thomas/www/cw/cweve.xsl")
        style = libxslt.parseStylesheetDoc(styledoc)
        doc = libxml2.parseFile("/home/thomas/www/cw/cw.xml")
        result = style.applyStylesheet(doc, None)
        style.saveResultToFilename("/home/thomas/www/cw/cweve.html", result, 0)

