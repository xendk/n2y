
window.addEventListener("load", () => {
  const data_rows = document.querySelectorAll(".log-table .data-toggle");

  data_rows.forEach((data) => {
    const onClick = (e) => {
      e.target.parentElement.classList.toggle("active");
    }

    data.addEventListener("click", onClick);
  })
});
