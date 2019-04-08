<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<html>
<head>
    <title>Bcrypt Encoder</title>
</head>
<body>

<form action = "/bcrypt" method = "GET">
    Enter password to encode: <input type = "text" name = "password">
    <br />
    <input type = "submit" value = "Submit" />
</form>

<c:out value="${encrypt}" escapeXml="false" />
</body>
</html>
