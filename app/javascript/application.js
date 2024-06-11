

// turboのメソッドを無効にする
document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll('a[data-method="delete"]').forEach((element) => {
    element.addEventListener('click', (event) => {
      event.preventDefault();
      const form = document.createElement('form');
      form.style.display = 'none';
      form.method = 'POST';
      form.action = element.href;

      const csrfInput = document.createElement('input');
      csrfInput.name = '_method';
      csrfInput.value = 'delete';
      form.appendChild(csrfInput);

      const csrfTokenInput = document.createElement('input');
      csrfTokenInput.name = 'authenticity_token';
      csrfTokenInput.value = document.querySelector('meta[name="csrf-token"]').content;
      form.appendChild(csrfTokenInput);

      document.body.appendChild(form);
      form.submit();
    });
  })
})