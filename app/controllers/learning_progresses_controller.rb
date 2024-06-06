class LearningProgressesController < ApplicationController
  before_action :authenticate_user!

  def index
    @word_data = fetch_random_word
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
  


  private

  def fetch_random_word
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/?random=true")
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
end
