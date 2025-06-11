// -----------------------------------------------------------------
//  Performance Chart（Chart.js）Turbolinks 対応・再描画安全版
// -----------------------------------------------------------------
import { Chart } from "chart.js";

let chartInstance = null;          // モジュール内で保持

function buildChart(canvas, dates, values, goalValue, goalDays) {
  // Y 軸最大値を決定
  const rawMax        = Math.max(...values, 10);
  const suggestedMax  = Math.ceil(Math.min(rawMax, 50) * 1.2);

  // 予測ライン
  const labels  = [...dates];
  const predict = [];
  if (goalValue > 0 && goalDays > 0) {
    const last = values.at(-1);
    const inc  = (goalValue - last) / goalDays;
    for (let i = 1; i <= goalDays; i++) {
      const d = new Date(dates.at(-1));
      d.setDate(d.getDate() + i);
      labels.push(d.toISOString().slice(0, 10));
      predict.push(+((last ?? 0) + inc * i).toFixed(1));
    }
  }
  const goalLine = labels.map(() => goalValue);

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
          suggestedMax,
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
  const ChartJS = Chart;               // window に依存しない

  const container = document.getElementById("performanceChartContainer");
  const direct    = document.getElementById("performanceChart");

  // ------------- Turbolinks 戻り時の二重生成防止 -------------
  if (chartInstance) return;

  // 一覧ページ：container の中に canvas を作る
  let canvas;
  if (container) {
    container.innerHTML = "";
    canvas       = document.createElement("canvas");
    canvas.id    = "performanceChart";
    canvas.style.width  = "100%";
    canvas.style.height = "100%";
    // goalValue / goalDays を data-* から引き継ぐ
    canvas.dataset.goalValue = container.dataset.goalValue;
    canvas.dataset.goalDays  = container.dataset.goalDays;
    container.appendChild(canvas);
  } else if (direct) {
    // 詳細ページ：canvas が直置き
    canvas = direct;
  } else {
    return; // 対象ページではない
  }

  const goalValue = +canvas.dataset.goalValue || 0;
  const goalDays  = +canvas.dataset.goalDays  || 0;

  // ----------- データ取得（埋め込み or Fetch） -----------
  const parseAndDraw = (dates, values) => {
    if (dates.length && values.length) {
      buildChart(canvas, dates, values, goalValue, goalDays);
    } else {
      console.warn("Performance data is empty.");
    }
  };

  if (canvas.dataset.dates && canvas.dataset.values) {
    // 詳細ページ：data 属性に JSON が埋め込まれている
    try {
      const dates  = JSON.parse(canvas.dataset.dates);
      const values = JSON.parse(canvas.dataset.values);
      parseAndDraw(dates, values);
    } catch (e) {
      console.error("Embedded data parse error:", e);
    }
  } else {
    // 一覧ページ：API から取得
    fetch("/daily_reports/performance_data.json")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then(data => parseAndDraw(data.dates || [], data.performance || []))
      .catch(err => console.error("Performance data fetch error:", err));
  }
};

// ------------------------ before-cache ------------------------
document.addEventListener("turbolinks:before-cache", () => {
  if (chartInstance) {
    chartInstance.destroy();
    chartInstance = null;
  }
});