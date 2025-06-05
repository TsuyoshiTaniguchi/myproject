// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

import "jquery";
import "popper.js";
import "bootstrap";
import "../stylesheets/application"; 


Rails.start();

document.addEventListener("turbo:load", function () {
  var dropdownToggle = document.querySelector(".dropdown-toggle");
  var dropdownMenu = document.querySelector(".dropdown-menu");

  if (dropdownToggle && dropdownMenu) {
    dropdownToggle.addEventListener("click", function (event) {
      event.stopPropagation();
      dropdownMenu.classList.toggle("show");
    });

    document.addEventListener("click", function (event) {
      if (!dropdownToggle.contains(event.target) && !dropdownMenu.contains(event.target)) {
        dropdownMenu.classList.remove("show");
      }
    });
  }
});

// ✅ Turboフレーム内の要素が読み込まれた時に再適用！
document.addEventListener("turbo:frame-load", function () {
  var dropdownToggle = document.querySelector(".dropdown-toggle");
  var dropdownMenu = document.querySelector(".dropdown-menu");

  if (dropdownToggle && dropdownMenu) {
    dropdownToggle.addEventListener("click", function (event) {
      event.stopPropagation();
      dropdownMenu.classList.toggle("show");
    });

    document.addEventListener("click", function (event) {
      if (!dropdownToggle.contains(event.target) && !dropdownMenu.contains(event.target)) {
        dropdownMenu.classList.remove("show");
      }
    });
  }
});

document.addEventListener("turbo:load", function () {
  document.querySelectorAll(".delete-comment").forEach(button => {
    button.addEventListener("click", event => {
      event.preventDefault();
      if (confirm("⚠️ 本当に削除しますか？この操作は取り消せません！")) {
        window.location.href = button.getAttribute("href"); //  リダイレクトして削除
      }
    });
  });
});

// 画像アップロード時に リアルタイムでプレビュー表示 
document.addEventListener("DOMContentLoaded", function() {
  const fileInput = document.querySelector('input[type="file"]');
  const previewArea = document.getElementById('image-preview');

  if (fileInput && previewArea) {
    fileInput.addEventListener("change", function() {
      previewArea.innerHTML = ""; // 既存のプレビューをクリア
      const files = fileInput.files;

      if (files.length > 0) {
        Array.from(files).forEach(file => {
          const reader = new FileReader();
          reader.onload = function(e) {
            const img = document.createElement("img");
            img.src = e.target.result;
            img.classList.add("img-thumbnail", "m-2");
            img.style.maxWidth = "200px";
            previewArea.appendChild(img);
          };
          reader.readAsDataURL(file);
        });
      } else {
        previewArea.innerHTML = "<p class='text-muted'>画像プレビューはここに表示されます</p>";
      }
    });
  } else {
    console.warn("ファイル入力またはプレビューエリアが見つかりませんでした。");
  }

  document.querySelectorAll('.remove-image-checkbox').forEach(checkbox => {
    checkbox.addEventListener("change", function() {
      const parent = this.closest('.existing-image');
      if (parent) {
        parent.style.display = this.checked ? "none" : "block";
      }
    });
  });
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