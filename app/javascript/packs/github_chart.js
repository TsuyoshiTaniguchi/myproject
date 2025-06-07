document.addEventListener("DOMContentLoaded", function () {
  fetch('/github_stats.json')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTPエラー: ${response.status}`);
      }
      // HTMLコンテンツが誤って返された場合のチェック
      return response.text().then(text => {
        if (text.startsWith("<!DOCTYPE html>")) {
          throw new Error("HTMLレスポンスを受信しました。APIの設定を確認してください。");
        }
        return JSON.parse(text);
      });
    })
    .then(stats => {
      const messageElement = document.getElementById('githubChartMessage');
      if (!messageElement) {
        console.warn("githubChartMessage要素が見つかりません");
        return;
      }

      if (stats.length === 0) {
        console.warn("GitHubデータがありません");
        messageElement.innerText = "GitHubデータがありません。";
        return;
      }

      let labels = stats.map(repo => repo.name);
      let starData = stats.map(repo => repo.stars);
      let forkData = stats.map(repo => repo.forks);

      let ctx = document.getElementById('githubChart');
      if (!ctx) {
        console.error("githubChart要素が見つかりません");
        return;
      }

      new Chart(ctx, {
        type: 'bar',
        data: {
          labels: labels,
          datasets: [
            { label: '⭐️ Stars', data: starData, backgroundColor: 'rgba(255, 206, 86, 0.5)' },
            { label: '🔗 Forks', data: forkData, backgroundColor: 'rgba(75, 192, 192, 0.5)' }
          ]
        },
        options: {
          responsive: true,
          scales: { y: { beginAtZero: true } }
        }
      });
    })
    .catch(error => console.error("GitHubデータの取得に失敗:", error));
});