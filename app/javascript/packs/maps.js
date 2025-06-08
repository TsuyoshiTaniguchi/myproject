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