// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

// Bootstrap & jQuery
import "jquery";
import "popper.js";
import "bootstrap";
import "../stylesheets/application"; 

// 外部ファイルの読み込み
import { initCalendar } from "packs/calendar"; // カレンダー機能
import "packs/maps";                           // Google Maps
import { Chart } from 'chart.js/auto';
window.Chart = Chart;                          // HTML 直書き用に公開

 
Rails.start();
Turbolinks.start();
ActiveStorage.start();


/* ---------- ユーティリティ関数 ---------- */
function initDropdown() {
  const toggle = document.querySelector(".dropdown-toggle");
  const menu   = document.querySelector(".dropdown-menu");
  if (!toggle || !menu) return;

  toggle.addEventListener("click",  e => { e.stopPropagation(); menu.classList.toggle("show"); });
  document.addEventListener("click", e => {
    if (!toggle.contains(e.target) && !menu.contains(e.target)) menu.classList.remove("show");
  });
}

function initDeleteConfirm() {
  document.querySelectorAll(".delete-comment").forEach(btn => {
    btn.addEventListener("click", e => {
      e.preventDefault();
      if (confirm("⚠️ 本当に削除しますか？この操作は取り消せません！")) {
        window.location.href = btn.href;
      }
    });
  });
}

function initImagePreview() {
  const fileInput   = document.querySelector('input[type="file"]');
  const previewArea = document.getElementById("image-preview");
  if (!fileInput || !previewArea) return;

  previewArea.innerHTML ||= "<p class='text-muted'>画像プレビューはここに表示されます</p>";

  fileInput.addEventListener("change", () => {
    previewArea.innerHTML = "";
    [...fileInput.files].forEach(file => {
      const reader = new FileReader();
      reader.onload = e => {
        const img = new Image();
        img.src   = e.target.result;
        img.className = "img-thumbnail m-2";
        img.style.maxWidth = "200px";
        previewArea.appendChild(img);
      };
      reader.readAsDataURL(file);
    });
  });

  document.querySelectorAll(".remove-image-checkbox").forEach(cb => {
    cb.addEventListener("change", () => {
      const wrap = cb.closest(".existing-image");
      if (wrap) wrap.style.display = cb.checked ? "none" : "block";
    });
  });
}

/* ---------- turbolinks:load ---------- */
function onLoad() {
  initDropdown();
  initDeleteConfirm();
  initImagePreview();
  initCalendar();  // カレンダーの初期化は問題ない前提

  // mapコンテナと google オブジェクトが存在するなら初期化
  if (document.getElementById("map") && typeof google !== "undefined") {
    initMap();
  } else {
    console.warn("Google Maps API がまだ読み込まれていないか、マップコンテナが存在しません。");
  }

  // 他のタブハンドラなど
  const dailyTab = document.querySelector('a[data-bs-toggle="tab"][href="#daily_reports"]');
  if (dailyTab) dailyTab.addEventListener("shown.bs.tab", initCalendar);
  if (document.querySelector("#daily_reports.show.active")) initCalendar();
}

/* ---------- 位置情報 ---------- */
window.getLocation = function () {
  if (!navigator.geolocation) {
    alert("このブラウザでは位置情報の取得ができません。");
    return;
  }
  navigator.geolocation.getCurrentPosition(
    pos => {
      document.getElementById("latitude").value  = pos.coords.latitude;
      document.getElementById("longitude").value = pos.coords.longitude;
      alert("位置情報を取得しました！");
    },
    err => alert("位置情報の取得に失敗しました：" + err.message)
  );
};




//  いいねボタンをでリロードなしに更新(現在うまく行っていない為リロードありで対応、将来用に残しています)
// document.addEventListener("DOMContentLoaded", function () {
//   console.log("ページ完全ロード完了 ");
  
//   var dropdownToggle = document.querySelector(".dropdown-toggle");
  
//   if (dropdownToggle) {
//     dropdownToggle.addEventListener("click", function (event) {
//       event.stopPropagation();
//       var dropdownMenu = document.querySelector(".dropdown-menu");
//       if (dropdownMenu) {
//         dropdownMenu.classList.toggle("show");
//       }
//     });
//   } else {
//     console.warn("⚠️ `.dropdown-toggle` が見つかりません！");
//   }
// });

