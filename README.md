ColdFusion WebEx API wrapper
==============

ColdFusion wrapper for the <a href="http://developer.cisco.com/web/webex-developer/xml-api-overview">WebEx</a> API

Installation
------------

Copy the 'webex' folder into your webroot

Usage
-----

Create a WebEx client in the application scope.

  <cfset application.webEx = CreateObject("component","webex.WebEx").init("username", "password", "sitename") />

After creating the client, you can start to make requests.

	<cfset eventXml = application.webex.lstSummaryEvent() />
	<cfset events = application.webex.deserializeResponse( eventXml ) />

Available Methods
* getUser
* getAPIVersion
* lstRecording
* getSessionInfo
* getEvent
* lstSummaryEvent
* lstSummaryProgram
* createMeetingAttendee
* delMeetingAttendee
* getEnrollmentInfo
* lstMeetingAttendee
* registerMeetingAttendee