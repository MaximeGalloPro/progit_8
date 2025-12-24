// Searchable Select Component
// Usage: Add data-searchable-select to a select element

document.addEventListener("DOMContentLoaded", function() {
    initSearchableSelects();
});

function initSearchableSelects() {
    document.querySelectorAll("[data-searchable-select]").forEach(select => {
        if (select.dataset.initialized) return;
        select.dataset.initialized = "true";
        new SearchableSelect(select);
    });
}

class SearchableSelect {
    constructor(selectElement) {
        this.select = selectElement;
        this.options = Array.from(selectElement.options);
        this.perPage = 20;
        this.currentPage = 1;
        this.filteredOptions = [...this.options];
        this.isOpen = false;

        this.createWrapper();
        this.bindEvents();
    }

    createWrapper() {
        // Hide original select
        this.select.style.display = "none";

        // Create wrapper
        this.wrapper = document.createElement("div");
        this.wrapper.className = "searchable-select-wrapper relative flex-1 min-w-0";

        // Create display button
        this.displayButton = document.createElement("button");
        this.displayButton.type = "button";
        this.displayButton.className = "searchable-select-display w-full rounded-lg bg-slate-700 px-4 py-3 text-white border border-slate-600 focus:ring-2 focus:ring-blue-500 transition-all text-left flex items-center justify-between";
        this.updateDisplayText();

        // Arrow icon
        const arrow = document.createElement("span");
        arrow.innerHTML = `<svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>`;
        this.displayButton.appendChild(arrow);

        // Create dropdown
        this.dropdown = document.createElement("div");
        this.dropdown.className = "searchable-select-dropdown absolute z-50 w-full mt-1 bg-slate-800 border border-slate-600 rounded-lg shadow-2xl hidden max-h-80 overflow-hidden";

        // Search input
        const searchWrapper = document.createElement("div");
        searchWrapper.className = "p-2 border-b border-slate-700";
        this.searchInput = document.createElement("input");
        this.searchInput.type = "text";
        this.searchInput.placeholder = "Rechercher...";
        this.searchInput.className = "w-full rounded-lg bg-slate-700 px-3 py-2 text-white text-sm border border-slate-600 focus:ring-2 focus:ring-blue-500 focus:outline-none transition-all placeholder:text-slate-400";
        searchWrapper.appendChild(this.searchInput);
        this.dropdown.appendChild(searchWrapper);

        // Options container
        this.optionsContainer = document.createElement("div");
        this.optionsContainer.className = "searchable-select-options overflow-y-auto max-h-52";
        this.dropdown.appendChild(this.optionsContainer);

        // Pagination
        this.paginationContainer = document.createElement("div");
        this.paginationContainer.className = "flex items-center justify-between p-2 border-t border-slate-700 text-xs text-slate-400";
        this.dropdown.appendChild(this.paginationContainer);

        // Insert into DOM
        this.select.parentNode.insertBefore(this.wrapper, this.select);
        this.wrapper.appendChild(this.select);
        this.wrapper.appendChild(this.displayButton);
        this.wrapper.appendChild(this.dropdown);

        this.renderOptions();
    }

    bindEvents() {
        // Toggle dropdown
        this.displayButton.addEventListener("click", (e) => {
            e.preventDefault();
            this.toggleDropdown();
        });

        // Search
        this.searchInput.addEventListener("input", () => {
            this.currentPage = 1;
            this.filterOptions();
        });

        // Close on outside click
        document.addEventListener("click", (e) => {
            if (!this.wrapper.contains(e.target)) {
                this.closeDropdown();
            }
        });

        // Keyboard navigation
        this.searchInput.addEventListener("keydown", (e) => {
            if (e.key === "Escape") {
                this.closeDropdown();
            }
        });
    }

    toggleDropdown() {
        if (this.isOpen) {
            this.closeDropdown();
        } else {
            this.openDropdown();
        }
    }

    openDropdown() {
        this.isOpen = true;
        this.dropdown.classList.remove("hidden");
        this.searchInput.focus();
        this.searchInput.value = "";
        this.currentPage = 1;
        this.filterOptions();
    }

    closeDropdown() {
        this.isOpen = false;
        this.dropdown.classList.add("hidden");
    }

    filterOptions() {
        const query = this.searchInput.value.toLowerCase().trim();

        if (query === "") {
            this.filteredOptions = [...this.options];
        } else {
            this.filteredOptions = this.options.filter(option => {
                return option.text.toLowerCase().includes(query);
            });
        }

        this.renderOptions();
    }

    renderOptions() {
        this.optionsContainer.innerHTML = "";

        const startIndex = (this.currentPage - 1) * this.perPage;
        const endIndex = startIndex + this.perPage;
        const pageOptions = this.filteredOptions.slice(startIndex, endIndex);

        if (pageOptions.length === 0) {
            const noResults = document.createElement("div");
            noResults.className = "px-4 py-3 text-sm text-slate-400 text-center";
            noResults.textContent = "Aucun résultat";
            this.optionsContainer.appendChild(noResults);
        } else {
            pageOptions.forEach(option => {
                const optionEl = document.createElement("div");
                optionEl.className = "px-4 py-2 text-sm text-slate-300 hover:bg-slate-700 hover:text-blue-400 cursor-pointer transition-colors";

                if (option.value === this.select.value) {
                    optionEl.className += " bg-blue-500/20 text-blue-400";
                }

                optionEl.textContent = option.text;
                optionEl.dataset.value = option.value;

                optionEl.addEventListener("click", () => {
                    this.selectOption(option.value);
                });

                this.optionsContainer.appendChild(optionEl);
            });
        }

        this.renderPagination();
    }

    renderPagination() {
        const totalPages = Math.ceil(this.filteredOptions.length / this.perPage);

        if (totalPages <= 1) {
            this.paginationContainer.innerHTML = `<span>${this.filteredOptions.length} élément(s)</span><span></span>`;
            return;
        }

        this.paginationContainer.innerHTML = `
            <span>Page ${this.currentPage}/${totalPages} (${this.filteredOptions.length} éléments)</span>
            <div class="flex gap-1">
                <button type="button" class="pagination-prev px-2 py-1 rounded bg-slate-700 hover:bg-slate-600 disabled:opacity-50 disabled:cursor-not-allowed" ${this.currentPage === 1 ? "disabled" : ""}>←</button>
                <button type="button" class="pagination-next px-2 py-1 rounded bg-slate-700 hover:bg-slate-600 disabled:opacity-50 disabled:cursor-not-allowed" ${this.currentPage === totalPages ? "disabled" : ""}>→</button>
            </div>
        `;

        const prevBtn = this.paginationContainer.querySelector(".pagination-prev");
        const nextBtn = this.paginationContainer.querySelector(".pagination-next");

        prevBtn?.addEventListener("click", (e) => {
            e.preventDefault();
            e.stopPropagation();
            if (this.currentPage > 1) {
                this.currentPage--;
                this.renderOptions();
            }
        });

        nextBtn?.addEventListener("click", (e) => {
            e.preventDefault();
            e.stopPropagation();
            if (this.currentPage < totalPages) {
                this.currentPage++;
                this.renderOptions();
            }
        });
    }

    selectOption(value) {
        this.select.value = value;
        this.select.dispatchEvent(new Event("change", { bubbles: true }));
        this.updateDisplayText();
        this.closeDropdown();
    }

    updateDisplayText() {
        const selectedOption = this.options.find(opt => opt.value === this.select.value);
        const textSpan = this.displayButton.querySelector("span:first-child") || document.createElement("span");
        textSpan.className = "truncate flex-1";

        if (selectedOption && selectedOption.value !== "") {
            textSpan.textContent = selectedOption.text;
            textSpan.classList.remove("text-slate-400");
        } else {
            textSpan.textContent = this.select.options[0]?.text || "Sélectionner...";
            textSpan.classList.add("text-slate-400");
        }

        if (!this.displayButton.querySelector("span:first-child")) {
            this.displayButton.insertBefore(textSpan, this.displayButton.firstChild);
        }
    }
}

// Export for use with importmap
window.initSearchableSelects = initSearchableSelects;
window.SearchableSelect = SearchableSelect;
