require 'net/http'
require 'uri'
require 'json'

class LearningProgressesController < ApplicationController
  before_action :authenticate_user!

  def index
    @word_data = fetch_random_word
    if @word_data.blank? || @word_data['word'].blank?
      redirect_to root_path
    else
      @options = generate_options(@word_data)
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

  def check
    response = Net::HTTP.get(URI("https://wordsapiv1.p.rapidapi.com/words/#{URI.encode_www_form_component(@word)}/synonyms"))
    synonyms = JSON.parse(response)['synonyms'] || []
    @is_correct = synonyms.include?(@option)
  
    # fetch_correct_optionメソッドの処理をここに直接組み込む
    correct_option = synonyms.sample || "No correct option found"
  
    current_user.increment!(:coins) if @is_correct
  
    if @is_correct
      redirect_to correct_learning_progresses_path
    else
      flash[:correct_option] = correct_option
      redirect_to incorrect_learning_progresses_path
    end
  end


  private

  def fetch_random_word
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/?random=true")
    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    Rails.logger.error("Error fetching random word: #{response.message}")
    nil
  end

  def generate_options(word_data)
    result = word_data.dig('results', 0)
    if result
      correct_option = result['synonyms'].sample
      other_words = Array.new(3) { fetch_random_word&.dig('word') }.compact
      (other_words + [correct_option]).shuffle
    else
      ["ダミー1", "ダミー2", "ダミー3", "ダミー4"].shuffle
    end
  end

  def correct_answer?(word, option)
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/#{URI.encode_www_form_component(word)}/synonyms")
    synonyms = JSON.parse(response.body).fetch('synonyms', [])
    synonyms.include?(option)
  end

  def fetch_correct_option(word)
    response = api_request("https://wordsapiv1.p.rapidapi.com/words/#{URI.encode_www_form_component(word)}/synonyms")
    synonyms = JSON.parse(response.body).fetch('synonyms', [])
    synonyms.sample
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
