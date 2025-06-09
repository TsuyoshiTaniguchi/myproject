// turbolinks:load イベント内でのみ実行
document.addEventListener("turbolinks:load", function() {
  const mapDiv = document.getElementById("map");
  if (!mapDiv) {
    console.error("Map container element with id 'map' not found.");
    return;
  }
  
  const tokyo = { lat: 35.6764225, lng: 139.650027 };
  const map = new google.maps.Map(mapDiv, {
    zoom: 10,
    center: tokyo
  });
  
  new google.maps.Marker({ position: tokyo, map: map });
});

// ※ Google Maps API が正常に読み込まれている場合のみ実行してください。
export function initMap() {
  const mapContainer = document.getElementById("map");
  if (!mapContainer) {
    console.warn("Map container element not found.");
    return;
  }
  
  // マップのオプション（適宜調整）
  const options = {
    center: { lat: 35.6895, lng: 139.6917 }, // 例：東京の中心
    zoom: 12
  };
  
  // マップの初期化
  new google.maps.Map(mapContainer, options);
}

// google.maps が読み込まれていれば自動で初期化するように
window.initMap = initMap;
