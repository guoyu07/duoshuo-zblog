<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Option Explicit %>
<% 'On Error Resume Next %>
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
Call System_Initialize()
'检查非法链接
Call CheckReference("")
'检查权限
If BlogUser.Level>1 Then Call ShowError(6)
If CheckPluginState("duoshuo")=False Then Call ShowError(48)
BlogTitle="多说社会化评论"
Call DuoShuo_Initialize
%>
<!--#include file="..\..\..\zb_system\admin\admin_header.asp"-->
<style type="text/css">
tr {
	height: 32px
}
#divMain2 ul li {
	margin-top: 6px;
	margin-bottom: 6px
}
.bold {
	font-weight: bold;
}
.note {
	margin-left: 10px
}
</style>
<!--#include file="..\..\..\zb_system\admin\admin_top.asp"-->
        <div id="divMain">
          <div id="ShowBlogHint">
            <%Call GetBlogHint()%>
          </div>
          <div class="divHeader"><%=BlogTitle%></div>
          <div class="SubMenu"><%=duoshuo_SubMenu("export")%></div>
          <div id="divMain2"> 
            <script type="text/javascript">ActiveTopMenu("aPlugInMng");</script>
            <form action="noresponse.asp?act=export" method="post" id="_form">
              <p id="_status">必须导出数据到多说才可以正常使用。如导入有任何问题，请联系多说客服解决。</p>
              <table width="100%">
                <thead>
                  <tr>
                    <th width="30%">配置项 </th>
                    <th>选择 </th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td><p><span class="bold"> · 立即进行数据同步</span><br/>
                        <span class="note"></span></p></td>
                    <td><input name="" type="submit" class="button" onClick="$('#type').val('backup')" value="立即从多说备份数据" /></td>
                  </tr>
                  <tr>
                    <td><p><span class="bold"> · 一键导出</span><br/>
                        <span class="note">如您的站点数据过多，请选择下面的分块导出</span></p></td>
                    <td><input name="" type="submit" class="button" onClick="$('#type').val('all')" value="一键导出全部数据" /></td>
                  </tr>
                  <tr>
                    <td><p><span class="bold"> · 文章数据导出</span><br/>
                        <span class="note">文章数据无论是否存在都将同步</span></p></td>
                    <td><%Dim o:o=objConn.Execute("SELECT MAX([log_ID]) FROM blog_Article")(0)%>
                      <p> 文章ID:
                        <input type="number" id="articlemin" name="articlemin" min="1" max="<%=o%>" value="1"/>
                        -
                        <input type="number" id="articlemax" name="articlemax" min="1" max="<%=o%>" value="<%=o%>"/>
                      </p>
                      <p>
                        <input name="" type="submit" class="button" onClick="$('#type').val('article')" value="导出文章" />
                      </p></td>
                  </tr>
                  <tr>
                    <%o=objConn.Execute("SELECT MAX([comm_ID]) FROM blog_Comment")(0):Dim p:p=objConn.Execute("SELECT COUNT([comm_ID]) FROM blog_Comment")(0)-objConn.Execute("SELECT COUNT([ds_cmtid]) FROM blog_Plugin_Duoshuo")(0)%>
                    <td><p><span class="bold"> · 评论数据导出</span><br/>
                        <span class="note">只同步未向多说同步的评论，还有<%=IIf(p>0,p,0)%>条未同步</span></p></td>
                    <td><p> 评论ID:
                        <input type="number" id="commentmin" name="commentmin" min="1" max="<%=o%>" value="1"/>
                        -
                        <input type="number" id="commentmax" name="commentmax" min="1" max="<%=o%>" value="<%=o%>"/>
                      </p>
                      <p>
                        <input name="" type="submit" class="button" onClick="$('#type').val('comment')" value="导出评论" />
                      </p></td>
                  </tr>
                </tbody>
                <tfoot>
                </tfoot>
              </table>
              <p>
                <input type="hidden" name="type" value="all" id="type"/>
              </p>
            </form>
          </div>
        </div>
        <script type="text/javascript">
        $(document).ready(function(){
          $("#_form").submit(function(){
            $("#_status").html("正在执行操作，请稍等..");
			try{
				$.post("noresponse.asp?act=export",{
					type:$("#type").val(),
					commentmin:$("#commentmin").val(),
					commentmax:$("#commentmax").val(),
					articlemax:$("#articlemax").val(),
					articlemin:$("#articlemin").val()
				},function(data){
				  try{
					  console.log(data)
					var o=eval('('+data+')');
					
					$("#_status").html(o.success);
				  }
				  catch(e){
					$("#_status").html("操作出错..服务器返回"+data);
				  }
				});
				
			  
		  }
		  catch(e){
		  	$("#_status").html("操作出错..服务器500错误..");
		  }
		  return false;
       })})
        </script> 
        <!--#include file="..\..\..\zb_system\admin\admin_footer.asp"-->
<script type="text/javascript">
ActiveLeftMenu("aCommentMng");
</script>
<%Call System_Terminate()%>