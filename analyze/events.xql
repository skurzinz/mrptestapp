xquery version "3.1";
declare namespace functx = "http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config="http://www.digital-archiv.at/ns/config" at "../modules/config.xqm";
import module namespace app="http://www.digital-archiv.at/ns/templates" at "../modules/app.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
(:declare option exist:serialize "method=xml";:)
(:declare option exist:serialize "method=html5 media-type=text/html";:)
declare option exist:serialize "method=xml media-type=text/xml";

let $notBefores := collection($app:editions)//tei:TEI//*[@notBefore castable as xs:date]
let $whens := collection($app:editions)//tei:TEI//tei:date[@when castable as xs:date]
let $dates := ($notBefores, $whens)

    let $collection := request:get-parameter("collection", "")
    let $docs := if ($collection)
        then
            collection(concat($config:app-root, '/data/', $collection, '/'))//tei:TEI
        else
            collection(concat($config:app-root, '/data/editions/'))//tei:TEI
    let $baseurl := "http://inz-pc18:8080/exist/apps/mrp/" (:"https://hw.oeaw.ac.at/ministerrat/serie-1/":)
    (: http://inz-pc18:8080/exist/apps/mrp/pages/show.html?document=MRP-1-0-00-0-00000000-abb.xml&directory=editions :)
    let $baseurlnew := "https://mrptestapp.acdh-dev.oeaw.ac.at/" 
            
    let $data :=
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader resp="#skurzinz">
        <fileDesc>
            <titleStmt>
                <title>listEvent Ministerratsprotokolle 1848-1867</title>
            </titleStmt>
            <publicationStmt>
                <publisher>ÖAW INZ
                </publisher>
                <pubPlace>Wien</pubPlace>
                <ptr target="https://www.oeaw.ac.at/inz/digitales/"/>
                <address>
                    <placeName>Wien</placeName>
                </address>
                <date when="2019-09-18">2019-09-18</date>
                <distributor>
                    <persName ref="http://d-nb.info/gnd/13281899X" xml:id="skurzinz">
                        <forename>Stephan</forename> <surname>Kurz</surname>
                    </persName>
                    <idno type="ORCID">https://orcid.org/0000-0003-2546-2570</idno>
                </distributor>
                <availability>
                    <licence target="https://creativecommons.org/licenses/by/4.0/">
                        <p>The CC BY 4.0 license applies to this document.</p>
                    </licence>
                </availability>
            </publicationStmt>
            <sourceDesc>
                <p>Generated using events.xql from unpublished TEI derivates of generic XML data available on <ref target="https://hw.oeaw.ac.at/ministerrat/">https://hw.oeaw.ac.at/ministerrat/</ref>.</p>
		<p>At the time of exporting, the parsing of what should indeed be saved in the tei:abstract as tei:listPerson was not yet finished; expect listPersons to bei included in a later release.</p>
            </sourceDesc>
        </fileDesc>
        <encodingDesc>
            <p>The current model follows the TEI P5 Guidelines on the `event` element in version <ref target="https://github.com/TEIC/TEI/releases/tag/P5_Release_3.6.0">3.6.0.</ref>  
            Known caveats include the nesting of agenda_item events within the `desc/listEvent` child of the session event, which is semantically imperfect.
            Nesting the `events` at all might be controversial for the purpose of a discovery/dissemination service; here they are neatly wrapped e.g. for dynamic preloading.
            For a discussion of the `event` model as given by <persName ref="https://orcid.org/0000-0001-5099-8970"><forename>Christiane</forename> <surname>Fritze</surname></persName>, 
            <persName ref="https://orcid.org/0000-0002-7461-5820"><forename>Helmut W.</forename> <surname>Klug</surname></persName> and 
            <persName ref="https://orcid.org/0000-0002-3651-8114"><forename>Christoph</forename> <surname>Steindl</surname></persName> together with the <rs type="person" ref="#skurzinz">author</rs>, 
            cf. <ref target="https://tinyurl.com/eventSearch">https://tinyurl.com/eventSearch</ref>.</p>
        </encodingDesc>
    </teiHeader>
    <text>
        <body>
        <p>Work in progress with a rudimentary display, see <ref target="/exist/restxq/mrptestapp/api/collections/indices/mrptestapp_analyze_events.xql.xml">source</ref> for details. No listPerson yet included for the time being.</p>
    <listEvent type="generated">{        
    for $title in $docs
        where count($title//tei:list[@type='agenda']/tei:item) > 0 and count($title//tei:titleStmt/tei:title) > 1
        let $id := concat('mrp-events-', $title//tei:body/tei:div/@xml:id[1])
        let $link2doc := if ($collection)
            then
                <a href="{app:hrefToDoc($title, $collection)}">{app:getDocName($title)}</a>
            else
                <a href="{app:hrefToDoc($title)}">{app:getDocName($title)}</a>
        let $link2docnew := if ($collection)
            then
                <a href="{app:hrefToDoc($title, $collection)}">{app:getDocName($title)}</a>
            else
                <a href="{app:hrefToDoc($title)}">{app:getDocName($title)}</a>
        let $link2doc := replace($link2doc, 'a1-b1', 'a1') (: special case where hw.oeaw.ac.at is providing inconsistent directory and file name schema for vol I/1 :)
        let $datum := if ($title//tei:titleStmt[1]//tei:meeting/tei:date[1]/@when[1])
            then data($title//tei:titleStmt[1]//tei:meeting/tei:date[1]/@when[1])(:/format-date(xs:date(@when), '[D02].[M02].[Y0001]')):)
            else data($title//tei:publicationStmt//tei:date[1]/@when[1]) (: picks date from print edition :)
        let $date := normalize-space(string-join($title//tei:div/tei:head/tei:title//text(), ' '))
        let $texts := for $x in $title//tei:list[@type='agenda']/tei:item
                    return
                        if (contains($title//tei:titleStmt/tei:title, 'cis'))  
                        then <event type="agenda_item" ref="{concat($baseurlnew, 'pages/show.html?directory=editions&amp;document=', $link2docnew, '#', $x//tei:label/tei:num)}" when="{$datum}" where="Wien" xml:id="{concat($id, '-', translate($x//tei:label/tei:num, '][ ', ''))}"><label>{normalize-space(concat('Tagesordnungspunkt ', $x//tei:num/text(), ' im österreichischen Ministerrat (', $datum, '): ', $x//tei:ref/text()))}</label></event>
(:                        else <event type="agenda_item" ref="{concat($baseurl, $link2doc, '#', $x//tei:label/tei:num)}" when="{$datum}" where="Wien" xml:id="{concat($id, '-', translate($x//tei:label/tei:num, '][ ', ''))}"><label>{normalize-space(concat('Tagesordnungspunkt ', $x//tei:num/text(), ' im österreichischen Ministerrat (', $datum, '): ', $x//tei:ref/text()))}</label></event>:)
(:                        else <event type="agenda_item" ref="{concat($baseurl, $link2doc, '#', $x//tei:label/tei:num)}" when="{$datum}" where="Wien" xml:id="{concat($id, '-', translate($x//tei:label/tei:num, '][ ', ''))}"><label>{concat('TOP ', $x//tei:num/text(), ' (', $datum, '): ', $x/tei:ref[1]/text())}</label></event>:)
                        else <event type="agenda_item" ref="{concat($baseurl, 'pages/show.html?directory=editions&amp;document=', $link2doc, $x//tei:ref/@target)}" when="{$datum}" where="Wien" xml:id="{concat($id, '-', translate($x//tei:label/tei:num, '][ ', ''))}"><label>{$x//tei:num/text(), ' (', $datum, '): ', $x/tei:ref[1]/text()}</label></event>
        let $abt := data($title//tei:titleStmt//tei:title[@level='s']/@n)
        let $vol := data($title//tei:titleStmt//tei:title[@level='m']/@n)
        let $editor := normalize-space(string-join($title//tei:titleStmt/tei:editor/tei:persName[1]))
        let $timespan := normalize-space(string-join($title//tei:titleStmt/tei:title[@level='m'][@type='sub']))
        
        return
            if (contains($title//tei:titleStmt/tei:title, 'cis'))
            then <event xml:id="{$id}" ref="{concat($baseurlnew, $link2docnew)}" when="{$datum}" where="Wien" type="session">
                    <head>{$date}</head>
                    <label>Ministerratssitzung <date when="{$datum}">{$datum}</date>, aus Band {$abt}/{$vol}, {$timespan}</label>
                    <desc>
                        <listEvent type="generated">
                            {$texts}
                        </listEvent>
                    </desc>
                </event>
            else <event xml:id="{$id}" ref="{concat($baseurl, $link2doc)}" when="{$datum}" where="Wien" type="session">
                <head>{$date}</head>
                    <label>Ministerratssitzung <date when="{$datum}">{$datum}</date>, aus Band {$abt}/{$vol}, {$timespan}</label>
                    <desc>
                        <listEvent type="generated">
                            {$texts}
                        </listEvent>
                    </desc>
                </event>
        }
        </listEvent>
        </body>
        </text>
        </TEI>
        
return $data
        (:<tr>
            <td>{$abt}</td>
            <td title="Hrsg.: {$editor}, {$timespan}">{$vol}</td>
           <td>{$date}<ul>{$texts}</ul></td>
           <td>{$datum}</td>
            <td>
                {$link2doc}
            </td>
        </tr>:)
