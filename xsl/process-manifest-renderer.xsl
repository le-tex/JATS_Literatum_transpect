<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:c="http://www.w3.org/ns/xproc-step"
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
    <h1>
      <xsl:apply-templates select="@*"/>
      <xsl:text>Submission Manifest</xsl:text>
    </h1>
    <xsl:apply-templates/>
    <hr/>
  </xsl:template>
  
  <xsl:template match="/c:directory">
    <xsl:next-match>
      <xsl:with-param name="base-dir-href" select="replace(@xlink:href, '/+', '/')" tunnel="yes"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template match="c:directory | c:file">
    <xsl:param name="base-dir-href" as="xs:string" tunnel="yes" select="'/'"/>
    <xsl:element name="h{count(ancestor-or-self::c:directory)}">
      <xsl:attribute name="style" select="'font-family: monospace'"></xsl:attribute>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="substring(replace(@xlink:href, '/+', '/'), string-length($base-dir-href))"/>
      <xsl:text> [</xsl:text>
      <xsl:value-of select="substring(local-name(), 1, 1)"/>
      <xsl:text>]</xsl:text>
    </xsl:element>
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
  
  <xsl:template match="html:h1">
    <h2>
      <xsl:apply-templates select="@*, node()"/>
    </h2>
  </xsl:template>
  
  <xsl:template match="html:h2">
    <h3>
      <xsl:apply-templates select="@*, node()"/>
    </h3>
  </xsl:template>
  
  <xsl:template match="html:h3">
    <h4>
      <xsl:apply-templates select="@*, node()"/>
    </h4>
  </xsl:template>
  
  <xsl:template match="html:h5 | html:h6">
    <p css:font-weight="bold">
      <xsl:apply-templates select="@*, node()"/>
    </p>
  </xsl:template>
  
</xsl:stylesheet>