// app/javascript/packs/daily_reports.js
import { Chart } from "chart.js/auto";

function initChart(ctxId, fetchUrl, datasetLabel, labelKey, dataKey, instancePropertyName) {
  const ctx = document.getElementById(ctxId);
  if (!ctx) return; // 要素がない場合は何もしない

  if (window[instancePropertyName]) {
    window[instancePropertyName].destroy();
    window[instancePropertyName] = null;
  }

  fetch(fetchUrl)
    .then(response => {
      if (!response.ok) { throw new Error(`HTTP error ${response.status}`); }
      return response.json();
    })
    .then(data => {
      console.log("Fetched data for", ctxId, data);
      const chart = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: data[labelKey], // 例: "dates"または"future_dates"
          datasets: [{
            label: datasetLabel,
            data: data[dataKey],
            backgroundColor: "rgba(255, 159, 64, 0.5)",
            borderColor: "rgba(255, 159, 64, 1)",
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: {
              beginAtZero: true,
              // 値が大きすぎる場合は適切な最大値を指定する例
              suggestedMax: Math.max(...data[dataKey]) * 1.2
            }
          }
        }
      });
      window[instancePropertyName] = chart;
    })
    .catch(error => console.error(`Error fetching ${ctxId} data:`, error));
}

document.addEventListener("turbolinks:load", () => {
  // 成長データ（棒グラフ）の初期化
  initChart(
    'growthChart',            // キャンバスのID
    '/daily_reports/growth_data.json', // API エンドポイント
    "コード量 & 改善数",       // グラフのラベル
    "dates",                  // ラベル用プロパティ
    "stats",                  // データ用プロパティ
    "growthChartInstance"     // インスタンスを格納する変数名
  );

  // 将来成長予測グラフの初期化（必要に応じて）
  initChart(
    'futureGrowthChart',
    '/daily_reports/future_growth_data.json',
    "予測成長度",
    "future_dates",
    "predicted_levels",
    "futureGrowthChartInstance"
  );
});