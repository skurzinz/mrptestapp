xquery version "3.0";
module namespace app="http://www.digital-archiv.at/ns/mp-app/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = 'http://www.functx.com';
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://www.digital-archiv.at/ns/mp-app/config" at "config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare variable $exist:root external;

declare variable  $app:editions := $config:app-root||'/data/editions';
declare variable $app:placeIndex := $config:app-root||'/data/indices/listplace.xml';
declare variable $app:personIndex := $config:app-root||'/data/indices/listperson.xml';

declare function functx:contains-case-insensitive
  ( $arg as xs:string? ,
    $substring as xs:string )  as xs:boolean? {

   contains(upper-case($arg), upper-case($substring))
 } ;

 declare function functx:escape-for-regex
  ( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
    replace ($arg,concat('^.*',$delim),'')
 };
 
 declare function functx:substring-before-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   if (matches($arg, functx:escape-for-regex($delim)))
   then replace($arg,
            concat('^(.*)', functx:escape-for-regex($delim),'.*'),
            '$1')
   else ''
 } ;

declare function app:fetchEntity($ref as xs:string){
    let $entity := collection($config:app-root||'/data/indices')//*[@xml:id=$ref]
    let $type: = if (contains(node-name($entity), 'place')) then 'place'
        else if  (contains(node-name($entity), 'person')) then 'person'
        else 'unkown'
    let $viewName := if($type eq 'place') then(string-join($entity/tei:placeName[1]//text(), ', '))
        else if ($type eq 'person' and exists($entity/tei:persName/tei:forename)) then string-join(($entity/tei:persName/tei:surname/text(), $entity/tei:persName/tei:forename/text()), ', ')
        else if ($type eq 'person') then $entity/tei:placeName/tei:surname/text()
        else 'no name'
    let $viewName := normalize-space($viewName)
    
    return 
        ($viewName, $type, $entity)
};

declare function local:everything2string($entity as node()){
    let $texts := normalize-space(string-join($entity//text(), ' '))
    return 
        $texts
};

declare function local:viewName($entity as node()){
    let $name := node-name($entity)
    return
        $name
};


(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

(:~
: returns the name of the document of the node passed to this function.
:)
declare function app:getDocName($node as node()){
let $name := functx:substring-after-last(document-uri(root($node)), '/')
    return $name
};

(:~
 : href to document.
 :)
declare function app:hrefToDoc($node as node()){
let $name := functx:substring-after-last($node, '/')
let $href := concat('show.html','?document=', app:getDocName($node))
    return $href
};

(:~
 : a fulltext-search function
 :)
 declare function app:ft_search($node as node(), $model as map (*)) {
 if (request:get-parameter("searchexpr", "") !="") then
 let $searchterm as xs:string:= request:get-parameter("searchexpr", "")
 for $hit in collection(concat($config:app-root, '/data/editions/'))//*[.//tei:p[ft:query(.,$searchterm)]|.//tei:cell[ft:query(.,$searchterm)]]
    let $href := concat(app:hrefToDoc($hit), "&amp;searchexpr=", $searchterm) 
    let $score as xs:float := ft:score($hit)
    order by $score descending
    return
    <tr>
        <td>{$score}</td>
        <td class="KWIC">{kwic:summarize($hit, <config width="40" link="{$href}" />)}</td>
        <td>{app:getDocName($hit)}</td>
    </tr>
 else
    <div>Nothing to search for</div>
 };

declare function app:indexSearch_hits($node as node(), $model as map(*),  $searchkey as xs:string?, $path as xs:string?){
    let $indexSerachKey := $searchkey
    let $searchkey:= '#'||$searchkey
    for $title in collection($app:editions)//tei:TEI[.//*[@ref=$searchkey]] 
        let $hits := if (count(root($title)//*[@ref=$searchkey]) = 0) then 1 else count(root($title)//*[@ref=$searchkey])
        let $snippet := 
            for $entity in root($title)//*[@ref=$searchkey]
                    let $before := $entity/preceding::text()[1]
                    let $after := $entity/following::text()[1]
                    return
                        <p>... {$before} <strong><a href="{app:hrefToDoc($title)}"> {$entity/text()}</a></strong> {$after}...<br/></p>
        let $year := "1867"
        let $month := "Februar"
        let $protocol := $title//tei:title[@type="main"]/text()
            return 
                <tr>
                    <td>{$year}</td>
                    <td>{$month}</td>
                    <td align="center">{$protocol}</td>
                       <td>{$hits}</td>
                       <td>{$snippet}<p style="text-align:right">({<a href="{app:hrefToDoc($title)}">{app:getDocName($title)}</a>})</p></td>
                    </tr>   
};
 
(:~
 : creates a basic person-index derived from the  '/data/indices/listperson.xml'
 :)
declare function app:listPers($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey="
    for $person in doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:listPerson/tei:person
        return
        <tr>
            <td>
                <a href="{concat($hitHtml,data($person/@xml:id))}">{$person/tei:persName/tei:surname}</a>
            </td>
            <td>
                {$person/tei:persName/tei:forename}
            </td>
        </tr>
};

(:~
 : creates a basic place-index derived from the  '/data/indices/listplace.xml'
 :)
declare function app:listPlace($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey="
    for $place in doc(concat($config:app-root, '/data/indices/listplace.xml'))//tei:listPlace/tei:place
        return
        <tr>
            <td>
                <a href="{concat($hitHtml, data($place/@xml:id))}">{$place/tei:placeName}</a>
            </td>
            <td>{$place//tei:idno}</td>
            <td>{$place//tei:geo}</td>
        </tr>
};
(:~
 : creates a basic term-index derived from the all documents stored in collection'/data/editions'
 :)
declare function app:listTerms($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey="
    for $term in distinct-values(collection(concat($config:app-root, '/data/editions/'))//tei:term)
    order by $term
    return
        <tr>
            <td>
                <a href="{concat($hitHtml,data($term))}">{$term}</a>
            </td>
        </tr>
 };
(:~
 : creates a basic table of content derived from the documents stored in '/data/editions'
 :)
declare function app:toc($node as node(), $model as map(*)) {

    let $bestand := request:get-parameter("bestand", "")
    let $docs := if ($bestand)
        then 
            collection(concat($config:app-root, '/data/editions/'))//tei:TEI[contains(.//tei:title/text(), $bestand)]
        else 
            collection(concat($config:app-root, '/data/editions/'))//tei:TEI
    for $title in $docs
        let $year := "1867"
        let $month := "Februar"
        let $protocol := $title//tei:title[@type="main"]/text()
        return
        <tr>
           <td>{$year}</td>
           <td>{$month}</td>
           <td align="center">{$protocol}</td>
            <td>
                <a href="{app:hrefToDoc($title)}">{app:getDocName($title)}</a>
            </td>
        </tr>   
};

(:~
 : perfoms an XSLT transformation
:)
declare function app:XMLtoHTML ($node as node(), $model as map (*), $query as xs:string?) {
let $ref := xs:string(request:get-parameter("document", ""))
let $xmlPath := concat(xs:string(request:get-parameter("directory", "editions")), '/')
let $xml := doc(replace(concat($config:app-root,'/data/', $xmlPath, $ref), '/exist/', '/db/'))
let $xslPath := concat(xs:string(request:get-parameter("stylesheet", "xmlToHtml")), '.xsl')
let $xsl := doc(replace(concat($config:app-root,'/resources/xslt/', $xslPath), '/exist/', '/db/'))
let $collection := functx:substring-after-last(util:collection-name($xml), '/')
let $path2source := string-join(('../../../../exist/restxq', $config:app-name, $collection, $ref, 'xml'), '/')
let $params := 
<parameters>
    <param name="app-name" value="{$config:app-name}"/>
    <param name="collection-name" value="{$collection}"/>
    <param name="path2source" value="{$path2source}"/>
   {for $p in request:get-parameter-names()
    let $val := request:get-parameter($p,())
   (: where  not($p = ("document","directory","stylesheet")):)
    return
       <param name="{$p}"  value="{$val}"/>
   }
</parameters>
return 
    transform:transform($xml, $xsl, $params)
};

(:~
 : creates a basic book-index derived from the  '/data/indices/listbook.xml'
 :)
declare function app:listBook($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey="
    for $item in doc(concat($config:app-root, '/data/indices/listbibl.xml'))//tei:biblStruct
    let $shortTitle := $item//tei:title[first]/text()
    let $longTitle := string-join($item//tei:title/text(), ', ')
    let $authors : = string-join($item//tei:author//text(), ', ')
    order by $item//tei:surname[first]
        return
        <tr>
            <td>
                <a href="{concat($hitHtml,data($item/@xml:id))}">{$authors}</a>
            </td>
            <td>{$longTitle}</td>
            <td>{$item//tei:pubPlace}</td>
            <td>{$item//tei:date}</td>
        </tr>
};