<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="/">
<html>
<head>
<title>
<xsl:value-of select="cinemalistings/@chain"/>
<!--
18:45 to 21:45
-->
(<xsl:value-of select="cinemalistings/@location"/>)
</title>
<script language="JavaScript">
function removesaved() {
        /* document.cookie.split("; ") */
}

function hideid(id) {
        var showings = document.evaluate( "//tr[@id='" + id + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (var i = 0; i &lt; showings.snapshotLength; i++) {
                var showing = showings.snapshotItem(i);
                showing.parentNode.removeChild(showing);

        } 
        /* document.cookie=id + "=" */
        }

function showid(id) {
        var showings = document.evaluate( "//tr[@id!='" + id + "']" ,
                document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (var i = 0; i &lt; showings.snapshotLength; i++) {
                var showing = showings.snapshotItem(i);
                showing.parentNode.removeChild(showing);

        } 
        document.cookie=id + "="
        }
</script>
</head>
<body onLoad="removesaved()">
<table>
        <xsl:for-each select="cinemalistings/film/showings/showing">
        <xsl:sort select="@time"/>
        <xsl:variable name="hour" select="substring-before(@time, ':')" />
        <xsl:variable name="min" select="substring-after(@time, ':')" />
<!--
        <xsl:if test="($hour = 18 and $min &gt; 44) or ($hour &gt; 18)">
        <xsl:if test="($hour = 22 and $min &lt; 46) or ($hour &lt; 22)">
-->
        <tr id="{../../@title}">
                <td colspan="2">
                        <br/>
                        <xsl:value-of select="@time"/> 
                        <a href="{../../@url}">
                                <xsl:value-of select="../../@title"/>
                        </a>
                </td>
        </tr>
        <tr id="{../../@title}">
                <td>
                        Runtime:
                        <b><xsl:value-of select="../../@runtime"/></b>
                        Showing Since:
                        <b><xsl:value-of select="../../@showingfrom"/></b>
                        Director:
                        <b><xsl:value-of select="../../@director"/></b>
                        Staring:
                        <xsl:value-of select="../../@staring"/>
                        <br/>
                        <a href="javascript:hideid('{../../@title}');">Hide</a>
                        <a href="javascript:showid('{../../@title}');">Show</a>
                </td>
                <td>
                        <img src="{../../@img}"/>
                </td>
        </tr>
<!--
        </xsl:if>
        </xsl:if>
-->
        </xsl:for-each>
</table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
