#!/usr/bin/env python

#Copyright (C) 2009 Thomas Stewart <thomas@stewarts.org.uk>
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
import getopt
import libxml2
import libxslt
import re
import sys
import tidy
import time
import urllib
import xml.dom.ext.reader.Sax2
import xml.xpath
import xml.dom.ext
import xml.dom.minidom
import pprint
pp = pprint.PrettyPrinter(depth=6)

class CineworldScrape:
        def __init__ (self, cinemaname = 'Stevenage'): 
                self.cinemaid = self.cinema(cinemaname)
                self.listingsurl = "http://www.cineworld.co.uk/cinemas/" \
                        + str (self.cinemaid)

        def downloadtidyparse (self, url):
                raw = urllib.urlopen (url)
                html = raw.read ()
                raw.close ()

                options = dict (
                        add_xml_decl=1,
                        output_xhtml=1,
                        output_encoding="utf8",
                        show_warnings=0,
                        indent=0,
                        bare=1,
                        force_output=1
                        )
                html = str (tidy.parseString (html, **options))

                reader = xml.dom.ext.reader.Sax2.Reader ()
                return reader.fromString (html)

        def cinema (self, name):
                url = 'http://www.cineworld.co.uk/cinemas'
                doc = self.downloadtidyparse (url)
                results = xml.xpath.Evaluate (
                        '//select[@id="cinema"]/option', doc)

                cinemas = {}
                for r in results:
                        i = xml.xpath.Evaluate('@value', r)[0].nodeValue
                        n = xml.xpath.Evaluate('text()', r)[0].nodeValue
                        if i > 0:
                                cinemas[n] = i

                if name in cinemas:
                        return cinemas[name]
                else:
                        return 0

        def filmurls (self):
                doc = self.downloadtidyparse (self.listingsurl)
                urls = xml.xpath.Evaluate ('//h3[@class="filmtitle"]/a/@href',
                        doc)
                base = "http://www.cineworld.co.uk"
                urls = [ base + url.nodeValue for url in urls ] 
                return urls

        def xpath (self, xp, doc, debug=0):
                result = xml.xpath.Evaluate (xp, doc)
                if(debug == 1):
                        print 'hits: %s' % (len (result))
                        for r in result:
                                print 'hit: %s' % (r.nodeValue)

                if len (result) == 1:
                        result = result[0].nodeValue.replace("\n", " ").strip()
                        return result
                elif len (result) > 1:
                        return "ERROR (more than one result)"
                else:
                        return ""

        def scrapefilm (self, doc):
                film = xml.dom.minidom.Document().createElement ("film")

                img = self.xpath ('//li[@class="film-detail"]/img/@src', doc)
                img = "http://www.cineworld.co.uk" + img
                film.setAttribute ("img", img)

                title = self.xpath ('//h3[@class="filmtitle"]/text()', doc)
                title = title.title ()
                title = title.replace("'S", "'s")
                title = title.replace("'", "")
                film.setAttribute ("title", title)

                cert = self.xpath ('//img[@class="cert-icon"]/@alt', doc)
                film.setAttribute ("cert", cert)

                certdesc = self.xpath ('//img[@class="cert-icon"]/@title', doc)
                film.setAttribute ("certdesc", certdesc)

                certimg = self.xpath ('//img[@class="cert-icon"]/@src', doc)
                certimg = "http://www.cineworld.co.uk" + certimg
                film.setAttribute ("certimg", certimg)

                release = self.xpath ('//p[strong="Release Date:"]/text()', doc)
                film.setAttribute ("release", release)

                runtime = self.xpath ('//p[strong="Running time:"]/text()', doc)
                film.setAttribute ("runtime", runtime)

                director = self.xpath ('//p[strong="Director:"]/text()',
                        doc)
                film.setAttribute ("director", director)

                staring = self.xpath ('//p[strong="Starring:"]/text()', doc)
                film.setAttribute ("staring", staring)

                trailer = xml.xpath.Evaluate ('//div[@class="lead"]/script[@type="text/javascript"]/text()', doc)
                if len(trailer) == 3:
                        trailer = trailer[1].nodeValue
                        trailer = trailer.replace("\n", " ").strip()
                        trailer = re.sub('.*trailer: "http(.*)flv".*',
                                r'http\1flv', trailer)
                else:
                        trailer=""   
                film.setAttribute ("trailer", trailer)

                summary = self.xpath (
                        '//div[@class="summary show-js"]/p[1]/text()', doc)
                film.setAttribute ("summary", summary)
                
                synopsis = self.xpath (
                        '//div[@class="synopsis hide-js"]/p[2]/text()', doc)
                film.setAttribute ("synopsis", synopsis)

                screenplay = self.xpath (
                        '//p[strong="Screenplay:"]/text()', doc)
                film.setAttribute ("screenplay", screenplay)
                
                distributor = self.xpath (
                        '//p[strong="Distributor:"]/text()', doc)
                film.setAttribute ("distributor", distributor)

                seebecause = self.xpath (
                        '//p[strong="You should see it because:"]/text()', doc)
                film.setAttribute ("seebecause", seebecause)

                seeifyouliked = self.xpath (
                        '//p[strong="See it if you liked:"]/text()', doc)
                film.setAttribute ("seeifyouliked", seeifyouliked)

                showings = xml.dom.minidom.Document().createElement("showings")
                film.appendChild (showings)
                day = ""
                for r in xml.xpath.Evaluate ('//dl/dt/text()|//dl/dd/a', doc):
                        if r.nodeType == xml.dom.Node.TEXT_NODE:
                                y = str(datetime.datetime.now().year)
                                d = r.nodeValue
                                d = datetime.datetime (*(time.strptime \
                                        (y + " " + d, "%Y %a %d %b")[0:6]))
                                day = str(d.year) + "-" + str(d.month) \
                                        + "-" + str(d.day)

                        if r.nodeType == xml.dom.Node.ELEMENT_NODE:
                                showing = xml.dom.minidom.Document(). \
                                        createElement ("showing")

                                url = self.xpath ('@href', r)
                                url = "http://www.cineworld.co.uk" + url
                                showing.setAttribute ("url", url)

                                showingtime = self.xpath ('text()', r)
                                showingtime = day + " " + showingtime[0:5]
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

        scrape=0
        transform=0

        try:
                opts, args = getopt.getopt(sys.argv[1:], "h",
                        ["help", "testcinema", "testurls", "testscrape",
                        "scrape", "transform"])
        except getopt.error, msg:
                print str(msg)
                sys.exit(2)

        for o, a in opts:
                if o in ("-h", "--help"):
                        print "cineworldscrape standalone"
                        print "--help this info"
                        print "--testcinema test cinema list"
                        print "--testurls test grabbing main url list"
                        print "--testscrape test one title"
                        print "--scrape scrape all"
                        print "--transform apply xsl to output"
                        sys.exit()

                elif o in ("--testcinema"):
                        pp.pprint(c.cinemaid)
                        sys.exit()

                elif o in ("--testurls"):
                        pp.pprint(c.filmurls())
                        sys.exit()

                elif o in ("--testscrape"):
                        doc = xml.dom.minidom.Document ()
                        cinemalistings = doc.createElement ("cinemalistings")
                        doc.appendChild (cinemalistings)

                        url="http://www.cineworld.co.uk/cinemas/61?film=3388"
                        filmdoc = c.downloadtidyparse (url)
                        film = c.scrapefilm (filmdoc)
                        cinemalistings.appendChild (film)

                        print doc.toprettyxml (indent="  ")
                        sys.exit ()

                elif o in ("--scrape"):
                        scrape=1

                elif o in ("--transform"):
                        transform=1

        if scrape:
                doc = c.scrape ()
                xml.dom.ext.PrettyPrint (doc,
                        open ("/home/thomas/www/cw/cw.xml", "w"))

        if transform:
                styledoc = libxml2.parseFile(
                        "/home/thomas/www/cw/cw.xsl")
                style = libxslt.parseStylesheetDoc (styledoc)
                doc = libxml2.parseFile ("/home/thomas/www/cw/cw.xml")
                result = style.applyStylesheet (doc, None)
                style.saveResultToFilename(
                        "/home/thomas/www/cw/cw.html", result, 0)

