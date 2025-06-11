// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.


//  app/javascript/packs/application.js
//  Bootstrap 4.6.2 用

import Rails from "@rails/ujs";
Rails.start();

import Turbolinks from "turbolinks";
Turbolinks.start();

import * as ActiveStorage from "@rails/activestorage";
ActiveStorage.start();

import "channels";

// ===== jQuery / Popper / Bootstrap (4.6.2) =====
import $ from "jquery";
window.$       = $;
window.jQuery  = $;                   // Bootstrap が内部参照
import "popper.js/dist/umd/popper";
import "bootstrap";

// ===== スタイル（SCSS 全体を一括で）=====
import "../stylesheets/application";

// ===== Chart.js =====
import { Chart, registerables } from "chart.js";
Chart.register(...registerables);
window.Chart = Chart;                // HTML 直書き用に公開

// ===== 外部モジュール =====
import { initCalendar }   from "./calendar"; // packs/calendar.js
import { initMapIfNeeded } from "./maps";    // packs/maps.js ※下で解説
import { initPerformanceChart } from "./daily_reports";  // ★追加



//  自作ユーティリティ

function initDropdown() {
  const toggle = document.querySelector(".dropdown-toggle");
  const menu   = document.querySelector(".dropdown-menu");
  if (!toggle || !menu) return;

  toggle.addEventListener("click", e => {
    e.stopPropagation();
    menu.classList.toggle("show");
  });

  document.addEventListener("click", e => {
    if (!toggle.contains(e.target) && !menu.contains(e.target)) {
      menu.classList.remove("show");
    }
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

  if (!previewArea.innerHTML.trim())
    previewArea.innerHTML = "<p class='text-muted'>画像プレビューはここに表示されます</p>";

  fileInput.addEventListener("change", () => {
    previewArea.innerHTML = "";
    [...fileInput.files].forEach(file => {
      const reader = new FileReader();
      reader.onload = e => {
        const img = new Image();
        img.src        = e.target.result;
        img.className  = "img-thumbnail m-2";
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


//  turbolinks:load で毎ページ初期化

document.addEventListener("turbolinks:load", () => {
  initDropdown();
  initDeleteConfirm();
  initImagePreview();
  initCalendar();
  initMapIfNeeded();                   // maps.js 側で map が必要なときだけ描画
  initPerformanceChart(); 

  // 「日報」タブに切り替わった瞬間に再描画
  const dailyTab = document.querySelector('a[data-toggle="tab"][href="#daily_reports"]');
  if (dailyTab) {
    $(dailyTab).on("shown.bs.tab", () => initCalendar());
  }
  // 直接 URL で日報タブが開かれていた場合
  if (document.querySelector("#daily_reports.show.active")) initCalendar();
});


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

