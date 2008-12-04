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
function hideid(id) {
        var showings = document.evaluate( "//tr[@id='" + id + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (var i = 0; i &lt; showings.snapshotLength; i++) {
                var showing = showings.snapshotItem(i);
                showing.parentNode.removeChild(showing);

        } 
}

function showid(id) {
        var showings = document.evaluate( "//tr[@id!='" + id + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (var i = 0; i &lt; showings.snapshotLength; i++) {
                var showing = showings.snapshotItem(i);
                showing.parentNode.removeChild(showing);

        } 
}
</script>
</head>
<body>
<table>
        <xsl:for-each select="cinemalistings/film/showings/showing">
        <xsl:sort select="substring(@time,1,4)"/>
        <xsl:sort select="substring(@time,6,2)"/>
        <xsl:sort select="substring(@time,9,2)"/>
        <xsl:sort select="substring(@time,12,2)"/>
        <xsl:sort select="substring(@time,15,2)"/>

        <tr id="{../../@title}">
                <td colspan="2">
                        <br/>
                        <xsl:value-of select="substring(@time,1,15)"/> 
                        <a href="{../../@url}">
                                <xsl:value-of select="../../@title"/>
                        </a>
                </td>
        </tr>
        <tr id="{../../@title}">
                <td>
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
                        <a href="javascript:hideid('{../../@title}');">Hide</a>
                        <a href="javascript:showid('{../../@title}');">Show</a>
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
