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
function hideshowings(showings) {
        for (var i = 0; i &lt; showings.snapshotLength; i++) {
                var showing = showings.snapshotItem(i).parentNode;
                showing.parentNode.removeChild(showing);
        } 
}

function hidetitle(title) {
        var showings = document.evaluate( "//td[@id='" + title + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function showtitle(title) {
        var showings = document.evaluate( "//td[@id!='" + title + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function hidebefore(time) {
        var showings = document.evaluate( "//td[@id&lt;'" + time + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        hideshowings(showings) 
}

function hideafter(time) {
        var showings = document.evaluate( "//td[@id&gt;'" + time + "']" ,
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

<a href="javascript:eve();">show evening showings (18:45 to 2245)</a><br/>
<a href="javascript:soon();">show showings starting soon (now to +1 hour)</a>
<table>
        <xsl:for-each select="cinemalistings/film/showings/showing">
        <xsl:sort select="substring(@time,1,4)"/>
        <xsl:sort select="substring(@time,6,2)"/>
        <xsl:sort select="substring(@time,9,2)"/>
        <xsl:sort select="substring(@time,12,2)"/>
        <xsl:sort select="substring(@time,15,2)"/>

        <xsl:variable name="stime" select="concat(substring(@time,1,4),substring(@time,6,2),substring(@time,9,2),substring(@time,12,2),substring(@time,15,2))"/>

        <tr>
                <td id="{../../@title}" />
                <td id="{$stime}" />
                <td>
                        <xsl:value-of select="substring(@time,1,16)"/> 
                        <a href="{../../@url}">
                                <xsl:value-of select="../../@title"/>
                        </a>
                        <br/>
                        Runtime:
                        <b><xsl:value-of select="../../@runtime"/></b>
                        Release:
                        <b><xsl:value-of select="../../@release"/></b>
                        Director:
                        <b><xsl:value-of select="../../@director"/></b>
                        Staring:
                        <b><xsl:value-of select="../../@staring"/></b>
                        <br/>

                        Hide showings
                        <a href="javascript:hidebefore('{$stime}');">before</a>
                        or
                        <a href="javascript:hideafter('{$stime}');">after</a>
                        this showing.
                        <br/>
                        <a href="javascript:hidetitle('{../../@title}');">Hide</a>
                        this title or  
                        <a href="javascript:showtitle('{../../@title}');">only</a>
                        show this title.
                </td>
                <td>
                        <img src="{../../@img}"/>
                </td>
        </tr>
        </xsl:for-each>
</table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
