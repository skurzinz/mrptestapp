xquery version "3.1";
declare namespace functx = "http://www.functx.com";
import module namespace app="http://www.digital-archiv.at/ns/templates" at "../modules/app.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=json media-type=text/javascript";

let $notBefores := collection($app:editions)//tei:TEI//*[@notBefore castable as xs:date]
let $whens := collection($app:editions)//tei:TEI//*[@when castable as xs:date]
let $dates := ($notBefores, $whens)

let $yearPrefix := request:get-parameter('year', '')

for $x in collection($app:editions)//tei:TEI[.//*[@when castable as xs:date]]
    let $link2doc := <a href="{app:hrefToDoc($x)}">{app:getDocName($x)}</a>
    let $startDate := data($x//tei:meeting/tei:date/@when[1])
    let $name := normalize-space(string-join($x//tei:body/tei:div[1]/tei:head[1]/tei:title[@type='descr']//text(), ' ')) 
    let $tops := 
      for $item in $x//tei:list[@type='agenda']/tei:item/text() 
         return 
            map { 
                 "item": $item 
                } 
    let $id := app:hrefToDoc($x) (: data($x/@ref) :)
    where fn:starts-with($startDate, $yearPrefix)
    return
        map {
                "name": $tops,
                "startDate": $startDate,
                "id": $id
        }