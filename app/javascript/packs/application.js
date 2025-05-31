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