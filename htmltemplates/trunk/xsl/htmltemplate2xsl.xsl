<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
  
  <xsl:variable name="implementing-stylesheet" as="document-node(element(*))" select="collection()[2]"/>
  
  <xsl:template match="/">
    <xslout:stylesheet version="2.0">
      <!-- The implementing stylesheet (or imported stylesheets thereof) must provide a template named 'main' -->
      <xsl:sequence select="$implementing-stylesheet/*/node()"/>
      <xslout:template name="body">
        <body xmlns="http://www.w3.org/1999/xhtml">
          <xsl:apply-templates select="/html/body/div[@id][1]"/>
        </body>
      </xslout:template>
    </xslout:stylesheet>
  </xsl:template>

  <xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="a[@rel = 'calc']">
    <xslout:call-template name="{@name}">
      <xsl:apply-templates select="input"/>
    </xslout:call-template>
  </xsl:template>
  
  <xsl:template match="input[@name][@value]">
    <xslout:with-param name="{@name}" select="'{@value}'"/>
  </xsl:template>
  
  <xsl:key name="by-id" match="*[@id]" use="@id"/>
  
  <xsl:template match="a[@rel = 'transclude'][@href]">
    <xsl:apply-templates select="key('by-id', replace(@href, '^#', ''))"/>
  </xsl:template>
  
  <!-- by convention, only divs that are immediately below body (and that have an ID)
    will be regarded as containers that surround template elements. They will be unwrapped. -->  
  <xsl:template match="body/div[@id]">
    <xsl:apply-templates/>
  </xsl:template>
  
</xsl:stylesheet>