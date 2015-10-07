<?xml version="1.0" encoding="utf-8"?>
<p:library 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
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
        a work-specific one, loaded by transpect:load-cascaded, that imports the more generic stylesheets.
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
    <p:input port="source" primary="true" sequence="true" select="/html:html">
      <p:documentation>one or more XHTML body element(s), possibly converted from InDesign</p:documentation>
    </p:input>
    <p:output port="result" primary="true"/>
    <p:input port="metadata" sequence="true" select="/*">
      <p:documentation>any vocabulary, any number of documents</p:documentation>
    </p:input>
    <p:input port="stylesheet-from-htmltemplate">
      <p:documentation>as generated by html:generate-xsl-from-html-template</p:documentation>
    </p:input>
    <p:input port="paths" kind="parameter"/>
    <p:option name="qa-run" required="false" select="'false'"/>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:xslt name="apply-generated-xsl" template-name="main">
      <p:input port="source">
        <p:documentation>It’s up to the stylesheet to tell metadata from HTML input (for example, by namespace and/or top level element name).</p:documentation>
        <p:pipe port="metadata" step="apply-generated"/>
        <p:pipe port="source" step="apply-generated"/>
      </p:input>
      <p:input port="parameters">
        <p:pipe port="paths" step="apply-generated"/>      
      </p:input>
      <p:input port="stylesheet">
        <p:pipe port="stylesheet-from-htmltemplate" step="apply-generated"/>
      </p:input>
      <p:with-param name="qa-run" select="$qa-run"/>
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
    <p:input port="source" primary="true" select="/html:html">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>An XHTML document that represents the body of a work (no frontmatter etc. – this will be added by this step).</p>
      </p:documentation>
    </p:input>
    <p:input port="meta" sequence="true" select="/*">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>One or more metadata documents in any vocabulary. Extracting meaningful data from these documents is up the implementing
          stylesheet. Also the number of documents expected.</p>
      </p:documentation>
    </p:input>
    <p:input port="paths">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>A transpect paths document (<code>c:param-set</code> with certain <code>c:param</code>s that enable cascaded
          loading).</p>
      </p:documentation>
    </p:input>
    <p:output port="result" primary="true">
      <p:pipe port="result" step="add-base-uri"/>
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <p>The source XHTML document that is enhanced with rendered metadata.</p>
      </p:documentation>
    </p:output>
    <p:option name="debug" required="false" select="'no'"/>
    <p:option name="debug-dir-uri" required="false" select="'debug'"/>
    <p:option name="html-template" required="false" select="'htmltemplates/template.xhtml'"/>
    <p:option name="xsl-implementation" required="false" select="'htmltemplates/implementation.xsl'"/>
    <p:option name="file-uri-to-cover-regex" required="false" select="'/.+?/.+$'"/>
    <p:option name="different-basename" required="false" select="''">
      <p:documentation>Whether the resulting HTML file (and therefore the future EPUB)
      should have a base name (non-directory, non-extension part of the complete file name)
      that is different from the input file. For example, this string could be looked up 
      in a metadata dump prior to invoking this HTML template.</p:documentation>
    </p:option>
    <p:option name="qa-run" required="false" select="'false'">
      <p:documentation>Whether the current conversion is for quality assurance purposes. Additional error information 
      may be rendered in the result.</p:documentation>
    </p:option>

    <transpect:load-whole-cascade name="all-templates">
      <p:with-option name="filename" select="$html-template">
        <p:empty/>
      </p:with-option>
      <p:input port="paths">
        <p:pipe port="paths" step="templates"/>
      </p:input>
    </transpect:load-whole-cascade>

    <html:consolidate-templates name="consolidate-templates">
      <p:with-option name="debug" select="$debug">
        <p:empty/>
      </p:with-option>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri">
        <p:empty/>
      </p:with-option>
    </html:consolidate-templates>

    <p:sink/>

    <transpect:load-cascaded name="htmltemplates-implementation">
      <p:with-option name="filename" select="$xsl-implementation">
        <p:empty/>
      </p:with-option>
      <p:input port="paths">
        <p:pipe port="paths" step="templates"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </transpect:load-cascaded>

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
      <p:with-option name="qa-run" select="$qa-run"><p:empty/></p:with-option>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </html:apply-generated-xsl>

    <!--<cx:message>
      <p:with-option name="message" select="'BASE: ', replace(
  	     	          /c:param-set/c:param[@name eq 'file']/@value, 
  		              '/[^/]+/([^/]+)$',
  		              if ($different-basename = '') 
  		              then '/epub/$1' 
  		              else concat('/epub/', $different-basename)
  		            )">
        <p:pipe port="paths" step="templates"/>
      </p:with-option>
    </cx:message>-->

    <p:add-attribute name="add-base-uri" match="/*" attribute-name="xml:base">
      <p:with-option name="attribute-value"
        select="replace(
  	              replace(
  	     	          /c:param-set/c:param[@name eq 'file']/@value, 
  		              '/[^/]+/([^/]+)$',
  		              if ($different-basename = '') 
  		              then '/epub/$1' 
  		              else concat('/epub/', $different-basename, '.html')
  		            ),
  		            '\.[^.]+$',
  		            '.html'
  	            )">
        <p:pipe port="paths" step="templates"/>
      </p:with-option>
    </p:add-attribute>

    <letex:store-debug extension="xhtml" name="store">
      <p:with-option name="pipeline-step" select="concat('htmltemplates/generated_', replace(base-uri(/*), '^.+/(.+)\..+?$', '$1'))"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>
    
    <p:choose name="get-http-cover">
      <p:when test="matches(/html:html/html:body/html:div[@class eq 'epub-cover-image-container']/html:img/@src, 'https?:')">
        <p:identity>
          <p:input port="source">
            <p:inline>
              <c:request method="GET"/>
            </p:inline>
          </p:input>
        </p:identity>
        <p:add-attribute match="/c:request" attribute-name="href">
          <p:with-option name="attribute-value"
            select="/html:html/html:body/html:div[@class eq 'epub-cover-image-container']/html:img/@src">
            <p:pipe step="add-base-uri" port="result"/>
          </p:with-option>
        </p:add-attribute>
        <p:http-request name="get-cover"/>
        <p:store name="store-cover" cx:decode="true">
          <p:with-option name="href"
            select="replace(/c:param-set/c:param[@name eq 'file']/@value, $file-uri-to-cover-regex, '/images/cover.jpg')">
            <p:pipe port="paths" step="templates"/>
          </p:with-option>
        </p:store>
      </p:when>
      <p:otherwise>
        <p:sink/>
      </p:otherwise>
    </p:choose>

  </p:declare-step>

</p:library>