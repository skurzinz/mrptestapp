xquery version "3.1";
declare namespace functx = "http://www.functx.com";
import module namespace app="http://www.digital-archiv.at/ns/mrptestapp/templates" at "../modules/app.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=json media-type=text/javascript";

let $notBefores := collection($app:indices)//tei:TEI//*[@notBefore castable as xs:date]
let $whens := collection($app:indices)//tei:TEI//*[@when castable as xs:date]
let $dates := ($notBefores, $whens)
let $baseurl := "https://hw.oeaw.ac.at/ministerrat/serie-1/"
let $yearPrefix := request:get-parameter('year', '')

for $x in collection($app:indices)//tei:TEI//tei:event[@when castable as xs:date]
    let $link2doc := <a href="{app:hrefToDoc($x)}">{app:getHWDocName($x)}</a>
    let $startDate := data($x//@when[1])
    let $name := normalize-space(string-join($x//tei:event/tei:label[1]//text(), ' '))
    let $id := data($x/@ref)
    where fn:starts-with($startDate, $yearPrefix)
    return
        map {
                "name": $name,
                "startDate": $startDate,
                "id": $id
        }