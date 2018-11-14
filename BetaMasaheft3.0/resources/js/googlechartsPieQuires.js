
var apiurl = '/api/quiresChart/'
$.getJSON(apiurl + role, function (data) {
    
google.charts.load("current", {packages:["corechart"]});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable(data);

        var options = {
          title: 'Quires Distribution',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d'));
        chart.draw(data, options);
      }
      });