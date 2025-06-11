// ------------------------------------------------------
//  FullCalendar を Turbolinks 対応で安全に初期化
// ------------------------------------------------------
import { Calendar } from "@fullcalendar/core";
import dayGridPlugin       from "@fullcalendar/daygrid";
import interactionPlugin   from "@fullcalendar/interaction";

let calendarInstance = null;          // モジュール内で保持

export async function initCalendar() {
  const el = document.getElementById("calendar");
  if (!el) return;                    // そもそもカレンダー領域が無いページはスキップ

  // 既に作成済みなら、サイズだけ合わせて終わり
  if (calendarInstance) {
    calendarInstance.updateSize();
    return;
  }

  try {
    // ---------- イベントデータ取得 ----------
    const res = await fetch("/daily_reports/calendar_data.json");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const reports = await res.json();

    const events = reports.map(r => ({
      id:    r.id,
      title: r.title,
      start: r.start,
      url:   r.url,
      backgroundColor: "#66ccff",
      borderColor:     "#0088cc"
    }));

    // ---------- FullCalendar 生成 ----------
    calendarInstance = new Calendar(el, {
      plugins:      [dayGridPlugin, interactionPlugin],
      initialView:  "dayGridMonth",
      height:       400,
      events,
      eventClick(info) {
        info.jsEvent.preventDefault();
        if (info.event.url) window.open(info.event.url, "_blank");
      }
    });

    calendarInstance.render();

    // レンダリング直後は幅0pxのことがあるので軽く遅延リサイズ
    setTimeout(() => calendarInstance.updateSize(), 10);
  } catch (err) {
    console.error("カレンダーデータ取得に失敗:", err);
  }
}

/* ----------------------------------------------------
   Turbolinks キャッシュに入る直前でインスタンス破棄
   - 戻る/進む時に二重生成や表示崩れを防止
---------------------------------------------------- */
document.addEventListener("turbolinks:before-cache", () => {
  if (calendarInstance) {
    calendarInstance.destroy();
    calendarInstance = null;
  }
});