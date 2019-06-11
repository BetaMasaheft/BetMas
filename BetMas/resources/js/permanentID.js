$('#LoadPermanentIDs').on('click', function () {
    /*expects <div data-path="Works/1001-2000/LIT1004AbbaNa.xml" id="LIT1004AbbaNa" data-type="Works"/>*/
    var path = $("#permanentIDs").data("path")
    var type = $("#permanentIDs").data("type")
    var id = $("#permanentIDs").data("id")
    /*    builds a request to the github api which returns all commits relevant for a given file*/
    var pathnorepo = path.replace(type, '')
    var restcall = 'https://api.github.com/repos/BetaMasaheft/' + type + '/commits?path=' + pathnorepo
    console.log(restcall)
    $.getJSON(restcall, function (data) {
        console.log(data)
/*        loop through each commit*/
        $.each(data, function (commit) {
        var sha = $(this)['0'].sha
        console.log(sha)
        var commit = $(this)['0'].commit
            console.log(commit)
            console.log(sha)
            var version = $('<table></table>')
            var versionname = '<tr><th>Version of '+commit.committer.date+'</th><th>SHA: '+sha+'</th></tr>'
            var bmVersionLin = 'https://betamasaheft.eu/permanent/'+sha+'/'+type.toLowerCase()+'/'+id +'/main'
            var githubversionlink = 'https://github.com/BetaMasaheft/'+type+'/blob/'+sha+'/'+pathnorepo
            var githubRawversionlink = 'https://raw.githubusercontent.com/BetaMasaheft/'+type+'/blob/'+sha+pathnorepo
            var betmasversion = '<tr><td>permalink to this version</td><td><a href="'+bmVersionLin+'">'+bmVersionLin+'</a></td></tr>'
            var github = '<tr><td>permalink to source file at this version</td><td><a href="'+githubRawversionlink+'">'+githubRawversionlink+'</a></td></tr>'
            var githubversion = '<tr><td>permalink to source file in github at this version</td><td><a href="'+githubversionlink+'">'+githubversionlink+'</a></td></tr>'
            version.append(versionname)
            version.append(betmasversion)
            version.append(github)
            version.append(githubversion)
            $("#permanentIDs").append(version)
        });
    });
});