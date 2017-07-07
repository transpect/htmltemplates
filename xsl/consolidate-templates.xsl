<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml" 
  exclude-result-prefixes="xs html"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0">
  
  <xsl:template match="/">
    <!-- Transform the first document in the default collection(). All the documents are supposed to be 
      XHTML 1.0 documents that provide some boilerplate text. The documents are expected to be sorted by
      ascending specificity. When an element with the same ID is present in a more specific document, this 
      more specific element will be used. -->
    <xsl:apply-templates mode="resolve-cascade"/>
  </xsl:template>
  
  <xsl:template match="body" mode="resolve-cascade" >
    <xsl:copy>
      <xsl:variable name="current-ids" select="*/@id" as="xs:string*"/>
      <!-- in addition to the most generic document’s body content, transform all elements with
        IDs in the other bodies. -->
<xsl:message select="'#########################', $current-ids"/>
      <xsl:apply-templates select="@*, node(), 
                                   collection()[position() gt 1]//body/*[@id][not(@id = $current-ids)]" 
                           mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Priority=2: If body has an ID, it may be superseded by a more specific document’s body -->
  <xsl:template match="*[@id]" mode="resolve-cascade" priority="2">
    <xsl:for-each-group select="collection()//*[@id = current()/@id]" group-by="@id">
      <xsl:apply-templates select="current-group()[1]" mode="elt-with-id"/>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="*" mode="elt-with-id">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="resolve-cascade"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="* | @*" mode="resolve-cascade">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="head" mode="resolve-cascade">
    <xsl:copy>
      <xsl:apply-templates select="@*, node() except meta[@http-equiv = 'Content-Type']" mode="#current"/>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>