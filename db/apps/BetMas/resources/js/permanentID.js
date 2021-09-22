$('[id^=LoadPermanentIDs]').on('click', function () {
    var currentid = $(this).attr('id')
    console.log(currentid)
    var onlyid = currentid.replace("LoadPermanentIDs", "#permanentIDs")
    // console.log(onlyid)
    /*expects <div data-path="Works/1001-2000/LIT1004AbbaNa.xml" id="LIT1004AbbaNa" data-type="Works"/>*/
    var pid = $(onlyid)
   // console.log(pid)
    var path = pid.data("path")
   // console.log(path)
    var type = pid.data("type")
    var id = pid.data("id")
    /*    builds a request to the github api which returns all commits relevant for a given file*/
    var pathnorepo = path.replace(type, '')
    var restcall = 'https://api.github.com/repos/BetaMasaheft/' + type + '/commits?path=' + pathnorepo
    //console.log(restcall)
    $.getJSON(restcall, function (data) {
      //  console.log(data)
/*        loop through each commit*/
        $.each(data, function (commit) {
        var sha = $(this)['0'].sha
     //   console.log(sha)
        var commit = $(this)['0'].commit
       //     console.log(commit)
      //      console.log(sha)
            var version = $('<table></table>')
            var versionname = '<tr><th>Version of '+commit.committer.date+'</th><th>SHA: '+sha+'</br>committed to github by '+commit.author.name+' with the following message:  '+commit.message+'</th></tr>'
            var bmVersionLin = 'https://betamasaheft.eu/permanent/'+sha+'/'+type.toLowerCase()+'/'+id +'/main'
            var githubversionlink = 'https://github.com/BetaMasaheft/'+type+'/blob/'+sha+'/'+pathnorepo
            var githubRawversionlink = 'https://raw.githubusercontent.com/BetaMasaheft/'+type+'/'+sha+pathnorepo
            var betmasversion = '<tr><td>permalink to this version</td><td><a href="'+bmVersionLin+'">'+bmVersionLin+'</a></td></tr>'
            var github = '<tr><td>source file at this version</td><td><a href="'+githubRawversionlink+'">'+githubRawversionlink+'</a></td></tr>'
            var githubversion = '<tr><td>source file in github at this version</td><td><a href="'+githubversionlink+'">'+githubversionlink+'</a></td></tr>'
            version.append(versionname)
            version.append(betmasversion)
            version.append(github)
            version.append(githubversion)
            pid.append(version)
        });
    });
});