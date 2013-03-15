﻿<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Option Explicit %>
<%' On Error Resume Next %>
<% Response.Charset="UTF-8" %>
<!-- #include file="..\..\c_option.asp" -->
<!-- #include file="..\..\..\zb_system\function\c_function.asp" -->
<!-- #include file="..\..\..\zb_system\function\c_system_lib.asp" -->
<!-- #include file="..\..\..\zb_system\function\c_system_base.asp" -->
<!-- #include file="..\..\..\zb_system\function\c_system_event.asp" -->
<!-- #include file="..\..\..\zb_system\function\c_system_manage.asp" -->
<!-- #include file="..\..\..\zb_system\function\c_system_plugin.asp" -->
<!-- #include file="..\p_config.asp" -->
<%
ShowError_Custom="If Err.Number>0 Then"&vbCrlf&"Response.Write ""({'success':'""&ZVA_ErrorMsg(id)&""'})"""&vbCrlf&"Response.End"&vbCrlf&"End If"
Dim intRight
intRight=1

Sub Duoshuo_NoResponse_Init()
	Call System_Initialize()
	'检查非法链接
	Call CheckReference("")
	'检查权限
	If BlogUser.Level>intRight Then Call ShowError(6)
	If CheckPluginState("duoshuo")=False Then Call ShowError(48)
	Call DuoShuo_Initialize
End Sub



Select Case Request.QueryString("act")
	Case "callback":Call Duoshuo_NoResponse_Init:Call CallBack
	Case "export":Call Duoshuo_NoResponse_Init:Call Export
	Case "fac":Call Duoshuo_NoResponse_Init:Call Fac
	Case "api":Call Api
	Case "api_async":intRight=4:Call api_async
	Case "save":Call Duoshuo_NoResponse_Init:Call Save
End Select


Sub CallBack()
	If Not IsEmpty(duoshuo.get("short_name")) Then
		duoshuo.config.Write "short_name",duoshuo.get("short_name")
		duoshuo.config.Write "secret",duoshuo.get("secret")
		duoshuo.config.Save
	End If
	Call SetBlogHint(True,Empty,Empty)
	Call SetBlogHint_Custom("现在，您必须导出数据到多说，否则可能会出现一些奇怪的问题。")
	Response.Write "<script>top.location.href='export.asp'</script>"
End Sub

Sub Fac()
	duoshuo.config.Delete
	Call SetBlogHint(True,Empty,Empty)
	Response.Redirect "main.asp"
End Sub

Sub Export
	Server.ScriptTimeout=1000000
	Dim objXmlHttp,strData,strSQL,intMin,intMax
	strData=""
	strSQL=""
	intMin=0
	intMax=0
	Set objXmlHttp=Server.CreateObject("MSXML2.ServerXMLHTTP")
	
	Response.ContentType="application/json"
	
	Select Case Request.Form("type")
	
	Case "all"
		Call Export_SubFunc_PostArticle(objXmlHttp,intMin,intMax)
		Call Export_SubFunc_PostComment(objXmlHttp,intMin,intMax)
	Case "article"
	
		intMin=Request.Form("articlemin")
		intMax=Request.Form("articlemax")
		Call CheckParameter(intMin,"int",1)
		Call CheckParameter(intMax,"int",1)
		Call Export_SubFunc_PostArticle(objXmlHttp,intMin,intMax)
		
	Case "comment"
	
		intMin=Request.Form("commentmin")
		intMax=Request.Form("commentmax")
		Call CheckParameter(intMin,"int",1)
		Call CheckParameter(intMax,"int",1)
		Call Export_SubFunc_PostComment(objXmlHttp,intMin,intMax)
		
	End Select

	
	'strData="short_name="+Server.URLEncode(duoshuo.config.Read("short_name")) & "&secret=" & Server.URLEncode(duoshuo.config.Read("secret")) & "&posts="& strData
	
	
	Response.Write objXmlHttp.ResponseText
	'Response.Write "}"
	Set objXmlHttp=Nothing
	Response.End

End Sub

Function Export_SubFunc_PostComment(objXmlHttp,intMin,intMax)
	Dim strSQL,strData
	strSQL="SELECT comm_AuthorID As author_key,comm_ID As post_key,log_id As thread_key,comm_ParentID As parent_key"
	strSQL=strSQL & ",comm_Author As author_name,comm_Email As author_email,comm_HomePage As author_url,comm_PostTime As created_at"
	strSQL=strSQL & ",comm_ip As ip,comm_agent As agent,comm_Content As message FROM blog_Comment WHERE comm_IsCheck=0"
	If intMax>0 Then strSQL=strSQL & " AND (comm_ID BETWEEN "&intMin&" AND "&intMax&")"
	strData="{""posts"":"
	strData=strData & Export_SubFunc_All(strSQL).jsString
	strData=strData & "}"
	
	objXmlHttp.Open "POST",duoshuo.url.posts.import & "?short_name=" & Server.URLEncode(duoshuo.config.Read("short_name")) & "&secret=" & Server.URLEncode(duoshuo.config.Read("secret"))
	
	objXmlHttp.SetRequestHeader "Content-Type","application/x-www-form-urlencoded"
	'Response.Write "{'orig':"&strData&",'result':"
	strData="posts="&Server.URLEncode(strData)
	objXmlHttp.Send strData
	
End Function

Function Export_SubFunc_PostArticle(objXmlHttp,intMin,intMax)
	Dim strSQL,strData
	strSQL="SELECT [log_ID] As thread_key,[log_CateID],[log_Title] as title,[log_Intro] as excerpt,[log_Level],[log_AuthorID] as author_key,[log_PostTime],[log_ViewNums] as views,[log_Url] as url,[log_Type],[log_Content] as content FROM [blog_Article]"
	If intMax>0 Then strSQL=strSQL & " WHERE (log_ID BETWEEN "&intMin&" AND "&intMax&")"
	strData=Export_SubFunc_Article(strSQL)
	
	objXmlHttp.Open "POST","http://" & duoshuo.config.Read("duoshuo_api_hostname") & duoshuo.url.threads.import
	
	objXmlHttp.SetRequestHeader "Content-Type","application/x-www-form-urlencoded"

	objXmlHttp.Send "short_name=" & Server.URLEncode(duoshuo.config.Read("short_name")) & "&secret=" & Server.URLEncode(duoshuo.config.Read("secret")) & "&" & strData
	
End Function

Function Export_SubFunc_Article(strSQL)
	Dim rs, jsa, col , o , k , aryData() , i
	Redim aryData(-1)
	i=-1
	Set rs = objConn.Execute(strSQL)

	While Not (rs.EOF Or rs.BOF)
		Set o=New TArticle
			If o.LoadInfoByArray(Array(rs(0),"",rs(1),rs(2),rs(3),"",rs(4),rs(5),rs(6),0,rs(7),0,rs(8),False,"","",rs(9),"")) Then
				For Each col In rs.Fields
					Redim Preserve aryData(i+1)
					i=Ubound(aryData)
					aryData(i)="threads["&o.ID&"]["
					If col.Name = "create_at" Then
						k=CStr(col.Value)
						aryData(i)=aryData(i)&col.Name & "]=" & Year(k) & "-" & Right("0"&Month(k),2) & "-" & Right("0"&Day(k),2)
						aryData(i)=aryData(i)& "T" & Right("0"&Hour(k),2) & ":" & Right("0"&Minute(k),2) & ":" & Right("0"&Second(k),2) & "+08:00"
					ElseIf col.Name = "excerpt" Then
						aryData(i)=aryData(i)&col.Name & "]=" & o.HtmlIntro
					ElseIf col.Name="url" Then
						aryData(i)=aryData(i)&col.Name & "]=" & TransferHTML(o.FullUrl,"[zc_blog_host]")
					ElseIf Left(col.Name,4)<>"log_" Then 
						aryData(i)=aryData(i)&col.Name & "]=" & rs(col.Name)
					Else
						i=i-1
					End If
				Next
        	End If
			Set o=Nothing
	rs.MoveNext
    Wend
    Export_SubFunc_Article = Join(aryData,"&")'Server.URLEncode(Join(aryData,"&"))
End Function

Function Export_SubFunc_All(sql)
    Dim rs, jsa, col, k
    Set rs = objConn.Execute(sql)
    Set jsa = jsArray()
	jsa.Kind=1
    While Not (rs.EOF Or rs.BOF)
		Set jsa(Null) = jsObject()
		For Each col In rs.Fields
			If col.Name = "created_at" Then
				k=CStr(col.Value)
				jsa(Null)(col.Name) = Year(k) & "-" & Right("0"&Month(k),2) & "-" & Right("0"&Day(k),2) & " " & Right("0"&Hour(k),2) & ":" & Right("0"&Minute(k),2) & ":" & Right("0"&Second(k),2)
			Else
	            jsa(Null)(col.Name) = col.Value
            End If
		Next
        rs.MoveNext
    Wend
    Set Export_SubFunc_All = jsa
End Function


Function jsObject
	Set jsObject = new duoshuo_aspjson
	jsObject.Kind = 0
End Function

Function jsArray
	Set jsArray = new duoshuo_aspjson
	jsArray.Kind = 1
End Function




Sub Api()
	
End Sub



Sub Save()
	Dim obj
	For Each obj In Request.Form
		duoshuo.config.Write obj,Request.Form(obj)
	Next
	duoshuo.config.Save()
	Call SetBlogHint(True,Empty,Empty)
	Response.Redirect "main.asp?act=setting"
End Sub


Function comparison(ByVal str1,ByVal str2)
	str1=CDBl(str1):str2=CDBl(str2)
	If str1>str2 Then 
		comparison=CStr(str1)
	Else
		comparison=CStr(str2)
	End If
End Function
%>
<script language="javascript" runat="server" >

function Api_Async(){
	Response.ContentType="application/javascript";//配置mime头
	
	var _last=Application(ZC_BLOG_CLSID+"duoshuo_lastpub"),_now=new Date().getTime();
	if(typeof(_last)=="number"){//20分钟时间限制
		if((_now-_last)/1000>=60*20){ 
			_last=_now
		}
		else{
			Response.Write("({'last':'"+_last+"','now':'"+_now+"','status':'waiting'})");
			Response.End()
		}
	}
	else{
		_last=_now
	}
	Application(ZC_BLOG_CLSID+"duoshuo_lastpub")=_now
	//x分钟内不再请求
	Response.Write("({'status':'"+Api_Run().success.replace(/\r/g,"\\r").replace(/\n/g,"\\n").replace(/'/g,"\'")+"'})")
	
}
function Api_Run(){
	Duoshuo_NoResponse_Init();//加载数据库
	if(duoshuo.config.Read("duoshuo_cron_sync_enabled")!="async") return {'success':'noasync'}
	try{
		duoshuo.api.sync();
		BlogReBuild_Statistics();
		BlogReBuild_Comments();
		BlogReBuild_Functions();
		BlogReBuild_Default();
		return {'success':'success'}
	}
	catch(e){
		return {'success':e.message}
	}
}
</script>