#!/usr/bin/env python3
#Copyright (C) 2009-2014 Thomas Stewart <thomas@stewarts.org.uk>
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

import getopt
import urllib.request, urllib.parse
import lxml.etree
import getopt, sys, io, re, time, datetime
from pprint import pprint as pp

class CineworldScrape:
        def __init__ (self, cinemaname = 'Stevenage'): 
                self.cinemaname = cinemaname
                self.cinemaid = self.cinema(cinemaname)
                self.listingsurl = "http://www.cineworld.co.uk/whatson" \
                        + "?cinema=" + str(self.cinemaid)

        def downloadparse (self, url):
                raw = urllib.request.urlopen(url)
                #html = raw.read().decode('windows-1252')
                html = raw.read().decode('utf-8')
                raw.close()
                html = io.StringIO(html)
                return lxml.etree.parse(html, lxml.etree.HTMLParser())

        def cinema (self, name):
                url = 'http://www.cineworld.co.uk/cinemas'
                doc = self.downloadparse(url)
                results = doc.xpath('//select[@id="cinemaId"]/option')

                cinemas = {}
                for r in results:
                        n = r.xpath('text()')[0]
                        try:
                                i = int(r.xpath('@value')[0])
                                if i > 0:
                                        cinemas[n] = i
                        except ValueError:
                                continue

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
                        print('hits: %s' % (len(result)))
                        for r in result:
                                print('hit: %s' % (r))

                if len(result) == 1:
                        result = result[0].replace("\n", " ").strip()
                        return result
                elif len(result) > 1:
                        return "ERROR (more than one result)"
                else:
                        return ""

        def scrapefilm (self, doc):
                film = lxml.etree.Element('film')

                img = self.xpath(doc, '//meta[@property="og:image"]/@content')
                film.set("img", img)

                title = self.xpath(doc, '//meta[@property="og:title"]/@content')
                #title = title.title().replace("'S", "'s")
                title = title.replace("'", "")
                film.set("title", title)

                cert = self.xpath(doc, '//a[@href="/classification"]/'
                        + '@data-classification')
                film.set("cert", cert)

                certdesc = self.xpath(doc, '//a[@href="/classification"]/'
                        + '@title')
                film.set("certdesc", certdesc)

                #certimg = self.xpath(doc, '//img[@class="cert-icon"]/@src')
                #certimg = "http://www.cineworld.co.uk" + certimg
                #film.set("certimg", certimg)

                release = self.xpath(doc, '//div[@class="span7"]/p[7]/text()')
                film.set("release", release)

                runtime = self.xpath(doc, '//div[@class="span7"]/p[5]/text()')
                film.set("runtime", runtime)

                director = self.xpath(doc, '//div[@class="span7"]/p[4]/text()')
                film.set("director", director)

                staring = self.xpath(doc, '//div[@class="span7"]/p[3]/text()')
                film.set("staring", staring)

                trailer = self.xpath(doc, '//meta[@property="og:video"]'
                        + '/@content')
                trailer = urllib.parse.unquote(trailer)
                trailer = re.sub('.*http(.*)mp4.*', r'http\1mp4', trailer)
                trailer = trailer.replace('+', ' ')
                film.set("trailer", trailer)

                summary = self.xpath(doc, '//meta[@property="og:description"]'
                        + '/@content')
                film.set("summary", summary)
                
                synopsis = self.xpath(doc, '//div[@class="span7"]/p[2]/text()')
                synopsis = synopsis.replace('\r', '')
                film.set("synopsis", synopsis)

                genre = self.xpath(doc, '//div[@class="span7"]/p[6]/text()')
                film.set("genre", genre)

                screentype = doc.xpath('//div/div/ul[@class="unstyled"]/li/@class')
                st = ''
                if 'icon-service-twod' in screentype \
                                and 'icon-service-thrd' not in screentype:
                        st = '2D'
                if 'icon-service-twod' in screentype \
                                and 'icon-service-thrd' in screentype:
                        st = '2D,3D'
                if 'icon-service-twod' not in screentype \
                                and 'icon-service-thrd' in screentype:
                        st = '2D'
                film.set("screentype", st)

                #screenplay = self.xpath(doc, '')
                #film.set("screenplay", screenplay)
                
                #distributor = self.xpath(doc, '')
                #film.set("distributor", distributor)

                seebecause = self.xpath(doc, '//div[@class="span12 quotes"]/'
                        + 'blockquote/p/text()')
                film.set("seebecause", seebecause)

                seeifyouliked = self.xpath(doc, '//div[@class="section dark  '
                        + 'clearfix "]/div/blockquote/p/text()')
                film.set("seeifyouliked", seeifyouliked)

                showings = lxml.etree.SubElement(film, 'showings')
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
                                showing =  lxml.etree.Element('showing')

                                url = self.xpath(r, '@href')
                                url = "http://www.cineworld.co.uk" + url
                                showing.set("url", url)
                                
                                showingtime = r.xpath('text()')
                                showingtime = showingtime[0]. \
                                        replace("\n", " ").strip()
                                showingtime = day + " " + showingtime[0:5]
                                showingtime = datetime.datetime(*( \
                                        time.strptime(showingtime, \
                                        "%Y-%m-%d %H:%M")[0:6]))
                                showingtime = showingtime.isoformat(' ')
                                showing.set("time", showingtime)
                                
                                screentype = r.getnext().xpath(
                                        'ul/li/text()')[0]
                                showing.set("screentype", screentype)

                                showings.append(showing)


                return film
               
        def scrape (self, debug=0):
                #imp = xml.dom.minidom.getDOMImplementation()
                #dt = imp.createDocumentType("cinemalistings", "", "cw.dtd")
                #doc = imp.createDocument(None, "cinemalistings", dt)
                #my $xml_i = $xml->createProcessingInstruction ("xml-stylesheet", 'type="text/xsl" href="cw.xsl"');

                cinemalistings = lxml.etree.Element('cinemalistings', \
                        chain = 'Cineworld', location = self.cinemaname, \
                        url = self.listingsurl)
                doc = lxml.etree.ElementTree(cinemalistings)

                urls = self.filmurls()
                for url in urls:
                        filmdoc = self.downloadparse(url)
                        #print(lxml.etree.tostring(filmdoc))
                        #sys.exit()

                        film = self.scrapefilm(filmdoc)
                        film.set('url', url)
                        cinemalistings.append(film)


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
        except(getopt.error, msg):
                print(str(msg))
                sys.exit(2)

        for o, a in opts:
                if o in ("-h", "--help"):
                        print("cineworldscrape [options...]")
                        print("  -h --help        this info")
                        print("     --testcinema  test cinema list")
                        print("     --testurls    test grabbing main url list")
                        print("     --testscrape  test one title")
                        print("  -s --scrape      scrape all")
                        print("  -t --transform   apply xsl to output")
                        sys.exit()

                elif o in ("--testcinema"):
                        pp(c.cinemaid)
                        sys.exit()

                elif o in ("--testurls"):
                        pp(c.filmurls())
                        sys.exit()

                elif o in ("--testscrape"):
                        doc = c.scrape(debug=1)
                        print(lxml.etree.tostring(doc, pretty_print=True,
                                encoding='unicode'))
                        sys.exit()

                elif o in ("-s", "--scrape"):
                        scrape=1

                elif o in ("-t", "--transform"):
                        transform=1

        base='/srv/www/stewarts.org.uk/cw/'
        if scrape:
                doc = c.scrape()
                xmlfile = open(base + 'cw.xml', 'w')
                doc = lxml.etree.tostring(doc, pretty_print=True, \
                        encoding='unicode')
                xmlfile.write(doc)
                xmlfile.close()

        if transform:
                xslt = lxml.etree.XML(open(base + 'cw.xsl').read())
                transform = lxml.etree.XSLT(xslt)
                doc = lxml.etree.parse(open(base + 'cw.xml'))
                result = transform(doc)
                output = open(base + 'cw.html', 'w')
                output.write(str(result))

