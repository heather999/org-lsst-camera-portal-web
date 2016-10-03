<%@page contentType="text/html"%>
<%@page pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>
<%@taglib uri="http://displaytag.sf.net" prefix="display" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="file" uri="http://portal.lsst.org/fileutils" %>
<%@taglib uri="http://srs.slac.stanford.edu/filter" prefix="filter"%>

<%-- 
    Provide a run centric listing of eTravelers
    Document   : runList.jsp
    Created on : Sep 18, 2016, 5:32:51 PM
    Author     : tonyj
--%>

<!DOCTYPE html>
<html>
    <head>
        <title>eTraveler Runs</title>
    </head>
    <body>
        <h1>eTraveler Runs</h1>
        <fmt:setTimeZone value="UTC"/>

        <filter:filterTable>
            <filter:filterCheckbox title="Most Recent" var="mostRecent" defaultValue="true"/>
            <filter:filterSelection title="Status" var="status" defaultValue='-1'>
                <filter:filterOption value="-1">Any</filter:filterOption>
                <filter:filterOption value="-2">Any final</filter:filterOption>
                <filter:filterOption value="-3">Any non-final</filter:filterOption>
                <sql:query var="statii">
                    select id,name from ActivityFinalStatus order by id
                </sql:query>
                <c:forEach var="row" items="${statii.rows}">
                    <filter:filterOption value="${row.id}">${row.name}</filter:filterOption>
                </c:forEach>
            </filter:filterSelection>
            <filter:filterSelection title="Traveler" var="traveler" defaultValue="any">
                <filter:filterOption value="any">Any</filter:filterOption>
                <sql:query var="travelers">
                    select distinct p.name
                    from Activity a 
                    join Process p on (a.processId=p.id)
                    where a.parentActivityId is null order by p.name
                </sql:query>
                <c:forEach var="row" items="${travelers.rows}">
                    <filter:filterOption value="${row.name}">${row.name}</filter:filterOption>
                </c:forEach>
            </filter:filterSelection>
            <filter:filterSelection title="Subsystem" var="subsystem" defaultValue="any">
                <filter:filterOption value="any">Any</filter:filterOption>
                <sql:query var="subsystems">
                    select name from Subsystem order by name
                </sql:query>
                <c:forEach var="row" items="${subsystems.rows}">
                    <filter:filterOption value="${row.name}">${row.name}</filter:filterOption>
                </c:forEach>
            </filter:filterSelection>
            <filter:filterInput title="Run min" var="runMin"/>
            <filter:filterInput title="Run max" var="runMax"/>
        </filter:filterTable>

        <sql:query var="runs">
            select * from (
            select a.id,a.begin,a.end,p.name ,h.lsstid,h.manufacturer,f.name as status, t.name hardwareType,ss.name subsystem,
            (select count(*) from Activity aa join FilepathResultHarnessed ff on (aa.id=ff.activityId) where aa.rootActivityId=a.id) as fileCount
            from Activity a 
            join Process p on (a.processId=p.id)
            join Hardware h on (a.hardwareId=h.id)
            join HardwareType t on (h.hardwareTypeId = t.id)
            join TravelerType tt on (p.id=tt.rootProcessId)
            join Subsystem ss on (ss.id=tt.subsystemId)
            join ActivityStatusHistory s on (s.id = (select max(id) from ActivityStatusHistory ss where ss.activityId=a.id))
            join ActivityFinalStatus f on (f.id=s.activityStatusId)
            where a.parentActivityId is null 
            <c:if test="${mostRecent}">
                and a.id=(select max(id) from Activity aaa where aaa.processId=a.processId and aaa.hardwareId=a.hardwareId)
            </c:if>
            <c:if test="${!empty runMin}">
                and a.id>=?
                <sql:param value="${runMin}"/>
            </c:if>
            <c:if test="${!empty runMax}">
                and a.id<=?
                <sql:param value="${runMax}"/>
            </c:if>
            <c:if test="${traveler!='any'}">
                and p.name=?
                <sql:param value="${traveler}"/>
            </c:if>           
            <c:if test="${subsystem!='any'}">
                and ss.name=?
                <sql:param value="${subsystem}"/>
            </c:if>   
                <c:choose>
                <c:when test="${status>=0}">
                    and f.id=?
                    <sql:param value="${status}"/>
                </c:when>
                <c:when test="${status==-2}">
                    and f.isFinal=true
                </c:when>
                <c:when test="${status==-3}">
                    and f.isFinal=false
                </c:when>
            </c:choose>
            ) x
        </sql:query>

        <display:table name="${runs.rows}" sort="list" defaultsort="1" defaultorder="descending" class="datatable" id="run" >
            <display:column property="id" title="Run" sortable="true"/>
            <display:column property="name" title="Traveler" sortable="true"/>
            <display:column property="hardwareType" title="Device Type" sortable="true"/>
            <display:column property="lsstid" title="Device" sortable="true"/>
            <display:column property="status" title="Status" sortable="true"/>
            <display:column property="subsystem" title="Subsystem" sortable="true"/>
            <display:column sortProperty="begin" title="Begin (UTC)" sortable="true">
                <fmt:formatDate value="${run.begin}" pattern="yyyy-MM-dd HH:mm:ss"/>
            </display:column>
            <display:column sortProperty="end" title="End (UTC)" sortable="true">
                <fmt:formatDate value="${run.end}" pattern="yyyy-MM-dd HH:mm:ss"/>
            </display:column>
            <display:column title="Links" class="leftAligned">
                <c:if test="${run.fileCount>0}">
                    <c:url var="files" value="runFiles.jsp">
                        <c:param name="run" value="${run.id}"/>
                    </c:url>
                    <a href="${files}">Files</a>
                </c:if>
            </display:column>
        </display:table>
    </body>
</html>
