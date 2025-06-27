// app/javascript/packs/location.js
window.getLocation = function() {
  if (!navigator.geolocation) {
    return alert("このブラウザは位置情報取得に対応していません");
  }

  navigator.geolocation.getCurrentPosition(
    async pos => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      console.log("▶︎ Lat/Lng →", lat, lng);

      // hidden フィールドに緯度経度をセット
      document.getElementById("latitude").value  = lat;
      document.getElementById("longitude").value = lng;

      // REST Geocoding API 呼び出し準備
      const apiKey = document
        .querySelector('meta[name="google-maps-api-key"]')
        .content;
      const url = `https://maps.googleapis.com/maps/api/geocode/json`
                + `?latlng=${lat},${lng}`
                + `&language=ja`
                + `&key=${apiKey}`;

      console.log("▶︎ about to fetch", url);
      try {
        const res  = await fetch(url);
        console.log("▶︎ fetch done, status:", res.status);
        const json = await res.json();
        console.log("▶︎ geocode response:", json);

        // ─── ここからガードを追加 ───
        if (json.status !== "OK" 
            || !Array.isArray(json.results) 
            || json.results.length === 0) {
          console.error("Geocode API error:", json.status, json.error_message);
          alert("住所取得に失敗しました: " + (json.error_message || json.status));
          return;
        }
        // ────────────────────────

        // ─── 都道府県＋市区町村抽出ロジック ───
        const comps = json.results[0].address_components;

        // 都道府県 (administrative_area_level_1)
        const prefectureComp = comps.find(c =>
          c.types.includes("administrative_area_level_1")
        );

        // 市区町村 (locality) を優先、それがなければ sub‐level をフォールバック
        let cityComp = comps.find(c => c.types.includes("locality"));
        if (!cityComp) {
          cityComp = comps.find(c =>
            c.types.includes("administrative_area_level_2")
          );
        }

        const prefecture = prefectureComp ? prefectureComp.long_name : "";
        const city       = cityComp       ? cityComp.long_name       : "";
        const fullLocation = prefecture + city;

        console.log("▶︎ Full location:", fullLocation);
        document.getElementById("daily_report_location").value = fullLocation;
        // ────────────────────────────────────

      } catch (err) {
        console.error("▶︎ fetch error:", err);
        alert("住所取得中にエラーが発生しました");
      }
    },
    err => {
      console.error("▶︎ geolocation error:", err);
      alert("位置情報の取得に失敗: " + err.message);
    },
    { enableHighAccuracy: true }
  );
};