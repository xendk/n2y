
// Add a toggler to log data rows.
htmx.on("htmx:load", function(evt) {
  const data_rows = evt.detail.elt.querySelectorAll(".log-table .data-toggle");

  data_rows.forEach((data) => {
    const onClick = (e) => {
      e.target.parentElement.classList.toggle("active");
    }

    data.addEventListener("click", onClick);
  })
});

// Remove the sync result when a new request is made.
htmx.on("htmx:beforeRequest", function(evt) {
  const sync_result = document.querySelector("#sync-result");
  if (sync_result) {
    sync_result.innerHTML = "";
  }
})
