class LearningProgressesController < ApplicationController
  before_action :authenticate_user!

  def index
    @language = params[:language]
    @word_data = fetch_random_word(@language)
    if @word_data.blank? || @word_data['word'].blank?
      flash[:alert] = 'Failed to load the question. Please try again.'
      redirect_to root_path
    else
      @options = generate_options(@word_data)
      if @options.present?
        @correct_option = @options.find { |option| correct_option?(@word_data, option) }
      else
        flash[:alert] = 'Failed to generate options. Please try again.'
        redirect_to root_path
      end
    end
  end

  def choose_language
  end

  def new
    @learning_progress = current_user.learning_progresses.new
  end

  def create
    @learning_progress = current_user.learning_progresses.new(learning_progress_params)
    if @learning_progress.save
      redirect_to root_path, notice: '学習履歴が追加されました'
    else
      render :new
    end
  end

  def increment_coins
    current_user.increment!(:coins)
    render json: { coins: current_user.coins }
  end

  def next_question
    @word_data = fetch_random_word
    if @word_data.blank? || @word_data['word'].blank?
      render json: { error: 'Failed to fetch a new word.' }, status: :unprocessable_entity
      return
    end
  
    @options = generate_options(@word_data)
    @correct_option = @options.find { |option| correct_option?(@word_data, option) }
  
    if @options.blank?
      # シノニムが見つからなかった場合は再度単語を取得
      logger.info "No synonyms found for the word: #{@word_data['word']}. Fetching a new word."
      next_question
    else
      render json: {
        word: @word_data['word'],
        options: @options,
        correct_option: @correct_option
      }
    end
  end

  def spanish_learning
    @word_data = fetch_random_word
    if @word_data.blank? || @word_data['word'].blank?
      flash[:alert] = 'Failed to load the question. Please try again.'
      redirect_to root_path
    else
      @options = generate_spanish_options(@word_data)
      if @options.present?
        @correct_option = @options.find { |option| correct_spanish_option?(@word_data, option) }
      else
        flash[:alert] = 'Failed to generate options. Please try again.'
        redirect_to root_path
      end
    end
  end

  def spanish_next_question
    @word_data = fetch_random_word
    if @word_data.blank? || @word_data['word'].blank?
      render json: { error: 'Failed to fetch a new word.' }, status: :unprocessable_entity
      return
    end

    @options = generate_spanish_options(@word_data)
    @correct_option = @options.find { |option| correct_spanish_option?(@word_data, option) }

    if @options.blank?
      # シノニムが見つからなかった場合は再度単語を取得
      logger.info "No synonyms found for the word: #{@word_data['word']}. Fetching a new word."
      spanish_next_question
    else
      render json: {
        word: @word_data['word'],
        options: @options,
        correct_option: @correct_option
      }
    end
  end

  private

  def fetch_random_word(language = 'english')
    url = "https://wordsapiv1.p.rapidapi.com/words/?random=true"

    response = api_request(url)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      Rails.logger.info("API response code: #{response.code}")
      Rails.logger.info("API response message: #{response.message}")
      Rails.logger.info("API response body: #{response.body}")
      {}
    end
  rescue StandardError => e
    Rails.logger.error("API request error: #{e.message}")
    {}
  end

  def generate_options(word_data)
    result = word_data.dig('results', 0)
    if result && result['synonyms'].present?
      correct_option = result['synonyms'].sample
      other_words = Array.new(3) { fetch_random_word&.dig('word') }.compact
      Rails.logger.info("Generated options: #{other_words + [correct_option]}")
      (other_words + [correct_option]).shuffle
    else
      []
    end
  end

  def correct_option?(word_data, option)
    result = word_data.dig('results', 0)
    result && result['synonyms'] && result['synonyms'].include?(option)
  end

  def api_request(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request["X-RapidAPI-Key"] = '9181eb53c2msh1ffb45d44a88647p16b21bjsnbaba426f557a'
    request["X-RapidAPI-Host"] = 'wordsapiv1.p.rapidapi.com'

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.error("API request error: #{e.message}")
    nil
  end

  def learning_progress_params
    params.require(:learning_progress).permit(:content, :progress)
  end

  def generate_spanish_options(word_data)
    result = word_data.dig('results', 0)
    if result && result['synonyms'].present?
      correct_option = translate_to_spanish(result['synonyms'].sample)
      other_words = Array.new(3) { translate_to_spanish(fetch_random_word&.dig('word')) }.compact
      (other_words + [correct_option]).shuffle
    else
      []
    end
  end

  def correct_spanish_option?(word_data, option)
    result = word_data.dig('results', 0)
    correct_option = translate_to_spanish(result['synonyms'].sample) if result && result['synonyms'].present?
    correct_option == option
  end

  def translate_to_spanish(word)
    api_key = 'AIzaSyBRuY34NeJgWGuiIfVT0Cki7YXVvW2CUDI'
    url = URI("https://translation.googleapis.com/language/translate/v2?key=#{api_key}")
    params = {
      q: word,
      target: 'es',
      source: 'en'
    }

    response = Net::HTTP.post_form(url, params)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body).dig("data", "translations", 0, "translatedText")
    else
      Rails.logger.error("Translation API request error: #{response.message}")
      word # 翻訳に失敗した場合は元の単語を返す
    end
  end
end
