// Generic reusable modal system
class Modal {
  constructor(modalId) {
    this.modal = document.getElementById(modalId);
    this.setupEventListeners();
  }

  setupEventListeners() {
    if (!this.modal) return;

    // Close on backdrop click
    this.modal.addEventListener('click', (e) => {
      if (e.target === this.modal) {
        this.close();
      }
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !this.modal.classList.contains('hidden')) {
        this.close();
      }
    });

    // Close buttons with data-modal-close attribute
    const closeButtons = this.modal.querySelectorAll('[data-modal-close]');
    closeButtons.forEach(btn => {
      btn.addEventListener('click', () => this.close());
    });
  }

  open() {
    if (this.modal) {
      this.modal.classList.remove('hidden');
      this.hideErrors();
      this.resetForm();
    }
  }

  close() {
    if (this.modal) {
      this.modal.classList.add('hidden');
      this.hideErrors();
    }
  }

  showErrors(errors) {
    const errorContainer = this.modal.querySelector('[data-modal-errors]');
    const errorsList = this.modal.querySelector('[data-modal-errors-list]');

    if (errorContainer && errorsList) {
      errorsList.innerHTML = '';
      errors.forEach(error => {
        const li = document.createElement('li');
        li.textContent = error;
        errorsList.appendChild(li);
      });
      errorContainer.classList.remove('hidden');
    }
  }

  hideErrors() {
    const errorContainer = this.modal.querySelector('[data-modal-errors]');
    if (errorContainer) {
      errorContainer.classList.add('hidden');
    }
  }

  resetForm() {
    const form = this.modal.querySelector('form');
    if (form) {
      form.reset();
    }
  }

  async submitForm(url, onSuccess) {
    const form = this.modal.querySelector('form');
    if (!form) return;

    const submitButton = form.querySelector('[type="submit"]');
    const originalText = submitButton?.textContent;

    if (submitButton) {
      submitButton.disabled = true;
      submitButton.textContent = 'En cours...';
    }

    const formData = new FormData(form);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json',
        },
        body: formData
      });

      const data = await response.json();

      if (data.success) {
        this.close();
        if (onSuccess) onSuccess(data);
      } else {
        this.showErrors(data.errors);
      }
    } catch (error) {
      console.error('Modal form submission error:', error);
      this.showErrors(['Une erreur est survenue.']);
    } finally {
      if (submitButton) {
        submitButton.disabled = false;
        submitButton.textContent = originalText;
      }
    }
  }
}

// Export for use in other modules
window.Modal = Modal;
