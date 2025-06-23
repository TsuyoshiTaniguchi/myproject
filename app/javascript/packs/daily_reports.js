// -----------------------------------------------------------------
//  Performance Chart（Chart.js）Turbolinks 対応・再描画安全版
// -----------------------------------------------------------------
import { Chart } from "chart.js";

let chartInstance = null;          // モジュール内で保持

function buildChart(canvas, rawDates, rawValues, goalValue, goalDays) {
  // 0) 入力の goalValue (1～10) を 0～100 のスケールに正規化
  const normalizedGoalValue = goalValue * 10;

  // 1) 埋め込まれた実績値を 0..100 にクリップ
  const values = rawValues.map(v => Math.min(Math.max(v, 0), 100));

  // 2) Y 軸最大値を 100 で固定
  const suggestedMax = 100;

  // 3) 予測ラインをつくる (クリップ込み)
  const labels  = [...rawDates];
  const predict = [];
  if (goalValue > 0 && goalDays > 0) {
    const last = values.at(-1) ?? 0;
    // normalizedGoalValue を使って、予測値の増加分を算出
    const inc  = (normalizedGoalValue - last) / goalDays;
    for (let i = 1; i <= goalDays; i++) {
      const next = +(last + inc * i).toFixed(1);
      // 予測値も 0..100 にクリップ
      predict.push(Math.min(Math.max(next, 0), 100));
      const d = new Date(rawDates.at(-1));
      d.setDate(d.getDate() + i);
      labels.push(d.toISOString().slice(0, 10));
    }
  }

  // 目標ライン (常に normalizedGoalValue を使用、0..100 にクリップ)
  const goalLine = labels.map(() =>
    Math.min(Math.max(normalizedGoalValue, 0), 100)
  );

  chartInstance = new Chart(canvas, {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "実績",
          data: values.concat(Array(labels.length - values.length).fill(null)),
          borderColor: "rgba(75,192,192,1)",
          backgroundColor: "rgba(75,192,192,0.15)",
          tension: 0.3,
          pointRadius: 3,
        },
        {
          label: "予測ペース",
          data: Array(values.length).fill(null).concat(predict),
          borderColor: "rgba(255,159,64,0.8)",
          borderDash: [6, 6],
          tension: 0.3,
          pointRadius: 0,
          fill: false,
        },
        {
          label: "目標ライン",
          data: goalLine,
          borderColor: "rgba(255,99,132,0.7)",
          borderDash: [3, 3],
          borderWidth: 1,
          pointRadius: 0,
          fill: false,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          beginAtZero: true,
          max: suggestedMax,  // 100 に固定
          ticks: { stepSize: 10 }
        },
      },
      plugins: {
        legend: { position: "bottom" },
        tooltip: { mode: "index", intersect: false },
      },
    },
  });
}

// ----------------------- 初期化エクスポート -----------------------
export const initPerformanceChart = () => {
  const container = document.getElementById("performanceChartContainer");
  const direct    = document.getElementById("performanceChart");

  if (chartInstance) return;  // Turbolinks 戻りの二重生成防止

  // canvas の取得 or 生成
  let canvas;
  if (container) {
    container.innerHTML = "";
    canvas       = document.createElement("canvas");
    canvas.id    = "performanceChart";
    canvas.style.width  = "100%";
    canvas.style.height = "100%";
    canvas.dataset.goalValue = container.dataset.goalValue;
    canvas.dataset.goalDays  = container.dataset.goalDays;
    container.appendChild(canvas);
  } else if (direct) {
    canvas = direct;
  } else {
    return;
  }

  const goalValue = +canvas.dataset.goalValue || 0;
  const goalDays  = +canvas.dataset.goalDays  || 0;

  const parseAndDraw = (dates, values) => {
    if (dates.length && values.length) {
      buildChart(canvas, dates, values, goalValue, goalDays);
    } else {
      console.warn("Performance data is empty.");
    }
  };

  if (canvas.dataset.dates && canvas.dataset.values) {
    // 詳細ページ：埋め込みデータ
    const dates  = JSON.parse(canvas.dataset.dates);
    const values = JSON.parse(canvas.dataset.values);
    parseAndDraw(dates, values);
  } else {
    // 一覧ページ：API
    fetch("/daily_reports/performance_data.json")
      .then(res => res.ok ? res.json() : Promise.reject(res.status))
      .then(data => parseAndDraw(data.dates || [], data.performance || []))
      .catch(err => console.error("Performance data error:", err));
  }
};

// ------------------------ before-cache ------------------------
document.addEventListener("turbolinks:before-cache", () => {
  if (chartInstance) {
    chartInstance.destroy();
    chartInstance = null;
  }
});