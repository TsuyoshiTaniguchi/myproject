document.addEventListener("turbolinks:load", function () {
  let growthCtx = document.getElementById('growthChart');
  let futureGrowthCtx = document.getElementById('futureGrowthChart');

  if (growthCtx) {
    fetch('/daily_reports/growth_data.json')
      .then(response => response.json())
      .then(data => {
        new Chart(growthCtx, {
          type: 'line',
          data: {
            labels: data.dates,  // 例: ["2025-06-07", "2025-06-08", "2025-06-09"]
            datasets: [{
              label: "コード量 & 改善数",
              data: data.stats,  // 例: [5, 8, 7]
              borderColor: "rgba(75, 192, 192, 1)",
              fill: false
            }]
          },
          options: { responsive: true }
        });
      })
      .catch(error => console.error("Error fetching growth_data:", error));
  }

  if (futureGrowthCtx) {
    fetch('/daily_reports/future_growth_data.json')
      .then(response => response.json())
      .then(data => {
        new Chart(futureGrowthCtx, {
          type: 'line',
          data: {
            labels: data.future_dates,  // 例: ["2025-06-10", "2025-06-11", "2025-06-12"]
            datasets: [{
              label: "予測成長度",
              data: data.predicted_levels,  // 例: [7, 9, 10]
              borderColor: "rgba(255, 159, 64, 1)",
              fill: false
            }]
          },
          options: { responsive: true }
        });
      })
      .catch(error => console.error("Error fetching future_growth_data:", error));
  }
});