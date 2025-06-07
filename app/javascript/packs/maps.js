function initMap() {
  var tokyo = {lat: 35.6764225, lng: 139.650027};
  var map = new google.maps.Map(document.getElementById('map'), {
    zoom: 10,
    center: tokyo
  });
  new google.maps.Marker({position: tokyo, map: map});
}

// グローバル関数として定義
window.initMap = initMap;