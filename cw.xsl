<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<html>
<head>
<title>
<xsl:value-of select="cinemalistings/@chain"/>
(<xsl:value-of select="cinemalistings/@location"/>)
</title>
<script language="JavaScript">
function getCookie(c_name) {
        if (document.cookie.length &gt; 0) {
                c_start = document.cookie.indexOf(c_name + "=");
                if (c_start != -1) { 
                        c_start = c_start + c_name.length + 1; 
                        c_end = document.cookie.indexOf(";", c_start);
                        if (c_end == -1) {
                                c_end = document.cookie.length;
                        }
                        return unescape(document.cookie.substring(c_start,
                                c_end));
                } 
        }
        return "";
}

function setCookie(c_name, value) {
        var exdate = new Date();
        exdate.setDate(exdate.getDate() + 180);
        document.cookie = c_name + "=" + escape(value) +
                ";expires=" + exdate.toGMTString();
}

function resetseen() {
        setCookie("titles", "");
}

function markseen(name) {
        titles = getCookie("titles");
        if(titles.length == 0) {
                titles = new Array();
        } else {
                titles = titles.split("^");
        }
        titles.push(name);
        hidetitle(name); 

        newtitles = new Array();
        for(i = 0; i &lt; titles.length; i++) {
                if(newtitles.toString().indexOf(titles[i])) {
                        newtitles.push(titles[i]);
                }
        }
        titles = newtitles;

        titles = titles.join("^");
        setCookie("titles", titles);
}

function hideseen(name){
        titles = getCookie("titles");
        titles = titles.split("^");
        for(i = 0; i &lt; titles.length; i++) {
                hidetitle(titles[i]); 
        }
}

function hideshowings(showings) {
        for (var i = 0; i &lt; showings.snapshotLength; i++) {
                var showing = showings.snapshotItem(i).parentNode;
                showing.parentNode.removeChild(showing);
        } 
}

function hidetitle(title) {
        var showings = document.evaluate(
                "//tr[@id='film']/td[@id='" + title + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function showtitle(title) {
        var showings = document.evaluate(
                "//tr[@id='film']/td[1][@id!='" + title + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function hidebefore(time) {
        var showings = document.evaluate(
                "//tr[@id='film']/td[@id&lt;'" + time + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function hideafter(time) {
        var showings = document.evaluate(
                "//tr[@id='film']/td[@id&gt;'" + time + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function getday() {
        var d = new Date();
        var year = String(d.getFullYear());
        var month = String(d.getMonth() + 1);
        var day = String(d.getDate());

        if (month.length == 1) {
                month = "0" + month;
        }
        if (day.length == 1) {
                day = "0" + day;
        }
        return year + month + day;
}

function eve() {
        day = getday();
        hidebefore(day + "1845");
        hideafter(day  + "2245");
}

function soon() {
        day = getday();
        var d = new Date();

        var hours = String(d.getHours());
        var minutes = String(d.getMinutes());
        time = hours + minutes;
        hidebefore(day + time);

        var hours = String(d.getHours()+1);
        var minutes = String(d.getMinutes());
        time = hours + minutes;
        hideafter(day + time);
}

</script>
</head>
<body>
show
<a href="javascript:eve();">evening showings (18:45 to 22:45)</a>
or
<a href="javascript:soon();">showings starting soon (now to +1 hour)</a><br/>
<a href="javascript:hideseen();">hide</a>
or
<a href="javascript:resetseen();">reset</a>
seen
<br/>
<br/>
<table>
        <xsl:for-each select="cinemalistings/film/showings/showing">
        <xsl:sort select="substring(@time,1,4)"/>
        <xsl:sort select="substring(@time,6,2)"/>
        <xsl:sort select="substring(@time,9,2)"/>
        <xsl:sort select="substring(@time,12,2)"/>
        <xsl:sort select="substring(@time,15,2)"/>
        <xsl:if test="position() &lt; 64">

        <xsl:variable name="stime" select="concat(substring(@time,1,4),substring(@time,6,2),substring(@time,9,2),substring(@time,12,2),substring(@time,15,2))"/>

        <tr id="film">
                <td id="{../../@title}" />
                <td id="{$stime}" />
                <td id="position()" />
                <td>
                        <b><xsl:value-of select="substring(@time,1,16)"/></b>
                        <a href="{../../@url}">
                                <xsl:value-of select="../../@title"/>
                        </a>
                        Summary:
                        <b><xsl:value-of select="../../@summary"/></b>
                        Runtime:
                        <b><xsl:value-of select="../../@runtime"/></b>
                        Release:
                        <b><xsl:value-of select="../../@release"/></b>
                        Director:
                        <b><xsl:value-of select="../../@director"/></b>
                        Distributor:
                        <b><xsl:value-of select="../../@distributor"/></b>
                        Staring:
                        <b><xsl:value-of select="../../@staring"/></b>
                        Screen Play:
                        <b><xsl:value-of select="../../@screenplay"/></b>
                        See because:
                        <b><xsl:value-of select="../../@seebecause"/></b>
                        See if you liked:
                        <b><xsl:value-of select="../../@seeifyouliked"/></b>
                        <br/>
                        Hide showings
                        <a href="javascript:hidebefore('{$stime}');">before</a>
                        or
                        <a href="javascript:hideafter('{$stime}');">after</a>
                        this showing.
                        <br/>
                        <a href="javascript:hidetitle('{../../@title}');">Hide</a>
                        this title, hide and mark this title
                        <a href="javascript:markseen('{../../@title}');">seen</a>
                        or
                        <a href="javascript:showtitle('{../../@title}');">only</a>
                        show this title.
                        <br/>
                        <br/>
                </td>
                <td style="vertical-align: top">
                        <img src="{../../@img}"/>
                </td>
        </tr>
        </xsl:if>
        </xsl:for-each>
</table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
