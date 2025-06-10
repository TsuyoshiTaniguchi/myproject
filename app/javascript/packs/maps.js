// app/javascript/packs/maps.js

// グローバル関数として定義 → API の callback で必ず起動
window.initMap = function() {
  const mapDiv = document.getElementById("map");
  if (!mapDiv) {
    console.warn("initMap: #map が見つかりません。");
    return;
  }
  const centerCoords = { lat: 35.6895, lng: 139.6917 };
  const mapOptions = { center: centerCoords, zoom: 12 };
  const map = new google.maps.Map(mapDiv, mapOptions);
  new google.maps.Marker({
    position: centerCoords,
    map: map,
  });
};

// Turbolinksのロード時、API が未読み込みの場合はログ出力のみ
document.addEventListener("turbolinks:load", function() {
  if (typeof google === "undefined") {
    console.warn("Google Maps API is not loaded yet.");
  }
});