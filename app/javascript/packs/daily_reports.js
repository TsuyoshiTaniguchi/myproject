// app/javascript/packs/daily_reports.js

import { Chart } from "chart.js/auto";

function initPerformanceChart() {
  const canvas = document.getElementById("performanceChart");
  if (!canvas) return;

  // — 重複初期化ガード（Turbolinks で二重実行を防ぐ）
  if (window.performanceChartInitialized) return;
  window.performanceChartInitialized = true;

  // — 既存インスタンスがあれば破棄
  const existing = Chart.getChart(canvas);
  if (existing) existing.destroy();

  // — data-* 属性から目標値／日数を取得
  const goalValue = +canvas.dataset.goalValue || 0;
  const goalDays  = +canvas.dataset.goalDays  || 0;

  fetch("/daily_reports/performance_data.json")
    .then(res => {
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    })
    .then(data => {
      const dates  = data.dates || [];
      const values = (data.performance || []).map(n => +n);

      if (!dates.length || !values.length) {
        console.error("パフォーマンスデータがありません。");
        return;
      }

      // — 元々の閾値ロジックで y 軸の suggestedMax を計算
      let rawMax = Math.max(...values);
      if (!isFinite(rawMax) || rawMax <= 0) rawMax = 10;
      const threshold   = 50;
      const cappedMax   = rawMax > threshold ? threshold : rawMax;
      const suggestedMax = cappedMax * 1.2;

      // — 予測ライン用のラベル／値を作成
      const allLabels     = [...dates];
      const predictValues = [];

      if (goalValue > 0 && goalDays > 0 && values.length) {
        const lastValue = values[values.length - 1];
        const dailyInc  = (goalValue - lastValue) / goalDays;

        for (let i = 1; i <= goalDays; i++) {
          const d = new Date(dates[dates.length - 1]);
          d.setDate(d.getDate() + i);
          allLabels.push(d.toISOString().slice(0, 10));
          predictValues.push(+(lastValue + dailyInc * i).toFixed(1));
        }
      }

      // — ゴールライン（全ラベル分 goalValue を並べる）
      const goalLine = allLabels.map(() => goalValue);

      // — チャート生成
      new Chart(canvas, {
        type: "line",
        data: {
          labels: allLabels,
          datasets: [
            {
              label: "実績",
              data: values.concat(new Array(allLabels.length - values.length).fill(null)),
              borderColor: "rgba(75,192,192,1)",
              backgroundColor: "rgba(75,192,192,0.2)",
              fill: false
            },
            {
              label: "予測ペース",
              data: new Array(values.length).fill(null).concat(predictValues),
              borderColor: "rgba(255,159,64,0.8)",
              borderDash: [5, 5],
              fill: false
            },
            {
              label: "目標ライン",
              data: goalLine,
              borderColor: "rgba(255,99,132,0.8)",
              borderDash: [2, 2],
              fill: false
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: { display: true },
            y: {
              beginAtZero: true,
              suggestedMax: suggestedMax
            }
          }
        }
      });
    })
    .catch(err => console.error("パフォーマンスデータ取得エラー:", err));
}

// Turbolinks イベントに登録
document.addEventListener("turbolinks:load", initPerformanceChart);

// ページキャッシュ前にインスタンス破棄＆初期化フラグリセット
document.addEventListener("turbolinks:before-cache", () => {
  const canvas = document.getElementById("performanceChart");
  if (canvas) {
    const existing = Chart.getChart(canvas);
    if (existing) existing.destroy();
  }
  window.performanceChartInitialized = false;
});