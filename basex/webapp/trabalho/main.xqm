(: BaseX Namespace :)

module namespace page = 'http://estg.ipp.pt/pei/trabalho';

(: XML Namespaces :)

declare namespace part = 'http://estg.ipp.pt/pei/trabalho/partner';
declare namespace insp = 'http://estg.ipp.pt/pei/trabalho/inspector';
declare namespace app = 'http://estg.ipp.pt/pei/trabalho/appointment';
declare namespace inspec = 'http://estg.ipp.pt/pei/trabalho/inspection';

(: Function to send a ping to the API :)

declare
    %rest:GET
    %rest:path('/ping')
function page:ping() {
    <rest:response>
        <http:response status="200"/>
    </rest:response>
};

(: Status code functions used to send a response to the user:)

(: 201 when a record is created :)

declare 
    %rest:path('/response/201') 
function page:created() {
    <rest:response>
        <http:response status="201"/>
    </rest:response>
};

(: 204 when a record is updated :)

declare 
    %rest:path('/response/204') 
function page:updated() {
    <rest:response>
        <http:response status="204"/>
    </rest:response>
};

(: 404 when a record is not found :)

declare 
    %rest:path('/response/404') 
function page:notFound() {
    <rest:response>
        <http:response status="404"/>
    </rest:response>
};

(: 409 when a record already exists :)

declare 
    %rest:path('/response/409') 
function page:conflict() {
    <rest:response>
        <http:response status="409"/>
    </rest:response>
};

(: 500 when an error occurs like validation error or some server error :)

declare 
    %rest:path('/response/500') 
function page:serverError() {
    <rest:response>
        <http:response status="500"/>
    </rest:response>
};

(: GET Partners :)

declare
    %updating
    %rest:GET
    %rest:path('/partners')
    %rest:produces('application/xml')
function page:getPartners() {
    (: Gets all partners from the database :)
    let $partners := db:get("partnerdb")//part:partner
    return (
        (: If there are no parters return a http code 404 otherwise a http code 200 with all the partners in the body :)
        if (count($partners) = 0) then (
            update:output(web:redirect('/response/404'))
        ) else (
            update:output(<partners>{$partners}</partners>)
        )
    )
        
};

(: POST Partners :)

declare 
    %updating 
    %rest:POST('{$partner}') 
    %rest:path('/partners')
    %rest:consumes('application/xml')
function page:addPartner($partner as item()) {
    (: Validates the partner to add against the partner.xsd schema :)
    validate:xsd($partner, './xsd/partner.xsd'),
    (: Gets the identifier of the partner to add :)
    let $identifier := $partner//part:partner//part:identifier/text(),
    (: Checks if there is a partner with the same identifier in the database :)
    $exists := db:open("partnerdb")//part:partner/part:identifier/text() = $identifier
    return (
        (: If there is a partner with the same identifier return a http code 409 otherwise add the partner to the database and return a http code 201 :)
        if ($exists) then (
            update:output(web:redirect('/response/409'))
        ) else (
            db:put("partnerdb", $partner, concat("partner", $identifier, ".xml")),
            update:output(web:redirect('/response/201'))
        )
    )
};

(: PUT Partners :)

declare 
    %updating 
    %rest:PUT('{$partner}') 
    %rest:path('/partners/{$identifier}')
    %rest:consumes('application/xml')
function page:updatePartner($identifier as xs:string, $partner as item()) {
    (: Validates the partner to update against the partner.xsd schema :)
    validate:xsd($partner, "./xsd/partner.xsd"),
    (: Checks if the identifier in the path is the same as the identifier in the body :)
    if ($identifier = $partner//part:partner//part:identifier/text()) then (
        (: Checks if there is a partner with the same identifier in the database :)
        let $exists := db:open("partnerdb")//part:partner/part:identifier/text() = $identifier
        return (
            (: If there is a partner with the same identifier update the partner in the database and return a http code 204 otherwise add to the database and return a http code 201 :)
            db:put("partnerdb", $partner, concat("partner", $identifier, ".xml")),
            if ($exists) then (
                update:output(web:redirect("/response/204"))
            ) else (
                update:output(web:redirect("/response/201"))
            )
        )
    ) else (
        update:output(web:redirect("/response/500"))
    )
};

(: GET Inspector :)

declare
    %updating
    %rest:GET
    %rest:path('/inspectors')
    %rest:produces('application/xml')
function page:getInspectors() {
    (: Gets all inspectors from the database :)
    let $inspectors := db:get("inspectordb")//insp:inspector
    return (
        (: If there are no inspectors return a http code 404 otherwise a http code 200 with all the inspectors in the body :)
        if (count($inspectors) = 0) then (
            update:output(web:redirect('/response/404'))
        ) else (
            update:output(<inspectors>{$inspectors}</inspectors>)
        )
    ) 
};

(: POST Inspector :)

declare 
    %updating 
    %rest:POST('{$inspector}') 
    %rest:path('/inspectors')
    %rest:consumes('application/xml')
function page:addInspector($inspector as item()) {
    (: Validates the inspector to add against the inspector.xsd schema :)
    validate:xsd($inspector, "./xsd/inspector.xsd"),
    (: Gets the identifier of the inspector to add :)
    let $identifier := $inspector//insp:inspector//insp:identifier/text(),
    (: Gets the partner of the inspector to add :)
    $partner := $inspector//insp:inspector//insp:partner/text(),
    (: Checks if there is a partner with the same identifier in the database :)
    $existsPartner := db:open("partnerdb")//part:partner/part:identifier/text() = $partner,
    (: Checks if there is a inspector with the same identifier in the database :)
    $exists := db:open("inspectordb")//insp:inspector/insp:identifier/text() = $identifier
    return (
        (: If there is a inspector with the same identifier return a http code 409 :)
        if ($exists) then (
            update:output(web:redirect("/response/409"))
        ) else (
            (: If there is a partner with the same identifier add the inspector to the database and return a http code 201 otherwise return a http code 500 :)
            if ($existsPartner) then (
                db:put("inspectordb", $inspector, concat("inspector", $identifier, ".xml")),
                update:output(web:redirect("/response/201"))
            ) else (
                update:output(web:redirect("/response/500"))
            )
        )
    ) 
};

(: PUT Inspector :)

declare 
    %updating 
    %rest:PUT('{$inspector}') 
    %rest:path('/inspectors/{$identifier}')
    %rest:consumes('application/xml')
function page:updateInspector($identifier as xs:string, $inspector as item()) {
    (: Validates the inspector to update against the inspector.xsd schema :)
    validate:xsd($inspector, "./xsd/inspector.xsd"),
    (: Checks if the identifier in the path is the same as the identifier in the body :)
    if ($identifier = $inspector//insp:inspector//insp:identifier/text()) then (
        (: Gets the identifier of the inspector to update :)
        let $identifier := $inspector//insp:inspector//insp:identifier/text(),
        (: Checks if there is a inspector with the same identifier in the database :)
        $exists := db:open("inspectordb")//insp:inspector/insp:identifier/text() = $identifier,
        (: Gets the partner of the inspector to update :)
        $partner := $inspector//insp:inspector//insp:partner/text(),
        (: Checks if there is a partner with the same identifier in the database :)
        $existsPartner := db:open("partnerdb")//part:partner/part:identifier/text() = $partner
        return (
            (: If there is no partner with the same identifier return a http code 500 :)
            if ($existsPartner) then (
                (: If there is a inspector with the same identifier update the inspector in the database and return a http code 204 otherwise add to the database and return a http code 201 :)
                db:put("inspectordb", $inspector, concat("inspector", $identifier, ".xml")),
                if ($exists) then (
                    update:output(web:redirect("/response/204"))
                ) else (
                    update:output(web:redirect("/response/201"))
                )
            ) else (
                update:output(web:redirect("/response/500"))
            )  
        )
    ) else (
        update:output(web:redirect("/response/500"))
    )
};

(: Validate Appointment :)

(: This kind of functions exist to overcome some xml 1.0 limitations :)

declare function page:validateEntityAppointment($appointment as item()) as xs:boolean {
    let $entityType := string($appointment//app:appointment/app:entity/@type),
    $existsEntityOwner := exists($appointment//app:appointment/app:entity/app:owner),
    $existsLatitude := exists($appointment//app:appointment/app:location/app:latitude),
    $existsLongitude := exists($appointment//app:appointment/app:location/app:longitude)
    return (
        if ($entityType = "Mechanic") then (
            if ($existsEntityOwner) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsEntityOwner) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        )
    )
};

(: Validate Latitude and Longitude :)

declare function page:validateLatitudeLongitude($appointment as item()) as xs:boolean {
    let $existsLatitude := exists($appointment//app:appointment/app:place/app:latitude),
    $existsLongitude := exists($appointment//app:appointment/app:place/app:longitude)
    return (
        if ($existsLatitude and $existsLongitude) then (
            (1 = 1)
        ) else (
            if ($existsLatitude) then (
                (1 = 0)
            ) else (
                if ($existsLongitude) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            )
        )
    ) 
};

(: GET Appointment :)

declare
    %updating
    %rest:GET
    %rest:path('/appointments')
    %rest:produces('application/xml')
function page:getAppointments() {
    let $appointments := db:get("appointmentdb")//app:appointment
    return
        if (count($appointments) = 0)
        then
            update:output(web:redirect('/response/404'))
        else
            update:output(<appointments>{$appointments}</appointments>)
};

(: POST Appointment :)

(: The only difference from this function from the previous POST is that now we need to check if the entity is valid :)

declare 
    %updating 
    %rest:POST('{$appointment}') 
    %rest:path('/appointments')
    %rest:consumes('application/xml')
function page:addAppointment($appointment as item()) {
    validate:xsd($appointment, "./xsd/appointment.xsd"),
    let $code := $appointment//app:appointment//app:code/text(),
    $exists := db:open("appointmentdb")//app:appointment/app:code/text() = $code,
    $valid := page:validateEntityAppointment($appointment) and page:validateLatitudeLongitude($appointment)
    return
        if ($valid) then (
            if ($exists) then (
                update:output(web:redirect("/response/409"))
            ) else (
                db:put("appointmentdb", $appointment, concat("appointment", $code, ".xml")),
                update:output(web:redirect("/response/201"))
            )
        ) else (
            update:output(web:redirect("/response/500"))
        )
};

(: PUT Appointment :)

declare 
    %updating 
    %rest:PUT('{$appointment}') 
    %rest:path('/appointments/{$code}')
    %rest:consumes('application/xml')
function page:updateAppointment($code as xs:string, $appointment as item()) {
    validate:xsd($appointment, "./xsd/appointment.xsd"),
    if ($code = $appointment//app:appointment//app:code/text()) then (
        let $exists := db:open("appointmentdb")//app:appointment/app:code/text() = $code,
        $valid := page:validateEntityAppointment($appointment) and page:validateLatitudeLongitude($appointment)
        return (
            if ($valid) then (
                db:put("appointmentdb", $appointment, concat("appointment", $code, ".xml")),
                if ($exists) then (
                    update:output(web:redirect("/response/204"))
                ) else (
                    update:output(web:redirect("/response/201"))
                )
            ) else (
                update:output(web:redirect("/response/500"))
            )
        )
    ) else (
        update:output(web:redirect("/response/500"))
    )
};

(: Gets all appointments for today for a specific inspector :)

declare
    %updating
    %rest:GET
    %rest:path('/appointments/today/inspector/{$identifier}')
    %rest:produces('application/xml')
function page:getTodayAppointmentsForInspector($identifier as xs:string) {	
    let $appointments := db:get("appointmentdb")//app:appointment[app:inspector/text() = $identifier and app:date/text() = current-date()]
    return
        if (count($appointments) = 0)
        then
            update:output(web:redirect('/response/404'))
        else
            update:output(<appointments>{$appointments}</appointments>)
};

(: Validate Inspection :)

(: These functions exists to overcome some xml 1.0 limitations :)

(: This one checks if the inspection date and time is after the present time :)

declare function page:validateInspectionAfterNow($inspection as item()) as xs:boolean {
    let $date := $inspection//inspec:inspection/inspec:date/text(),
    $end := $inspection//inspec:inspection/inspec:end/text()
    return (
        if ($date > current-date()) then (
            (1 = 0)
        ) else (
            if ($date = current-date()) then (
                if ($end > current-time()) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 1)
            )
        )
    )
};

(: This one checks if the inspection start time is after the end time :)

declare function page:validateStartAfterEnd($inspection as item()) as xs:boolean {
    let $start := $inspection//inspec:inspection/inspec:start/text(),
    $end := $inspection//inspec:inspection/inspec:end/text()
    return (
        if ($start > $end) then (
            (1 = 0)
        ) else (
            (1 = 1)
        )
    )
};

(: This one checks if the inspection state is valid :)

declare function page:validateState($inspection as item()) as xs:boolean {
    let $stateRealized := string($inspection//inspec:inspection/inspec:state/@realized),
    $existsStateCategory := exists($inspection//inspec:inspection/inspec:state/inspec:category),
    $stateCategory := string($inspection//inspec:inspection/inspec:state/inspec:category),
    $existsStateExplanation := exists($inspection//inspec:inspection/inspec:state/inspec:explanation),
    $stateExplanation := string($inspection//inspec:inspection/inspec:state/inspec:explanation)
    return (
        if ($stateRealized = "Yes") then (
            if ($existsStateCategory or $existsStateExplanation) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsStateCategory) then (
                if ($stateCategory = "Other") then (
                    if ($existsStateExplanation) then (
                        if ($stateExplanation = "") then (
                            (1 = 0)
                        ) else (
                            (1 = 1)
                        )
                    ) else (
                        (1 = 0)
                    )
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )
};

(: This one checks if the inspection entity fields are valid :)

declare function page:validateEntity($inspection as item()) as xs:boolean {
    let $entityType := string($inspection//inspec:inspection/inspec:entity/@type),
    $existsEntityOwner := exists($inspection//inspec:inspection/inspec:entity/inspec:owner)
    return (
        if ($entityType = "Mechanic") then (
            if ($existsEntityOwner) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsEntityOwner) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        )
    )
};

(: This one checks if the inspection battery fields are valid :)

declare function page:validateBattery($inspection as item()) as xs:boolean {
    let $batteryNormal := string($inspection//inspec:inspection/inspec:battery/@normal),
    $existsBatteryState := exists($inspection//inspec:inspection/inspec:battery/inspec:state)
    return (
        if ($batteryNormal = "Yes") then (
            if ($existsBatteryState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsBatteryState) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection transmission oil fields are valid :)

declare function page:validateTransmissionOil($inspection as item()) as xs:boolean {
    let $transmissionOilNormal := string($inspection//inspec:inspection/inspec:transmissionOil/@normal),
    $existsTransmissionOilState := exists($inspection//inspec:inspection/inspec:transmissionOil/inspec:state),
    $transmissionOilStates := $inspection//inspec:inspection/inspec:transmissionOil/inspec:state/text()
    return (
        if ($transmissionOilNormal = "Yes") then (
            if ($existsTransmissionOilState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsTransmissionOilState) then (
                if (fn:count($transmissionOilStates) != count(distinct-values($transmissionOilStates))) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection transmission engine fields are valid :)

declare function page:validateTransmissionEngine($inspection as item()) as xs:boolean {
    let $transmissionEngineNormal := string($inspection//inspec:inspection/inspec:transmissionEngine/@normal),
    $existsTransmissionEngineState := exists($inspection//inspec:inspection/inspec:transmissionEngine/inspec:state),
    $transmissionEngineStates := $inspection//inspec:inspection/inspec:transmissionEngine/inspec:state/text()
    return (
        if ($transmissionEngineNormal = "Yes") then (
            if ($existsTransmissionEngineState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsTransmissionEngineState) then (
                if (fn:count($transmissionEngineStates) != count(distinct-values($transmissionEngineStates))) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection refrigeration system is valid :)

declare function page:validateRefrigerationSystem($inspection as item()) as xs:boolean {
    let $refrigerationSystemNormal := string($inspection//inspec:inspection/inspec:refrigerationSystem/@normal),
    $existsRefrigerationSystemState := exists($inspection//inspec:inspection/inspec:refrigerationSystem/inspec:state),
    $refrigerationSystemStates := $inspection//inspec:inspection/inspec:refrigerationSystem/inspec:state/text()
    return (
       if ($refrigerationSystemNormal = "Yes") then (
            if ($existsRefrigerationSystemState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsRefrigerationSystemState) then (
                if (count($refrigerationSystemStates) != count(distinct-values($refrigerationSystemStates))) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection engine support is valid :)

declare function page:validateEngineSupport($inspection as item()) as xs:boolean {
    let $engineSupportNormal := string($inspection//inspec:inspection/inspec:engineSupport/@normal),
    $existsEngineSupportState := exists($inspection//inspec:inspection/inspec:engineSupport/inspec:state),
    $engineSupportStates := $inspection//inspec:inspection/inspec:engineSupport/inspec:state/text()
    return (
        if ($engineSupportNormal = "Yes") then (
            if ($existsEngineSupportState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsEngineSupportState) then (
                if (count($engineSupportStates) != count(distinct-values($engineSupportStates))) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection engine noise is valid :)

declare function page:validateEngineNoise($inspection as item()) as xs:boolean {
    let $engineNoiseNormal := string($inspection//inspec:inspection/inspec:engineNoise/@normal),
    $existsEngineNoiseState := exists($inspection//inspec:inspection/inspec:engineNoise/inspec:state),
    $engineNoiseStates := $inspection//inspec:inspection/inspec:engineNoise/inspec:state/text()
    return (
        if ($engineNoiseNormal = "Yes") then (
            if ($existsEngineNoiseState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsEngineNoiseState) then (
                if (count($engineNoiseStates) != count(distinct-values($engineNoiseStates))) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection gases are valid :)

declare function page:validateGases($inspection as item()) as xs:boolean {
    let $gasesNormal := string($inspection//inspec:inspection/inspec:gases/@normal),
    $existsGasesState := exists($inspection//inspec:inspection/inspec:gases/inspec:state)
    return (
        if ($gasesNormal = "Yes") then (
            if ($existsGasesState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsGasesState) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        )
    )   
};

(: This one checks if the inspection gearbox is valid :)

declare function page:validateGearbox($inspection as item()) as xs:boolean {
    let $gearboxNormal := string($inspection//inspec:inspection/inspec:gearbox/@normal),
    $existsGearboxState := exists($inspection//inspec:inspection/inspec:gearbox/inspec:state),
    $gearboxStates := $inspection//inspec:inspection/inspec:gearbox/inspec:state/text()
    return (
        if ($gearboxNormal = "Yes") then (
            if ($existsGearboxState) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        ) else (
            if ($existsGearboxState) then (
                if (count($gearboxStates) != count(distinct-values($gearboxStates))) then (
                    (1 = 0)
                ) else (
                    (1 = 1)
                )
            ) else (
                (1 = 0)
            )
        )
    )
};

(: This one checks if the inspection realized state is valid :)

declare function page:validateInspectionRealized($inspection as item()) as xs:boolean {
    let $inspectionRealized := string($inspection//inspec:inspection/inspec:state/@realized),
    $existsEntity := exists($inspection//inspec:inspection/inspec:entity),
    $existsBattery := exists($inspection//inspec:inspection/inspec:battery),
    $existsTransmissionOil := exists($inspection//inspec:inspection/inspec:transmissionOil),
    $existsTransmissionEngine := exists($inspection//inspec:inspection/inspec:transmissionEngine),
    $existsRefrigerationSystem := exists($inspection//inspec:inspection/inspec:refrigerationSystem),
    $existsEngineSupport := exists($inspection//inspec:inspection/inspec:engineSupport),
    $existsEngineNoise := exists($inspection//inspec:inspection/inspec:engineNoise),
    $existsGases := exists($inspection//inspec:inspection/inspec:gases),
    $existsGearbox := exists($inspection//inspec:inspection/inspec:gearbox),
    $existsQuilometers := exists($inspection//inspec:inspection/inspec:quilometers)
    return (
        if ($inspectionRealized = "Yes") then (
            if ($existsEntity and $existsBattery and $existsTransmissionOil and $existsTransmissionEngine and $existsRefrigerationSystem and $existsEngineSupport and $existsEngineNoise and $existsGases and $existsGearbox and $existsQuilometers) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        ) else (
            if ($existsEntity or $existsBattery or $existsTransmissionOil or $existsTransmissionEngine or $existsRefrigerationSystem or $existsEngineSupport or $existsEngineNoise or $existsGases or $existsGearbox or $existsQuilometers) then (
                (1 = 0)
            ) else (
                (1 = 1)
            )
        )
    )
};

(: Check if the Partner is Valid for the Given Inspector :)

declare function page:validatePartnerFromInspector($inspection as item()) {
    let $inspector := $inspection//inspec:inspection/inspec:inspector/text(),
    $partner := $inspection//inspec:inspection/inspec:partner/text(),
    $validInspectorFromPartner := count(db:open("inspectordb")//insp:inspector[insp:identifier = $inspector and insp:partner = $partner]) = 1
    return (
        if ($validInspectorFromPartner) then (
            (1 = 1)
        ) else (
            (1 = 0)
        )
    )
};

(: This one checks if the inspection is valid based on the previous functions :)

declare function page:validateInspection($inspection as item()) as xs:boolean {
    let $inspectionRealized := string($inspection//inspec:inspection/inspec:state/@realized),
    $validNo := page:validateInspectionAfterNow($inspection) and page:validateStartAfterEnd($inspection) and page:validateState($inspection) and page:validateInspectionRealized($inspection) and page:validatePartnerFromInspector($inspection),
    $validYes := page:validateEntity($inspection) and page:validateBattery($inspection) and page:validateTransmissionOil($inspection) and page:validateTransmissionEngine($inspection) and page:validateRefrigerationSystem($inspection) and page:validateEngineSupport($inspection) and page:validateEngineNoise($inspection) and page:validateGases($inspection) and page:validateGearbox($inspection)
    return (
        if ($inspectionRealized = "Yes") then (
            if ($validNo and $validYes) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        )else (
            if ($validNo) then (
                (1 = 1)
            ) else (
                (1 = 0)
            )
        )   
    )
};

(: GET Inspection :)

declare
    %updating
    %rest:GET
    %rest:path('/inspections')
    %rest:produces('application/xml')
function page:getInspection() {
    let $inspection := db:get("inspectiondb")//inspec:inspection
    return
        if (count($inspection) = 0)
        then
            update:output(web:redirect('/response/404'))
        else
            update:output(<inspections>{$inspection}</inspections>)    
};

(: GET Inspection by code :)

declare
    %updating
    %rest:GET
    %rest:path('/inspections/{$code}')
    %rest:produces('application/xml')
function page:getInspectionByCode($code as xs:string) {
    let $inspection := db:get("inspectiondb")//inspec:inspection[inspec:code = $code]
    return
        if (count($inspection) = 0)
        then
            update:output(web:redirect('/response/404'))
        else
            update:output($inspection)
};

(: GET all realized/not realized inspections from a specific date and partner:)

declare
    %updating
    %rest:GET
    %rest:path('/inspections/date/{$date}/partner/{$partner}/realized/{$realized}')
    %rest:produces('application/xml')
function page:getInspectionsByDateAndPartner($date as xs:string, $partner as xs:string, $realized as xs:string) {
    let $inspections := db:get("inspectiondb")//inspec:inspection[inspec:date = $date and inspec:partner = $partner and inspec:state/@realized = $realized]
    return
        if (count($inspections) = 0)
        then
            update:output(web:redirect('/response/404'))
        else
            update:output(<inspections>{$inspections}</inspections>)
};

(: POST Inspection :)

(: The difference on this one from the previous is that needs to check if the partner, the inspector and the appointment exists in order to add :)

declare 
    %updating 
    %rest:POST('{$inspection}') 
    %rest:path('/inspections')
    %rest:consumes('application/xml')
function page:addInspection($inspection as item()) {
    validate:xsd($inspection, "./xsd/inspection.xsd"),
    if (page:validateInspection($inspection)) then (
        let $code := $inspection//inspec:inspection//inspec:code/text(),
        $exists := db:open("inspectiondb")//inspec:inspection/inspec:code/text() = $code,
        $partner := $inspection//inspec:inspection//inspec:partner/text(),
        $existsPartner := db:open("partnerdb")//part:partner/part:identifier/text() = $partner,
        $inspector := $inspection//inspec:inspection//inspec:inspector/text(),
        $existsInspector := db:open("inspectordb")//insp:inspector/insp:identifier/text() = $inspector,
        $existsAppointment := db:open("appointmentdb")//app:appointment/app:code/text() = $code
        return (
            if ($exists) then (
                update:output(web:redirect('/response/409'))
            ) else (
                if ($existsPartner and $existsInspector and $existsAppointment) then (
                    db:put("inspectiondb", $inspection, concat("inspection", $code, ".xml")),
                    update:output(web:redirect('/response/201'))
                ) else (
                    update:output(web:redirect('/response/404'))
                )
            )
        )
    ) else (
        update:output(web:redirect('/response/500'))
    )
};

(: PUT Inspection :)

declare 
    %updating 
    %rest:PUT('{$inspection}') 
    %rest:path('/inspections/{$identifier}')
    %rest:consumes('application/xml')
function page:updateInspection($identifier as xs:string, $inspection as item()) {
    validate:xsd($inspection, "./xsd/inspection.xsd"),
    if (page:validateInspection($inspection) and $identifier = $inspection//inspec:inspection//inspec:code/text()) then (
        let $code := $inspection//inspec:inspection//inspec:code/text(),
        $exists := db:open("inspectiondb")//inspec:inspection/inspec:code/text() = $code,
        $partner := $inspection//inspec:inspection//inspec:partner/text(),
        $existsPartner := db:open("partnerdb")//part:partner/part:identifier/text() = $partner,
        $inspector := $inspection//inspec:inspection//inspec:inspector/text(),
        $existsInspector := db:open("inspectordb")//insp:inspector/insp:identifier/text() = $inspector,
        $existsAppointment := db:open("appointmentdb")//app:appointment/app:code/text() = $code
        return (
            if ($existsPartner and $existsInspector and $existsAppointment) then (
                db:put("inspectiondb", $inspection, concat("inspection", $code, ".xml")),
                if ($exists) then (
                    update:output(web:redirect('/response/204'))
                ) else (
                    update:output(web:redirect('/response/201'))
                )
            ) else (
                update:output(web:redirect('/response/500'))
            )
            
        )
    ) else (
        update:output(web:redirect('/response/500'))
    ) 
};
