document.addEventListener('turbolinks:load', () => {
  // 共通の処理を関数として定義
  const setupLearningPage = (language) => {
    const buttons = document.querySelectorAll('.option-button');
    const correctOption = document.getElementById('correct-option').value;
    const resultPopup = document.getElementById('result-popup');
    const resultMessage = document.getElementById('result-message');
    const nextQuestionButton = document.getElementById('next-question');
    const closePopupButton = document.getElementById('close-popup');
    const coinsDisplay = document.getElementById('coins-display');

    buttons.forEach(button => {
      button.addEventListener('click', (event) => {
        const selectedOption = event.target.getAttribute('data-option');
        if (selectedOption === correctOption) {
          resultMessage.textContent = 'Correct!';
          // コインを増やす処理
          fetch('/learning_progresses/increment_coins', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            }
          })
          .then(response => response.json())
          .then(data => {
            coinsDisplay.textContent = `Coins: ${data.coins}`;
          });
        } else {
          resultMessage.textContent = `Incorrect. The correct answer is ${correctOption}.`;
        }
        resultPopup.classList.remove('hidden');
        nextQuestionButton.classList.remove('hidden');
      });
    });

    closePopupButton.addEventListener('click', () => {
      resultPopup.classList.add('hidden');
      nextQuestionButton.classList.add('hidden');
    });

    nextQuestionButton.addEventListener('click', () => {
      fetch(`/learning_progresses/next_question?language=${language}`)
        .then(response => response.json())
        .then(data => {
          if (data.error) {
            resultMessage.textContent = data.error;
          } else {
            document.querySelector('.word').textContent = data.word;
            buttons.forEach((button, index) => {
              button.textContent = data.options[index];
              button.setAttribute('data-option', data.options[index]);
            });
            document.getElementById('correct-option').value = data.correct_option;
            resultPopup.classList.add('hidden');
            nextQuestionButton.classList.add('hidden');
          }
        });
    });
  };

  // ページごとに設定を呼び出す
  if (document.querySelector('body.learning_progresses')) {
    setupLearningPage('english');
  }
  if (document.querySelector('body.spanish_learning')) {
    setupLearningPage('spanish');
  }
});
