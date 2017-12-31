<!--- 
	Template to generate an html report for cflint results
  
  build/resources/cflint/report.cfm
 --->
<!doctype html>
<html lang="en">
  <head>
	<title>CFLint Results</title>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/css/bootstrap.min.css" integrity="sha384-PsH8R72JQ3SOdhVi3uxftmaW6Vc51MKb0q5P2rRUpPvrszuE4W1povHYgTpBfshb" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/open-iconic/1.1.1/font/css/open-iconic.min.css" crossorigin="anonymous">

	</head>
  <body>
	<div class="container" style="margin-top: 30px; margin-bottom: 40px">
		<h2>CFLint Results</h2>
		<cfoutput>
		<table class="table table-bordered table-sm">
			<tbody>
				<tr>
					<th>Version</th>
					<td>#data.version#</td>
				</tr>
				<tr>
					<th>Timestamp</th>
					<td>#dateTimeFormat(data.timestamp)#</td>
				</tr>
				<tr>
					<th>Files</th>
					<td>#data.counts.totalFiles#</td>
				</tr>
				<tr>
					<th>Lines</th>
					<td>#data.counts.totalLines#</td>
				</tr>
				<cfloop array="#data.counts.countBySeverity#" index="item">
					<tr>
						<th>
							<cfswitch expression="#item.severity#">
									<cfcase value="ERROR"><span class="oi" data-glyph="bug"></span></cfcase>
									<cfcase value="WARNING"><span class="oi" data-glyph="warning"></span></cfcase>
									<cfdefaultcase><span class="oi" data-glyph="info"></span></cfdefaultcase>
							</cfswitch>
							#item.severity#
						</th>
						<td>#item.count#</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
		<div id="accordion" role="tablist">
			<cfset index = 1>
			<cfloop collection="#data.files#" key="file">
			<div class="card">
				<div class="card-header" role="tab" id="heading#index#">
					<h5 class="mb-0">
					<a data-toggle="collapse" class="collapsed" href="##collapse#index#" aria-expanded="true" aria-controls="collapse#index#">
						#file#
					</a>
					</h5>
				</div>
				<div id="collapse#index#" class="collapse hide" role="tabpanel" aria-labelledby="heading#index#" data-parent="##accordion">
					<div class="card-body">
						<table class="table">
							<tbody>
							<cfloop array="#data.files[file]#" index="issue">
								<tr>
									<td>
										<cfswitch expression="#issue.severity#">
												<cfcase value="ERROR"><span class="oi" data-glyph="bug"></span></cfcase>
												<cfcase value="WARNING"><span class="oi" data-glyph="warning"></span></cfcase>
												<cfdefaultcase><span class="oi" data-glyph="info"></span></cfdefaultcase>
										</cfswitch>
									</td>
									<td>#issue.id#</td>
									<td>#issue.message#</td>
									<!--- <td>[#issue.line#,#issue.column#]</td> --->
									<td>
										<button type="button" class="btn btn-secondary btn-sm" data-toggle="modal" data-target="##expressionModal" data-issue="#encodeForHTMLAttribute(serializeJSON({'id' = issue.id, 'message' = issue.message, 'line' = issue.line}))#" data-file="#listLast(file,"\")#" data-expression="#encodeForHTML(issue.expression)#">
											[#issue.line#,#issue.column#]
										</button>
									</td>
								</tr>
							</cfloop>	
						</tbody>
					</table>
					</div>
				</div>
			</div>
			<cfset index++>
			</cfloop>
		</div>
	</div>
	</cfoutput>
	<div class="modal fade" id="expressionModal" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"></h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
			<div class="modal-body">
				<h6 class="issue-id"></h6>
				<p class="issue-msg"></p>
				<p class="issue-line"></p>
				<pre></pre>
      </div>
    </div>
  </div>
</div>

    <!-- Optional JavaScript -->
    <!-- jQuery first, then Popper.js, then Bootstrap JS -->
    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.3/umd/popper.min.js" integrity="sha384-vFJXuSJphROIrBnz7yo7oB41mKfc8JzQZiCq4NCceLEaO4IHwicKwpJf9c9IpFgh" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/js/bootstrap.min.js" integrity="sha384-alpBpkh1PFOepccYVYDB4do5UnbKysX5WZXm3XxPqe5iKTfUKjNkCk9SaVuEZflJ" crossorigin="anonymous"></script>
		<script>
			$(function () {
				//$('[data-toggle="popover"]').popover({html: true});
				$('#expressionModal').on('show.bs.modal', function (event) {
					var button = $(event.relatedTarget); // Button that triggered the modal
					var expression = button.data('expression');
					var issue = button.data('issue');
					var file = button.data('file');
					var modal = $(this);
					modal.find('pre').text( expression );
					modal.find('.issue-id').text( issue.id );
					modal.find('.issue-msg').text( issue.message );
					modal.find('.issue-line').text( "Line: " + issue.line );
					modal.find('.modal-title').text( file );
				})
			});
		</script>
	</body>
</html>