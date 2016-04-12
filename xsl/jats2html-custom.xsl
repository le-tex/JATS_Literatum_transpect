<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:css="http://www.w3.org/1996/css"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:jats="http://jats.nlm.nih.gov"
                xmlns:jats2html="http://transpect.io/jats2html"
                xmlns:hub2htm="http://transpect.io/hub2htm"
                xmlns:l10n="http://transpect.io/l10n"
                xmlns:tr="http://transpect.io"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns="http://www.w3.org/1999/xhtml"
                xml:base="http://transpect.io/jats2html/xsl/jats2html.xsl"
                exclude-result-prefixes="html tr xlink xs css saxon jats2html hub2htm l10n cx"
                version="2.0">

  <xsl:import href="http://transpect.io/jats2html/xsl/jats2html.xsl"/>

  <xsl:template match="table-wrap[alternatives]" mode="jats2html" priority="3">
      <div class="{local-name()} {string(table/@content-type)} alt-image">
         <xsl:apply-templates select="@*, node()" mode="#current"/>
      </div>
  </xsl:template>

  <xsl:template match="table-wrap/alternatives[graphic] | boxed-text/alternatives[graphic]" mode="jats2html" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:key name="by-id" match="*[@id]" use="@id"/>
  
  <xsl:template match="@id" mode="clean-up">
    <xsl:attribute name="{name()}" select="string-join((., generate-id()), '_______')"/>
  </xsl:template>
  
  <xsl:template match="@href[matches(., '#')]" mode="clean-up">
    <xsl:variable name="id" select="key('by-id', replace(., '^#', ''))" as="element(*)?"/>
    <xsl:variable name="new" as="attribute(*)?">
      <xsl:apply-templates select="$id/@id" mode="#current"/>
    </xsl:variable>
    <xsl:attribute name="{name()}" select="if ($new) then concat('#', $new) else ."/>
  </xsl:template>

</xsl:stylesheet>
