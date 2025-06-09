// app/javascript/packs/calendar.js
import { Calendar } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import interactionPlugin from "@fullcalendar/interaction";

export async function initCalendar() {
  const el = document.getElementById("calendar");
  if (!el || el.dataset.initialized) return;
  el.dataset.initialized = "true";

  try {
    const response = await fetch("/daily_reports/calendar_data.json");
    if (!response.ok) {
      throw new Error(`HTTPエラー: ${response.status}`);
    }
    const reports = await response.json();
    const events = reports.map(r => ({
      id: r.id,
      title: r.title,
      start: r.start,
      url: r.url,
      backgroundColor: "#66ccff"
    }));

    const calendar = new Calendar(el, {
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      height: 400, // 固定値（px）により表示サイズを調整
      events: events,
      eventClick(info) {
        info.jsEvent.preventDefault();
        if (info.event.url) {
          window.open(info.event.url, "_blank");
        }
      }
    });

    // カレンダーをレンダリングし、グローバル変数に保持
    calendar.render();
    window.fullCalendarInstance = calendar;

    // 表示状態になったタイミングで updateSize を呼ぶためのリトライ処理
    let attempts = 10;
    const interval = setInterval(() => {
      if (el.offsetWidth > 0 && el.offsetHeight > 0) {
        calendar.updateSize();
        clearInterval(interval);
      }
      attempts--;
      if (attempts <= 0) clearInterval(interval);
    }, 300);
  } catch (err) {
    console.error("カレンダーデータ取得に失敗:", err);
  }
}

document.addEventListener("turbolinks:load", () => {
  initCalendar();
});