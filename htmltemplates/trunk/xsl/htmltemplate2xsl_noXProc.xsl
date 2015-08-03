<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:xslout="bogo"
  exclude-result-prefixes="xs"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <xsl:namespace-alias stylesheet-prefix="xslout" result-prefix="xsl"/>
  
  <!-- The processed document is an XHTML file. By convention, we start processing the first div that has an ID. -->
  <!-- The second document in the default collection is the implementing stylesheet (for the named templates).
    Since it may contain xsl:import statements, its content must be included first in the generated stylesheet. -->
  
  <!-- override this in an appropriate importing stylesheet, such as htmltemplate2xsl.xsl for XProc or other systems
    where there is a default collection() and the implementing stylesheet will be the 2nd document in the default collection. 
    If present, it should be an xsl:stylesheet document.
    Its contents will be passed literally to the generated stylesheet. -->
  <xsl:variable name="implementing-stylesheet" as="document-node(element(*))?"/>
  <xsl:variable name="htmltemplate" as="document-node(element(*))" select="/"/>
  
  <xsl:template match="/">
    <xslout:stylesheet version="2.0">
      <!-- The implementing stylesheet (or imported stylesheets thereof) must provide a template named 'main' -->
<!--      <xsl:sequence select="$implementing-stylesheet/*/node()"/>-->
      <xsl:apply-templates select="$implementing-stylesheet/*/node()" mode="copy-xsl"/>
      <xsl:apply-templates select="/html/body/div[@id][1]/input" mode="root"/> 
      <xslout:template name="body">
        <body xmlns="http://www.w3.org/1999/xhtml">
          <xsl:apply-templates select="/html/body/div[@id][1]"/>
        </body>
      </xslout:template>
    </xslout:stylesheet>
  </xsl:template>

  <xsl:template match="* | @*">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="xsl:* | @*" mode="copy-xsl">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!--<xsl:template match="text()[not(normalize-space())]" mode="copy-xsl"/>-->

  <xsl:template match="*" mode="copy-xsl">
    <xsl:apply-templates select="." mode="#default"/>
  </xsl:template>
  
  <xsl:template match="a[@rel = 'calc']" mode="#default copy-xsl">
    <xsl:param name="_input" as="element(html:input)*" tunnel="yes"/>
    <xslout:call-template name="{@name}">
      <xsl:apply-templates select="input, $_input[not(@title = current()/input/@title)]"/>
      <xsl:variable name="non-input-nodes" as="node()*" select="node() except input"/>
      <xsl:if test="matches(string-join($non-input-nodes, ''), '\S') or $non-input-nodes/self::*">
        <xslout:with-param name="_content">
          <xsl:apply-templates select="$non-input-nodes" mode="copy-xsl">
            <xsl:with-param name="_input" select="input" tunnel="yes"/>
          </xsl:apply-templates>
        </xslout:with-param>
      </xsl:if>
    </xslout:call-template>
  </xsl:template>
  
  <xsl:template match="input[@title][@value]">
    <xslout:with-param name="{@title}" select="'{@value}'" tunnel="yes"/>
  </xsl:template>

  <xsl:template match="input[@title][@value]" mode="root">
    <xslout:param name="{@title}" select="'{@value}'"/>
  </xsl:template>
  
  <xsl:key name="by-id" match="*[@id]" use="@id"/>
  
  <xsl:template match="a[@rel = 'transclude'][@href]">
    <xsl:variable name="target" select="key('by-id', replace(@href, '^#', ''), $htmltemplate)" as="element(html:div)?"/>
    <xsl:choose>
      <xsl:when test="not($target)">
        <xsl:message select="'htmltemplates: target ', string(@href), ' not found'" ></xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$target"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- by convention, only divs that are immediately below body (and that have an ID)
    will be regarded as containers that surround template elements. They will be unwrapped. -->  
  <xsl:template match="body/div[@id]">
    <xsl:apply-templates select="* except input"/>
  </xsl:template>
  
</xsl:stylesheet>