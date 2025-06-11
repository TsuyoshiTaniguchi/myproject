// app/javascript/packs/maps.js
// ------------------------------------------------------
//   Google Maps を「必要なページで 1 回だけ」初期化（推奨 API）
//   – loading=async&libraries=marker 付きで Maps JS を読込済み前提
// ------------------------------------------------------
export const initMapIfNeeded = () => {
  const mapDiv = document.getElementById("map");
  if (!mapDiv) return; // 対象ページでなければ終了

  // API がまだ来ていない場合
  if (typeof google === "undefined" || !google.maps) {
    console.warn("Google Maps API がまだ読み込まれていません。");
    return;
  }

  // Turbolinks 戻り時の二重生成防止
  if (mapDiv.dataset.initialized) return;

  const TOKYO = { lat: 35.6895, lng: 139.6917 };

  // HTML 側で data-map-id 属性が指定されている場合、有効な Map ID として利用
  // ※ "YOUR_VALID_MAP_ID" はプレースホルダーなので無視する
  const rawMapId = mapDiv.dataset.mapId;
  const validMapId = rawMapId && rawMapId !== "YOUR_VALID_MAP_ID" ? rawMapId : null;

  const mapOptions = {
    center: TOKYO,
    zoom: 12,
  };
  if (validMapId) {
    mapOptions.mapId = validMapId;
  }

  try {
    const map = new google.maps.Map(mapDiv, mapOptions);

    /* ----------------------------------------------------
       2024-02 以降推奨: AdvancedMarkerElement を優先使用
       ※ 有効な Map ID が指定されている場合にのみ利用し、
         それ以外は従来の google.maps.Marker でフォールバック
    ---------------------------------------------------- */
    if (validMapId && google.maps.marker?.AdvancedMarkerElement) {
      new google.maps.marker.AdvancedMarkerElement({ 
        map, 
        position: TOKYO 
      });
    } else {
      new google.maps.Marker({ 
        map, 
        position: TOKYO 
      });
    }

    mapDiv.dataset.initialized = "true";
  } catch (e) {
    console.error("Google Maps の初期化中にエラーが発生しました: ", e);
  }
};