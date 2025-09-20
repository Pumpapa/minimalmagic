document.addEventListener("DOMContentLoaded", () => {
  // TOC: Handle book and part details toggle
  const bookDetails = document.querySelectorAll(".toc > ul > li > details");
  bookDetails.forEach(book => {
    const partDetails = book.querySelectorAll("ul > li > details");
    book.addEventListener("toggle", (event) => {
      const bookKey = book.querySelector("summary").textContent.toLowerCase();
      if (event.target.open) {
        // Close other books
        bookDetails.forEach(b => {
          if (b !== event.target) b.open = false;
        });
        // Navigate to book view
        window.location.href = `/${bookKey}/`;
      } else {
        // Navigate to main view when closing book
        window.location.href = `/`;
      }
    });
    partDetails.forEach(part => {
      part.addEventListener("toggle", (event) => {
        const partKey = part.dataset.partKey;
        if (event.target.open) {
          // Close other parts in the same book
          partDetails.forEach(p => {
            if (p !== event.target) p.open = false;
          });
          // Navigate to part view
          window.location.href = `/${bookKey}/${partKey}/`;
        } else {
          // Navigate to book view when closing part
          window.location.href = `/${bookKey}/`;
        }
      });
    });
  });

  // Menu: Handle checkbox-based dropdowns
  const menuInputs = document.querySelectorAll(".menu__input");
  menuInputs.forEach(input => {
    input.addEventListener("change", (event) => {
      menuInputs.forEach(other => {
        if (other !== event.target) other.checked = false;
      });
    });
  });
});
