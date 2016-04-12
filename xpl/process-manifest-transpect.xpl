<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:l="http://xproc.org/library" 
  xmlns:pxp="http://exproc.org/proposed/steps"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:tr="http://transpect.io"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:jats="http://jats.nlm.nih.gov"
  xmlns:html="http://www.w3.org/1999/xhtml"
  version="1.0" 
  name="process-manifest-transpect">

  <p:documentation>This is a front-end for transpect to process-manifest.xpl. See the corresponding documentation there.</p:documentation>

  <p:input port="source" primary="true">
    <p:documentation>A manifest file. See framework/build-issue/process-manifest.xpl</p:documentation>
  </p:input>

  <p:input port="schematron">
    <p:document href="http://hogrefe.com/JATS/schematron/literatum_package.sch"/>
  </p:input>
  <p:input port="article-schematron">
    <p:document href="http://hogrefe.com/JATS/schematron/literatum_JATS.sch"/>
  </p:input>
  <p:input port="html-rendering-xsl">
    <p:document href="../xsl/process-manifest-renderer.xsl"/>
  </p:input>

  <p:output port="htmlreport" primary="true"/>
  <p:serialization port="htmlreport" indent="true" omit-xml-declaration="false" method="xhtml"/>

  <p:output port="report" sequence="true">
    <p:pipe port="report" step="rng-article"/>
  </p:output>

  <p:option name="tmpdir" required="false" select="''">
    <p:documentation>URI or file system path. If not given, will be calculated.</p:documentation>
  </p:option>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://hogrefe.com/JATS/build-issue/process-manifest.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/insert-srcpaths/xpl/insert-srcpaths.xpl"/>
  <p:import href="http://transpect.io/jats2html/xpl/jats2html.xpl"/>
  <p:import href="http://transpect.io/htmlreports/xpl/validate-with-rng.xpl"/>
  <p:import href="http://transpect.io/htmlreports/xpl/patch-svrl.xpl"/>
  
  <jats:process-manifest name="process-manifest" transpect="true">
    <p:input port="schematron">
      <p:pipe port="schematron" step="process-manifest-transpect"/>
    </p:input>
    <p:input port="article-schematron">
      <p:pipe port="article-schematron" step="process-manifest-transpect"/>
    </p:input>
    <p:with-option name="tmpdir" select="$tmpdir"/>
  </jats:process-manifest>
  
  <p:viewport match="c:file/article" name="render-articles">
    <p:output port="result" primary="true"/>
    <tr:insert-srcpaths/>
    <p:documentation>Unfortunately, we cannot use the packaged jats-html.xsl because the stylesheet is not
    designed for custom attributes. It will be too difficult not to discard srcpath attributes if we use
    this stylesheet.</p:documentation>
    <jats:html srcpaths="yes">
      <p:input port="paths">
        <p:empty/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </jats:html>
    <p:filter select="/html:html/html:body"/>
    <p:rename match="/html:body" new-name="div" new-namespace="http://www.w3.org/1999/xhtml"/>
    <p:add-attribute match="/html:div" attribute-name="class" attribute-value="jats-article"/>
  </p:viewport>
  
  <tr:store-debug pipeline-step="render-package-input">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug> 

  <p:xslt name="render">
    <p:input port="stylesheet">
      <p:pipe port="html-rendering-xsl" step="process-manifest-transpect"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="render-package-output">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug> 

  <p:sink/>
  
  <p:for-each name="rng-article">
    <p:iteration-source select="//c:file/article">
      <p:pipe port="validation-input" step="process-manifest"/>
    </p:iteration-source>
    <p:output port="report" primary="true">
      <p:pipe port="result" step="rename-family"/>
    </p:output>
    <p:delete match="/*/@xml:base"/>
    <tr:validate-with-rng-svrl name="rng-article1" debug="yes">
      <p:with-option name="debug-dir-uri" select="/*/@local-href">
        <p:pipe port="tmpdir-uri" step="process-manifest"/>
      </p:with-option>
      <p:input port="schema">
        <p:document href="http://hogrefe.com/JATS/schema/JATS-1.0/rng/JATS-archivearticle1.rng"/>
      </p:input>
    </tr:validate-with-rng-svrl>
    <p:sink/>
    <p:add-attribute attribute-name="tr:rule-family" match="/*" name="rename-family">
      <p:with-option name="attribute-value" select="replace(base-uri(/*), '^.+/', 'article schema ')">
        <p:pipe port="current" step="rng-article"/>
      </p:with-option>
      <p:input port="source">
        <p:pipe port="report" step="rng-article1"/>
      </p:input>
    </p:add-attribute>
  </p:for-each>
  
  <p:sink/>

  <tr:patch-svrl name="patch">
    <p:input port="source">
      <p:pipe port="result" step="render"/>
    </p:input>
    <p:input port="reports">
      <p:pipe port="report" step="rng-article"/>
      <p:pipe port="report" step="process-manifest"/>
    </p:input>
    <p:with-option name="debug" select="'yes'"/>
    <p:with-option name="debug-dir-uri" select="/*/@local-href">
      <p:pipe port="tmpdir-uri" step="process-manifest"/>
    </p:with-option>
    <p:input port="params">
      <p:empty/>
    </p:input>
  </tr:patch-svrl>

</p:declare-step>