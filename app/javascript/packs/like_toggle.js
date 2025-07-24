// app/javascript/packs/like_toggle.js
document.addEventListener("turbolinks:load", () => {
  document.body.addEventListener("click", e => {
    const btn = e.target.closest(".js-like-btn");
    if (!btn) return;

    e.preventDefault();
    const postId = btn.closest("[data-post-id]").dataset.postId;
    const url    = btn.dataset.url;
    const method = btn.dataset.method.toUpperCase();

    fetch(url, {
      method: method,
      headers: {
        "Accept":       "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      }
    })
    .then(res => {
      if (!res.ok) throw new Error("Network response was not ok");
      return res.json();
    })
    .then(json => {
      // いいね数更新
      btn.querySelector(".js-like-count").textContent = json.count;

      // 状態をトグル＆data属性を更新
      if (json.liked) {
        // now liked → switch to "unlike" mode
        btn.dataset.method = "delete";
        btn.dataset.url    = `/posts/${postId}/likes/${json.like_id}`;
        btn.classList.replace("btn-outline-secondary", "btn-primary");
        btn.querySelector("i").classList.replace("far", "fas");
      } else {
        // now unliked → switch to "like" mode
        btn.dataset.method = "post";
        btn.dataset.url    = `/posts/${postId}/likes`;
        btn.classList.replace("btn-primary", "btn-outline-secondary");
        btn.querySelector("i").classList.replace("fas", "far");
      }
    })
    .catch(err => console.error("Like toggle failed:", err));
  });
});