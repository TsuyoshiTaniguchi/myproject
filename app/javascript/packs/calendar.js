import { Calendar } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";

export async function initCalendar() {
  const el = document.getElementById("calendar");
  if (!el || el.dataset.initialized) return; // 対象要素が存在しないまたは既に初期化済みなら中断
  el.dataset.initialized = "true";

  try {
    // APIから日報データを取得
    const response = await fetch("/daily_reports/calendar_data.json");
    if (!response.ok) {
      throw new Error(`HTTPエラー: ${response.status}`);
    }
    const reports = await response.json();

    // 取得した日報データからFullCalendar用のイベントオブジェクトに変換
    const events = reports.map(r => ({
      id: r.id,
      title: r.title,
      start: r.start,
      url: r.url,
      backgroundColor: "#66ccff"
    }));

    // FullCalendar のインスタンスを生成し、設定を適用
    const calendar = new Calendar(el, {
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      height: "auto",
      events: events,
      eventClick(info) {
        info.jsEvent.preventDefault();
        if (info.event.url) {
          window.open(info.event.url, "_blank");
        }
      }
    });

    calendar.render();
  } catch (err) {
    console.error("カレンダーデータ取得に失敗:", err);
  }
}