<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs"
  version="2.0">
  <xsl:template match="/">
    <html>
      <head><title></title>
        <meta charset="UTF-8"/>
      </head>
      <body>
      <xsl:apply-templates/>
    </body>
    </html>
    
  </xsl:template>
  
  <xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="submission">
    <h1>Submission Manifest</h1>
    <xsl:apply-templates/>
    <hr/>
  </xsl:template>
  
  <xsl:template match="submission//*">
    <p>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each select="1 to count(ancestor::*)">
        <xsl:text>&#x2003;</xsl:text>
      </xsl:for-each>
      <b>
        <xsl:value-of select="name()"/>
      </b>
      <xsl:value-of select="string-join(for $a in (@* except @srcpath) return concat($a/name(), '=''', $a, ''''), ' ')"/>
      <xsl:text>:&#x2003;</xsl:text>
      <xsl:apply-templates select="text()" mode="#current"/>
    </p>
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>
  
</xsl:stylesheet>