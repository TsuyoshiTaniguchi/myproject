// app/javascript/packs/daily_reports.js
// -----------------------------------------------------------------
// Performance Chart（Chart.js）Turbolinks 対応版
//  ・Category 軸＋ラベル昇順ソート＋欠損日に null 埋め（Index）
//  ・API 取得（一覧） or embed データ（MyPage/Show） 両対応
// -----------------------------------------------------------------
import { Chart } from "chart.js";

let chartInstance = null;

function buildChart(canvas, rawDates, rawValues, goalValue, goalDays) {
  // ―――― 1) Indexモードなら「記録がない日」を null で埋める ――――
  let dates     = [...rawDates];
  let valuesArr = [...rawValues];

  if (canvas.dataset.apiUrl) {
    // 日付文字列→Date と値をペア化
    let tmp = dates
      .map((d, i) => ({ date: new Date(d), val: valuesArr[i] }))
      .filter(p => !isNaN(p.date));

    if (tmp.length) {
      tmp.sort((a, b) => a.date - b.date);
      let start = tmp[0].date, end = tmp[tmp.length - 1].date;
      let fullDates = [], fullValues = [], cur = new Date(start);

      while (cur <= end) {
        const iso = cur.toISOString().slice(0, 10);
        fullDates.push(iso);
        const found = tmp.find(x => x.date.toISOString().slice(0, 10) === iso);
        fullValues.push(found ? Math.min(Math.max(found.val, 0), 100) : null);
        cur.setDate(cur.getDate() + 1);
      }

      dates     = fullDates;
      valuesArr = fullValues;
    }
  }

  // ―――― 2) ペアを再構築 → ソート → labels/values 抽出 ――――
  const pairs = dates
    .map((d, i) => ({ date: new Date(d), val: valuesArr[i] }))
    .filter(p => !isNaN(p.date));
  pairs.sort((a, b) => a.date - b.date);

  const labels = pairs.map(p => p.date.toISOString().slice(0, 10));
  const values = pairs.map(p => Math.min(Math.max(p.val ?? 0, 0), 100));

  // ―――― 3) 目標ライン ――――
  const normGoal = goalValue * 10;
  const goalLine = labels.map(() => Math.min(Math.max(normGoal, 0), 100));

  // ―――― 4) 予測ライン ――――
  const predict = [];
  if (goalValue > 0 && goalDays > 0 && values.length) {
    const last = values[values.length - 1];
    const inc  = (normGoal - last) / goalDays;
    for (let i = 1; i <= goalDays; i++) {
      predict.push(Math.min(Math.max(+(last + inc * i).toFixed(1), 0), 100));
      const d = new Date(labels[labels.length - 1]);
      d.setDate(d.getDate() + i);
      labels.push(d.toISOString().slice(0, 10));
    }
  }

  // ―――― 5) 既存チャート破棄 → 新規作成 ――――
  if (chartInstance) {
    chartInstance.destroy();
    chartInstance = null;
  }

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
          data: labels.map(() => normGoal),
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
          max: 100,
          ticks: { stepSize: 10 },
        },
      },
      plugins: {
        legend: { position: "bottom" },
        tooltip: { mode: "index", intersect: false },
      },
    },
  });
}

export const initPerformanceChart = () => {
  const container = document.getElementById("performanceChartContainer");
  const direct    = document.getElementById("performanceChart");
  if (!container && !direct) return;

  let canvas;
  if (container) {
    container.innerHTML = "";
    canvas = document.createElement("canvas");
    canvas.id    = "performanceChart";
    canvas.style = "width:100%; height:100%;";

    // embed 用データ（MyPage/Show）
    if (container.dataset.dates)  canvas.dataset.dates      = container.dataset.dates;
    if (container.dataset.values) canvas.dataset.values     = container.dataset.values;

    // 目標値／日数
    canvas.dataset.goalValue = container.dataset.goalValue || 0;
    canvas.dataset.goalDays  = container.dataset.goalDays  || 0;

    // API URL（Index 用）
    if (container.dataset.apiUrl) canvas.dataset.apiUrl     = container.dataset.apiUrl;

    container.appendChild(canvas);
  } else {
    canvas = direct;
  }

  const goalValue = +canvas.dataset.goalValue || 0;
  const goalDays  = +canvas.dataset.goalDays  || 0;
  const drawWith  = (d, v) => buildChart(canvas, d, v, goalValue, goalDays);

  // embed データ優先
  if (canvas.dataset.dates && canvas.dataset.values) {
    const dates  = JSON.parse(canvas.dataset.dates);
    const values = JSON.parse(canvas.dataset.values);
    drawWith(dates, values);

  // Index → API 取得
  } else {
    const url = canvas.dataset.apiUrl || "/daily_reports/performance_data.json";
    fetch(url)
      .then(res => (res.ok ? res.json() : Promise.reject(res)))
      .then(data => drawWith(data.dates || [], data.performance || []))
      .catch(err => console.error("Performance data error:", err));
  }
};

// Turbolinks キャッシュ前に破棄
document.addEventListener("turbolinks:before-cache", () => {
  if (chartInstance) {
    chartInstance.destroy();
    chartInstance = null;
  }
});
