xquery version "3.1";

declare namespace functx = "http://www.functx.com";
import module namespace app="http://www.digital-archiv.at/ns/templates" at "../modules/app.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=json media-type=text/javascript"; 

let $yearPrefix := request:get-parameter('year', '')

for $x in collection($app:editions)//tei:TEI[*//tei:meeting//tei:date[@when castable as xs:date]]
    let $startDate := data($x//tei:meeting/tei:date/@when[1])
    let $name := normalize-space(string-join($x//tei:body/tei:div[1]/tei:head[1]/tei:title[@type='descr']//text(), ' ')) 
    let $items := for $i in $x//tei:list[@type='agenda']/tei:item return array { normalize-space(string-join($i//text(), ' ')), data($i/tei:ref/@target) }
    let $id := app:hrefToDoc($x) (: data($x/@ref) :)
    where fn:starts-with($startDate, $yearPrefix) 
    return map { "name": $name,
        "items": $items, 
        "startDate": $startDate,
        "id": $id } 

