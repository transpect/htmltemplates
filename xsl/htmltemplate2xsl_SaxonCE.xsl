<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
  xmlns:xslout="bogo"
  exclude-result-prefixes="xs"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  version="2.0">

  <!-- this is the XProc frontend to this stylesheet: -->
  <xsl:import href="htmltemplate2xsl_noXProc.xsl"/>
  
  <xsl:param name="implementing-stylesheet-as-string" as="xs:string"/>
  
  <xsl:variable name="implementing-stylesheet" as="document-node(element(*))" 
    select="ixsl:eval('Saxon.parseXML(', $implementing-stylesheet-as-string, ')')"/>
  
</xsl:stylesheet>