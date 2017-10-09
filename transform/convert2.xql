xquery version "3.0";

declare namespace tei	= "http://www.tei-c.org/ns/1.0";
declare namespace mets	= "http://www.loc.gov/METS/";
declare namespace xlink	= "http://www.w3.org/1999/xlink";

import module namespace console = "http://exist-db.org/xquery/console";
import module namespace config="http://www.digital-archiv.at/ns/mp-app/config" at "../modules/config.xqm";
import module namespace app="http://www.digital-archiv.at/ns/mp-app/templates" at "../modules/app.xql";

let $filter := function ($path as xs:string, $data-type as xs:string, $param as item()*) as xs:boolean {
    switch ($path)
        case "word/document.xml"
        case "word/comments.xml"
        case "word/endnotes.xml"
        case "word/footnotes.xml"
            return true()
        default
            return false()
}

let $entry-data := function ($path as xs:string, $data-type as xs:string, $data as item()?, $param as item()*) {
  $data
}

let $title := if (ends-with(request:get-uploaded-file-name('file'), '.odt'))
	then substring-before(request:get-uploaded-file-name('file'), '.odt')
	else substring-before(request:get-uploaded-file-name('file'), '.docx')

let $origFileData := string(request:get-uploaded-file-data('file'))
(: unzip erwartet base64Binary, die vom Upload direkt geliefert werden :)
let $unpack := compression:unzip($origFileData, $filter, (), $entry-data, ())
let $incoming := 
	<pack>{
		for $item in $unpack
			return $item}
	</pack>

(: for now, we assume that we will do this in one pass - or we might later need
		two specific runs anyway :)
(:let $type := if (local-name($incoming/*[1]) = 'document-content')
	then 'OO'
	else 'MS'
let $xslt := if ($type = 'OO')
	then doc('xslt/oo2tei.xsl')
	else doc('xslt/ms2tei.xsl'):)
let $add := request:get-parameter('xslt', 'none')
let $post := request:get-parameter('firstheading', false())

let $params :=
	<parameters/>
	

(:let $firstPass :=
	if ($post)
		then transform:transform($incoming, $xslt, $params)
		else transform:transform($incoming, $xslt, ())

let $result := if ($add != 'none')
	then transform:transform($firstPass, doc($add), ())
	else $firstPass:)
	
(:let $ret := if (count($incoming//w:pStyle[@w:val='berschrift1']) > 1)
	then 
		let $result := transform:transform($incoming, doc($add), $params)
		let $filename := $result//tei:TEI/@xml:id || '.xml'
		return xmldb:store('/db/apps/word2tei/mp-data', $filename, $result)
	else
		for :)

(:let $result := transform:transform($incoming, doc($add), $params):)
let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
(:let $result := try { transform:transform($incoming, doc($add), $params) }
		catch * { console:log('
		x:' || $add || '
		p: ' || $params || '
		a: ' || $attr || '
		e: ' ||	$err:code || ': ' || $err:description || ' @ ' || $err:line-number ||':'||$err:column-number || '
		c: ' || $err:value || ' in ' || $err:module || '
		a: ' || $err:additional)
		}:)
let $result := transform:transform($incoming, doc($add), $params)
for $el in $result//tei:TEI
	let $filename := $el//tei:title[@type='short'] || '.xml'
	return <p>{xmldb:store($app:staging, $filename, $el)}</p>
(:	return $filename:)