<cfcomponent output="false"
    hint="wrapper for WebEx API">

    <!--- constants --->
    <cffunction name="init" access="public" returntype="any" output="false">
        <cfargument name="webExId" type="string" required="true" />
        <cfargument name="password" type="string" required="true" />
        <cfargument name="siteName" type="string" required="true" />
        <cfargument name="siteUrl" type="string" default="https://#arguments.siteName#.webex.com/WBXService/XMLService" />
        <cfargument name="timeout" type="numeric" default="30" />

        <cfset variables.instance = StructNew() />

        <cfset setWebExId(arguments.webExId) />
        <cfset setPassword(arguments.password) />
        <cfset setSiteName(arguments.siteName) />
        <cfset setSiteUrl(arguments.siteUrl) />
        <cfset variables.timeout = arguments.timeout />

        <cfreturn this />
    </cffunction>

    <!--- getters/setters --->
    <cffunction name="setWebExId" access="public" returntype="void" output="false">
        <cfargument name="webExId" type="string" required="true" />
        <cfset variables.instance.webExId = arguments.webExId />
    </cffunction>
    <cffunction name="getWebExId" access="public" returntype="string" output="false">
        <cfreturn variables.instance.webExId />
    </cffunction>

    <cffunction name="setPassword" access="public" returntype="void" output="false">
        <cfargument name="password" type="string" required="true" />
        <cfset variables.instance.password = arguments.password />
    </cffunction>
    <cffunction name="getPassword" access="public" returntype="string" output="false">
        <cfreturn variables.instance.password />
    </cffunction>

    <cffunction name="setSiteName" access="public" returntype="void" output="false">
        <cfargument name="siteName" type="string" required="true" />
        <cfset variables.instance.siteName = arguments.siteName />
    </cffunction>
    <cffunction name="getSiteName" access="public" returntype="string" output="false">
        <cfreturn variables.instance.siteName />
    </cffunction>

    <cffunction name="setSiteUrl" access="public" returntype="void" output="false">
        <cfargument name="siteUrl" type="string" required="true" />
        <cfset variables.instance.siteUrl = arguments.siteUrl />
    </cffunction>
    <cffunction name="getSiteUrl" access="public" returntype="string" output="false">
        <cfreturn variables.instance.siteUrl />
    </cffunction>

    <!--- private methods --->
    <cffunction name="sendRequest" access="private" returntype="any" output="false">
        <cfargument name="theXml" type="string" required="true" />

        <cfset var theRequest = "" />
        <cfset var theResponse = "" />

        <!--- UTF-8 encoding sends characters that break JSON parsing --->
        <cfsavecontent variable="theRequest">
            <cfoutput>
                <?xml version="1.0" encoding="ISO-8859-1"?>
                <serv:message xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <header>
                        <securityContext>
                            <webExID>#getWebExId()#</webExID>
                            <password>#getPassword()#</password>
                            <siteName>#getSiteName()#</siteName>
                        </securityContext>
                    </header>
                    <body>#Trim(arguments.theXml)#</body>
                </serv:message>
            </cfoutput>
        </cfsavecontent>

        <cftry>
            <cfhttp url="#getSiteUrl()#" method="POST" timeout="#variables.timeout#">
                <cfhttpparam type="xml" value="#Trim(theRequest)#" />
            </cfhttp>
            <cfset theResponse = cfhttp.FileContent />
            <cfcatch>
                <!--- log the error for metrics --->
            </cfcatch>
        </cftry>

        <cfreturn theResponse />
    </cffunction>

    <cffunction name="localDateTime" access="private" output="false" returntype="any"
        hint="converts all times to Eastern">
        <cfargument name="theTime" type="string" required="true" />
        <cfargument name="timeZoneID" type="string" required="true" />

        <cfset var localDateTime = "" />

        <cfswitch expression="#arguments.timeZoneID#">
            <cfcase value="4">
                <cfset localDateTime = DateAdd("h",3,arguments.theTime) />
            </cfcase>
            <cfcase value="5,6">
                <cfset localDateTime = DateAdd("h",2,arguments.theTime) />
            </cfcase>
            <cfcase value="7,8,9">
                <cfset localDateTime = DateAdd("h",1,arguments.theTime) />
            </cfcase>
            <cfcase value="10,11,12">
                <cfset localDateTime = arguments.theTime />
            </cfcase>
            <cfdefaultcase>
                <cfset localDateTime = arguments.theTime />
            </cfdefaultcase>
        </cfswitch>

        <cfreturn localDateTime />
    </cffunction>

    <!--- User Service --->
    <cffunction name="getUser" access="public" returntype="string" output="false">
        <cfargument name="webExId" type="string" required="true" />

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
            <bodyContent xsi:type="java:com.webex.service.binding.user.GetUser">
                <webExId><cfoutput>#arguments.webExId#</cfoutput></webExId>
            </bodyContent>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <!--- General Session Service --->
    <cffunction name="getAPIVersion" access="public" returntype="string" output="false">

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
            <bodyContent xsi:type="java:com.webex.service.binding.ep.GetAPIVersion"></bodyContent>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="lstRecording" access="public" returntype="string" output="false">
        <cfargument name="startFrom" type="string" required="false" default="0" />
        <cfargument name="maximumNum" type="string" required="false" default="10" />
        <cfargument name="serviceTypes" type="string" required="false" default="" />
        <cfargument name="sessionKey" type="string" required="false" default="" />
        <cfargument name="returnSessionDetails" type="string" required="false" default="TRUE" />

        <cfset var theXml = "" />
        <cfset var serviceType = "" />

        <cfsavecontent variable="theXml">
            <cfoutput>
                <bodyContent xsi:type="java:com.webex.service.binding.ep.LstRecording">
                    <listControl>
                        <startFrom>#arguments.startFrom#</startFrom>
                        <maximumNum>#arguments.maximumNum#</maximumNum>
                    </listControl>
                <cfif StructKeyExists(arguments,"sessionKey") AND Len(arguments.sessionKey)>
                    <sessionKey>#arguments.sessionKey#</sessionKey>
                </cfif>
                    <returnSessionDetails>#arguments.returnSessionDetails#</returnSessionDetails>
                <cfif StructKeyExists(arguments,"serviceTypes") AND Len(arguments.serviceTypes)>
                    <serviceTypes>
                    <cfloop list="#arguments.serviceTypes#" index="serviceType" delimiters=",">
                        <serviceType>#serviceType#</serviceType>
                    </cfloop>
                    </serviceTypes>
                </cfif>
                </bodyContent>
            </cfoutput>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="getSessionInfo" access="public" returntype="string" output="true">
        <cfargument name="sessionKey" type="string" required="true" />

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
<bodyContent xsi:type="java:com.webex.service.binding.ep.GetSessionInfo">
    <sessionKey>#arguments.sessionKey#</sessionKey>
</bodyContent>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <!--- Event Session Service --->
    <cffunction name="getEvent" access="public" output="false" returntype="any">
        <cfargument name="sessionKey" type="string" required="true" />

        <cfset var theXml = "" />

    <cfsavecontent variable="theXml">
        <bodyContent xsi:type="java:com.webex.service.binding.event.GetEvent">
            <sessionKey><cfoutput>#arguments.sessionKey#</cfoutput></sessionKey>
        </bodyContent>
    </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="lstSummaryEvent" access="remote" returntype="string" output="false"
        hint="Lists all the scheduled events on the current site.
        Note Site administrators can list event sessions scheduled by all users on the site.
        Regular hosts can list only their own sessions of any access type (i.e., PUBLIC, PRIVATE, and UNLISTED).">
        <cfargument name="startFrom" required="false" default="1" />
        <cfargument name="maximumNum" required="false" default="75" />
        <cfargument name="listMethod" required="false" default="AND" />
        <cfargument name="orderBy" required="false" default="STARTTIME" />
        <cfargument name="orderAD" required="false" default="ASC" />
        <cfargument name="startDateStart" required="false" default="#Now()#" />
        <cfargument name="startDateEnd" required="false" default="" />
        <cfargument name="timeZoneID" required="false" default="7" />
        <cfargument name="programID" required="false" default="" />
        <cfargument name="sessionKey" required="false" default="" />

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
            <cfoutput>
                <bodyContent xsi:type="java:com.webex.service.binding.event.LstsummaryEvent">
                    <listControl>
                        <startFrom>#arguments.startFrom#</startFrom>
                        <maximumNum>#arguments.maximumNum#</maximumNum>
                        <listMethod>#arguments.listMethod#</listMethod>
                    </listControl>
                    <order>
                        <orderBy>#arguments.orderBy#</orderBy>
                        <orderAD>#arguments.orderAD#</orderAD>
                    </order>
                    <dateScope>
                        <startDateStart>#DateFormat(arguments.startDateStart,"mm/dd/yyyy")# #TimeFormat(arguments.startDateStart,"HH:mm:ss")#</startDateStart>
                    <cfif StructKeyExists(arguments,"startDateEnd") AND arguments.startDateEnd NEQ "">
                        <startDateEnd>#DateFormat(arguments.startDateEnd,"mm/dd/yyyy")# #TimeFormat(arguments.startDateEnd,"HH:mm:ss")#</startDateEnd>
                    </cfif>
                        <timeZoneID>#arguments.timeZoneID#</timeZoneID>
                    </dateScope>
                <cfif StructKeyExists(arguments,"programID") AND arguments.programID NEQ "">
                    <programID>#arguments.programID#</programID>
                </cfif>
                <cfif StructKeyExists(arguments,"sessionKey") AND arguments.sessionKey NEQ "">
                    <sessionKey>#arguments.sessionKey#</sessionKey>
                </cfif>
                </bodyContent>
            </cfoutput>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="lstSummaryProgram" access="public" output="false" returntype="string">
        <cfargument name="orderBY" required="false" default="PROGRAMNAME" />
        <cfargument name="orderAD" required="false" default="ASC" />
        <cfargument name="programID" required="false" default="" />

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
            <cfoutput>
                <bodyContent xsi:type="java:com.webex.service.binding.event.LstsummaryProgram">
                    <order>
                        <orderBy>#arguments.orderBY#</orderBy>
                        <orderAD>#arguments.orderAD#</orderAD>
                    </order>
                <cfif StructKeyExists(arguments,"programID") AND arguments.programID NEQ "">
                    <programID>#arguments.programID#</programID>
                </cfif>
                </bodyContent>
            </cfoutput>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <!--- Meeting Attendee Service --->
    <cffunction name="createMeetingAttendee" access="public" returntype="string" output="true">
        <cfargument name="sessionKey" type="string" required="true" />
        <cfargument name="name" type="string" required="true" />
        <cfargument name="email" type="string" required="true" />

        <cfset var theXml = "" />

<cfsavecontent variable="theXml">
        <bodyContent xsi:type="java:com.webex.service.binding.attendee.CreateMeetingAttendee">
            <person>
                <name>#arguments.name#</name>
                <email>#arguments.email#</email>
            </person>
            <sessionKey>#arguments.sessionKey#</sessionKey>
        </bodyContent>
</cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="delMeetingAttendee" access="public" returntype="string" output="true">
        <cfargument name="attendeeID" type="string" required="true" />

        <cfset var theXml = "" />

<cfsavecontent variable="theXml">
        <bodyContent xsi:type="java:com.webex.service.binding.attendee.DelMeetingAttendee">
            <attendeeID>#arguments.attendeeID#</attendeeID>
        </bodyContent>
</cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="getEnrollmentInfo" access="public" returntype="string" output="false">
        <cfargument name="sessionKey" type="string" required="true" />

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
            <bodyContent xsi:type="java:com.webex.service.binding.attendee.GetEnrollmentInfo">
                <sessionKey><cfoutput>#arguments.sessionKey#</cfoutput></sessionKey>
            </bodyContent>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="lstMeetingAttendee" access="public" returntype="string" output="false"
        hint="Retrieves the attendees information of a session hosted on the site.
        The session can be one of all the WebEx session types including Meeting Center, Training Center, Event Center, Sales Center, or Teleconference-only sessions.">
        <cfargument name="sessionKey" type="string" required="true" />

        <cfset var theXml = "" />

        <cfsavecontent variable="theXml">
            <bodyContent xsi:type="java:com.webex.service.binding.attendee.LstMeetingAttendee">
                <sessionKey><cfoutput>#arguments.sessionKey#</cfoutput></sessionKey>
            </bodyContent>
        </cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <cffunction name="registerMeetingAttendee" access="public" returntype="string" output="true">
        <cfargument name="sessionKey" type="string" required="true" />
        <cfargument name="name" type="string" required="true" />
        <cfargument name="email" type="string" required="false" />
        <cfargument name="joinStatus" type="string" required="false" default="ACCEPT" />

        <cfset var theXml = "" />

<cfsavecontent variable="theXml">
        <bodyContent xsi:type="java:com.webex.service.binding.attendee.RegisterMeetingAttendee">
            <attendees>
                <person>
                    <name>#arguments.name#</name>
                    <email>#arguments.email#</email>
                </person>
                <sessionKey>#arguments.sessionKey#</sessionKey>
                <joinStatus>#arguments.joinStatus#</joinStatus>
            </attendees>
        </bodyContent>
</cfsavecontent>

        <cfreturn sendRequest(theXml) />
    </cffunction>

    <!--- utility functions --->
    <cffunction name="deserializeResponse" access="public" output="false" returntype="any">
        <cfargument name="xmlString" type="string" required="true" />

        <cfset var theXml = "" />
        <cfset var data = ArrayNew(1) />
        <cfset var temp = "" />
        <cfset var xmlArray = "" />
        <cfset var xmlArrayItem = "" />
        <cfset var i = "" />
        <cfset var success = true />
        <cfset var type = "" />
        <cfset var len = 0 />

        <cftry>
            <cfset theXml = XmlParse(arguments.xmlString) />
            <cfcatch>
                <cfreturn data />
            </cfcatch>
        </cftry>

        <cfif theXml["serv:message"]["serv:header"]["serv:response"]["serv:result"].XmlText EQ "FAILURE">
            <cfset success = false />
        </cfif>

        <cfif success>
            <cfset type = theXml["serv:message"]["serv:body"]["serv:bodyContent"].XmlAttributes["xsi:type"] />
        </cfif>

        <cfswitch expression="#type#">
            <cfcase value="ep:getSessionInfoResponse">
                <cfset xmlArray = XmlSearch(theXml,"/serv:message/serv:body/serv:bodyContent") />
                <cfset len = ArrayLen(xmlArray) />

                <cfloop from="1" to="#len#" index="i">
                    <cfset temp = {} />
                    <cfset xmlArrayItem = xmlArray[i] />

                    <cfset temp["status"] = xmlArrayItem["ep:status"].XmlText />
                    <cfset temp["panelistsInfo"] = xmlArrayItem["ep:panelistsInfo"].XmlText />
                    <cfset temp["sessionKey"] = JavaCast("int",xmlArrayItem["ep:sessionKey"].XmlText) />
                    <cfset temp["confID"] = JavaCast("int",xmlArrayItem["ep:confID"].XmlText) />
                    <cfset temp["accessControl"] = StructNew() />
                    <cfset temp["accessControl"]["listStatus"] = xmlArrayItem["ep:accessControl"]["ep:listStatus"].XmlText />
                    <cfset temp["accessControl"]["registration"] = xmlArrayItem["ep:accessControl"]["ep:registration"].XmlText />
                    <cfset temp["accessControl"]["registrationURL"] = xmlArrayItem["ep:accessControl"]["ep:registrationURL"].XmlText />
                    <cfset temp["accessControl"]["passwordReq"] = xmlArrayItem["ep:accessControl"]["ep:passwordReq"].XmlText />
                    <cfset temp["metadata"] = StructNew() />
                    <cfset temp["metadata"]["confName"] = xmlArrayItem["ep:metadata"]["ep:confName"].XmlText />
                    <cfset temp["metadata"]["sessionType"] = xmlArrayItem["ep:metadata"]["ep:sessionType"].XmlText />
                    <cfset temp["metadata"]["serviceType"] = xmlArrayItem["ep:metadata"]["ep:serviceType"].XmlText />
                    <cfset temp["metadata"]["description"] = xmlArrayItem["ep:metadata"]["ep:description"].XmlText />
                    <cfset temp["metadata"]["isRecurring"] = xmlArrayItem["ep:metadata"]["ep:isRecurring"].XmlText />
                    <cfset temp["material"] = StructNew() />
                    <cfset temp["material"]["imageURL"] = xmlArrayItem["ep:material"]["ep:imageURL"].XmlText />
                    <cfset temp["host"] = StructNew() />
                    <cfset temp["host"]["firstName"] = xmlArrayItem["ep:host"]["ep:firstName"].XmlText />
                    <cfset temp["host"]["lastName"] = xmlArrayItem["ep:host"]["ep:lastName"].XmlText />
                    <cfset temp["host"]["email"] = xmlArrayItem["ep:host"]["ep:email"].XmlText />
                    <cfset temp["host"]["webExId"] = xmlArrayItem["ep:host"]["ep:webExId"].XmlText />
                    <cfset temp["schedule"] = StructNew() />
                    <cfset temp["schedule"]["startDate"] = xmlArrayItem["ep:schedule"]["ep:startDate"].XmlText />
                    <cfset temp["schedule"]["duration"] = xmlArrayItem["ep:schedule"]["ep:duration"].XmlText />
                    <cfset temp["schedule"]["timeZone"] = xmlArrayItem["ep:schedule"]["ep:timeZone"].XmlText />
                    <cfset temp["attendeeOptions"] = StructNew() />
                    <cfset temp["attendeeOptions"]["joinRequiresAccount"] = xmlArrayItem["ep:attendeeOptions"]["ep:joinRequiresAccount"].XmlText />

                    <cfset ArrayAppend(data,temp) />
                </cfloop>

            </cfcase>
            <cfcase value="event:lstsummaryEventResponse">
                <cfset xmlArray = XmlSearch(theXml,"//event:event") />
                <cfset len = ArrayLen(xmlArray) />

                <cfloop from="1" to="#len#" index="i">
                    <cfset temp = {} />
                    <cfset xmlArrayItem = xmlArray[i] />

                    <cfset temp["sessionKey"] = JavaCast("int",xmlArrayItem["event:sessionKey"].xmlText) />
                    <cfset temp["sessionName"] = xmlArrayItem["event:sessionName"].xmlText />
                    <cfset temp["sessionType"] = xmlArrayItem["event:sessionType"].xmlText />
                    <cfset temp["hostWebExID"] = xmlArrayItem["event:hostWebExID"].xmlText />
                    <cfset temp["startDate"] = localDateTime(xmlArrayItem["event:startDate"].xmlText,xmlArrayItem["event:timeZoneID"].xmlText) />
                    <cfset temp["endDate"] = localDateTime(xmlArrayItem["event:endDate"].xmlText,xmlArrayItem["event:timeZoneID"].xmlText) />
                    <cfset temp["timeZoneID"] = xmlArrayItem["event:timeZoneID"].xmlText />
                    <cfset temp["duration"] = xmlArrayItem["event:duration"].xmlText />
                    <cfset temp["description"] = xmlArrayItem["event:description"].xmlText />
                    <cfset temp["status"] = xmlArrayItem["event:status"].xmlText />
                    <cfset temp["panelists"] = xmlArrayItem["event:panelists"].xmlText />
                    <cfset temp["listStatus"] = xmlArrayItem["event:listStatus"].xmlText />
                    <cfset temp["url"] = "https://" & getSiteName() & ".webex.com/" & getSiteName() & "/e.php?AT=SINF&MK=" & xmlArrayItem["event:sessionKey"].xmlText />

                    <cfset ArrayAppend(data,temp) />
                </cfloop>
            </cfcase>
            <cfcase value="event:lstsummaryProgramResponse">
                <cfset xmlArray = XmlSearch(theXml,"//event:program") />
                <cfset len = ArrayLen(xmlArray) />

                <cfloop from="1" to="#len#" index="i">
                    <cfset temp = {} />
                    <cfset xmlArrayItem = xmlArray[i] />

                    <cfset temp["programID"] = JavaCast("int",xmlArrayItem["event:programID"].xmlText) />
                    <cfset temp["programName"] = xmlArrayItem["event:programName"].xmlText />
                    <cfset temp["hostWebExID"] = xmlArrayItem["event:hostWebExID"].xmlText />
                <cfif StructKeyExists(xmlArrayItem,"event:expectedEnrollment")>
                    <cfset temp["expectedEnrollment"] = xmlArrayItem["event:expectedEnrollment"].xmlText />
                </cfif>
                    <cfset temp["status"] = xmlArrayItem["event:status"].xmlText />
                    <cfset temp["programURL"] = xmlArrayItem["event:programURL"].xmlText />
                <cfif StructKeyExists(xmlArrayItem,"event:afterEnrollmentURL")>
                    <cfset temp["afterEnrollmentURL"] = xmlArrayItem["event:afterEnrollmentURL"].xmlText />
                </cfif>

                    <cfset ArrayAppend(data,temp) />
                </cfloop>
            </cfcase>
            <cfcase value="att:registerMeetingAttendeeResponse">
                <cfset xmlArray = XmlSearch(theXml,"//att:register") />
                <cfset len = ArrayLen(xmlArray) />

                <cfloop from="1" to="#len#" index="i">
                    <cfset temp = {} />
                    <cfset xmlArrayItem = xmlArray[i] />

                    <cfset temp["attendeeID"] = JavaCast("int",xmlArrayItem["att:attendeeID"].xmlText) />
                    <cfset temp["registerID"] = JavaCast("int",xmlArrayItem["att:registerID"].xmlText) />

                    <cfset ArrayAppend(data,temp) />
                </cfloop>
            </cfcase>
            <cfcase value="att:lstMeetingAttendeeResponse">
                <cfset xmlArray = XmlSearch(theXml,"//att:attendee") />
                <cfset len = ArrayLen(xmlArray) />

                <cfloop from="1" to="#len#" index="i">
                    <cfset temp = {} />
                    <cfset xmlArrayItem = xmlArray[i] />

                    <cfset temp["person"] = StructNew() />
                    <cfset temp["person"]["name"] = xmlArrayItem["att:person"]["com:name"].XmlText />
                    <cfset temp["person"]["firstName"] = xmlArrayItem["att:person"]["com:firstName"].XmlText />
                    <cfset temp["person"]["email"] = xmlArrayItem["att:person"]["com:email"].XmlText />
                    <cfset temp["person"]["type"] = xmlArrayItem["att:person"]["com:type"].XmlText />
                    <cfset temp["contactID"] = JavaCast("int",xmlArrayItem["att:contactID"].xmlText) />
                    <cfset temp["joinStatus"] = xmlArrayItem["att:joinStatus"].xmlText />
                    <cfset temp["meetingKey"] = xmlArrayItem["att:meetingKey"].xmlText />
                    <cfset temp["sessionKey"] = xmlArrayItem["att:sessionKey"].xmlText />
                    <cfset temp["language"] = xmlArrayItem["att:language"].xmlText />
                    <cfset temp["role"] = xmlArrayItem["att:role"].xmlText />
                    <cfset temp["locale"] = xmlArrayItem["att:locale"].xmlText />
                    <cfset temp["timeZoneID"] = xmlArrayItem["att:timeZoneID"].xmlText />
                    <cfset temp["languageID"] = xmlArrayItem["att:languageID"].xmlText />
                    <cfset temp["attendeeId"] = xmlArrayItem["att:attendeeId"].xmlText />
                    <cfset temp["confID"] = xmlArrayItem["att:confID"].xmlText />
                    <cfset temp["registerID"] = JavaCast("int",xmlArrayItem["att:registerID"].xmlText) />

                    <cfset ArrayAppend(data,temp) />
                </cfloop>
            </cfcase>
            <cfcase value="ep:lstRecordingResponse">
                <cfset xmlArray = XmlSearch(theXml,"//ep:recording") />
                <cfset len = ArrayLen(xmlArray) />

                <cfloop from="1" to="#len#" index="i">
                    <cfset temp = {} />
                    <cfset xmlArrayItem = xmlArray[i] />

                    <cfset temp["recordingID"] = xmlArrayItem["ep:recordingID"].XmlText />
                    <cfset temp["hostWebExID"] = xmlArrayItem["ep:hostWebExID"].XmlText />
                    <cfset temp["name"] = xmlArrayItem["ep:name"].XmlText />
                <cfif StructKeyExists(xmlArrayItem,"ep:description")>
                    <cfset temp["description"] = xmlArrayItem["ep:description"].XmlText />
                </cfif>
                    <cfset temp["createTime"] = xmlArrayItem["ep:createTime"].XmlText />
                    <cfset temp["timeZoneID"] = xmlArrayItem["ep:timeZoneID"].XmlText />
                    <cfset temp["size"] = xmlArrayItem["ep:size"].XmlText />
                    <cfset temp["streamURL"] = xmlArrayItem["ep:streamURL"].XmlText />
                    <cfset temp["fileURL"] = xmlArrayItem["ep:fileURL"].XmlText />
                <cfif StructKeyExists(xmlArrayItem,"ep:sessionKey")>
                    <cfset temp["sessionKey"] = xmlArrayItem["ep:sessionKey"].XmlText />
                </cfif>
                    <cfset temp["recordingType"] = xmlArrayItem["ep:recordingType"].XmlText />
                    <cfset temp["duration"] = xmlArrayItem["ep:duration"].XmlText />
                <cfif StructKeyExists(xmlArrayItem,"ep:listing")>
                    <cfset temp["listing"] = xmlArrayItem["ep:listing"].XmlText />
                </cfif>
                    <cfset temp["format"] = xmlArrayItem["ep:format"].XmlText />
                    <cfset temp["serviceType"] = xmlArrayItem["ep:serviceType"].XmlText />
                    <cfset temp["passwordReq"] = xmlArrayItem["ep:passwordReq"].XmlText />
                <cfif StructKeyExists(xmlArrayItem,"ep:registerReq")>
                    <cfset temp["registerReq"] = xmlArrayItem["ep:registerReq"].XmlText />
                </cfif>
                <cfif StructKeyExists(xmlArrayItem,"ep:postRecordingSurvey")>
                    <cfset temp["postRecordingSurvey"] = xmlArrayItem["ep:postRecordingSurvey"].XmlText />
                </cfif>

                    <cfset ArrayAppend(data,temp) />
                </cfloop>

            </cfcase>
        </cfswitch>

        <cfreturn data />
    </cffunction>

</cfcomponent>