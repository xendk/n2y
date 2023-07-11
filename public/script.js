
htmx.on("htmx:load", function(evt) {
  const data_rows = evt.detail.elt.querySelectorAll(".log-table .data-toggle");

  data_rows.forEach((data) => {
    const onClick = (e) => {
      e.target.parentElement.classList.toggle("active");
    }

    data.addEventListener("click", onClick);
  })
});
