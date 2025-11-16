// Guide modal - uses generic Modal class
document.addEventListener('DOMContentLoaded', () => {
  const guideModal = new Modal('guideModal');
  const form = document.getElementById('createGuideForm');

  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();

      await guideModal.submitForm('/users/create_guide', (data) => {
        // Success callback: update the user select
        const userSelect = document.getElementById('hike_history_user_id');
        if (userSelect && userSelect.tagName === 'SELECT') {
          const displayText = data.guide.name
            ? `${data.guide.name} (${data.guide.email})`
            : data.guide.email;

          const option = new Option(displayText, data.guide.id, true, true);
          userSelect.add(option);

          // Trigger change for select2 if present
          if (window.jQuery && window.jQuery(userSelect).data('select2')) {
            window.jQuery(userSelect).trigger('change');
          }
        }
      });
    });
  }

  // Make modal accessible globally for button clicks
  window.openGuideModal = () => guideModal.open();
  window.closeGuideModal = () => guideModal.close();
});
