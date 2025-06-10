// app/javascript/packs/daily_reports.js

function buildChart(canvas, dates, values, goalValue, goalDays) {
  let rawMax = Math.max(...values);
  rawMax = (!isFinite(rawMax) || rawMax <= 0) ? 10 : rawMax;
  const suggestedMax = Math.min(rawMax, 50) * 1.2;

  const labels = [...dates];
  const predict = [];
  if (goalValue > 0 && goalDays > 0) {
    const last = values.at(-1);
    const inc = (goalValue - last) / goalDays;
    for (let i = 1; i <= goalDays; i++) {
      const d = new Date(dates.at(-1));
      d.setDate(d.getDate() + i);
      labels.push(d.toISOString().slice(0, 10));
      predict.push(+(last + inc * i).toFixed(1));
    }
  }
  const goalLine = labels.map(() => goalValue);

  new Chart(canvas, {
    type: "line",
    data: {
      labels: labels,
      datasets: [
        {
          label: "実績",
          data: values.concat(Array(labels.length - values.length).fill(null)),
          borderColor: "rgba(75,192,192,1)",
          backgroundColor: "rgba(75,192,192,0.2)",
          fill: false,
        },
        {
          label: "予測ペース",
          data: Array(values.length).fill(null).concat(predict),
          borderColor: "rgba(255,159,64,0.8)",
          borderDash: [5, 5],
          fill: false,
        },
        {
          label: "目標ライン",
          data: goalLine,
          borderColor: "rgba(255,99,132,0.8)",
          borderDash: [2, 2],
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
          suggestedMax: suggestedMax,
        },
      },
    },
  });
}

function initPerformanceChart() {
  const Chart = window.Chart;
  if (!Chart) return;

  let canvas;
  const container = document.getElementById("performanceChartContainer");
  if (container) {
    // 一覧ページの場合
    container.innerHTML = "";
    canvas = document.createElement("canvas");
    canvas.id = "performanceChart";
    canvas.dataset.goalValue = container.dataset.goalValue;
    canvas.dataset.goalDays = container.dataset.goalDays;
    canvas.style.width = "100%";
    canvas.style.height = "100%";
    container.appendChild(canvas);
  } else {
    // 詳細ページの場合：canvas が直接配置されている
    canvas = document.getElementById("performanceChart");
  }
  if (!canvas) return;

  const goalValue = +canvas.dataset.goalValue || 0;
  const goalDays = +canvas.dataset.goalDays || 0;
  let dates = [];
  let values = [];

  if (canvas.dataset.dates && canvas.dataset.values) {
    try {
      dates = JSON.parse(canvas.dataset.dates);
      values = JSON.parse(canvas.dataset.values);
    } catch (e) {
      console.error("Embedded data parse error:", e);
      return;
    }
    if (!dates.length || !values.length) {
      console.warn("Embedded performance data is empty.");
      return;
    }
    buildChart(canvas, dates, values, goalValue, goalDays);
  } else {
    // 一覧ページの場合、fetch API から取得
    fetch("/daily_reports/performance_data.json")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then(data => {
        dates = data.dates || [];
        values = data.performance || [];
        if (!dates.length || !values.length) {
          console.warn("Performance data is empty.");
          return;
        }
        buildChart(canvas, dates, values, goalValue, goalDays);
      })
      .catch(err => console.error("Performance data fetch error:", err));
  }
}

document.addEventListener("turbolinks:load", initPerformanceChart);
document.addEventListener("turbolinks:before-cache", () => {
  const Chart = window.Chart;
  const canvas = document.getElementById("performanceChart");
  if (!canvas || !Chart) return;
  const existing = Chart.getChart(canvas);
  if (existing) existing.destroy();
});