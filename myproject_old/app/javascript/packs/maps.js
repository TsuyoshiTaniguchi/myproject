// app/javascript/packs/maps.js
//──────────────────────────────────────────────────────────
//  Google Maps を “必要なページで１回だけ” 初期化
//  ‐ <script …&libraries=marker&loading=async&callback=gmapsBoot async defer>
//    が head 内に 1 本だけ入っている前提
//  ‐ Turbolinks 5 / Bootstrap / Chart.js とは独立
//──────────────────────────────────────────────────────────

/* ============ 1. ページごとの初期化本体 ============ */
export function initMapIfNeeded () {
  const el = document.getElementById('map');
  if (!el || el.dataset.mapReady) return;               // ① 対象ページで１回だけ
  if (!(window.google && google.maps && google.maps.Map)) return; // ② API 未読込なら次回

  /* --- オプション組み立て -------------------------- */
  const TOKYO = { lat: 35.6895, lng: 139.7671 };
  const mapId = el.dataset.mapId;                       // view 側で data-map-id を渡す場合
  const opt   = { center: TOKYO, zoom: 12 };
  if (mapId && mapId !== 'YOUR_VALID_MAP_ID') opt.mapId = mapId;

  /* --- 描画 ---------------------------------------- */
  const map = new google.maps.Map(el, opt);

  // ③ AdvancedMarkerElement は「有効 mapId がある時だけ」使う
  if (mapId && google.maps.marker?.AdvancedMarkerElement) {
    new google.maps.marker.AdvancedMarkerElement({ map, position: TOKYO });
  } else {
    new google.maps.Marker({ map, position: TOKYO });
  }

  el.dataset.mapReady = 'true';                         // 二重生成ガード
}

/* ============ 2. Google Maps から呼ばれる CB ============ */
window.gmapsBoot = function () {
  initMapIfNeeded();                                    // 初回 (最初の HTML)
  document.removeEventListener('turbolinks:load', initMapIfNeeded);
  document.addEventListener('turbolinks:load', initMapIfNeeded); // 以後の遷移
};