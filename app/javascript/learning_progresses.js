

const initLearningProgress = () => {
  const questionElement = document.querySelector('.question');
  if (questionElement) {
    const buttons = document.querySelectorAll('.option-button');
    const popup = document.getElementById('result-popup');
    const message = document.getElementById('result-message');
    const closePopup = document.getElementById('close-popup');
    const correctOptionElement = document.getElementById('correct-option');
    const coinsDisplay = document.getElementById('coins-display');
    const nextQuestionButton = document.getElementById('next-question');

    const incrementCoins = async (word) => {
      try {
        const response = await fetch('/learning_progresses/increment_coins', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          },
          body: JSON.stringify({ word: word })
        });
        const data = await response.json();
        coinsDisplay.textContent = `Coins: ${data.coins}`;
      } catch (error) {
        console.error('Error incrementing coins:', error);
      }
    };

    const loadNextQuestion = async () => {
      try {
        const response = await fetch('/learning_progresses/next_question', {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          }
        });
        const data = await response.json();
        if (response.ok) {
          document.querySelector('.word').textContent = data.word;
          const newOptions = data.options;
          buttons.forEach((button, index) => {
            button.textContent = newOptions[index];
            button.dataset.option = newOptions[index];
          });
          correctOptionElement.value = data.correct_option;
        } else {
          console.error('Error loading next question:', data.error);
        }
      } catch (error) {
        console.error('Error loading next question:', error);
      }
    };

    buttons.forEach(button => {
      button.addEventListener('click', async (e) => {
        e.preventDefault();
        buttons.forEach(btn => btn.classList.remove('selected'));
        button.classList.add('selected');

        if (button.dataset.option === correctOptionElement.value) {
          message.textContent = 'Correct!';
          await incrementCoins(correctOptionElement.value);
          nextQuestionButton.classList.remove('hidden');
        } else {
          message.textContent = `Incorrect! The correct answer was ${correctOptionElement.value}.`;
          nextQuestionButton.classList.add('hidden');
        }

        popup.classList.remove('hidden');
      });
    });

    closePopup.addEventListener('click', (e) => {
      e.preventDefault();
      popup.classList.add('hidden');
    });

    nextQuestionButton.addEventListener('click', async (e) => {
      e.preventDefault();
      popup.classList.add('hidden');
      await loadNextQuestion();
    });
  }
};

// Turboのイベントリスナーを設定
document.addEventListener("DOMContentLoaded", initLearningProgress);