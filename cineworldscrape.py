#!/usr/bin/env python
#Copyright (C) 2009-2013 Thomas Stewart <thomas@stewarts.org.uk>
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
import time
import urllib
import StringIO
import lxml.etree
import xml.dom.minidom
import pprint
pp = pprint.PrettyPrinter(depth=6)

class CineworldScrape:
        def __init__ (self, cinemaname = 'Stevenage'): 
                self.cinemaname = cinemaname
                self.cinemaid = self.cinema(cinemaname)
                self.listingsurl = "http://www.cineworld.co.uk/whatson" \
                        + "?cinema=" + str(self.cinemaid)

        def downloadparse (self, url):
                raw = urllib.urlopen(url)
                html = raw.read().decode('windows-1252')
                raw.close()
                html = StringIO.StringIO(html)
                return lxml.etree.parse(html, lxml.etree.HTMLParser())

        def cinema (self, name):
                url = 'http://www.cineworld.co.uk/cinemas'
                doc = self.downloadparse(url)
                results = doc.xpath('//select[@id="cinemaId"]/option')

                cinemas = {}
                for r in results:
                        i = r.xpath('@value')[0]
                        n = r.xpath('text()')[0]
                        if i > 0:
                                cinemas[n] = i

                if name in cinemas:
                        return cinemas[name]
                else:
                        return 0

        def filmurls (self):
                doc = self.downloadparse(self.listingsurl)
                urls = doc.xpath('//div[@class="row"]/div/a/@href')
                urls = [ 'http://www.cineworld.co.uk' + url for url in urls ] 
                return urls

        def xpath (self, doc, xpath, debug=0):
                result = doc.xpath(xpath)
                if debug:
                        print 'hits: %s' % (len(result))
                        for r in result:
                                print 'hit: %s' % (r)

                if len(result) == 1:
                        result = result[0].replace("\n", " ").strip()
                        return result
                elif len(result) > 1:
                        return "ERROR (more than one result)"
                else:
                        return ""

        def scrapefilm (self, doc):
                film = xml.dom.minidom.Document().createElement("film")

                img = self.xpath(doc, '//meta[@property="og:image"]/@content')
                film.setAttribute("img", img)

                title = self.xpath(doc, '//meta[@property="og:title"]/@content')
                #title = title.title().replace("'S", "'s")
                title = title.replace("'", "")
                film.setAttribute("title", title)

                cert = self.xpath(doc, '//a[@href="/classification"]/'
                        + '@data-classification')
                film.setAttribute("cert", cert)

                certdesc = self.xpath(doc, '//a[@href="/classification"]/'
                        + '@title')
                film.setAttribute("certdesc", certdesc)

                #certimg = self.xpath(doc, '//img[@class="cert-icon"]/@src')
                #certimg = "http://www.cineworld.co.uk" + certimg
                #film.setAttribute("certimg", certimg)

                release = self.xpath(doc, '//div[@class="span7"]/p[7]/text()')
                film.setAttribute("release", release)

                runtime = self.xpath(doc, '//div[@class="span7"]/p[5]/text()')
                film.setAttribute("runtime", runtime)

                director = self.xpath(doc, '//div[@class="span7"]/p[4]/text()')
                film.setAttribute("director", director)

                staring = self.xpath(doc, '//div[@class="span7"]/p[3]/text()')
                film.setAttribute("staring", staring)

                trailer = self.xpath(doc, '//meta[@property="og:video"]'
                        + '/@content')
                trailer = urllib.unquote(trailer)
                trailer = re.sub('.*http(.*)mp4.*', r'http\1mp4', trailer)
                film.setAttribute("trailer", trailer)

                summary = self.xpath(doc, '//meta[@property="og:description"]'
                        + '/@content')
                film.setAttribute("summary", summary)
                
                synopsis = self.xpath(doc, '//div[@class="span7"]/p[2]/text()')
                synopsis = synopsis.replace('\r', '')
                film.setAttribute("synopsis", synopsis)

                genre = self.xpath(doc, '//div[@class="span7"]/p[6]/text()')
                film.setAttribute("genre", genre)

                screentype = doc.xpath('//div[@class="span7"]/ul/li/@class')
                if 'icon-service-twod' in screentype \
                                and 'icon-service-thrd' not in screentype:
                        st = '2D'
                if 'icon-service-twod' in screentype \
                                and 'icon-service-thrd' in screentype:
                        st = '2D,3D'
                if 'icon-service-twod' not in screentype \
                                and 'icon-service-thrd' in screentype:
                        st = '2D'
                film.setAttribute("screentype", st)

                #screenplay = self.xpath(doc, '')
                #film.setAttribute("screenplay", screenplay)
                
                #distributor = self.xpath(doc, '')
                #film.setAttribute("distributor", distributor)

                seebecause = self.xpath(doc, '//div[@class="span12 quotes"]/'
                        + 'blockquote/p/text()')
                film.setAttribute("seebecause", seebecause)

                seeifyouliked = self.xpath(doc, '//div[@class="section dark  '
                        + 'clearfix "]/div/blockquote/p/text()')
                film.setAttribute("seeifyouliked", seeifyouliked)

                showings = xml.dom.minidom.Document().createElement("showings")
                film.appendChild(showings)
                for r in doc.xpath('//div[@class="span2"]/h3/text()' \
                                + '|//ol[@class="performances"]/li/a'):
                        if not lxml.etree.iselement(r):
                                r = r.replace('st ', ' ').replace('nd ', ' ') \
                                        .replace('rd ',' ').replace('th ', ' ')
                                r = str(datetime.datetime.now().year) + " " + r
                                d = datetime.datetime(*(time.strptime 
                                        (r, "%Y %A %d %b")[0:6]))
                                day = str(d.year) + "-" + str(d.month) \
                                        + "-" + str(d.day)

                        if lxml.etree.iselement(r):
                                showing = xml.dom.minidom.Document(). \
                                        createElement("showing")

                                url = self.xpath(r, '@href')
                                url = "http://www.cineworld.co.uk" + url
                                showing.setAttribute("url", url)
                                
                                showingtime = r.xpath('text()')
                                showingtime = showingtime[0]. \
                                        replace("\n", " ").strip()
                                showingtime = day + " " + showingtime[0:5]
                                showingtime = datetime.datetime(*( \
                                        time.strptime(showingtime, \
                                        "%Y-%m-%d %H:%M")[0:6]))
                                showingtime = showingtime.isoformat(' ')
                                showing.setAttribute("time", showingtime)
                                
                                screentype = r.getnext().xpath(
                                        'ul/li/text()')[0]
                                showing.setAttribute("screentype", screentype)

                                showings.appendChild(showing)


                return film
               
        def scrape (self, debug=0):
                doc = xml.dom.minidom.Document()
                #imp = xml.dom.minidom.getDOMImplementation()
                #dt = imp.createDocumentType("cinemalistings", "", "cw.dtd")
                #doc = imp.createDocument(None, "cinemalistings", dt)

                #my $xml_i = $xml->createProcessingInstruction ("xml-stylesheet", 'type="text/xsl" href="cw.xsl"');

                cinemalistings = doc.createElement("cinemalistings")
                cinemalistings.setAttribute("chain", "Cineworld")
                cinemalistings.setAttribute("location", self.cinemaname)
                cinemalistings.setAttribute("url", self.listingsurl)
                doc.appendChild(cinemalistings)

                urls = self.filmurls()
                for url in urls:
                        filmdoc = self.downloadparse(url)
                        #print lxml.etree.tostring(filmdoc)
                        #sys.exit()
                        film = self.scrapefilm(filmdoc)
                        film.setAttribute("url", url)
                        cinemalistings.appendChild(film)
                        if debug:
                                break
                
                return doc

if __name__ == "__main__":
        c=CineworldScrape()

        scrape=0
        transform=0

        try:
                opts, args = getopt.getopt(sys.argv[1:], "hst",
                        ["help", "testcinema", "testurls", "testscrape",
                        "scrape", "transform"])
        except getopt.error, msg:
                print str(msg)
                sys.exit(2)

        for o, a in opts:
                if o in ("-h", "--help"):
                        print "cineworldscrape [options...]"
                        print "  -h --help        this info"
                        print "     --testcinema  test cinema list"
                        print "     --testurls    test grabbing main url list"
                        print "     --testscrape  test one title"
                        print "  -s --scrape      scrape all"
                        print "  -t --transform   apply xsl to output"
                        sys.exit()

                elif o in ("--testcinema"):
                        pp.pprint(c.cinemaid)
                        sys.exit()

                elif o in ("--testurls"):
                        pp.pprint(c.filmurls())
                        sys.exit()

                elif o in ("--testscrape"):
                        doc = c.scrape(debug=1)
                        print doc.toprettyxml()
                        sys.exit()

                elif o in ("-s", "--scrape"):
                        scrape=1

                elif o in ("-t", "--transform"):
                        transform=1

        base='/home/thomas/www/cw/'
        if scrape:
                doc = c.scrape()
                xmlfile = open(base + "cw.xml", "w")
                xmlfile.write(doc.toprettyxml(encoding="utf8"))
                xmlfile.close()

        if transform:
                styledoc = libxml2.parseFile(base + "cw.xsl")
                style = libxslt.parseStylesheetDoc(styledoc)
                doc = libxml2.parseFile(base + "cw.xml")
                result = style.applyStylesheet(doc, None)
                style.saveResultToFilename(base + "cw.html", result, 0)

