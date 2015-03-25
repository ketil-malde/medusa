<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="dataset">
  <a>
    <xsl:attribute name="href">/data/<xsl:value-of select="@id"/>/index.html</xsl:attribute>
    <xsl:attribute name="class">dataset</xsl:attribute>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<xsl:template match="species">
  <a>
    <xsl:attribute name="href">/TSN/<xsl:value-of select="@tsn"/>.html</xsl:attribute>
    <xsl:attribute name="class">species</xsl:attribute>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<xsl:template match="cite">
  <a>
    <xsl:attribute name="href">http://dx.doi.org/<xsl:value-of select="@doi"/></xsl:attribute>
    <xsl:if test="not(string(.))">
       [Citation]
    </xsl:if>
    <xsl:apply-templates/>

  </a>
</xsl:template>

</xsl:stylesheet>
