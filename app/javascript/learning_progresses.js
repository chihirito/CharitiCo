// app/javascript/learning_progresses.js

document.addEventListener("turbo:load", function() {
  console.log('JavaScript file loaded successfully');
});

const initLearningProgress = () => {
  const questionElement = document.querySelector('.question');
  if (questionElement) {
    console.log('Question element found');
    const buttons = document.querySelectorAll('.option-button');
    const popup = document.getElementById('result-popup');
    const message = document.getElementById('result-message');
    const closePopup = document.getElementById('close-popup');
    const correctOption = document.getElementById('correct-option').value;

    console.log('Correct option:', correctOption); // 追加

    buttons.forEach(button => {
      button.addEventListener('click', () => {
        console.log('Button clicked:', button.dataset.option);
        buttons.forEach(btn => btn.classList.remove('selected'));
        button.classList.add('selected');

        if (button.dataset.option === correctOption) {
          message.textContent = 'Correct!';
        } else {
          message.textContent = `Incorrect! The correct answer was ${correctOption}.`;
        }

        popup.classList.remove('hidden');
      });
    });

    closePopup.addEventListener('click', () => {
      popup.classList.add('hidden');
    });
  }
};

// Turboのイベントリスナーを設定
document.addEventListener("turbo:load", initLearningProgress);
document.addEventListener("turbo:render", initLearningProgress);
