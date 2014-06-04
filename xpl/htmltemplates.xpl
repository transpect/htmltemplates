<?xml version="1.0" encoding="utf-8"?>
<p:library 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:bc="http://transpect.le-tex.de/book-conversion"
  xmlns:html="http://www.w3.org/1999/xhtml"
  version="1.0">

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/xproc-util/xslt-mode/xslt-mode.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  
  <p:declare-step name="consolidate-templates" type="html:consolidate-templates">
    <p:input port="source" primary="true" sequence="true">
      <p:documentation>HTML templates that will translate to XSLT templates.
      This one is for reducing templates of ascending specificity into one, using
      common IDs as a key for selecting only the most specific template.
      Transform the first document in the default collection(). All the documents are supposed to be 
      XHTML 1.0 documents that provide some boilerplate text. 
      Look into the XSLT file for a more specific description of the semantics. 
      </p:documentation>
    </p:input>
    <p:output port="result" primary="true"/>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:xslt name="consolidating-xsl">
      <p:input port="stylesheet">
        <p:document href="../xsl/consolidate-templates.xsl"/>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
    </p:xslt>
    <letex:store-debug pipeline-step="htmltemplates/compound" extension="xhtml">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>
  </p:declare-step>

  <p:declare-step name="generate-xsl-from-html-template" type="html:generate-xsl-from-html-template">
    <p:input port="source" primary="true">
      <p:documentation>HTML template, possibly consolidated by html:consolidate-templates</p:documentation>
    </p:input>
    <p:input port="generating-xsl">
      <p:documentation>A stylesheet that translates &lt;a rel="calc" name="…"/> to &lt;xsl:call-template name="…"/>.         
        The called templates have to be supplied on the 'implementing-xsl' port. implementing-xsl may of course
        import other stylesheets. This supports the configuration cascade: the implementing stylesheet may be
        a work-specific one, loaded by bc:load-cascaded, that imports the more generic stylesheets.
        &lt;a rel="calc"> may contain parameters &lt;input title="param-name" value="string"/>. These parameters
        have to be handled by the implementing stylesheet. 
        
        The remainder of the &lt;a rel="calc"> children will be passed to the implementing stylesheet in
        the $_content variable. The template might then choose to process a contained &lt;h2>, &lt;h3>, … HTML 
        element as the heading of the auto-generated section that it is going to create.
        
        Another mechanism is transclusion: &lt;a rel="transclude" href="#foo"/> will replace itself with 
        the content of &lt;div id="foo">&lt;/div> (that must reside immediately below the assembled HTML template’s 
        body element). 
        </p:documentation>
      <p:document href="../xsl/htmltemplate2xsl.xsl"/>
    </p:input>
    <p:input port="implementing-xsl">
      <p:documentation>The first document in the default collection is a metadata document (in an arbitrary XML vocabulary).
      All subsequent documents are XHTML fragments (e.g., renderings of a book’s body).</p:documentation>
    </p:input>
    <p:output port="result" >
      <p:pipe port="result" step="store"/>
      <p:documentation>An XSLT that will transform an HTML template into an XSLT template.
      This XSLT will be used to populate the body of the final HTML page. </p:documentation>
    </p:output>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:xslt name="generating-xsl">
      <p:input port="stylesheet">
        <p:pipe port="generating-xsl" step="generate-xsl-from-html-template"/>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="source">
        <p:pipe step="generate-xsl-from-html-template" port="source"/>
        <p:pipe step="generate-xsl-from-html-template" port="implementing-xsl"/>
      </p:input>
    </p:xslt>
    <letex:store-debug pipeline-step="htmltemplates/generated" extension="xsl" name="store">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>
    <p:sink/>
  </p:declare-step>


  <p:declare-step name="apply-generated" type="html:apply-generated-xsl">
    <p:input port="source" primary="true">
      <p:documentation>one or more XHTML body element(s), possibly converted from InDesign</p:documentation>
    </p:input>
    <p:output port="result" primary="true"/>
    <p:input port="metadata">
      <p:documentation>any vocabulary</p:documentation>
    </p:input>
    <p:input port="stylesheet-from-htmltemplate">
      <p:documentation>as generated by html:generate-xsl-from-html-template</p:documentation>
    </p:input>
    <p:input port="paths" kind="parameter"/>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:xslt name="apply-generated-xsl" template-name="main">
      <p:input port="source">
        <p:pipe port="metadata" step="apply-generated"/>
        <p:pipe port="source" step="apply-generated"/>
      </p:input>
      <p:input port="parameters">
        <p:pipe port="paths" step="apply-generated"/>      
      </p:input>
      <p:input port="stylesheet">
        <p:pipe port="stylesheet-from-htmltemplate" step="apply-generated"/>
      </p:input>
    </p:xslt>
    <letex:store-debug pipeline-step="htmltemplates/applied-generated" extension="xhtml">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>
  </p:declare-step>
  
  <p:declare-step name="templates" type="html:templates">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>A wrapper for the individual other steps in this library.</p>
    </p:documentation>
    <p:input port="source" primary="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>An XHTML document that represents the body of a work (no frontmatter etc. – this will be added by this step).</p>
      </p:documentation>
    </p:input>
    <p:input port="meta">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A metadata document in any vocabulary. Extracting meaningful data from this document 
          is up the implementing stylesheet.</p>
      </p:documentation>
    </p:input>
    <p:input port="paths">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A transpect paths document (<code>c:param-set</code> with certain <code>c:param</code>s
          that enable cascaded loading).</p>
      </p:documentation>
    </p:input>
    <p:output port="result" primary="true">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>The source XHTML document that is enhanced with rendered metadata.</p>
      </p:documentation>
    </p:output>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:option name="html-template" required="false" select="'htmltemplates/template.xhtml'"/>
    <p:option name="xsl-implementation" required="false" select="'htmltemplates/implementation.xsl'"/>
    
    <bc:load-whole-cascade name="all-templates">
      <p:with-option name="filename" select="$html-template"><p:empty/></p:with-option>
      <p:input port="paths">
        <p:pipe port="paths" step="templates"/>
      </p:input>
    </bc:load-whole-cascade>
    
    <html:consolidate-templates name="consolidate-templates">
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </html:consolidate-templates>
    
    <p:sink/>
    
    <bc:load-cascaded name="htmltemplates-implementation">
      <p:with-option name="filename" select="$xsl-implementation"><p:empty/></p:with-option>
      <p:input port="paths">
        <p:pipe port="paths" step="templates"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </bc:load-cascaded>
    
    <html:generate-xsl-from-html-template name="generate-xsl-from-html-template">
      <p:input port="implementing-xsl">
        <p:pipe port="result" step="htmltemplates-implementation"/>
      </p:input>
      <p:input port="source">
        <p:pipe port="result" step="consolidate-templates"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </html:generate-xsl-from-html-template>
    
    <p:sink/>
    
    <html:apply-generated-xsl name="apply-generated">
      <p:input port="source">
        <p:pipe port="source" step="templates"/>
      </p:input>
      <p:input port="metadata">
        <p:pipe port="meta" step="templates"/>
      </p:input>
      <p:input port="stylesheet-from-htmltemplate">
        <p:pipe port="result" step="generate-xsl-from-html-template"/>
      </p:input>
      <p:input port="paths">
        <p:pipe port="paths" step="templates"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </html:apply-generated-xsl>
    
  </p:declare-step>

</p:library>