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

import datetime
import libxml2
import libxslt
import sys
import tidy
import time
import urllib
import xml.dom.ext.reader.Sax2
import xml.xpath
import xml.dom.ext
import xml.dom.minidom

class CineworldScrape:
        def __init__ (self, cinema = 61): 
                self.cinema = cinema
                self.listingsurl = "http://www.cineworld.co.uk/cinemas/" \
                        + str (self.cinema)

        def downloadtidyparse (self, url):
                raw = urllib.urlopen (url)
                html = raw.read ()
                raw.close ()

                options = dict (
                        add_xml_decl=1,
                        output_xhtml=1,
                        show_warnings=0,
                        indent=0,
                        bare=1,
                        force_output=1
                        )
                html = str (tidy.parseString (html, **options))

                reader = xml.dom.ext.reader.Sax2.Reader ()
                return reader.fromString (html)

        def filmurls (self):
                doc = self.downloadtidyparse (self.listingsurl)
                urls = xml.xpath.Evaluate ('//h3[@class="first"]/a/@href', doc)
                base = "http://www.cineworld.co.uk"
                urls = [ base + url.nodeValue for url in urls ] 
                return urls

        def xpath (self, xp, doc):
                result = xml.xpath.Evaluate (xp, doc)
                #print 'hits: %s' % (len (result))
                #for r in result:
                #        print 'hit: %s' % (r.nodeValue)
                if len (result) == 1:
                        result = result[0].nodeValue.replace ("\n", " ").\
                                strip ()
                        result = result.encode ('ascii', 'replace')
                        return result
                elif len (result) > 1:
                        return "ERROR (more than one result)"
                else:
                        return ""

        def scrapefilm (self, doc):
                film = xml.dom.minidom.Document().createElement ("film")

                title = self.xpath ('//h3[@class="large-title first"]/text()',\
                        doc)
                title = title.title ()
                film.setAttribute ("title", title)

                img = self.xpath (
                        '//div[@class="sub"]/div[@class="image"]/img/@src',
                        doc)
                img = "http://www.cineworld.co.uk" + img
                film.setAttribute ("img", img)

                certdesc = self.xpath ('//img[@class="cert-icon"]/@title', doc)
                film.setAttribute ("certdesc", certdesc)

                cert = self.xpath ('//img[@class="cert-icon"]/@alt', doc)
                film.setAttribute ("cert", cert)

                certimg = self.xpath ('//img[@class="cert-icon"]/@src', doc)
                certimg = "http://www.cineworld.co.uk" + certimg
                film.setAttribute ("certimg", certimg)

                release = self.xpath ('//div[@class="main"]/p[2]/text()', doc)
                film.setAttribute ("release", release)

                runtime = self.xpath ('//div[@class="main"]/p[3]/text()', doc)
                film.setAttribute ("runtime", runtime)

                director = self.xpath ('//div[@class="main"]/p[4]/text()', doc)
                film.setAttribute ("director", director)

                staring = self.xpath ('//div[@class="main"]/p[5]/text()', doc)
                film.setAttribute ("staring", staring)

                flv = self.xpath ('//div[@id="flashcontent"]/text()', doc)
                
                synopsis = self.xpath ('//div[@class="synopsis"]/p[1]/text()',
                        doc)
                film.setAttribute ("synopsis", synopsis)

                longsynopsis = self.xpath (
                        '//div[@class="synopsis"]/p[2]/text()', doc)
                film.setAttribute ("longsynopsis", longsynopsis)

                screenplay = self.xpath ('//div[@class="main"]/p[6]/text()',
                        doc)
                film.setAttribute ("screenplay", screenplay)
                
                distributor = self.xpath ('//div[@class="main"]/p[7]/text()',
                        doc)
                film.setAttribute ("distributor", distributor)

                seebecause = self.xpath ('//div[@class="main"]/p[8]/text()',
                        doc)
                film.setAttribute ("seebecause", seebecause)

                seeifyouliked = self.xpath ('//div[@class="main"]/p[9]/text()',
                        doc)
                film.setAttribute ("seeifyouliked", seeifyouliked)

                showings = xml.dom.minidom.Document().createElement("showings")
                film.appendChild (showings)
                day = ""
                for r in xml.xpath.Evaluate ('//dl/dt/text()|//dl/dd/a', doc):
                        if r.nodeType == xml.dom.Node.TEXT_NODE:
                                y = str(datetime.datetime.now().year)
                                d = r.nodeValue
                                d = d.encode ('ascii', 'replace')
                                d = datetime.datetime (*(time.strptime \
                                        (y + d, "%Y %a %d %b")[0:6]))
                                day = str(d.year) + "-" + str(d.month) \
                                        + "-" + str(d.day)

                        if r.nodeType == xml.dom.Node.ELEMENT_NODE:
                                showing = xml.dom.minidom.Document(). \
                                        createElement ("showing")

                                url = self.xpath ('@href', r)
                                url = "http://www.cineworld.co.uk" + url
                                showing.setAttribute ("url", url)

                                showingtime = self.xpath ('text()', r)
                                showingtime = day + " " + showingtime
                                showingtime = datetime.datetime (*( \
                                        time.strptime (showingtime, \
                                        "%Y-%m-%d %H:%M")[0:6]))
                                showingtime = showingtime.isoformat(' ')

                                showing.setAttribute ("time", showingtime)
                                showings.appendChild (showing)

                return film
               
        def scrape (self):

                doc = xml.dom.minidom.Document ()
                #doctype = xml.dom.minidom.DocumentType('cw.dtd')
                #doc.appendChild (doctype)
                #my $xml_i = $xml->createProcessingInstruction ("xml-stylesheet", 'type="text/xsl" href="cw.xsl"');

                cinemalistings = doc.createElement ("cinemalistings")
                cinemalistings.setAttribute ("chain", "Cineworld")
                cinemalistings.setAttribute ("location", "Stevenage")
                cinemalistings.setAttribute ("url", self.listingsurl)
                doc.appendChild (cinemalistings)

                urls = self.filmurls ()
                for url in urls:
                        filmdoc = self.downloadtidyparse (url)
                        film = self.scrapefilm (filmdoc)
                        film.setAttribute ("url", url)
                        cinemalistings.appendChild (film)
                
                return doc

if __name__ == "__main__":
        c=CineworldScrape ()

        #urls = c.listingsurl ()

        #doc = xml.dom.minidom.Document ()
        #cinemalistings = doc.createElement ("cinemalistings")
        #doc.appendChild (cinemalistings)

        #url="http://www.cineworld.co.uk/cinemas/61?film=175"
        #filmdoc = c.downloadtidyparse (url)
        #film = c.scrapefilm (filmdoc)
        #cinemalistings.appendChild (film)

        #print doc.toprettyxml (indent="  ")
        #sys.exit ()
        #print c.scrape ().toprettyxml (indent="  ")

        doc = c.scrape ()
        xml.dom.ext.PrettyPrint (doc, open ("/home/thomas/www/cw/cw.xml", "w"))

        styledoc = libxml2.parseFile ("/home/thomas/www/cw/cw.xsl")
        style = libxslt.parseStylesheetDoc (styledoc)
        doc = libxml2.parseFile ("/home/thomas/www/cw/cw.xml")
        result = style.applyStylesheet (doc, None)
        style.saveResultToFilename ("/home/thomas/www/cw/cw.html", result, 0)

        styledoc = libxml2.parseFile ("/home/thomas/www/cw/cweve.xsl")
        style = libxslt.parseStylesheetDoc (styledoc)
        doc = libxml2.parseFile ("/home/thomas/www/cw/cw.xml")
        result = style.applyStylesheet (doc, None)
        style.saveResultToFilename ("/home/thomas/www/cw/cweve.html", result, 0)

