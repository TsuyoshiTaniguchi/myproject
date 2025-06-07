import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin from '@fullcalendar/interaction';

const languageColors = {
  "Ruby": "#CC342D",
  "JavaScript": "#F7DF1E",
  "Python": "#3572A5",
  "Java": "#B07219",
  "C++": "#00599C",
  "不明": "#CCCCCC"
};

document.addEventListener("DOMContentLoaded", function () {
  let calendarEl = document.getElementById('calendar');
  if (!calendarEl) return;

  // カレンダー用データ取得
  Promise.all([
    fetch('/daily_reports/calendar_data.json').then(response => response.json()),
    fetch('/github_commits.json').then(response => response.json())
  ])
  .then(([reports, commits]) => {
    let events = [];

    // 📝 **日報データをカレンダーに追加**
    reports.forEach(report => {
      events.push({
        title: `${report.visibility === "public" ? "🔓" : "🔒"} [${report.skill_tags.join(', ')}] ${report.content.substring(0, 20)}...`,
        start: report.date,
        url: `/daily_reports/${report.id}`,
        backgroundColor: report.importance_level >= 3 ? "#ffcc00" : "#66ccff"
      });
    });

    // 🔄 **GitHubコミットデータをカレンダーに追加**
    commits.forEach(commit => {
      events.push({
        title: `[${commit.language || '不明'}] ${commit.title.substring(0, 20)}...`,
        start: commit.date,
        url: commit.url,
        backgroundColor: languageColors[commit.language] || "#66ccff"
      });
    });

    // 🎨 **カレンダーを作成**
    let calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, interactionPlugin],
      initialView: 'dayGridMonth',
      events: events,
      eventClick: function(info) {
        if (info.event.url) {
          window.open(info.event.url, "_blank");
        } else {
          console.warn("このイベントには URL がありません:", info.event);
        }
      }
    });

    calendar.render();
  })
  .catch(error => console.error("データの取得に失敗:", error));
});