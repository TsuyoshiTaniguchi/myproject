import { Calendar } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";

/* ───── 色定義 ───── */
const languageColors = {
  Ruby:        "#CC342D",
  JavaScript:  "#F7DF1E",
  Python:      "#3572A5",
  Java:        "#B07219",
  "C++":       "#00599C",
  不明:        "#CCCCCC"
};

/* ───────────────────
   タブを開いた瞬間だけ呼ばれる初期化関数
─────────────────── */
export async function initCalendar() {
  const el = document.getElementById("calendar");
  if (!el || el.dataset.initialized) return;   // ① DOM に無い / ② 二重初期化防止
  el.dataset.initialized = true;

  try {
    // Rails 側 API を並列取得
    const [reports, commits] = await Promise.all([
      fetch("/daily_reports/calendar_data.json").then(r => r.json()),
      fetch("/github_commits.json").then(r => r.json())
    ]);

    /* ─ イベント配列を組み立て ─ */
    const events = [
      ...reports.map(r => ({
        title: `${r.visibility === "public_report" ? "🔓" : "🔒"} [${r.skill_tags.join(", ")}] ${r.content.slice(0, 20)}…`,
        start: r.date,
        url:   `/daily_reports/${r.id}`,
        backgroundColor: r.importance_level >= 3 ? "#ffcc00" : "#66ccff"
      })),
      ...commits.map(c => ({
        title: `[${c.language || "不明"}] ${c.title.slice(0, 20)}…`,
        start: c.date,
        url:   c.url,
        backgroundColor: languageColors[c.language] || "#66ccff"
      }))
    ];

    /* ─ FullCalendar を描画 ─ */
    const calendar = new Calendar(el, {
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      height: "auto",
      events,
      eventClick(info) {
        info.jsEvent.preventDefault();
        if (info.event.url) window.open(info.event.url, "_blank");
      }
    });

    calendar.render();
  } catch (err) {
    console.error("カレンダーデータ取得に失敗:", err);
  }
}